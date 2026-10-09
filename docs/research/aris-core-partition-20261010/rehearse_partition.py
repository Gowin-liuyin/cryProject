import datetime
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import pwd
import re
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


def guard(store, life_reader, lock_descriptor, token, fallback_inode):
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
    try:
        store.save('guard.json', {'pid': os.getpid(), 'start_ticks': start_ticks(os.getpid()),
                                 'effective_uid': os.geteuid()})
        store.save('baseline.json', snapshot())
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

        monitor()
        empty_probe(probe_group, store, min(deadline_seconds, time.monotonic() + 2))
        store.save('active.json', {'partition': values(probe_group.path),
                                  'snapshot': snapshot((guard_group.name, probe_group.name), True)})
        active = True
        received = wait_byte(life_reader, deadline_seconds, monitor)
        require(received in (b'R', b''), 'Unexpected controller instruction')
        reason = 'release' if received == b'R' else 'controller_eof'
    except BaseException as error:
        errors.append({'step': 'guard', 'error': repr(error)})
    finally:
        if probe_group is not None:
            try:
                require(not probe_group.read('cgroup.procs') and
                        not any(child.is_dir() for child in probe_group.path.iterdir()),
                        'Unknown member or child prevents probe restoration')
            except Exception as error:
                errors.append({'step': 'probe_empty_check', 'error': repr(error)})
            else:
                attempt(errors, 'release_probe', lambda: probe_group.write('cpuset.cpus.partition', 'member'))
                attempt(errors, 'remove_probe', probe_group.remove)
        if guard_group is not None:
            def return_guard():
                fallback = CGROUP_ROOT / 'init.scope'
                require(fallback.stat().st_ino == fallback_inode, 'Fallback inode differs')
                (fallback / 'cgroup.procs').write_text(str(os.getpid()) + '\n')
                require(process_group(os.getpid()) == '0::/init.scope', 'Guard return failed')
            attempt(errors, 'return_guard', return_guard)
            attempt(errors, 'remove_guard', guard_group.remove)
        restored = None
        try:
            restored = snapshot()
            baseline = store.load('baseline.json')
            require(restored['top_names'] == baseline['top_names'], 'Top groups differ after restore')
        except Exception as error:
            errors.append({'step': 'final_readback', 'error': repr(error)})
        outcome = {'utc': utc_now(), 'pid': os.getpid(), 'active_observed': active,
                   'reason': reason, 'errors': errors, 'restored': restored,
                   'success': active and not errors}
        try:
            store.save('terminal.json', outcome)
        except Exception:
            os._exit(2)
        os.close(life_reader)
        os.close(lock_descriptor)
    os._exit(0 if outcome['success'] else 1)


def controller(store, lock_descriptor, token, fallback_inode):
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    store.save('controller.json', {'pid': os.getpid(), 'start_ticks': start_ticks(os.getpid())})
    life_reader, life_writer = os.pipe()
    guard_id = os.fork()
    if guard_id == 0:
        os.close(life_writer)
        try:
            guard(store, life_reader, lock_descriptor, token, fallback_inode)
        except BaseException:
            os._exit(2)
    os.close(life_reader)
    os.close(lock_descriptor)
    try:
        while True:
            instruction = os.read(0, 1)
            if instruction not in (b'A', b'R'):
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


