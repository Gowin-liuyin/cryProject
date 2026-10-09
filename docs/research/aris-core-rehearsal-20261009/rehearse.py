import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time

CGROUP_ROOT = Path('/sys/fs/cgroup')
WORK_ROOT = Path('/home/nss-marker/yhr/Cry')
ONLINE_CPUS = set(range(32))
RESERVED_CPUS = {2, 18}
HOUSEKEEPING_CPUS = ONLINE_CPUS - RESERVED_CPUS
HOUSEKEEPING_TEXT = '0-1,3-17,19-31'
INVENTORY_SHA256 = '16284d8f6dc990a1f08c0ac9b27f3754571cbb6ff2ab0fc586b6b3a20db497a0'
TOP_UNITS = ['dev-hugepages.mount', 'dev-mqueue.mount', 'init.scope',
             'proc-sys-fs-binfmt_misc.mount', 'sys-fs-fuse-connections.mount',
             'sys-kernel-config.mount', 'sys-kernel-debug.mount',
             'sys-kernel-tracing.mount', 'system.slice', 'user.slice']
PROPERTY_NAMES = ['AllowedCPUs', 'StartupAllowedCPUs', 'AllowedMemoryNodes',
                  'StartupAllowedMemoryNodes', 'ControlGroup', 'Transient',
                  'FragmentPath', 'DropInPaths']
GROUP_FIELDS = ['cpuset.cpus', 'cpuset.cpus.effective', 'cpuset.mems',
                'cpuset.mems.effective', 'cgroup.subtree_control']
HEADER_LINES = ['# This is a drop-in unit file extension, created via "systemctl set-property"',
                '# or an equivalent operation. Do not edit.']


def cpu_set(value):
    values = set()
    for part in re.split(r'[ ,]+', value.strip()):
        if part:
            bounds = part.split('-')
            if len(bounds) > 2 or any(not bound.isdigit() for bound in bounds):
                raise ValueError('Invalid CPU list')
            lower = int(bounds[0])
            upper = int(bounds[-1])
            if lower > upper or upper > 31:
                raise ValueError('CPU list outside this rehearsal')
            values.update(range(lower, upper + 1))
    return values


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def save_json(path, value):
    temporary = path.with_suffix(path.suffix + '.new')
    with temporary.open('w') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def load_json(path):
    return json.loads(path.read_text())


def command(directory, arguments, timeout_seconds=5, require_success=True):
    entry = {'utc': utc_now(), 'arguments': arguments}
    try:
        result = subprocess.run(arguments, capture_output=True, text=True,
                                timeout=timeout_seconds)
        entry.update(returncode=result.returncode, stdout=result.stdout, stderr=result.stderr)
    except subprocess.TimeoutExpired:
        entry.update(returncode=None, timeout_seconds=timeout_seconds)
        result = None
    with (directory / 'commands.jsonl').open('a') as stream:
        stream.write(json.dumps(entry, ensure_ascii=False) + '\n')
    if require_success and (result is None or result.returncode != 0):
        raise RuntimeError('Management command failed: ' + arguments[0])
    return entry


def properties(directory, unit, names=PROPERTY_NAMES):
    arguments = ['systemctl', 'show', unit, '--no-pager']
    for name in names:
        arguments.extend(['-p', name])
    result = command(directory, arguments, require_success=False)
    if result.get('returncode') is None:
        raise RuntimeError('Unit query timed out')
    return dict(line.split('=', 1) for line in result.get('stdout', '').splitlines()
                if '=' in line)


def optional_read(path):
    try:
        return path.read_text().strip()
    except FileNotFoundError:
        return None


def group_values(path):
    return {name: optional_read(path / name) for name in GROUP_FIELDS}


def configuration_fingerprints(values, ignored_path=None):
    paths = set(values.get('DropInPaths', '').split())
    if values.get('FragmentPath'):
        paths.add(values['FragmentPath'])
    if ignored_path is not None:
        paths.discard(str(ignored_path))
    return {name: hashlib.sha256(Path(name).read_bytes()).hexdigest() for name in sorted(paths)}


def check_root_threads():
    for token in (CGROUP_ROOT / 'cgroup.threads').read_text().split():
        fields = (Path('/proc') / token / 'stat').read_text().rsplit(')', 1)[1].split()
        if not int(fields[6]) & 0x00200000:
            raise RuntimeError('Ordinary root-group thread is outside managed top-level units')


