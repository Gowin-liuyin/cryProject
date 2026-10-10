import datetime
import errno
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import pwd
import re
import resource
import select
import signal
import stat
import subprocess
import sys
import tarfile
import tempfile
import time

WORK_ROOT = Path('/home/nss-marker/yhr/Cry')
CGROUP_ROOT = Path('/sys/fs/cgroup')
ALL_CPUS = set(range(32))
PROBE_CPUS = {2, 18}
HOUSEKEEPING_CPUS = ALL_CPUS - PROBE_CPUS
HOUSEKEEPING_TEXT = '0-1,3-17,19-31'
FIELDS = ('cpuset.cpus', 'cpuset.cpus.effective', 'cpuset.cpus.exclusive',
          'cpuset.cpus.exclusive.effective', 'cpuset.cpus.partition', 'cpuset.mems')
FREQUENCY_ROOT = Path('/sys/devices/system/cpu/cpufreq')
FREQUENCY_POLICIES = tuple(sorted('policy' + str(cpu) for cpu in range(32)))
FREQUENCY_TARGETS = ('policy2', 'policy18')
FREQUENCY_FIELDS = ('affected_cpus', 'related_cpus', 'scaling_driver', 'scaling_governor',
                    'energy_performance_preference', 'boost', 'cpuinfo_min_freq',
                    'cpuinfo_max_freq', 'scaling_min_freq', 'scaling_max_freq')
FREQUENCY_MUTABLE = ('scaling_min_freq', 'scaling_max_freq')
FREQUENCY_TARGET_KHZ = '4300000'
WINDOW_WORKER_PATH = WORK_ROOT / 'window-source-c0e5990/build-normal/frequency_workload'
WINDOW_WORKER_SHA256 = '023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b'
WINDOW_FILE_LIMIT = 120 * 1024 * 1024
WINDOW_CASE_LIMIT = 256 * 1024 * 1024
WINDOW_REQUIRED_FREE = 2 * 1024 * 1024 * 1024


def frequency_receipt(store, state, name, value, restoring):
    try:
        store.save(name, value)
        return True
    except OSError as error:
        plan = state.get('recovery_plan')
        if not (restoring and error.errno in (errno.ENOSPC, errno.EDQUOT) and plan is not None):
            raise
        require(plan.get('profile') == 'window' and plan.get('state_path') == str(store.path) and
                store.path.name in ('normal', 'parent-loss') and store.path.parent.parent == WORK_ROOT and
                re.fullmatch(r'core-window-20261010-[0-9a-f]{12}', store.path.parent.name) and
                store.load('frequency-recovery-plan.json') == plan and
                plan['baseline_sha256'] == hashlib.sha256(json.dumps(
                    state['baseline'], sort_keys=True).encode()).hexdigest() and
                plan['original_values'] == {policy_name: {
                    field: state['baseline']['policies'][policy_name][field]['value']
                    for field in FREQUENCY_MUTABLE} for policy_name in FREQUENCY_TARGETS},
                'Storage failure is not an authorized original-value recovery')
        state['evidence_complete'] = False
        state.setdefault('storage_errors', []).append({'receipt': name, 'errno': error.errno})
        if store.has(name):
            require(store.load(name) == value, 'Partially published recovery receipt differs')
            return True
        return False


def frequency_snapshot(policy_names=FREQUENCY_POLICIES):
    require(all(name in FREQUENCY_POLICIES for name in policy_names), 'Unknown frequency policy')

    def read_attribute(path):
        descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
        try:
            metadata = os.fstat(descriptor)
            require(metadata.st_uid == 0 and stat.S_ISREG(metadata.st_mode),
                    'Frequency attribute identity differs')
            contents = os.read(descriptor, 4096)
            require(len(contents) < 4096, 'Oversized frequency attribute')
            return {'value': contents.decode().strip(), 'inode': metadata.st_ino,
                    'device': metadata.st_dev, 'owner_uid': metadata.st_uid,
                    'mode': stat.S_IMODE(metadata.st_mode)}
        finally:
            os.close(descriptor)

    result = {'policies': {}, 'global': {}, 'cpu_links': {
        str(cpu): str((FREQUENCY_ROOT.parent / ('cpu' + str(cpu)) / 'cpufreq').resolve())
        for cpu in (2, 18)},
              'policy_names': sorted(path.name for path in FREQUENCY_ROOT.iterdir() if path.is_dir())}
    for name, path in (
            ('status', FREQUENCY_ROOT.parent / 'amd_pstate/status'),
            ('boost', FREQUENCY_ROOT / 'boost'),
            ('prefcore', FREQUENCY_ROOT.parent / 'amd_pstate/prefcore')):
        result['global'][name] = read_attribute(path)
    for name in policy_names:
        path = FREQUENCY_ROOT / name
        metadata = path.stat(follow_symlinks=False)
        require(metadata.st_uid == 0 and stat.S_ISDIR(metadata.st_mode), 'Policy identity differs')
        row = {'identity': {'inode': metadata.st_ino, 'device': metadata.st_dev}}
        row.update({field: read_attribute(path / field) for field in FREQUENCY_FIELDS})
        result['policies'][name] = row
    return result