def run_case(run_store, mode, lock_descriptor, fallback_inode):
    path = run_store.path / mode
    os.mkdir(mode, 0o700, dir_fd=run_store.descriptor)
    store = Store(path)
    token = run_store.path.name.rsplit('-', 1)[1] + '-' + mode
    controller_log = store.open_file('controller.log', os.O_WRONLY | os.O_CREAT | os.O_EXCL)
    process = subprocess.Popen(frozen_command(['controller', str(path), str(store.descriptor),
                               str(lock_descriptor), token, str(fallback_inode)]),
                               stdin=subprocess.PIPE, stdout=controller_log, stderr=controller_log,
                               pass_fds=(store.descriptor, lock_descriptor))
    os.close(controller_log)
    guard_descriptor = None
    guard_identity = None
    try:
        guard_identity = wait_record(store, 'guard.json')
        guard_descriptor = os.pidfd_open(guard_identity['pid'])
        require(start_ticks(guard_identity['pid']) == guard_identity['start_ticks'], 'Guard PID reused')
        store.save('observer-guard.json', {'identity': guard_identity, 'pidfd_opened_before_arm': True})
        wait_record(store, 'ready.json', guard_descriptor)
        process.stdin.write(b'A')
        process.stdin.flush()
        wait_record(store, 'active.json', guard_descriptor)
        if mode == 'normal':
            process.stdin.write(b'R')
            process.stdin.flush()
        else:
            require(process.poll() is None, 'Controller already ended')
            process.kill()
        process.stdin.close()
        require(select.select([guard_descriptor], [], [], 35)[0], 'Guard still live; do not restart')
        exit_code = process.wait(timeout=3)
        expected_code = 0 if mode == 'normal' else -signal.SIGKILL
        require(exit_code == expected_code, 'Controller exit differs')
        terminal = store.load('terminal.json')
        require(terminal['success'] and terminal['reason'] ==
                ('release' if mode == 'normal' else 'controller_eof'), 'Restoration did not pass')
        final = snapshot()
        require(final['top_names'] == store.load('baseline.json')['top_names'], 'Independent readback differs')
        store.save('observer.json', {'utc': utc_now(), 'guard_pidfd_exit_observed': True,
                                    'controller_exit_code': exit_code, 'readback': final, 'success': True})
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


def run():
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    fallback_inode = root_gate()
    work_directory = work_descriptor()
    lock_descriptor = lock_root(work_directory)
    path = WORK_ROOT / ('core-partition-20261010-' + os.urandom(6).hex())
    check_work(work_directory)
    os.mkdir(path.name, mode=0o700, dir_fd=work_directory)
    store = Store(path)
    errors = []
    try:
        store.save('source.json', {'sha256': hashlib.sha256(SOURCE_TEXT.encode()).hexdigest(),
                                  'source': SOURCE_TEXT, 'utc': utc_now()})
        for mode in ('normal', 'parent-loss'):
            run_case(store, mode, lock_descriptor, fallback_inode)
    except Exception as error:
        errors.append(repr(error))
    store.save('run.json', {'success': not errors, 'errors': errors, 'utc': utc_now(),
                          'configuration_scope': 'owned_virtual_cgroups_only'})
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
            re.fullmatch(r'core-partition-20261010-[0-9a-f]{12}', store.path.parent.name),
            'Recovery path is not a known case')
    errors = []
    token = store.path.parent.name.rsplit('-', 1)[1] + '-' + store.path.name
    expected_names = ['a113part-' + token + suffix for suffix in ('-probe', '-guard')]
    try:
        for name in ('guard.json', 'controller.json'):
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
    print('selfcheck=pass; cpu_parser,cleanup_continuation,pipe_eof,wrong_inode,atomic_receipt,probe_gate,failure_reap,sigchld_reset; kernel_writes=none')


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--selfcheck':
        selfcheck(sys.argv[2])
    elif sys.argv[1:] == ['run']:
        raise SystemExit(run())
    elif len(sys.argv) == 7 and sys.argv[1] == 'controller':
        case_store = Store(sys.argv[2], int(sys.argv[3]))
        raise SystemExit(controller(case_store, int(sys.argv[4]), sys.argv[5], int(sys.argv[6])))
    elif len(sys.argv) == 3 and sys.argv[1] == 'recover':
        raise SystemExit(recover(sys.argv[2]))
    else:
        raise SystemExit('Use --selfcheck ABS_BUILD_ROOT, or a reviewed frozen root run/recover')