def property_path(unit):
    parent = '/run/systemd/transient' if unit == 'init.scope' else '/run/systemd/system.control'
    return Path(parent) / (unit + '.d') / '50-AllowedCPUs.conf'


def generated_value(contents):
    lines = contents.decode('utf-8').splitlines()
    if len(lines) != 5 or lines[:2] != HEADER_LINES:
        raise ValueError('Unrecognized property file')
    if lines[2] not in ['[Unit]', '[Scope]', '[Slice]', '[Mount]']:
        raise ValueError('Unrecognized property section')
    if lines[3] != 'AllowedCPUs=' or not lines[4].startswith('AllowedCPUs='):
        raise ValueError('Unrecognized property assignments')
    return cpu_set(lines[4].split('=', 1)[1])


def check_owned_file(path, permitted_values):
    metadata = path.lstat()
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != 0:
        raise RuntimeError('Property file is not an owned regular file')
    value = generated_value(path.read_bytes())
    if value not in permitted_values:
        raise RuntimeError('Property file changed concurrently')
    return value


def stop_owned_unit(directory, unit):
    state = properties(directory, unit, ['LoadState'])
    if state.get('LoadState') == 'not-found':
        return
    command(directory, ['systemctl', 'stop', unit])


def current_top_units():
    return sorted(path.name for path in CGROUP_ROOT.iterdir() if path.is_dir())


def snapshot(directory):
    if platform.node() != 'nss-m' or not platform.release().startswith('6.17.'):
        raise RuntimeError('Unexpected host or kernel')
    version = command(directory, ['systemctl', '--version'])['stdout'].splitlines()[0]
    if not version.startswith('systemd 255 '):
        raise RuntimeError('Unexpected systemd version')
    manager = command(directory, ['systemctl', 'is-system-running'], require_success=False)
    if manager.get('stdout', '').strip() not in ['running', 'degraded']:
        raise RuntimeError('Manager is starting, stopping or unavailable')
    if cpu_set(Path('/sys/devices/system/cpu/online').read_text()) != ONLINE_CPUS:
        raise RuntimeError('Online CPUs changed')
    for cpu in RESERVED_CPUS:
        path = Path('/sys/devices/system/cpu') / ('cpu' + str(cpu)) / 'topology/thread_siblings_list'
        if cpu_set(path.read_text()) != RESERVED_CPUS:
            raise RuntimeError('Sibling topology changed')
    if current_top_units() != TOP_UNITS:
        raise RuntimeError('Top-level units changed')
    inventory = command(directory, [sys.executable, str(directory / 'inventory.py')])
    records = json.loads(inventory['stdout'])
    save_json(directory / 'inventory-before.json', records)
    if records['snapshot_conflicts_observed']:
        raise RuntimeError('Fresh inventory has a conflict or read gap')
    baseline = {'utc': utc_now(), 'units': {}, 'unit_file_hashes': {}, 'groups': {},
                'threads': records['thread_records'], 'parent_existed': {}}
    for row in records['cgroup_records']:
        if row['requested'] not in [None, ''] or row['effective'] not in [None, '0-31']:
            raise RuntimeError('Existing CPU configuration is outside the constrained baseline')
        path = CGROUP_ROOT / row['path'].lstrip('/')
        partition = optional_read(path / 'cpuset.cpus.partition')
        if partition not in [None, 'member']:
            raise RuntimeError('Existing partition is outside the constrained baseline')
        values = group_values(path)
        if values['cpuset.mems'] not in [None, '']:
            raise RuntimeError('Existing memory node request is not empty')
        baseline['groups'][row['path']] = values
    if optional_read(CGROUP_ROOT / 'cpuset.cpus.isolated') != '':
        raise RuntimeError('Existing isolated CPUs')
    for unit in TOP_UNITS:
        values = properties(directory, unit)
        if any(values.get(name) != '' for name in PROPERTY_NAMES[:4]):
            raise RuntimeError('Existing manager CPU or memory configuration')
        if values.get('ControlGroup') != '/' + unit:
            raise RuntimeError('Unit mapping changed')
        baseline['units'][unit] = values
        baseline['unit_file_hashes'][unit] = configuration_fingerprints(values)
        for parent in ['/run/systemd/system.control', '/run/systemd/transient']:
            path = Path(parent) / (unit + '.d') / '50-AllowedCPUs.conf'
            if path.exists() or path.is_symlink():
                raise RuntimeError('Original property file must be absent')
            baseline['parent_existed'][str(path.parent)] = path.parent.exists()
    return baseline