def frequency_change(store, state, policy_name, field, value, deadline_seconds, restoring=False):
    require(policy_name in FREQUENCY_TARGETS and field in FREQUENCY_MUTABLE,
            'Only the two fixed per-policy frequency limits may be written')
    baseline = state['baseline']
    require(value in (FREQUENCY_TARGET_KHZ, baseline['policies'][policy_name][field]['value']),
            'Frequency value outside this contract')
    require(not restoring or value == baseline['policies'][policy_name][field]['value'],
            'Recovery can only resend the original value')
    current = frequency_snapshot((policy_name,) if restoring else FREQUENCY_POLICIES)
    require(current['global'] == baseline['global'], 'Global frequency state changed')
    require(current['cpu_links'] == baseline['cpu_links'], 'CPU frequency mapping changed')
    if not restoring:
        require(current['policy_names'] == baseline['policy_names'], 'Frequency policy set changed')
    for name, row in current['policies'].items():
        original = baseline['policies'][name]
        for key in ('identity',) + FREQUENCY_FIELDS:
            if name in FREQUENCY_TARGETS and key in FREQUENCY_MUTABLE:
                require({name: item for name, item in row[key].items() if name != 'value'} ==
                        {name: item for name, item in original[key].items() if name != 'value'},
                        'Frequency limit identity changed')
            else:
                require(row[key] == original[key], 'Non-target frequency setting changed')
        pair = [row[key]['value'] for key in FREQUENCY_MUTABLE]
        if name in FREQUENCY_TARGETS:
            require(pair in state['known_pairs'][name], 'Unknown frequency limits; no overwrite')
    before_pair = [current['policies'][policy_name][key]['value'] for key in FREQUENCY_MUTABLE]
    field_index = FREQUENCY_MUTABLE.index(field)
    pending_fields = state.setdefault('pending_fields', {name: [] for name in FREQUENCY_TARGETS})
    if before_pair[field_index] == value and not (restoring and field in pending_fields[policy_name]):
        return
    after_pair = before_pair.copy()
    after_pair[field_index] = value
    require(int(after_pair[0]) <= int(after_pair[1]), 'Frequency min exceeds max')
    require(time.monotonic() < deadline_seconds, 'Frequency write deadline')
    intent = {'sequence': state['sequence'], 'policy_name': policy_name, 'field': field,
              'before_pair': before_pair, 'after_pair': after_pair}
    # 首写前持久化意图；写入报错也不能假定内核未接受请求。
    is_persisted = frequency_receipt(store, state,
        'frequency-dirty-' + str(state['sequence']).zfill(4) + '.json', intent, restoring)
    if is_persisted:
        state['sequence'] += 1
    if field not in pending_fields[policy_name]:
        pending_fields[policy_name].append(field)
    if after_pair not in state['known_pairs'][policy_name]:
        state['known_pairs'][policy_name].append(after_pair)
    descriptor = os.open(FREQUENCY_ROOT / policy_name / field,
                         os.O_WRONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        metadata = os.fstat(descriptor)
        expected = baseline['policies'][policy_name][field]
        require(stat.S_ISREG(metadata.st_mode) and metadata.st_uid == 0 and
                metadata.st_ino == expected['inode'] and metadata.st_dev == expected['device'] and
                stat.S_IMODE(metadata.st_mode) == expected['mode'], 'Write descriptor identity differs')
        contents = (value + '\n').encode()
        require(os.write(descriptor, contents) == len(contents), 'Short frequency write')
    finally:
        os.close(descriptor)
    while time.monotonic() < deadline_seconds:
        observed = frequency_snapshot((policy_name,))
        require(observed['global'] == baseline['global'], 'Global state changed during apply')
        require(observed['cpu_links'] == baseline['cpu_links'], 'CPU mapping changed during apply')
        row = observed['policies'][policy_name]
        for key in ('identity',) + FREQUENCY_FIELDS:
            if key not in FREQUENCY_MUTABLE:
                require(row[key] == baseline['policies'][policy_name][key],
                        'Policy changed during asynchronous apply')
            else:
                require({name: item for name, item in row[key].items() if name != 'value'} ==
                        {name: item for name, item in baseline['policies'][policy_name][key].items()
                         if name != 'value'}, 'Limit identity changed during apply')
        pair = [row[key]['value'] for key in FREQUENCY_MUTABLE]
        require(pair in state['known_pairs'][policy_name], 'Unknown asynchronous frequency state')
        if pair == after_pair:
            visible_name = 'frequency-visible-' + str(intent['sequence']).zfill(4) + '.json'
            if not is_persisted:
                visible_name = 'frequency-unlogged-visible-' + os.urandom(6).hex() + '.json'
            frequency_receipt(store, state, visible_name,
                       {'utc': utc_now(), 'policy_name': policy_name, 'limits_khz': pair,
                        'hardware_frequency_qualified': False}, restoring)
            if value == baseline['policies'][policy_name][field]['value']:
                pending_fields[policy_name].remove(field)
            return
        time.sleep(0.01)
    raise TimeoutError('Frequency request did not reach visible limits')


def frequency_restore(store, state, errors, deadline_seconds):
    if state is None:
        try:
            baseline = store.load('frequency-baseline.json')
            state = {'baseline': baseline, 'sequence': 0,
                     'pending_fields': {name: [] for name in FREQUENCY_TARGETS}, 'known_pairs': {
                name: [[baseline['policies'][name][field]['value'] for field in FREQUENCY_MUTABLE]]
                for name in FREQUENCY_TARGETS}}
            if store.has('frequency-recovery-plan.json'):
                plan = store.load('frequency-recovery-plan.json')
                require(plan.get('profile') == 'window' and plan.get('state_path') == str(store.path) and
                        store.path.name in ('normal', 'parent-loss') and store.path.parent.parent == WORK_ROOT and
                        re.fullmatch(r'core-window-20261010-[0-9a-f]{12}', store.path.parent.name) and
                        plan['baseline_sha256'] == hashlib.sha256(json.dumps(
                            baseline, sort_keys=True).encode()).hexdigest() and
                        plan['original_values'] == {policy_name: {
                            field: baseline['policies'][policy_name][field]['value']
                            for field in FREQUENCY_MUTABLE} for policy_name in FREQUENCY_TARGETS},
                        'Stored recovery authorization differs')
                state['recovery_plan'] = plan
                state['evidence_complete'] = False
            names = sorted(name for name in os.listdir(store.descriptor)
                           if re.fullmatch(r'frequency-dirty-[0-9]{4}\.json', name))
            require(len(names) < 100, 'Too many frequency recovery intents')
            for name in names:
                intent = store.load(name)
                policy_name = intent['policy_name']
                field = intent['field']
                require(name == 'frequency-dirty-' + str(state['sequence']).zfill(4) + '.json' and
                        intent['sequence'] == state['sequence'] and
                        policy_name in FREQUENCY_TARGETS and field in FREQUENCY_MUTABLE,
                        'Frequency intent identity differs')
                require(intent['before_pair'] in state['known_pairs'][policy_name],
                        'Frequency intent predecessor unknown')
                after_pair = intent['before_pair'].copy()
                field_index = FREQUENCY_MUTABLE.index(field)
                after_pair[field_index] = intent['after_pair'][field_index]
                require(after_pair == intent['after_pair'] and
                        after_pair[field_index] in (FREQUENCY_TARGET_KHZ,
                            baseline['policies'][policy_name][field]['value']) and
                        int(after_pair[0]) <= int(after_pair[1]), 'Frequency intent value differs')
                if after_pair not in state['known_pairs'][policy_name]:
                    state['known_pairs'][policy_name].append(after_pair)
                if 'recovery_plan' in state:
                    for pair in state['known_pairs'][policy_name].copy():
                        for recovery_index, recovery_field in enumerate(FREQUENCY_MUTABLE):
                            projected = pair.copy()
                            projected[recovery_index] = baseline['policies'][policy_name][recovery_field]['value']
                            if projected not in state['known_pairs'][policy_name]:
                                state['known_pairs'][policy_name].append(projected)
                if field not in state['pending_fields'][policy_name]:
                    state['pending_fields'][policy_name].append(field)
                visible_name = 'frequency-visible-' + str(state['sequence']).zfill(4) + '.json'
                if after_pair[field_index] == baseline['policies'][policy_name][field]['value'] and store.has(visible_name):
                    visible = store.load(visible_name)
                    require(visible['policy_name'] == policy_name and visible['limits_khz'] == after_pair,
                            'Frequency restoration receipt differs')
                    state['pending_fields'][policy_name].remove(field)
                state['sequence'] += 1
            if 'recovery_plan' in state:
                for policy_name in FREQUENCY_TARGETS:
                    state['pending_fields'][policy_name] = list(FREQUENCY_MUTABLE)
        except Exception as error:
            errors.append({'step': 'frequency_reconstruct', 'error': repr(error)})
            return
    for policy_name in FREQUENCY_TARGETS:
        for field in FREQUENCY_MUTABLE:
            attempt(errors, 'restore_' + policy_name + '_' + field,
                    lambda policy_name=policy_name, field=field: frequency_change(
                        store, state, policy_name, field,
                        state['baseline']['policies'][policy_name][field]['value'],
                        min(deadline_seconds, time.monotonic() + 1), restoring=True))
    def final_frequency_readback():
        current = frequency_snapshot()
        require(not any(state.get('pending_fields', {}).values()),
                'Dirty frequency request has not been explicitly cancelled')
        require(current == state['baseline'], 'Visible frequency configuration not restored')
        state['restoration_visible'] = True
        frequency_receipt(store, state,
                   'frequency-restored-' + str(state['sequence']).zfill(4) + '-' + os.urandom(6).hex() + '.json',
                   {'utc': utc_now(), 'snapshot': current, 'hardware_frequency_qualified': False}, True)
    attempt(errors, 'frequency_final_readback', final_frequency_readback)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def cpu_set(text):
    result = set()
    normalized = text.strip()
    if not normalized:
        return result
    for component in normalized.split(','):
        bounds = component.split('-')
        require(len(bounds) <= 2 and all(value.isdigit() for value in bounds), 'Bad CPU list')
        lower, upper = int(bounds[0]), int(bounds[-1])
        require(0 <= lower <= upper < 32, 'CPU outside this rehearsal')
        result.update(range(lower, upper + 1))
    return result


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def start_ticks(process_id):
    return int(Path(f'/proc/{process_id}/stat').read_text().rsplit(')', 1)[1].split()[19])


def process_group(process_id):
    return Path(f'/proc/{process_id}/cgroup').read_text().strip()


class Store:
    def __init__(self, path, descriptor=None):
        self.path = Path(path)
        self.descriptor = descriptor if descriptor is not None else os.open(
            self.path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
        self.check()

    def check(self):
        metadata = os.fstat(self.descriptor)
        require(metadata.st_uid == 0 and stat.S_IMODE(metadata.st_mode) == 0o700,
                'State must be root private')
        actual = Path(os.readlink(f'/proc/self/fd/{self.descriptor}'))
        require(actual == self.path and actual.is_relative_to(WORK_ROOT), 'State path moved')

    def open_file(self, name, flags):
        self.check()
        require('/' not in name and name not in ('', '.', '..'), 'Invalid state filename')
        descriptor = os.open(name, flags | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600,
                             dir_fd=self.descriptor)
        metadata = os.fstat(descriptor)
        require(stat.S_ISREG(metadata.st_mode) and metadata.st_uid == 0,
                'Unexpected state file identity')
        return descriptor

    def save(self, name, value):
        temporary = name + '.new-' + os.urandom(6).hex()
        descriptor = self.open_file(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL)
        with os.fdopen(descriptor, 'w') as output:
            json.dump(value, output, indent=2)
            output.write('\n')
            output.flush()
            os.fsync(output.fileno())
        self.check()
        try:
            os.link(temporary, name, src_dir_fd=self.descriptor,
                    dst_dir_fd=self.descriptor, follow_symlinks=False)
            os.fsync(self.descriptor)
        finally:
            os.unlink(temporary, dir_fd=self.descriptor)

    def load(self, name):
        with os.fdopen(self.open_file(name, os.O_RDONLY)) as source:
            return json.load(source)

    def has(self, name):
        self.check()
        try:
            os.stat(name, dir_fd=self.descriptor, follow_symlinks=False)
            return True
        except FileNotFoundError:
            return False


class OwnedGroup:
    def __init__(self, name, inode=None):
        require(name.startswith('a113part-') and name.replace('-', '').isalnum(), 'Bad group name')
        self.name = name
        self.path = CGROUP_ROOT / name
        created_inode = None
        if inode is None:
            self.path.mkdir()
            created_inode = self.path.stat(follow_symlinks=False).st_ino
        try:
            self.descriptor = os.open(self.path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            self.inode = os.fstat(self.descriptor).st_ino if inode is None else inode
            self.check()
        except Exception:
            if created_inode is not None and self.path.stat(follow_symlinks=False).st_ino == created_inode:
                try:
                    self.path.rmdir()
                except OSError:
                    pass
            raise

    def check(self):
        metadata = self.path.stat(follow_symlinks=False)
        require(metadata.st_uid == 0 and metadata.st_ino == self.inode and
                os.fstat(self.descriptor).st_ino == self.inode, 'Owned cgroup identity changed')

    def read(self, name):
        self.check()
        descriptor = os.open(name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=self.descriptor)
        with os.fdopen(descriptor) as source:
            return source.read().strip()

    def write(self, name, value):
        self.check()
        descriptor = os.open(name, os.O_WRONLY | os.O_NOFOLLOW, dir_fd=self.descriptor)
        with os.fdopen(descriptor, 'w') as output:
            output.write(str(value) + '\n')

    def remove(self):
        self.check()
        require(not self.read('cgroup.procs'), 'Unknown member prevents removal')
        require(not any(path.is_dir() for path in self.path.iterdir()), 'Unknown child group')
        self.path.rmdir()
        os.close(self.descriptor)


def values(path):
    result = {}
    for name in FIELDS:
        try:
            result[name] = (path / name).read_text().strip()
        except FileNotFoundError:
            result[name] = None
    return result


def snapshot(ignored=(), active=False):
    require(Path('/sys/devices/system/cpu/online').read_text().strip() == '0-31', 'CPU hotplug')
    expected = HOUSEKEEPING_CPUS if active else ALL_CPUS
    require(cpu_set((CGROUP_ROOT / 'cpuset.cpus.effective').read_text()) == expected,
            'Root effective CPUs differ')
    isolated = cpu_set((CGROUP_ROOT / 'cpuset.cpus.isolated').read_text())
    require(isolated == (PROBE_CPUS if active else set()), 'Unexpected isolated CPUs')
    groups = {}
    for path in sorted(CGROUP_ROOT.rglob('cpuset.cpus.partition')):
        group = path.parent
        if group == CGROUP_ROOT or group.name in ignored:
            continue
        row = values(group)
        require(row['cpuset.cpus.partition'] == 'member' and
                row['cpuset.cpus'] == '' and row['cpuset.cpus.exclusive'] == '' and
                row['cpuset.mems'] == '', 'Existing group has a requested setting')
        require(cpu_set(row['cpuset.cpus.effective']) == expected, 'Existing group effective differs')
        groups[str(group.relative_to(CGROUP_ROOT))] = row
    return {'utc': utc_now(), 'root_effective': sorted(expected),
            'root_isolated': sorted(isolated), 'groups': groups,
            'top_names': sorted(path.name for path in CGROUP_ROOT.iterdir() if path.is_dir())}


def root_gate(recovering=False):
    require(sys.platform == 'linux' and os.geteuid() == 0 and sys.flags.isolated,
            'Requires isolated root Python on Linux')
    require(os.uname().nodename == 'nss-m' and os.uname().release.startswith('6.17.'),
            'Unexpected host')
    require(WORK_ROOT.resolve(strict=True) == WORK_ROOT, 'Work root is a symlink')
    require(isinstance(globals().get('SOURCE_TEXT'), str), 'Requires frozen in-memory source')
    for namespace in ('pid', 'cgroup', 'mnt'):
        require(os.readlink('/proc/self/ns/' + namespace) == os.readlink('/proc/1/ns/' + namespace),
                'Not in the host namespace')
    require('cpuset' in (CGROUP_ROOT / 'cgroup.subtree_control').read_text().split(),
            'Root cpuset controller unavailable')
    if not recovering:
        for cpu in PROBE_CPUS:
            require(cpu_set(Path(f'/sys/devices/system/cpu/cpu{cpu}/topology/thread_siblings_list').read_text())
                    == PROBE_CPUS, 'Sibling topology changed')
        require(os.sched_getaffinity(0) == ALL_CPUS, 'Caller already has an affinity restriction')
    fallback = CGROUP_ROOT / 'init.scope'
    require(os.access(fallback / 'cgroup.procs', os.W_OK), 'Restore location unavailable')
    return fallback.stat().st_ino


def work_descriptor():
    descriptor = os.open(WORK_ROOT, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    check_work(descriptor)
    return descriptor


def check_work(descriptor):
    require(Path(os.readlink(f'/proc/self/fd/{descriptor}')) == WORK_ROOT,
            'Work directory identity moved')
    require(os.fstat(descriptor).st_uid == pwd.getpwnam('nss-marker').pw_uid,
            'Unexpected work directory owner')


def attempt(errors, label, operation):
    try:
        operation()
    except Exception as error:
        errors.append({'step': label, 'error': repr(error)})


def wait_byte(descriptor, deadline_seconds, monitor=lambda: None):
    while time.monotonic() < deadline_seconds:
        monitor()
        if select.select([descriptor], [], [], max(0, min(0.1, deadline_seconds - time.monotonic())))[0]:
            return os.read(descriptor, 1)
    raise TimeoutError('Management soft deadline reached')


def wait_owned_child(process_id, deadline_seconds):
    while time.monotonic() < deadline_seconds:
        ended_id, status_code = os.waitpid(process_id, os.WNOHANG)
        if ended_id:
            return status_code
        time.sleep(0.01)
    raise TimeoutError(f'Owned child {process_id} still not reaped; inspect original process')


def empty_probe(group, store, deadline_seconds):
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    read_gate, write_gate = os.pipe()
    child_id = os.fork()
    if child_id == 0:
        try:
            os.close(write_gate)
            if os.read(read_gate, 1) != b'A':
                os._exit(3)
            os.close(read_gate)
            os.execve('/usr/bin/true', ['/usr/bin/true'], {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'})
        except BaseException as error:
            try:
                os.write(2, (repr(error) + '\n').encode())
            except OSError:
                pass
            os._exit(4)
    os.close(read_gate)
    waiting_child = child_id
    try:
        group.write('cgroup.procs', child_id)
        observed = {'pid': child_id, 'start_ticks': start_ticks(child_id),
                    'cgroup': process_group(child_id),
                    'allowed_cpus': sorted(os.sched_getaffinity(child_id))}
        require(observed['cgroup'] == '0::/' + group.name and
                set(observed['allowed_cpus']) == PROBE_CPUS, 'Probe was not placed')
        store.save('probe-before-exec.json', observed)
        os.write(write_gate, b'A')
        os.close(write_gate)
        write_gate = None
        while time.monotonic() < deadline_seconds:
            ended_id, status_code = os.waitpid(child_id, os.WNOHANG)
            if ended_id:
                waiting_child = None
                exit_code = os.waitstatus_to_exitcode(status_code)
                store.save('probe-exit.json', {'pid': child_id, 'exit_code': exit_code})
                require(exit_code == 0, 'Empty task failed')
                return
            time.sleep(0.01)
        raise TimeoutError('Empty task deadline')
    finally:
        if write_gate is not None:
            os.close(write_gate)
        if waiting_child is not None:
            try:
                os.kill(waiting_child, signal.SIGKILL)
            except ProcessLookupError:
                pass
            finally:
                wait_owned_child(waiting_child, time.monotonic() + 1)


def prepare_window_worker(store):
    require(isinstance(WINDOW_WORKER_SHA256, str) and
            re.fullmatch(r'[0-9a-f]{64}', WINDOW_WORKER_SHA256), 'Window worker is not frozen')
    descriptor = os.open(WINDOW_WORKER_PATH, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        before = os.fstat(descriptor)
        require(stat.S_ISREG(before.st_mode) and before.st_uid == pwd.getpwnam('nss-marker').pw_uid and
                0 < before.st_size < 1024 * 1024 and
                Path(os.readlink('/proc/self/fd/' + str(descriptor))) == WINDOW_WORKER_PATH,
                'Window source executable identity differs')
        contents = bytearray()
        while len(contents) < before.st_size:
            chunk = os.read(descriptor, before.st_size - len(contents))
            require(bool(chunk), 'Short window source read')
            contents.extend(chunk)
        after = os.fstat(descriptor)
        require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
                (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns) and
                hashlib.sha256(contents).hexdigest() == WINDOW_WORKER_SHA256 and
                contents[:6] == b'\x7fELF\x02\x01' and contents[18:20] == b'>\x00',
                'Window source bytes changed or digest differs')
    finally:
        os.close(descriptor)
    output_descriptor = store.open_file('worker.bin', os.O_WRONLY | os.O_CREAT | os.O_EXCL)
    try:
        completed = 0
        while completed < len(contents):
            written = os.write(output_descriptor, contents[completed:])
            require(written > 0, 'Short protected worker write')
            completed += written
        os.fchmod(output_descriptor, 0o500)
        os.fsync(output_descriptor)
    finally:
        os.close(output_descriptor)
    os.fsync(store.descriptor)
    descriptor = store.open_file('worker.bin', os.O_RDONLY)
    metadata = os.fstat(descriptor)
    require(stat.S_IMODE(metadata.st_mode) == 0o500 and metadata.st_size == len(contents),
            'Protected worker identity differs')
    identity = {'path': str(store.path / 'worker.bin'), 'inode': metadata.st_ino,
                'device': metadata.st_dev, 'sha256': WINDOW_WORKER_SHA256, 'bytes': metadata.st_size,
                'source_path': str(WINDOW_WORKER_PATH), 'source_owner_uid': before.st_uid,
                'source_inode': before.st_ino, 'source_device': before.st_dev}
    store.save('worker-binary.json', identity)
    return descriptor, identity


def spawn_window_worker(group, store, life_reader, lock_descriptor, prepared_worker):
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    binary_descriptor, binary_identity = prepared_worker
    stdout_descriptor = store.open_file('worker.stdout.jsonl', os.O_RDWR | os.O_CREAT | os.O_EXCL)
    stderr_descriptor = store.open_file('worker.stderr.log', os.O_RDWR | os.O_CREAT | os.O_EXCL)
    read_gate, write_gate = os.pipe()
    child_id = os.fork()
    if child_id == 0:
        try:
            os.close(write_gate)
            for descriptor in (life_reader, lock_descriptor, store.descriptor):
                os.close(descriptor)
            os.dup2(stdout_descriptor, 1)
            os.dup2(stderr_descriptor, 2)
            os.close(stdout_descriptor)
            os.close(stderr_descriptor)
            null_descriptor = os.open('/dev/null', os.O_RDONLY)
            os.dup2(null_descriptor, 0)
            if null_descriptor != 0:
                os.close(null_descriptor)
            resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
            resource.setrlimit(resource.RLIMIT_FSIZE, (WINDOW_FILE_LIMIT, WINDOW_FILE_LIMIT))
            signal.signal(signal.SIGXFSZ, signal.SIG_IGN)
            if os.read(read_gate, 1) != b'A':
                os._exit(3)
            os.close(read_gate)
            os.execve(binary_descriptor, [binary_identity['path']],
                      {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C', 'TMPDIR': str(store.path)})
        except BaseException as error:
            try:
                os.write(2, (repr(error) + '\n').encode())
            except OSError:
                pass
            os._exit(4)
    spawn_errors = []
    for descriptor in (read_gate, binary_descriptor):
        try:
            os.close(descriptor)
        except OSError as error:
            spawn_errors.append(repr(error))
    return {'pid': child_id, 'gate': write_gate, 'stdout_descriptor': stdout_descriptor,
            'stderr_descriptor': stderr_descriptor, 'binary': binary_identity,
            'reaped': False, 'released': False, 'exit_code': None, 'spawn_errors': spawn_errors}


def window_output_status(worker):
    result = {'measurement_complete': False, 'outputs': {}}
    for name in ('stdout', 'stderr'):
        descriptor = worker[name + '_descriptor']
        os.fsync(descriptor)
        size = os.fstat(descriptor).st_size
        require(size <= WINDOW_FILE_LIMIT, 'Worker output exceeds file budget')
        digest = hashlib.sha256()
        position = 0
        while position < size:
            contents = os.pread(descriptor, min(1024 * 1024, size - position), position)
            require(bool(contents), 'Short worker output read')
            digest.update(contents)
            position += len(contents)
        result['outputs'][name] = {'bytes': size, 'sha256': digest.hexdigest()}
    if worker['exit_code'] == 0:
        descriptor = worker['stdout_descriptor']
        size = result['outputs']['stdout']['bytes']
        first = os.pread(descriptor, min(size, 65536), 0).split(b'\n', 1)[0]
        tail = os.pread(descriptor, min(size, 65536), max(0, size - 65536))
        require(tail.endswith(b'\n'), 'Worker output has no complete final line')
        contract = json.loads(first)
        summary = json.loads(tail.splitlines()[-1])
        require(contract['type'] == 'contract' and contract['implementation'] == 'reference' and
                contract['warmup_target_ns'] == '1000000000' and
                contract['main_target_ns'] == '4000000000' and
                summary['type'] == 'summary' and summary['status'] == 'completed' and
                summary['valid_final_snapshot'] is True, 'Worker completion envelope differs')
        result['measurement_complete'] = True
    return result


def window_worker(group, store, life_reader, lock_descriptor, deadline_seconds, monitor,
                  prepared_worker):
    worker = None
    result = {'reason': 'not_started', 'measurement_complete': False, 'evidence_complete': True,
              'cancel_while_running': False, 'registered_cancel': False, 'errors': [], 'reaped': False}
    try:
        worker = spawn_window_worker(group, store, life_reader, lock_descriptor, prepared_worker)
        prepared_worker = None
        require(not worker['spawn_errors'], 'Worker parent descriptor close failed')
        group.write('cgroup.procs', worker['pid'])
        os.sched_setaffinity(worker['pid'], {2})
        identity = {'pid': worker['pid'], 'start_ticks': start_ticks(worker['pid']),
                    'cgroup': process_group(worker['pid']),
                    'allowed_cpus': sorted(os.sched_getaffinity(worker['pid'])),
                    'binary': worker['binary']}
        require(identity['cgroup'] == '0::/' + group.name and identity['allowed_cpus'] == [2],
                'Window worker did not remain gated in the probe')
        store.save('probe-before-exec.json', identity)
        store.save('worker-ready.json', identity)
        require(wait_byte(life_reader, deadline_seconds, monitor) == b'W', 'Window release not received')
        os.write(worker['gate'], b'A')
        os.close(worker['gate'])
        worker['gate'] = None
        worker['released'] = True
        released_at = time.monotonic()
        store.save('worker-released.json', {'utc': utc_now(), 'pid': worker['pid'],
                                           'released_monotonic_seconds': released_at})
        worker_deadline = min(deadline_seconds, released_at + 12)
        running_observed = False
        while True:
            ended_id, status_code = os.waitpid(worker['pid'], os.WNOHANG)
            if ended_id:
                worker['reaped'] = True
                worker['exit_code'] = os.waitstatus_to_exitcode(status_code)
                result['reason'] = 'worker_exited'
                break
            if time.monotonic() >= worker_deadline:
                result['reason'] = 'worker_timeout'
                break
            monitor()
            require(set(group.read('cgroup.procs').split()) <= {str(worker['pid'])},
                    'Unknown process entered the window probe')
            sizes = [os.fstat(worker[name + '_descriptor']).st_size for name in ('stdout', 'stderr')]
            require(sum(sizes) <= WINDOW_CASE_LIMIT and all(size <= WINDOW_FILE_LIMIT for size in sizes),
                    'Worker output budget exceeded')
            require(sum(os.stat(name, dir_fd=store.descriptor, follow_symlinks=False).st_size
                        for name in os.listdir(store.descriptor)) <= WINDOW_CASE_LIMIT,
                    'Window case file budget exceeded')
            if not running_observed:
                executable = Path('/proc/' + str(worker['pid']) + '/exe')
                try:
                    metadata = executable.stat()
                    running_observed = (metadata.st_ino == worker['binary']['inode'] and
                                        metadata.st_dev == worker['binary']['device'] and
                                        os.readlink(executable) == worker['binary']['path'])
                except FileNotFoundError:
                    pass
                if running_observed:
                    ended_id, status_code = os.waitpid(worker['pid'], os.WNOHANG)
                    if ended_id:
                        worker['reaped'] = True
                        worker['exit_code'] = os.waitstatus_to_exitcode(status_code)
                        result['reason'] = 'worker_exited'
                        break
                    store.save('worker-running.json', dict(identity, utc=utc_now(),
                        released_monotonic_seconds=released_at, executable_observed=True,
                        alive_at_check=True, running_check_monotonic_seconds=time.monotonic()))
            if select.select([life_reader], [], [], 0.02)[0]:
                instruction = os.read(life_reader, 1)
                require(instruction in (b'R', b''), 'Unexpected running worker instruction')
                ended_id, status_code = os.waitpid(worker['pid'], os.WNOHANG)
                if ended_id:
                    worker['reaped'] = True
                    worker['exit_code'] = os.waitstatus_to_exitcode(status_code)
                result['cancel_while_running'] = ended_id == 0 and worker['released']
                result['registered_cancel'] = (result['cancel_while_running'] and running_observed and
                                               time.monotonic() >= released_at + 0.25)
                result['reason'] = 'controller_eof' if instruction == b'' else 'running_release'
                break
    except BaseException as error:
        result['errors'].append(repr(error))
        result['evidence_complete'] = False
        result['reason'] = 'worker_error'
    finally:
        if prepared_worker is not None:
            try:
                os.close(prepared_worker[0])
            except OSError:
                pass
        if worker is not None:
            if worker['gate'] is not None:
                try:
                    os.close(worker['gate'])
                except OSError as error:
                    result['errors'].append(repr(error))
                    result['evidence_complete'] = False
                worker['gate'] = None
            if not worker['reaped']:
                try:
                    os.kill(worker['pid'], signal.SIGKILL)
                except ProcessLookupError:
                    pass
                except OSError as error:
                    result['errors'].append(repr(error))
                    result['evidence_complete'] = False
                try:
                    status_code = wait_owned_child(worker['pid'], time.monotonic() + 2)
                    worker['exit_code'] = os.waitstatus_to_exitcode(status_code)
                    worker['reaped'] = True
                except Exception as error:
                    result['errors'].append(repr(error))
            result.update({'pid': worker['pid'], 'reaped': worker['reaped'],
                           'worker_exit_code': worker['exit_code']})
            if worker['reaped']:
                try:
                    result.update(window_output_status(worker))
                except Exception as error:
                    result['errors'].append(repr(error))
                    result['evidence_complete'] = False
            if result['reason'] != 'worker_exited':
                result['measurement_complete'] = False
            result['data_role'] = 'complete' if result['measurement_complete'] else 'partial_or_unknown'
            try:
                store.save('worker-exit.json', dict(result, utc=utc_now()))
            except Exception as error:
                result['errors'].append(repr(error))
                result['evidence_complete'] = False
            for name in ('stdout', 'stderr'):
                try:
                    os.close(worker[name + '_descriptor'])
                except OSError as error:
                    result['errors'].append(repr(error))
                    result['evidence_complete'] = False
        else:
            result['reaped'] = True
            result['no_child_created'] = True
    return result


def guard(store, life_reader, lock_descriptor, token, fallback_inode,
          frequency_mode=False, window_mode=False):
    deadline_seconds = time.monotonic() + 20
    os.setsid()
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    signal.signal(signal.SIGPIPE, signal.SIG_IGN)
    os.set_inheritable(store.descriptor, False)
    os.set_inheritable(lock_descriptor, False)
    log_descriptor = store.open_file('guard.log', os.O_RDWR | os.O_CREAT | os.O_EXCL)
    for descriptor in (0, 1, 2):
        os.dup2(log_descriptor, descriptor)
    os.close(log_descriptor)
    guard_group = None
    probe_group = None
    errors = []
    reason = 'not_started'
    active = False
    frequency_state = None
    worker_result = None
    prepared_worker = None
    restoration_errors = []
    try:
        store.save('guard.json', {'pid': os.getpid(), 'start_ticks': start_ticks(os.getpid()),
                                 'effective_uid': os.geteuid()})
        store.save('baseline.json', snapshot())
        if frequency_mode:
            frequency_baseline = frequency_snapshot()
            require(frequency_baseline['policy_names'] == list(FREQUENCY_POLICIES),
                    'Expected exactly 32 frequency policies')
            require(frequency_baseline['cpu_links'] == {
                str(cpu): str(FREQUENCY_ROOT / ('policy' + str(cpu))) for cpu in (2, 18)},
                'Initial CPU frequency mapping differs')
            require({name: row['value'] for name, row in frequency_baseline['global'].items()} ==
                    {'status': 'active', 'boost': '1', 'prefcore': 'enabled'},
                    'Unexpected initial global frequency state')
            for name, row in frequency_baseline['policies'].items():
                expected_fields = {'affected_cpus': name[6:], 'related_cpus': name[6:],
                                   'scaling_driver': 'amd-pstate-epp',
                                   'scaling_governor': 'powersave',
                                   'energy_performance_preference': 'balance_performance',
                                   'boost': '1', 'scaling_min_freq': '2982259',
                                   'scaling_max_freq': '5756452'}
                require(all(row[field]['value'] == value for field, value in expected_fields.items()),
                        'Initial frequency policy differs')
                require(int(row['cpuinfo_min_freq']['value']) <= int(FREQUENCY_TARGET_KHZ) <=
                        int(row['cpuinfo_max_freq']['value']), 'Target outside CPU capability')
            store.save('frequency-baseline.json', frequency_baseline)
            frequency_state = {'baseline': frequency_baseline, 'sequence': 0, 'known_pairs': {
                name: [[frequency_baseline['policies'][name][field]['value']
                        for field in FREQUENCY_MUTABLE]] for name in FREQUENCY_TARGETS}}
            if window_mode:
                plan = {'profile': 'window', 'state_path': str(store.path),
                        'baseline_sha256': hashlib.sha256(json.dumps(
                            frequency_baseline, sort_keys=True).encode()).hexdigest(),
                        'original_values': {policy_name: {
                            field: frequency_baseline['policies'][policy_name][field]['value']
                            for field in FREQUENCY_MUTABLE} for policy_name in FREQUENCY_TARGETS}}
                store.save('frequency-recovery-plan.json', plan)
                frequency_state['recovery_plan'] = plan
                frequency_state['evidence_complete'] = True
                available = os.fstatvfs(store.descriptor)
                require(available.f_bavail * available.f_frsize >= WINDOW_REQUIRED_FREE,
                        'Cry disk reserve is below the window requirement')
                prepared_worker = prepare_window_worker(store)
        guard_group = OwnedGroup('a113part-' + token + '-guard')
        store.save('guard-group.json', {'name': guard_group.name, 'inode': guard_group.inode})
        guard_group.write('cpuset.mems', '0')
        guard_group.write('cpuset.cpus', HOUSEKEEPING_TEXT)
        guard_group.write('cgroup.procs', os.getpid())
        require(process_group(os.getpid()) == '0::/' + guard_group.name and
                os.sched_getaffinity(0) == HOUSEKEEPING_CPUS, 'Guard did not leave SSH group')
        require((CGROUP_ROOT / 'init.scope').stat().st_ino == fallback_inode,
                'Restore location identity changed')
        store.save('ready.json', {'pid': os.getpid(), 'cgroup': process_group(os.getpid()),
                                 'allowed_cpus': sorted(os.sched_getaffinity(0))})
        require(wait_byte(life_reader, deadline_seconds) == b'A', 'Controller ended before ARM')
        snapshot((guard_group.name,))
        probe_group = OwnedGroup('a113part-' + token + '-probe')
        store.save('probe-group.json', {'name': probe_group.name, 'inode': probe_group.inode})
        probe_group.write('cpuset.mems', '0')
        probe_group.write('cpuset.cpus', '2,18')
        probe_group.write('cpuset.cpus.exclusive', '2,18')
        probe_group.write('cpuset.cpus.partition', 'isolated')

        def monitor():
            store.check()
            require(probe_group.read('cpuset.cpus.partition') == 'isolated' and
                    cpu_set(probe_group.read('cpuset.cpus.exclusive.effective')) == PROBE_CPUS and
                    cpu_set(probe_group.read('cpuset.cpus.effective')) == PROBE_CPUS,
                    'Probe partition lost validity')
            snapshot((guard_group.name, probe_group.name), active=True)
            if frequency_mode and active:
                require(frequency_snapshot() == expected_frequency,
                        'Active frequency configuration changed')

        monitor()
        if frequency_mode:
            for policy_name in FREQUENCY_TARGETS:
                for field in FREQUENCY_MUTABLE:
                    frequency_change(store, frequency_state, policy_name, field,
                                     FREQUENCY_TARGET_KHZ,
                                     min(deadline_seconds, time.monotonic() + 1))
            expected_frequency = json.loads(json.dumps(frequency_state['baseline']))
            for policy_name in FREQUENCY_TARGETS:
                for field in FREQUENCY_MUTABLE:
                    expected_frequency['policies'][policy_name][field]['value'] = FREQUENCY_TARGET_KHZ
            require(frequency_snapshot() == expected_frequency, 'Active frequency request differs')
        if not window_mode:
            empty_probe(probe_group, store, min(deadline_seconds, time.monotonic() + 2))
        active_frequency = frequency_snapshot() if frequency_mode else None
        if frequency_mode:
            require(active_frequency == expected_frequency, 'Frequency changed before active receipt')
        store.save('active.json', {'partition': values(probe_group.path),
                                  'snapshot': snapshot((guard_group.name, probe_group.name), True),
                                  'frequency_mode': frequency_mode,
                                  'frequency': active_frequency,
                                  'hardware_frequency_qualified': False})
        active = True
        if window_mode:
            current_worker = prepared_worker
            prepared_worker = None
            worker_result = window_worker(probe_group, store, life_reader, lock_descriptor,
                                          deadline_seconds, monitor, current_worker)
            reason = worker_result['reason']
            if reason == 'worker_exited':
                received = wait_byte(life_reader, deadline_seconds, monitor)
                require(received in (b'R', b''), 'Unexpected completed worker instruction')
                reason = 'release' if received == b'R' else 'controller_eof'
        else:
            received = wait_byte(life_reader, deadline_seconds, monitor)
            require(received in (b'R', b''), 'Unexpected controller instruction')
            reason = 'release' if received == b'R' else 'controller_eof'
    except BaseException as error:
        errors.append({'step': 'guard', 'error': repr(error)})
    finally:
        if prepared_worker is not None:
            attempt(restoration_errors, 'close_prepared_worker', lambda: os.close(prepared_worker[0]))
        cleanup_errors = restoration_errors if window_mode else errors
        if probe_group is not None:
            try:
                require(not probe_group.read('cgroup.procs') and
                        not any(child.is_dir() for child in probe_group.path.iterdir()),
                        'Unknown member or child prevents probe restoration')
                if frequency_state is not None and guard_group is not None:
                    require(guard_group.read('cgroup.procs').split() == [str(os.getpid())] and
                            not any(child.is_dir() for child in guard_group.path.iterdir()),
                            'Unknown guard member or child prevents frequency restoration')
                if window_mode and worker_result is not None:
                    require(worker_result['reaped'], 'Window worker has not been reaped')
            except Exception as error:
                cleanup_errors.append({'step': 'probe_empty_check', 'error': repr(error)})
            else:
                if frequency_state is not None:
                    frequency_restore(store, frequency_state, cleanup_errors, time.monotonic() + 6)
                attempt(cleanup_errors, 'release_probe', lambda: probe_group.write('cpuset.cpus.partition', 'member'))
                attempt(cleanup_errors, 'remove_probe', probe_group.remove)
        elif frequency_state is not None:
            attempt(cleanup_errors, 'frequency_without_probe', lambda: require(
                frequency_state['sequence'] == 0, 'Frequency write without an owned probe'))
        if guard_group is not None:
            def return_guard():
                fallback = CGROUP_ROOT / 'init.scope'
                require(fallback.stat().st_ino == fallback_inode, 'Fallback inode differs')
                (fallback / 'cgroup.procs').write_text(str(os.getpid()) + '\n')
                require(process_group(os.getpid()) == '0::/init.scope', 'Guard return failed')
            attempt(cleanup_errors, 'return_guard', return_guard)
            attempt(cleanup_errors, 'remove_guard', guard_group.remove)
        restored = None
        try:
            restored = snapshot()
            baseline = store.load('baseline.json')
            require(restored['top_names'] == baseline['top_names'], 'Top groups differ after restore')
        except Exception as error:
            cleanup_errors.append({'step': 'final_readback', 'error': repr(error)})
        restoration_visible = active and not cleanup_errors and (not window_mode or (
            worker_result is not None and worker_result['reaped'] and
            frequency_state is not None and frequency_state.get('restoration_visible', False)))
        evidence_complete = not errors and (worker_result is None or worker_result['evidence_complete']) and (
            frequency_state is None or frequency_state.get('evidence_complete', True))
        measurement_complete = bool(worker_result and worker_result['measurement_complete'])
        window_passed = bool(worker_result and (measurement_complete if reason == 'release' else (
            reason == 'controller_eof' and worker_result['cancel_while_running'] and
            worker_result['registered_cancel'] and
            worker_result['worker_exit_code'] == -signal.SIGKILL)))
        outcome = {'utc': utc_now(), 'pid': os.getpid(), 'active_observed': active,
                   'reason': reason, 'errors': errors, 'restored': restored,
                   'restoration_errors': restoration_errors,
                   'restoration_visible': restoration_visible,
                   'evidence_complete': evidence_complete,
                   'measurement_complete': measurement_complete,
                   'worker': worker_result,
                   'success': (restoration_visible and evidence_complete and window_passed)
                   if window_mode else active and not errors}
        try:
            store.save('terminal.json', outcome)
        except Exception:
            os._exit(2)
        os.close(life_reader)
        os.close(lock_descriptor)
    os._exit(0 if outcome['success'] else 1)


def controller(store, lock_descriptor, token, fallback_inode,
               frequency_mode=False, window_mode=False):
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    store.save('controller.json', {'pid': os.getpid(), 'start_ticks': start_ticks(os.getpid())})
    life_reader, life_writer = os.pipe()
    guard_id = os.fork()
    if guard_id == 0:
        os.close(life_writer)
        try:
            guard(store, life_reader, lock_descriptor, token, fallback_inode, frequency_mode, window_mode)
        except BaseException:
            os._exit(2)
    os.close(life_reader)
    os.close(lock_descriptor)
    try:
        while True:
            instruction = os.read(0, 1)
            if instruction not in ((b'A', b'W', b'R') if window_mode else (b'A', b'R')):
                break
            os.write(life_writer, instruction)
            if instruction == b'R':
                break
    finally:
        os.close(life_writer)
        status_code = wait_owned_child(guard_id, time.monotonic() + 25)
    return os.waitstatus_to_exitcode(status_code)


def wait_record(store, name, guard_descriptor=None):
    deadline_seconds = time.monotonic() + 25
    while time.monotonic() < deadline_seconds:
        if store.has(name):
            return store.load(name)
        if guard_descriptor is not None and select.select([guard_descriptor], [], [], 0)[0]:
            raise RuntimeError('Guard exited before ' + name)
        time.sleep(0.02)
    raise TimeoutError('Observation deadline, inspect original process; do not restart')


def frozen_command(arguments):
    source_text = globals().get('SOURCE_TEXT')
    require(source_text is not None, 'Root execution requires frozen in-memory source')
    bootstrap = 'SOURCE_TEXT=' + repr(source_text) + ';exec(compile(SOURCE_TEXT,"frozen_partition.py","exec"))'
    require(len(bootstrap.encode()) + 1 < 128 * 1024, 'Frozen controller source exceeds one Linux argument')
    return [sys.executable, '-I', '-B', '-c', bootstrap] + arguments


def lock_root(work_directory):
    check_work(work_directory)
    descriptor = os.open('partition-admin.lock',
                         os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600,
                         dir_fd=work_directory)
    metadata = os.fstat(descriptor)
    require(stat.S_ISREG(metadata.st_mode) and metadata.st_uid == 0 and
            stat.S_IMODE(metadata.st_mode) == 0o600, 'Unexpected lock file')
    fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
    return descriptor


def run_case(run_store, mode, lock_descriptor, fallback_inode,
             frequency_mode=False, window_mode=False):
    path = run_store.path / mode
    os.mkdir(mode, 0o700, dir_fd=run_store.descriptor)
    store = Store(path)
    token = run_store.path.name.rsplit('-', 1)[1] + '-' + mode
    controller_log = store.open_file('controller.log', os.O_WRONLY | os.O_CREAT | os.O_EXCL)
    process = subprocess.Popen(frozen_command(['controller', str(path), str(store.descriptor),
                               str(lock_descriptor), token, str(fallback_inode),
                               'window' if window_mode else 'frequency' if frequency_mode else 'partition']),
                               stdin=subprocess.PIPE, stdout=controller_log, stderr=controller_log,
                               pass_fds=(store.descriptor, lock_descriptor))
    os.close(controller_log)
    guard_descriptor = None
    guard_identity = None
    worker_descriptor = None
    try:
        guard_identity = wait_record(store, 'guard.json')
        guard_descriptor = os.pidfd_open(guard_identity['pid'])
        require(start_ticks(guard_identity['pid']) == guard_identity['start_ticks'], 'Guard PID reused')
        store.save('observer-guard.json', {'identity': guard_identity, 'pidfd_opened_before_arm': True})
        wait_record(store, 'ready.json', guard_descriptor)
        process.stdin.write(b'A')
        process.stdin.flush()
        wait_record(store, 'active.json', guard_descriptor)
        if window_mode:
            worker_identity = wait_record(store, 'worker-ready.json', guard_descriptor)
            worker_descriptor = os.pidfd_open(worker_identity['pid'])
            require(start_ticks(worker_identity['pid']) == worker_identity['start_ticks'] and
                    not select.select([worker_descriptor], [], [], 0)[0] and
                    process_group(worker_identity['pid']) == '0::/a113part-' + token + '-probe' and
                    os.sched_getaffinity(worker_identity['pid']) == {2}, 'Gated worker identity differs')
            store.save('observer-worker.json', {'identity': worker_identity,
                       'pidfd_opened_before_release': True})
            process.stdin.write(b'W')
            process.stdin.flush()
            running = wait_record(store, 'worker-running.json', guard_descriptor)
            require(running['pid'] == worker_identity['pid'] and
                    running['start_ticks'] == worker_identity['start_ticks'] and running['alive_at_check'],
                    'Running worker identity differs')
        if mode == 'normal':
            if window_mode:
                worker_exit = wait_record(store, 'worker-exit.json', guard_descriptor)
                require(worker_exit['reaped'] and select.select([worker_descriptor], [], [], 0)[0],
                        'Worker exit was not observed before release')
            process.stdin.write(b'R')
            process.stdin.flush()
        else:
            if window_mode:
                while time.monotonic() < running['released_monotonic_seconds'] + 0.25:
                    require(not select.select([worker_descriptor, guard_descriptor], [], [], 0.02)[0],
                            'Worker or guard ended before registered cancellation')
                executable = Path('/proc/' + str(worker_identity['pid']) + '/exe')
                metadata = executable.stat()
                require(start_ticks(worker_identity['pid']) == worker_identity['start_ticks'] and
                        process_group(worker_identity['pid']) == '0::/a113part-' + token + '-probe' and
                        os.sched_getaffinity(worker_identity['pid']) == {2} and
                        metadata.st_ino == worker_identity['binary']['inode'] and
                        metadata.st_dev == worker_identity['binary']['device'],
                        'Worker changed before cancellation')
                store.save('observer-cancel.json', {'utc': utc_now(), 'identity': worker_identity,
                           'check_monotonic_seconds': time.monotonic(), 'minimum_release_age_seconds': 0.25})
                require(not select.select([worker_descriptor], [], [], 0)[0],
                        'Worker ended before controller SIGKILL')
            require(process.poll() is None, 'Controller already ended')
            process.kill()
        process.stdin.close()
        require(select.select([guard_descriptor], [], [], 35)[0], 'Guard still live; do not restart')
        exit_code = process.wait(timeout=3)
        expected_code = 0 if mode == 'normal' else -signal.SIGKILL
        if not window_mode:
            require(exit_code == expected_code, 'Controller exit differs')
        terminal = store.load('terminal.json') if store.has('terminal.json') else None
        worker_exit_observed = False
        if window_mode:
            worker_exit_observed = bool(select.select([worker_descriptor], [], [], 0)[0])
            require(worker_exit_observed, 'Window worker remained live after guard exit')
        if not window_mode:
            require(terminal['success'] and terminal['reason'] ==
                    ('release' if mode == 'normal' else 'controller_eof'), 'Restoration did not pass')
        final = snapshot()
        require(final['top_names'] == store.load('baseline.json')['top_names'], 'Independent readback differs')
        frequency_final = frequency_snapshot() if frequency_mode else None
        if frequency_mode:
            require(frequency_final == store.load('frequency-baseline.json'),
                    'Independent frequency readback differs')
        case_success = bool(terminal and terminal['success'] and exit_code == expected_code and (
            not window_mode or (terminal['worker'] is not None and
                terminal['worker']['pid'] == worker_identity['pid'] and terminal['worker']['reaped'])))
        store.save('observer.json', {'utc': utc_now(), 'guard_pidfd_exit_observed': True,
                                    'controller_exit_code': exit_code, 'readback': final,
                                    'frequency_readback': frequency_final,
                                    'terminal': terminal, 'window_mode': window_mode,
                                    'worker_pidfd_exit_observed': worker_exit_observed,
                                    'restoration_visible': True,
                                    'hardware_frequency_qualified': False,
                                    'success': case_success if window_mode else True})
        if window_mode:
            require(case_success and terminal is not None and terminal['success'] and
                    terminal['restoration_visible'] and terminal['evidence_complete'] and
                    terminal['reason'] == ('release' if mode == 'normal' else 'controller_eof'),
                    'Window case incomplete; independent resource readback is retained')
    finally:
        if not process.stdin.closed:
            try:
                process.stdin.close()
            except BrokenPipeError:
                pass
        if guard_descriptor is not None:
            exited = bool(select.select([guard_descriptor], [], [], 35)[0])
            store.save('observer-final.json', {'utc': utc_now(), 'guard_identity': guard_identity,
                       'guard_exit_observed': exited, 'artifact_role':
                       'terminal_snapshot' if exited else 'partial_snapshot_live_guard'})
            os.close(guard_descriptor)
        if worker_descriptor is not None:
            os.close(worker_descriptor)
        os.close(store.descriptor)


def archive_run(store, work_directory):
    store.check()
    check_work(work_directory)
    target = WORK_ROOT / (store.path.name + '.tar')
    descriptor = os.open(target.name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                         0o600, dir_fd=work_directory)
    with os.fdopen(descriptor, 'wb') as output, tarfile.open(fileobj=output, mode='w') as archive:
        for directory in (store.path, store.path / 'normal', store.path / 'parent-loss'):
            if not directory.exists():
                continue
            current = Store(directory)
            if store.path.name.startswith('core-window-') and directory != store.path:
                require(sum(os.stat(name, dir_fd=current.descriptor, follow_symlinks=False).st_size
                            for name in os.listdir(current.descriptor)) <= WINDOW_CASE_LIMIT,
                        'Window case exceeds archive budget')
            for name in sorted(os.listdir(current.descriptor)):
                metadata = os.stat(name, dir_fd=current.descriptor, follow_symlinks=False)
                if stat.S_ISDIR(metadata.st_mode):
                    continue
                with os.fdopen(current.open_file(name, os.O_RDONLY), 'rb') as source:
                    contents = source.read()
                entry = tarfile.TarInfo(str((directory / name).relative_to(store.path)))
                entry.size = len(contents)
                entry.mode = 0o600
                archive.addfile(entry, io.BytesIO(contents))
            os.close(current.descriptor)
        archive.close()
        account = pwd.getpwnam('nss-marker')
        os.fchown(output.fileno(), account.pw_uid, account.pw_gid)
        output.flush()
        os.fsync(output.fileno())
    return target


def run(frequency_mode=False, window_mode=False):
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    fallback_inode = root_gate()
    work_directory = work_descriptor()
    if window_mode:
        require(frequency_mode and os.execve in os.supports_fd and
                re.fullmatch(r'[0-9a-f]{64}', WINDOW_WORKER_SHA256 or ''),
                'Window execution requires a frozen native worker and descriptor exec')
        available = os.fstatvfs(work_directory)
        require(available.f_bavail * available.f_frsize >= WINDOW_REQUIRED_FREE, 'Cry disk reserve too small')
    lock_descriptor = lock_root(work_directory)
    prefix = 'core-window' if window_mode else 'core-frequency' if frequency_mode else 'core-partition'
    path = WORK_ROOT / (prefix + '-20261010-' + os.urandom(6).hex())
    check_work(work_directory)
    os.mkdir(path.name, mode=0o700, dir_fd=work_directory)
    store = Store(path)
    errors = []
    try:
        store.save('source.json', {'sha256': hashlib.sha256(SOURCE_TEXT.encode()).hexdigest(),
                                  'source': SOURCE_TEXT, 'utc': utc_now()})
        for mode in ('normal', 'parent-loss'):
            run_case(store, mode, lock_descriptor, fallback_inode, frequency_mode, window_mode)
    except Exception as error:
        errors.append(repr(error))
    store.save('run.json', {'success': not errors, 'errors': errors, 'utc': utc_now(),
                          'configuration_scope': 'owned_virtual_cgroups_and_two_policy_frequency_limits'
                          if frequency_mode else 'owned_virtual_cgroups_only',
                          'hardware_frequency_qualified': False})
    target = archive_run(store, work_directory)
    print(json.dumps({'run_directory': str(path), 'archive': str(target), 'success': not errors,
                      'errors': errors}), flush=True)
    os.close(store.descriptor)
    os.close(lock_descriptor)
    os.close(work_directory)
    return 0 if not errors else 1


def recover(path):
    root_gate(recovering=True)
    work_directory = work_descriptor()
    lock_descriptor = lock_root(work_directory)
    store = Store(path)
    require(store.path.name in ('normal', 'parent-loss') and
            store.path.parent.parent == WORK_ROOT and
            re.fullmatch(r'core-(partition|frequency|window)-20261010-[0-9a-f]{12}', store.path.parent.name),
            'Recovery path is not a known case')
    errors = []
    token = store.path.parent.name.rsplit('-', 1)[1] + '-' + store.path.name
    expected_names = ['a113part-' + token + suffix for suffix in ('-probe', '-guard')]
    try:
        if store.path.parent.name.startswith('core-window-'):
            require(store.has('probe-before-exec.json') or not store.has('active.json'),
                    'Window worker identity is uncertain; manual recovery refuses')
        for name in ('guard.json', 'controller.json', 'probe-before-exec.json'):
            if name == 'probe-before-exec.json' and not store.has(name):
                continue
            identity = store.load(name)
            try:
                descriptor = os.pidfd_open(identity['pid'])
            except ProcessLookupError:
                continue
            try:
                if not select.select([descriptor], [], [], 0)[0]:
                    require(start_ticks(identity['pid']) != identity['start_ticks'],
                            'Original process still live')
            finally:
                os.close(descriptor)
        owned_groups = []
        for name, expected_name in zip(('probe-group.json', 'guard-group.json'), expected_names):
            present = (CGROUP_ROOT / expected_name).exists()
            require(store.has(name) or not present, 'Owned path exists without inode receipt')
            if not present:
                continue
            identity = store.load(name)
            require(identity['name'] == expected_name, 'Group nonce differs')
            group = OwnedGroup(expected_name, identity['inode'])
            require(not group.read('cgroup.procs') and
                    not any(child.is_dir() for child in group.path.iterdir()),
                    'Manual recovery refuses unknown members or child groups')
            owned_groups.append((name, group))
        if store.path.parent.name.startswith(('core-frequency-', 'core-window-')):
            if store.has('frequency-baseline.json'):
                frequency_restore(store, None, errors, time.monotonic() + 6)
            else:
                require(not any((CGROUP_ROOT / name).exists() for name in expected_names) and
                        not any(name.startswith('frequency-dirty-') for name in os.listdir(store.descriptor)),
                        'Frequency recovery state missing')
        for name, group in owned_groups:
            if name == 'probe-group.json':
                attempt(errors, 'manual_release', lambda: group.write('cpuset.cpus.partition', 'member'))
            attempt(errors, 'manual_remove', group.remove)
        restored = snapshot()
        require(restored['top_names'] == store.load('baseline.json')['top_names'],
                'Manual top-group readback differs')
        require(not any((CGROUP_ROOT / name).exists() for name in expected_names),
                'Owned group remains after manual recovery')
    except Exception as error:
        errors.append({'step': 'manual_recovery', 'error': repr(error)})
    result = {'utc': utc_now(), 'errors': errors, 'success': not errors}
    store.save('manual-' + os.urandom(6).hex() + '.json', result)
    print(json.dumps(result))
    os.close(lock_descriptor)
    os.close(work_directory)
    return 0 if not errors else 1


def selfcheck(directory):
    from unittest.mock import patch
    from types import SimpleNamespace
    require(Path(directory).is_absolute(), 'Selfcheck requires an explicit absolute build root')
    with patch.dict(globals(), {'SOURCE_TEXT': "print('benign')\n"}):
        require(frozen_command([])[1:3] == ['-I', '-B'], 'Frozen controller lost isolated flags')
    with patch.dict(globals(), {'SOURCE_TEXT': '文' * 50000}):
        try:
            frozen_command([])
        except RuntimeError:
            pass
        else:
            raise AssertionError('Oversized UTF-8 controller argument accepted')
    require(cpu_set(HOUSEKEEPING_TEXT) == HOUSEKEEPING_CPUS, 'CPU parser mismatch')
    require(cpu_set('2,18\n') == PROBE_CPUS and cpu_set('\n') == set(), 'Kernel newline rejected')
    for bad in ('32', '-1', '3-2', '2-3-4', '2;id', '2,,18', '2,'):
        try:
            cpu_set(bad)
        except RuntimeError:
            continue
        raise AssertionError('Invalid list accepted')
    errors = []
    order = []
    attempt(errors, 'injected', lambda: (_ for _ in ()).throw(OSError('injected')))
    attempt(errors, 'continued', lambda: order.append('continued'))
    require(len(errors) == 1 and order == ['continued'], 'Cleanup did not continue')
    reader, writer = os.pipe()
    child_id = os.fork()
    if child_id == 0:
        os.close(writer)
        try:
            os._exit(0 if wait_byte(reader, time.monotonic() + 2) == b'' else 1)
        except BaseException:
            os._exit(2)
    os.close(reader)
    os.close(writer)
    _, status_code = os.waitpid(child_id, 0)
    require(os.waitstatus_to_exitcode(status_code) == 0, 'Pipe EOF check failed')
    with tempfile.TemporaryDirectory(dir=directory, prefix='partition-selfcheck-') as temporary:
        group = object.__new__(OwnedGroup)
        group.path = Path(temporary)
        group.inode = group.path.stat().st_ino + 1
        group.descriptor = os.open(group.path, os.O_RDONLY)
        with patch.object(Path, 'stat', return_value=SimpleNamespace(st_uid=0, st_ino=group.inode+1)):
            try:
                group.check()
            except RuntimeError:
                pass
            else:
                raise AssertionError('Wrong group identity accepted')
        os.close(group.descriptor)
        store = object.__new__(Store)
        store.descriptor = os.open(temporary, os.O_RDONLY | os.O_DIRECTORY)
        store.check = lambda: None
        store.open_file = lambda name, flags: os.open(name, flags, 0o600, dir_fd=store.descriptor)
        store.save('atomic.json', {'complete': True})
        require(json.loads((Path(temporary)/'atomic.json').read_text()) == {'complete': True},
                'Atomic receipt mismatch')
        try:
            store.save('atomic.json', {'complete': False})
        except FileExistsError:
            pass
        else:
            raise AssertionError('Existing receipt overwritten')
        require(json.loads((Path(temporary)/'atomic.json').read_text())['complete'],
                'Original receipt changed')
        os.close(store.descriptor)
        records = {}
        children = []
        fake_group = SimpleNamespace(name='a113part-selfcheck-probe')
        def fake_move(name, process_id):
            require(name == 'cgroup.procs', 'Unexpected probe write')
            require(os.waitpid(process_id, os.WNOHANG)[0] == 0, 'Probe escaped its gate')
            children.append(process_id)
        fake_group.write = fake_move
        fake_store = SimpleNamespace(save=lambda name, value: records.update({name: value}))
        with patch.dict(globals(), {'start_ticks': lambda process_id: 123,
                'process_group': lambda process_id: '0::/' + fake_group.name}), \
                patch.object(os, 'sched_getaffinity', return_value=PROBE_CPUS, create=True):
            signal.signal(signal.SIGCHLD, signal.SIG_IGN)
            empty_probe(fake_group, fake_store, time.monotonic()+2)
            require(signal.getsignal(signal.SIGCHLD) == signal.SIG_DFL, 'SIGCHLD not restored before fork')
            require(records['probe-exit.json']['exit_code'] == 0, 'Gated empty task failed')
            fake_store.save = lambda name, value: (_ for _ in ()).throw(OSError('injected receipt failure'))
            try:
                empty_probe(fake_group, fake_store, time.monotonic()+2)
            except OSError:
                pass
            else:
                raise AssertionError('Injected probe failure hidden')
        for process_id in children:
            try:
                os.waitpid(process_id, os.WNOHANG)
            except ChildProcessError:
                continue
            raise AssertionError('Owned probe child not reaped')
    for frequency_case in ('partial', 'pending_invisible', 'pending_cancel_failure',
                           'restore_failure', 'unknown', 'storage_dirty', 'storage_visible',
                           'storage_published_dirty'):
        baseline = {'global': {'status': {'value': 'active'}},
                    'cpu_links': {'2': 'policy2', '18': 'policy18'},
                    'policy_names': list(FREQUENCY_POLICIES), 'policies': {}}
        for policy_index, policy_name in enumerate(FREQUENCY_POLICIES):
            row = {'identity': {'inode': policy_index + 1, 'device': 42}}
            for field_index, field in enumerate(FREQUENCY_FIELDS):
                value = '2982259' if field == 'scaling_min_freq' else '5756452'
                row[field] = {'value': value, 'inode': 100 + policy_index * 20 + field_index,
                              'device': 42, 'owner_uid': 0, 'mode': 0o644}
            baseline['policies'][policy_name] = row
        virtual = json.loads(json.dumps(baseline))
        records = {'frequency-baseline.json': baseline}
        state = {'baseline': baseline, 'sequence': 0, 'known_pairs': {
            name: [['2982259', '5756452']] for name in FREQUENCY_TARGETS}}
        control = {'pending': None, 'opened': None, 'fail': None,
                   'accept_failure': False, 'writes': [], 'snapshot_count': 0, 'delay': 2}

        def save_frequency_record(name, value):
            require(name not in records, 'Frequency receipt overwritten')
            failure = control.get('storage_failure')
            if failure and name.startswith('frequency-' + failure.replace('published_', '') + '-'):
                control['storage_failure'] = None
                if failure == 'published_dirty':
                    records[name] = json.loads(json.dumps(value))
                raise OSError(control.get('storage_errno', errno.ENOSPC), 'injected recovery allocation failure')
            records[name] = json.loads(json.dumps(value))

        fake_store = SimpleNamespace(descriptor=98765,
                                     path=WORK_ROOT/'core-window-20261010-000000000000'/'normal',
                                     save=save_frequency_record,
                                     has=lambda name: name in records,
                                     load=lambda name: json.loads(json.dumps(records[name])))

        def fake_frequency_snapshot(policy_names=FREQUENCY_POLICIES):
            control['snapshot_count'] += 1
            if control['pending'] is not None:
                control['pending'][3] -= 1
                if control['pending'][3] == 0:
                    name, field, value, _ = control['pending']
                    virtual['policies'][name][field]['value'] = value
                    control['pending'] = None
            result = json.loads(json.dumps(virtual))
            result['policies'] = {name: result['policies'][name] for name in policy_names}
            return result

        def fake_frequency_open(path, flags):
            path = Path(path)
            require(path.parent.name in FREQUENCY_TARGETS and path.name in FREQUENCY_MUTABLE and
                    flags == os.O_WRONLY | os.O_NOFOLLOW | os.O_CLOEXEC,
                    'Unexpected frequency write path or flags')
            control['opened'] = (path.parent.name, path.name)
            return 98766

        def fake_frequency_stat(descriptor):
            require(descriptor == 98766, 'Unexpected fake frequency descriptor')
            name, field = control['opened']
            expected = baseline['policies'][name][field]
            return SimpleNamespace(st_uid=0, st_mode=stat.S_IFREG | expected['mode'],
                                   st_ino=expected['inode'], st_dev=expected['device'])

        def fake_frequency_write(descriptor, contents):
            require(descriptor == 98766, 'Unexpected fake write descriptor')
            name, field = control['opened']
            value = contents.decode().strip()
            latest_name = max(name for name in records if re.fullmatch(
                r'frequency-dirty-[0-9]{4}\.json', name))
            latest = records[latest_name]
            if not (latest['policy_name'] == name and latest['field'] == field):
                require('recovery_plan' in state and state.get('evidence_complete') is False and
                        value == baseline['policies'][name][field]['value'],
                        'Write preceded neither durable intent nor fixed recovery plan')
            control['writes'].append((name, field, value))
            if control['fail'] == (name, field):
                control['fail'] = None
                if control['accept_failure']:
                    virtual['policies'][name][field]['value'] = value
                raise OSError('injected frequency write failure')
            control['pending'] = [name, field, value, control['delay']]
            return len(contents)

        with patch.object(sys.modules[__name__], 'frequency_snapshot', fake_frequency_snapshot), \
                patch.object(os, 'open', fake_frequency_open), \
                patch.object(os, 'fstat', fake_frequency_stat), \
                patch.object(os, 'write', fake_frequency_write), \
                patch.object(os, 'close', lambda descriptor: None), \
                patch.object(os, 'listdir', lambda descriptor: list(records)):
            for policy_name, field in (('policy2', 'boost'), ('policy0', 'scaling_min_freq')):
                try:
                    frequency_change(fake_store, state, policy_name, field, '0', time.monotonic()+1)
                except RuntimeError:
                    pass
                else:
                    raise AssertionError('Out-of-scope frequency write accepted')
            require(not control['writes'], 'Rejected frequency write reached syscall')
            if frequency_case == 'partial':
                frequency_change(fake_store, state, 'policy2', 'scaling_min_freq',
                                 FREQUENCY_TARGET_KHZ, time.monotonic()+1)
                control['fail'] = ('policy2', 'scaling_max_freq')
                control['accept_failure'] = True
                try:
                    frequency_change(fake_store, state, 'policy2', 'scaling_max_freq',
                                     FREQUENCY_TARGET_KHZ, time.monotonic()+1)
                except OSError:
                    pass
                else:
                    raise AssertionError('Partial write failure hidden')
            elif frequency_case in ('pending_invisible', 'pending_cancel_failure'):
                control['delay'] = 1000000
                try:
                    frequency_change(fake_store, state, 'policy2', 'scaling_min_freq',
                                     FREQUENCY_TARGET_KHZ, time.monotonic()+0.02)
                except TimeoutError:
                    pass
                else:
                    raise AssertionError('Invisible accepted frequency request did not time out')
                require(virtual == baseline, 'Delayed request became visible too early')
                control['delay'] = 2
                if frequency_case == 'pending_cancel_failure':
                    control['fail'] = ('policy2', 'scaling_min_freq')
            else:
                for policy_name in FREQUENCY_TARGETS:
                    for field in FREQUENCY_MUTABLE:
                        frequency_change(fake_store, state, policy_name, field,
                                         FREQUENCY_TARGET_KHZ, time.monotonic()+1)
                if frequency_case == 'restore_failure':
                    control['fail'] = ('policy2', 'scaling_min_freq')
                elif frequency_case == 'unknown':
                    virtual['policies']['policy2']['scaling_min_freq']['value'] = '4000000'
                    virtual['policies']['policy3']['scaling_max_freq']['value'] = '5700000'
                elif frequency_case.startswith('storage_'):
                    plan = {'profile': 'window', 'state_path': str(fake_store.path),
                            'baseline_sha256': hashlib.sha256(json.dumps(baseline, sort_keys=True).encode()).hexdigest(),
                            'original_values': {policy_name: {
                                field: baseline['policies'][policy_name][field]['value']
                                for field in FREQUENCY_MUTABLE} for policy_name in FREQUENCY_TARGETS}}
                    records['frequency-recovery-plan.json'] = plan
                    state['recovery_plan'] = plan
                    state['evidence_complete'] = True
                    original_plan = json.loads(json.dumps(plan))
                    for wrong_plan in ('path', 'profile'):
                        bad_plan = json.loads(json.dumps(original_plan))
                        bad_plan['state_path' if wrong_plan == 'path' else 'profile'] = 'incorrect'
                        records['frequency-recovery-plan.json'] = bad_plan
                        state['recovery_plan'] = bad_plan
                        control['storage_failure'] = 'dirty'
                        prior_write_count = len(control['writes'])
                        try:
                            frequency_change(fake_store, state, 'policy2', 'scaling_min_freq',
                                             '2982259', time.monotonic()+1, restoring=True)
                        except RuntimeError:
                            pass
                        else:
                            raise AssertionError('Wrong recovery plan authorized a fallback write')
                        require(len(control['writes']) == prior_write_count, 'Invalid plan reached a write')
                    records['frequency-recovery-plan.json'] = original_plan
                    state['recovery_plan'] = original_plan
                    for storage_errno in (errno.EACCES, errno.EIO):
                        control['storage_failure'] = 'dirty'
                        control['storage_errno'] = storage_errno
                        prior_write_count = len(control['writes'])
                        try:
                            frequency_change(fake_store, state, 'policy2', 'scaling_min_freq',
                                             '2982259', time.monotonic()+1, restoring=True)
                        except OSError as error:
                            require(error.errno == storage_errno, 'Storage error was changed')
                        else:
                            raise AssertionError('Non-allocation failure used the recovery exception')
                        require(len(control['writes']) == prior_write_count, 'Invalid storage fallback wrote')
                    control['storage_errno'] = errno.ENOSPC
                    original_pair = [virtual['policies']['policy2'][field]['value'] for field in FREQUENCY_MUTABLE]
                    for field in FREQUENCY_MUTABLE:
                        virtual['policies']['policy2'][field]['value'] = baseline['policies']['policy2'][field]['value']
                    control['storage_failure'] = 'dirty'
                    try:
                        frequency_change(fake_store, state, 'policy2', 'scaling_min_freq',
                                         FREQUENCY_TARGET_KHZ, time.monotonic()+1)
                    except OSError as error:
                        require(error.errno == errno.ENOSPC, 'Apply storage error was changed')
                    else:
                        raise AssertionError('Apply used the original-value recovery exception')
                    for field_index, field in enumerate(FREQUENCY_MUTABLE):
                        virtual['policies']['policy2'][field]['value'] = original_pair[field_index]
                    control['storage_failure'] = frequency_case.removeprefix('storage_')
            errors = []
            frequency_restore(fake_store, state, errors, time.monotonic()+6)
            require(virtual['policies']['policy18'] == baseline['policies']['policy18'],
                    'Frequency restoration did not continue to second policy')
            if frequency_case in ('partial', 'pending_invisible'):
                require(not errors and virtual == baseline, 'Partial accepted write not restored')
                if frequency_case == 'pending_invisible':
                    require(control['writes'] == [('policy2', 'scaling_min_freq', FREQUENCY_TARGET_KHZ),
                                                  ('policy2', 'scaling_min_freq', '2982259')],
                            'Invisible dirty request was not explicitly superseded')
                    if control['pending'] is not None:
                        control['pending'][3] = 1
                    require(fake_frequency_snapshot() == baseline, 'Delayed request reappeared')
                write_count = len(control['writes'])
                frequency_restore(fake_store, None, errors, time.monotonic()+6)
                frequency_restore(fake_store, None, errors, time.monotonic()+6)
                require(not errors and len(control['writes']) == write_count,
                        'Repeated manual recovery changed a restored policy or overwrote receipt')
            elif frequency_case == 'restore_failure':
                require(errors and virtual['policies']['policy2']['scaling_max_freq']['value'] == '5756452',
                        'Failure prevented remaining frequency restore steps')
                errors = []
                frequency_restore(fake_store, None, errors, time.monotonic()+6)
                require(not errors and virtual == baseline, 'Manual partial-state reconstruction failed')
            elif frequency_case == 'pending_cancel_failure':
                require(errors and virtual == baseline and
                        not any(name.startswith('frequency-restored-') for name in records),
                        'Pending cancellation failure published a restored receipt')
                control['pending'][3] = 1
                require(fake_frequency_snapshot() != baseline, 'Late failed-cancellation request absent')
                errors = []
                frequency_restore(fake_store, None, errors, time.monotonic()+6)
                require(not errors and virtual == baseline, 'Pending manual cancellation failed')
            elif frequency_case == 'unknown':
                require(errors and virtual['policies']['policy2']['scaling_min_freq']['value'] == '4000000' and
                        virtual['policies']['policy3']['scaling_max_freq']['value'] == '5700000',
                        'Unknown or non-target frequency state overwritten')
            else:
                require(not errors and virtual == baseline and state['restoration_visible'] and
                        state['evidence_complete'] is False, 'Allocation failure blocked original-value recovery')
                frequency_restore(fake_store, None, errors, time.monotonic()+6)
                require(not errors and virtual == baseline, 'Recovery plan could not reconstruct a missing intent')
            require(control['snapshot_count'] > len(control['writes']), 'Async readback not exercised')

    for window_case in ('normal', 'eof', 'registered_eof', 'release', 'timeout', 'failure', 'receipt', 'output'):
        with tempfile.TemporaryDirectory(dir=directory, prefix='window-selfcheck-') as temporary:
            test_store = object.__new__(Store)
            test_store.path = Path(temporary)
            test_store.descriptor = os.open(temporary, os.O_RDONLY | os.O_DIRECTORY)
            test_store.check = lambda: None
            test_store.open_file = lambda name, flags: os.open(name, flags, 0o600,
                                                               dir_fd=test_store.descriptor)
            real_save = test_store.save
            def save_window_record(name, value):
                if window_case == 'receipt' and name == 'worker-released.json':
                    raise OSError(errno.ENOSPC, 'injected worker receipt failure')
                real_save(name, value)
            test_store.save = save_window_record
            reader, writer = os.pipe()
            os.write(writer, b'WR' if window_case == 'release' else b'W')
            if window_case == 'eof':
                os.close(writer)
                writer = None
            control = {'worker': None}
            fake_group = SimpleNamespace(name='a113part-window-selfcheck-probe')
            def move_window_child(name, process_id):
                require(name == 'cgroup.procs' and os.waitpid(process_id, os.WNOHANG)[0] == 0,
                        'Window test child escaped gate')
            fake_group.write = move_window_child
            fake_group.read = lambda name: str(control['worker']['pid'])
            def spawn_benign_window(group, store, life_reader, lock_descriptor, prepared_worker):
                stdout_descriptor = store.open_file('worker.stdout.jsonl', os.O_RDWR | os.O_CREAT | os.O_EXCL)
                stderr_descriptor = store.open_file('worker.stderr.log', os.O_RDWR | os.O_CREAT | os.O_EXCL)
                read_gate, write_gate = os.pipe()
                child_id = os.fork()
                if child_id == 0:
                    os.close(write_gate)
                    os.close(life_reader)
                    if writer is not None:
                        os.close(writer)
                    os.close(store.descriptor)
                    try:
                        if os.read(read_gate, 1) != b'A':
                            os._exit(3)
                        select.select([], [], [], 0.03 if window_case in ('normal', 'failure') else 4)
                        if window_case == 'failure':
                            os._exit(7)
                        contents = (json.dumps({'type': 'contract', 'implementation': 'reference',
                            'warmup_target_ns': '1000000000', 'main_target_ns': '4000000000'}) + '\n' +
                            json.dumps({'type': 'summary', 'status': 'completed', 'valid_final_snapshot': True}) + '\n')
                        os.write(stdout_descriptor, contents.encode())
                        os._exit(0)
                    except BaseException:
                        os._exit(8)
                os.close(read_gate)
                worker = {'pid': child_id, 'gate': write_gate, 'stdout_descriptor': stdout_descriptor,
                          'stderr_descriptor': stderr_descriptor,
                          'binary': {'path': '/benign-selfcheck', 'inode': 7, 'device': 42},
                          'reaped': False, 'released': False, 'exit_code': None, 'spawn_errors': []}
                control['worker'] = worker
                return worker
            original_stat = Path.stat
            original_readlink = os.readlink
            original_fstat = os.fstat
            def window_stat(path, *arguments, **keywords):
                if str(path).startswith('/proc/') and str(path).endswith('/exe'):
                    return SimpleNamespace(st_ino=7, st_dev=42)
                return original_stat(path, *arguments, **keywords)
            def window_readlink(path, *arguments, **keywords):
                if str(path).startswith('/proc/') and str(path).endswith('/exe'):
                    return '/benign-selfcheck'
                return original_readlink(path, *arguments, **keywords)
            def window_fstat(descriptor):
                worker = control['worker']
                if window_case == 'output' and worker is not None and worker['released'] and descriptor == worker['stdout_descriptor']:
                    return SimpleNamespace(st_size=WINDOW_FILE_LIMIT + 1)
                return original_fstat(descriptor)
            def benign_monitor():
                nonlocal writer
                if window_case == 'registered_eof' and control['worker']['released'] and writer is not None:
                    released = test_store.load('worker-released.json')['released_monotonic_seconds']
                    if time.monotonic() >= released + 0.26:
                        os.close(writer)
                        writer = None
            with patch.object(sys.modules[__name__], 'spawn_window_worker', spawn_benign_window), \
                    patch.object(sys.modules[__name__], 'start_ticks', lambda process_id: 123), \
                    patch.object(sys.modules[__name__], 'process_group', lambda process_id: '0::/' + fake_group.name), \
                    patch.object(os, 'sched_setaffinity', lambda *arguments: None, create=True), \
                    patch.object(os, 'sched_getaffinity', lambda process_id: {2}, create=True), \
                    patch.object(Path, 'stat', window_stat), \
                    patch.object(os, 'readlink', window_readlink), \
                    patch.object(os, 'fstat', window_fstat):
                result = window_worker(fake_group, test_store, reader, -1,
                                       time.monotonic() + (0.06 if window_case == 'timeout' else 2),
                                       benign_monitor, None)
            require(result['reaped'], 'Benign window worker was not reaped')
            try:
                os.waitpid(result['pid'], os.WNOHANG)
            except ChildProcessError:
                pass
            else:
                raise AssertionError('Benign worker remained an unreaped child')
            if window_case == 'normal':
                require(result['measurement_complete'] and result['worker_exit_code'] == 0,
                        'Benign normal window did not complete')
            else:
                require(not result['measurement_complete'], 'Cancelled or failed worker signed complete')
            if window_case in ('eof', 'registered_eof', 'release', 'timeout', 'receipt', 'output'):
                require(result['worker_exit_code'] == -signal.SIGKILL,
                        'Cancelled benign worker was not killed and reaped')
            if window_case == 'registered_eof':
                require(result['reason'] == 'controller_eof' and result['cancel_while_running'] and
                        result['registered_cancel'], 'Registered live-worker cancellation not exercised')
            elif window_case == 'eof':
                require(not result['registered_cancel'], 'Early EOF signed a registered cancellation')
            if window_case in ('receipt', 'output'):
                require(not result['evidence_complete'], 'Failed worker output/receipt signed complete')
            os.close(reader)
            if writer is not None:
                os.close(writer)
            os.close(test_store.descriptor)
    print('selfcheck=pass; cpu_parser,cleanup_continuation,pipe_eof,wrong_inode,atomic_receipt,probe_gate,failure_reap,sigchld_reset,frequency_partial,frequency_async,frequency_scope,frequency_conflict,frequency_continue,frequency_manual_repeat,frequency_pending_superseded,frequency_cancel_failure,frequency_storage,window_normal,window_eof,window_registered_eof,window_release,window_timeout,window_failure,window_receipt,window_output; kernel_writes=none; crypto_workload=none')


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--selfcheck':
        selfcheck(sys.argv[2])
    elif sys.argv[1:] == ['run']:
        raise SystemExit(run())
    elif sys.argv[1:] == ['run-frequency']:
        raise SystemExit(run(frequency_mode=True))
    elif sys.argv[1:] == ['run-window']:
        raise SystemExit(run(frequency_mode=True, window_mode=True))
    elif len(sys.argv) == 8 and sys.argv[1] == 'controller':
        require(sys.argv[7] in ('partition', 'frequency', 'window'), 'Unknown controller mode')
        case_store = Store(sys.argv[2], int(sys.argv[3]))
        raise SystemExit(controller(case_store, int(sys.argv[4]), sys.argv[5], int(sys.argv[6]),
                                    sys.argv[7] in ('frequency', 'window'), sys.argv[7] == 'window'))
    elif len(sys.argv) == 3 and sys.argv[1] == 'recover':
        raise SystemExit(recover(sys.argv[2]))
    else:
        raise SystemExit('Use --selfcheck ABS_BUILD_ROOT, or a reviewed frozen root run/recover')