def check_window(directory, configuration, changed_units):
    expected_top = sorted(TOP_UNITS + [configuration['slice']])
    if current_top_units() != expected_top:
        raise RuntimeError('Top-level units changed during rehearsal')
    if cpu_set(Path('/sys/devices/system/cpu/online').read_text()) != ONLINE_CPUS:
        raise RuntimeError('Online CPUs changed during rehearsal')
    baseline = load_json(directory / 'baseline.json')
    check_root_threads()
    for unit in TOP_UNITS:
        values = properties(directory, unit)
        expected = HOUSEKEEPING_CPUS if unit in changed_units else set()
        if cpu_set(values.get('AllowedCPUs', '')) != expected:
            raise RuntimeError('Unit CPU property changed concurrently')
        original = baseline['units'][unit]
        for name in ['StartupAllowedCPUs', 'AllowedMemoryNodes', 'StartupAllowedMemoryNodes',
                     'FragmentPath', 'ControlGroup', 'Transient']:
            if values.get(name) != original.get(name):
                raise RuntimeError('Unit configuration changed concurrently')
        expected_dropins = set(original['DropInPaths'].split())
        if unit in changed_units:
            expected_dropins.add(str(property_path(unit)))
            check_owned_file(property_path(unit), [HOUSEKEEPING_CPUS])
        if set(values.get('DropInPaths', '').split()) != expected_dropins:
            raise RuntimeError('Unit drop-ins changed concurrently')
        if configuration_fingerprints(values, property_path(unit)) != baseline['unit_file_hashes'][unit]:
            raise RuntimeError('Existing configuration file content changed')
        effective = (CGROUP_ROOT / unit / 'cpuset.cpus.effective').read_text()
        if cpu_set(effective) != (HOUSEKEEPING_CPUS if unit in changed_units else ONLINE_CPUS):
            raise RuntimeError('An ordinary unit kernel cpuset differs')
    own_unit = configuration['slice']
    if cpu_set(properties(directory, own_unit).get('AllowedCPUs', '')) != RESERVED_CPUS:
        raise RuntimeError('Reservation slice property differs')
    check_owned_file(property_path(own_unit), [RESERVED_CPUS])
    if cpu_set((CGROUP_ROOT / own_unit / 'cpuset.cpus.effective').read_text()) != RESERVED_CPUS:
        raise RuntimeError('Reservation slice kernel cpuset differs')


def check_before_write(directory, unit, configuration):
    for parent in ['/run/systemd/system.control', '/run/systemd/transient']:
        path = Path(parent) / (unit + '.d') / '50-AllowedCPUs.conf'
        if path.exists() or path.is_symlink():
            raise RuntimeError('Property file appeared before mutation')
    if unit == configuration['slice']:
        if (CGROUP_ROOT / unit).exists():
            raise RuntimeError('Reservation slice already exists')
    else:
        baseline = load_json(directory / 'baseline.json')
        if properties(directory, unit) != baseline['units'][unit]:
            raise RuntimeError('Untouched unit changed before mutation')
        if configuration_fingerprints(baseline['units'][unit]) != baseline['unit_file_hashes'][unit]:
            raise RuntimeError('Untouched configuration file content changed')
        if group_values(CGROUP_ROOT / unit) != baseline['groups']['/' + unit]:
            raise RuntimeError('Untouched kernel CPU/memory/controller configuration changed')


def apply(directory):
    configuration = load_json(directory / 'configuration.json')
    changed_units = []
    for unit in [configuration['slice']] + TOP_UNITS:
        check_before_write(directory, unit, configuration)
        changed_units.append(unit)
        save_json(directory / 'may-touch.json', changed_units)
        value = '2,18' if unit == configuration['slice'] else HOUSEKEEPING_TEXT
        command(directory, ['systemctl', 'set-property', '--runtime', unit, 'AllowedCPUs=' + value])
        if unit == configuration['slice']:
            command(directory, ['systemctl', 'start', unit])
        target = RESERVED_CPUS if unit == configuration['slice'] else HOUSEKEEPING_CPUS
        actual = (CGROUP_ROOT / unit / 'cpuset.cpus.effective').read_text()
        if cpu_set(actual) != target:
            raise RuntimeError('Kernel cpuset readback differs')
        check_window(directory, configuration, changed_units)
    command(directory, ['systemd-run', '--unit=' + configuration['task'],
                        '--slice=' + configuration['slice'], '--property=Type=oneshot',
                        '--property=RemainAfterExit=yes', '--property=TimeoutStartSec=5s',
                        '--property=CPUAffinity=2', '--property=AllowedCPUs=2', '/bin/true'])
    task = properties(directory, configuration['task'],
                      ['Result', 'ExecMainStatus', 'AllowedCPUs', 'CPUAffinity', 'ControlGroup'])
    if task.get('Result') != 'success' or task.get('ExecMainStatus') != '0':
        raise RuntimeError('Empty task failed')
    if cpu_set(task.get('AllowedCPUs', '')) != {2} or cpu_set(task.get('CPUAffinity', '')) != {2}:
        raise RuntimeError('Empty task management configuration differs')
    check_window(directory, configuration, changed_units)
    save_json(directory / 'applied.json', {'utc': utc_now(), 'task': task,
              'slice_effective': (CGROUP_ROOT / configuration['slice'] / 'cpuset.cpus.effective').read_text().strip(),
              'ordinary_task_reservation_readback': True, 'observed_cpu_execution_trace': False})


def restore(directory):
    configuration = load_json(directory / 'configuration.json')
    baseline = load_json(directory / 'baseline.json')
    result = {'utc': utc_now(), 'errors': [], 'ended_groups': [], 'ended_threads': 0,
              'changed_thread_identity_or_group': [], 'surviving_threads_checked': 0,
              'restoration_verified': False}
    attempt_path = directory / ('restore-attempt-' + str(time.time_ns()) + '.json')
    try:
        stop_owned_unit(directory, configuration['apply'])
        apply_group = CGROUP_ROOT / 'system.slice' / configuration['apply']
        if apply_group.exists() and (apply_group / 'cgroup.procs').read_text().strip():
            raise RuntimeError('Apply process group is not empty; refusing concurrent restore')
    except Exception as error:
        result['errors'].append({'stage': 'stop_apply', 'reason': str(error)})
        save_json(attempt_path, result)
        save_json(directory / 'restored.json', result)
        raise
    try:
        stop_owned_unit(directory, configuration['task'])
    except Exception as error:
        result['errors'].append({'stage': 'stop_empty_task', 'reason': str(error)})
    touched = load_json(directory / 'may-touch.json') if (directory / 'may-touch.json').exists() else []
    for unit in reversed(touched):
        try:
            path = property_path(unit)
            expected = RESERVED_CPUS if unit == configuration['slice'] else HOUSEKEEPING_CPUS
            values = properties(directory, unit)
            live = cpu_set(values.get('AllowedCPUs', ''))
            if live not in [set(), expected]:
                raise RuntimeError('Concurrent CPU property; not overwriting')
            original = baseline['units'].get(unit)
            if original:
                for name in ['StartupAllowedCPUs', 'AllowedMemoryNodes', 'StartupAllowedMemoryNodes',
                             'FragmentPath', 'ControlGroup', 'Transient']:
                    if values.get(name) != original.get(name):
                        raise RuntimeError('Concurrent non-CPU configuration; not overwriting')
                dropins = set(values.get('DropInPaths', '').split()) - {str(path)}
                if dropins != set(original['DropInPaths'].split()):
                    raise RuntimeError('Concurrent drop-in configuration; not overwriting')
                if configuration_fingerprints(values, path) != baseline['unit_file_hashes'][unit]:
                    raise RuntimeError('Concurrent original file content; not overwriting')
            if path.exists() or path.is_symlink():
                check_owned_file(path, [set(), expected])
            elif live:
                raise RuntimeError('Restricted property has no owned file')
            if live:
                command(directory, ['systemctl', 'set-property', '--runtime', unit, 'AllowedCPUs='])
            if path.exists() or path.is_symlink():
                check_owned_file(path, [set(), expected])
                path.unlink()
            if not baseline['parent_existed'].get(str(path.parent), False) and path.parent.exists():
                path.parent.rmdir()
        except Exception as error:
            result['errors'].append({'unit': unit, 'reason': str(error)})
    try:
        stop_owned_unit(directory, configuration['slice'])
    except Exception as error:
        result['errors'].append({'stage': 'stop_slice', 'reason': str(error)})
    try:
        command(directory, ['systemctl', 'daemon-reload'])
    except Exception as error:
        result['errors'].append({'stage': 'daemon_reload', 'reason': str(error)})
    for unit, original in baseline['units'].items():
        try:
            if properties(directory, unit) != original:
                raise RuntimeError('Manager properties differ after restore')
            for parent in ['/run/systemd/system.control', '/run/systemd/transient']:
                path = Path(parent) / (unit + '.d') / '50-AllowedCPUs.conf'
                if path.exists() or path.is_symlink():
                    raise RuntimeError('Original absent property file remains')
                if path.parent.exists() != baseline['parent_existed'][str(path.parent)]:
                    raise RuntimeError('Property parent existence differs')
        except Exception as error:
            result['errors'].append({'unit': unit, 'reason': str(error)})
    for name, original in baseline['groups'].items():
        path = CGROUP_ROOT / name.lstrip('/')
        try:
            if not path.exists():
                result['ended_groups'].append(name)
                if name == '/' or name.lstrip('/') in TOP_UNITS:
                    result['errors'].append({'group': name, 'reason': 'Required group disappeared'})
            elif group_values(path) != original:
                result['errors'].append({'group': name, 'reason': 'CPU/memory/controller readback differs'})
        except Exception as error:
            result['errors'].append({'group': name, 'reason': str(error)})
    for original in baseline['threads']:
        task = Path('/proc') / str(original['pid']) / 'task' / str(original['tid'])
        try:
            fields = (task / 'stat').read_text().rsplit(')', 1)[1].split()
            groups = [line[3:] for line in (task / 'cgroup').read_text().splitlines() if line.startswith('0::')]
            if fields[19] != original['start_ticks'] or groups != original['cgroup']:
                result['changed_thread_identity_or_group'].append(original['tid'])
                continue
            if set(os.sched_getaffinity(original['tid'])) != set(original['allowed_cpus']):
                result['errors'].append({'tid': original['tid'], 'reason': 'Surviving affinity differs'})
            result['surviving_threads_checked'] += 1
        except (FileNotFoundError, ProcessLookupError):
            result['ended_threads'] += 1
        except Exception as error:
            result['errors'].append({'tid': original['tid'], 'reason': str(error)})
    try:
        if current_top_units() != TOP_UNITS:
            result['errors'].append({'reason': 'Top-level set differs after restore'})
    except Exception as error:
        result['errors'].append({'stage': 'top_level_readback', 'reason': str(error)})
    result['restoration_verified'] = not result['errors']
    save_json(attempt_path, result)
    save_json(directory / 'restored.json', result)
    if result['errors']:
        raise RuntimeError('Restoration readback has differences; retain state and watchdog')


def arm_timer(directory, name, mode, delay_seconds):
    execution_seconds = 300 if mode == 'restore' else 10
    return command(directory, ['systemd-run', '--unit=' + name, '--on-active=' + str(delay_seconds) + 's',
                   '--timer-property=AccuracySec=1us', '--timer-property=RandomizedDelaySec=0',
                   '--property=Type=oneshot', '--property=RemainAfterExit=yes',
                   '--property=TimeoutStartSec=' + str(execution_seconds) + 's', '--property=TimeoutStopSec=2s',
                   '--property=KillMode=control-group', '--property=CPUAffinity=' + HOUSEKEEPING_TEXT,
                   sys.executable, str(directory / 'rehearse.py'), mode, str(directory)])


def launch(run_directory):
    run_directory = run_directory.resolve()
    if run_directory.parent != WORK_ROOT or not re.fullmatch(r'core-rehearsal-20261009-[a-z0-9]+', run_directory.name):
        raise RuntimeError('Unexpected run directory')
    if run_directory.stat().st_uid != 1000 or (run_directory / 'results').exists():
        raise RuntimeError('Run ownership differs or output already exists')
    source = run_directory / 'source'
    if hashlib.sha256((source / 'inventory.py').read_bytes()).hexdigest() != INVENTORY_SHA256:
        raise RuntimeError('Frozen inventory source differs')
    directory = Path(tempfile.mkdtemp(prefix='a113core', dir='/run'))
    directory.chmod(0o700)
    for name in ['rehearse.py', 'inventory.py']:
        shutil.copyfile(source / name, directory / name)
    nonce = directory.name
    configuration = {'slice': nonce + '.slice', 'apply': nonce + 'apply.service',
                     'task': nonce + 'task.service', 'marker': nonce + 'marker',
                     'restore': nonce + 'restore'}
    save_json(directory / 'configuration.json', configuration)
    save_json(directory / 'source-hashes.json', {name: hashlib.sha256((directory / name).read_bytes()).hexdigest()
                                               for name in ['rehearse.py', 'inventory.py']})
    watchdog_armed = False
    watchdog_requested = False
    marker_requested = False
    outcome = {'root_state_directory': str(directory), 'utc_started': utc_now(),
               'configuration_changes_attempted': False, 'success': False, 'errors': []}
    try:
        save_json(directory / 'baseline.json', snapshot(directory))
        marker_requested = True
        arm_timer(directory, configuration['marker'], 'marker', 1)
        deadline = time.monotonic() + 8
        while not (directory / 'marker.json').exists() and time.monotonic() < deadline:
            time.sleep(0.1)
        marker = properties(directory, configuration['marker'] + '.timer', ['LastTriggerUSecMonotonic'])
        if not (directory / 'marker.json').exists() or marker.get('LastTriggerUSecMonotonic', '0') == '0':
            raise RuntimeError('Independent marker timer did not trigger')
        save_json(directory / 'marker-observed.json', marker)
        for suffix in ['.timer', '.service']:
            stop_owned_unit(directory, configuration['marker'] + suffix)
        watchdog_requested = True
        arm_timer(directory, configuration['restore'], 'restore', 45)
        watchdog_armed = True
        timer = properties(directory, configuration['restore'] + '.timer', ['ActiveState', 'NextElapseUSecMonotonic'])
        if timer.get('ActiveState') != 'active':
            raise RuntimeError('Restore timer is not armed')
        save_json(directory / 'watchdog-armed.json', timer)
        outcome['configuration_changes_attempted'] = True
        command(directory, ['systemd-run', '--unit=' + configuration['apply'],
                '--property=Type=oneshot', '--property=RemainAfterExit=yes',
                '--property=TimeoutStartSec=20s', '--property=TimeoutStopSec=2s',
                '--property=KillMode=control-group', '--property=CPUAffinity=' + HOUSEKEEPING_TEXT,
                sys.executable, str(directory / 'rehearse.py'), 'apply', str(directory)], timeout_seconds=25)
    except Exception as error:
        outcome['errors'].append(str(error))
    finally:
        if watchdog_armed:
            try:
                command(directory, ['systemctl', 'start', configuration['restore'] + '.service'], timeout_seconds=315)
                restored = load_json(directory / 'restored.json')
                if not restored['restoration_verified']:
                    raise RuntimeError('Restore is not verified')
                for unit in [configuration['restore'] + '.timer', configuration['restore'] + '.service',
                             configuration['apply']]:
                    stop_owned_unit(directory, unit)
                outcome['success'] = (directory / 'applied.json').exists() and not outcome['errors']
            except Exception as error:
                outcome['errors'].append(str(error))
        elif watchdog_requested:
            for suffix in ['.timer', '.service']:
                try:
                    stop_owned_unit(directory, configuration['restore'] + suffix)
                except Exception as error:
                    outcome['errors'].append(str(error))
        if marker_requested:
            for suffix in ['.timer', '.service']:
                try:
                    stop_owned_unit(directory, configuration['marker'] + suffix)
                except Exception as error:
                    outcome['errors'].append(str(error))
        outcome['success'] = outcome['success'] and not outcome['errors']
        outcome['utc_finished'] = utc_now()
        save_json(directory / 'outcome.json', outcome)
        output = run_directory / 'results'
        try:
            output.mkdir(mode=0o700)
            for path in directory.iterdir():
                if path.suffix in ['.json', '.jsonl']:
                    target = output / path.name
                    shutil.copyfile(path, target)
                    os.chown(target, 1000, 1000)
            os.chown(output, 1000, 1000)
        except Exception as error:
            outcome['errors'].append('Result export failed: ' + str(error))
            outcome['success'] = False
            save_json(directory / 'outcome.json', outcome)
            print(json.dumps(outcome, ensure_ascii=False))
            raise
        print(json.dumps(outcome, ensure_ascii=False))
    if not outcome['success']:
        raise RuntimeError('Management rehearsal incomplete; inspect retained state')


def selfcheck():
    from unittest.mock import patch

    assert cpu_set(HOUSEKEEPING_TEXT) == HOUSEKEEPING_CPUS
    for value in ['', '2,18', HOUSEKEEPING_TEXT]:
        contents = ('\n'.join(HEADER_LINES + ['[Unit]', 'AllowedCPUs=', 'AllowedCPUs=' + value]) + '\n').encode()
        assert generated_value(contents) == cpu_set(value)
        try:
            generated_value(contents + b'CPUQuota=1%\n')
        except ValueError:
            pass
        else:
            raise AssertionError('Unrelated settings accepted')
    for value in ['31-2', '32', '-1', '2;id', '2-3-4']:
        try:
            cpu_set(value)
        except ValueError:
            pass
        else:
            raise AssertionError('Invalid CPU list accepted')
    assert str(property_path('init.scope')).startswith('/run/systemd/transient/')
    with tempfile.TemporaryDirectory(prefix='a113core-selfcheck-') as temporary:
        directory = Path(temporary)
        units = TOP_UNITS[:2]
        configuration = {'apply': 'ownedapply.service', 'task': 'ownedtask.service',
                         'slice': 'ownedslice.slice'}
        baseline = {'units': {unit: dict.fromkeys(PROPERTY_NAMES, '') for unit in units},
                    'unit_file_hashes': {unit: {} for unit in units},
                    'groups': {}, 'threads': [], 'parent_existed': {}}
        for unit in units:
            for parent in ['/run/systemd/system.control', '/run/systemd/transient']:
                baseline['parent_existed'][str(Path(parent) / (unit + '.d'))] = False
        save_json(directory / 'configuration.json', configuration)
        save_json(directory / 'baseline.json', baseline)
        save_json(directory / 'may-touch.json', units)
        queried = []

        def fake_properties(current_directory, unit):
            queried.append(unit)
            return dict(baseline['units'][unit])

        def fake_stop(current_directory, unit):
            if unit == configuration['task']:
                raise RuntimeError('injected empty-task stop failure')

        def fake_command(current_directory, arguments):
            if arguments == ['systemctl', 'daemon-reload']:
                raise RuntimeError('injected reload failure')
            raise AssertionError('Unexpected command in administrative selfcheck')

        with patch.dict(globals(), {'CGROUP_ROOT': directory / 'cgroup',
                'properties': fake_properties, 'stop_owned_unit': fake_stop,
                'command': fake_command, 'current_top_units': lambda: TOP_UNITS,
                'property_path': lambda unit: directory / (unit + '.d') / '50-AllowedCPUs.conf'}):
            try:
                restore(directory)
            except RuntimeError:
                pass
            else:
                raise AssertionError('Injected restoration failures were hidden')
        result = load_json(directory / 'restored.json')
        assert all(queried.count(unit) == 2 for unit in units)
        assert {row.get('stage') for row in result['errors']} == {'stop_empty_task', 'daemon_reload'}, result['errors']
        assert not result['restoration_verified']
        assert len(list(directory.glob('restore-attempt-*.json'))) == 1
    print('administrative_selfcheck=pass;configuration_writes=none')


if __name__ == '__main__':
    if sys.argv[1:] == ['--selfcheck']:
        selfcheck()
    else:
        raise SystemExit('Remote management modes disabled: the old plan writes project files outside /home/nss-marker/yhr/Cry')
        if os.geteuid() != 0 or len(sys.argv) != 3:
            raise SystemExit('Requires root and a bounded management mode/path')
        mode, path = sys.argv[1], Path(sys.argv[2])
        if mode == 'launch':
            launch(path)
        elif mode in ['apply', 'restore', 'marker']:
            if path.parent != Path('/run') or not path.name.startswith('a113core') or path.stat().st_uid != 0:
                raise SystemExit('Unexpected root state directory')
            if mode == 'marker':
                save_json(path / 'marker.json', {'utc': utc_now(), 'effective_uid': os.geteuid()})
            elif mode == 'apply':
                apply(path)
            else:
                restore(path)
        else:
            raise SystemExit('Unknown management mode')
