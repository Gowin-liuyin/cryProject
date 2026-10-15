#!/usr/bin/env python3
"""只负责频率管理、进程回收和证据，不实现计时或统计。"""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import resource
import select
import signal
import shutil
import stat
import subprocess
import sys
import time

CRY_ROOT = Path('/home/nss-marker/yhr/Cry')
CPU_ROOT = Path('/sys/devices/system/cpu')
STATE_ROOT = CRY_ROOT / 'platform-control-20261016-state'
TARGET_KHZ = '4300000'
CONTROL_FIELDS = ('scaling_governor', 'scaling_min_freq', 'scaling_max_freq',
                  'energy_performance_preference')
IDENTITY_FIELDS = ('affected_cpus', 'related_cpus', 'scaling_driver',
                   'cpuinfo_min_freq', 'cpuinfo_max_freq', 'scaling_available_governors')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def reset_child_reaping():
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)


def contained(path):
    absolute = Path(path).absolute()
    require(absolute == absolute.resolve(), '路径含符号链接或非规范分量')
    require(absolute.is_relative_to(CRY_ROOT), '项目路径超出 Cry')
    return absolute


class Store:
    def __init__(self, path):
        self.path = Path(path)
        self.descriptor = os.open(self.path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        self.identity = os.fstat(self.descriptor)

    def check_identity(self):
        current = self.path.stat(follow_symlinks=False)
        require((current.st_dev, current.st_ino, current.st_uid, current.st_mode) ==
                (self.identity.st_dev, self.identity.st_ino, self.identity.st_uid, self.identity.st_mode),
                '证据目录身份变化')

    def write(self, name, value):
        self.check_identity()
        require(re.fullmatch(r'[A-Za-z0-9_.-]+', name), '非法证据文件名')
        descriptor = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                             0o640, dir_fd=self.descriptor)
        try:
            contents = json.dumps(value, sort_keys=True, indent=2).encode() + b'\n'
            with os.fdopen(descriptor, 'wb', closefd=False) as stream:
                stream.write(contents)
                stream.flush()
                os.fsync(stream.fileno())
        finally:
            os.close(descriptor)
        os.fsync(self.descriptor)


def read_receipt(store, name):
    store.check_identity()
    descriptor = os.open(name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=store.descriptor)
    try:
        metadata = os.fstat(descriptor)
        require(stat.S_ISREG(metadata.st_mode) and metadata.st_uid == 0 and
                metadata.st_mode & 0o022 == 0, '恢复文件所有者或权限不符')
        contents = os.read(descriptor, 1024 * 1024)
        require(len(contents) < 1024 * 1024, '恢复文件过长')
        return contents
    finally:
        os.close(descriptor)


def state_gate():
    if not STATE_ROOT.exists():
        STATE_ROOT.mkdir(mode=0o700)
    require(STATE_ROOT == STATE_ROOT.resolve(), '状态根含符号链接')
    metadata = STATE_ROOT.stat(follow_symlinks=False)
    require(metadata.st_uid == 0 and stat.S_ISDIR(metadata.st_mode) and
            stat.S_IMODE(metadata.st_mode) == 0o700, '状态根身份不符')
    return Store(STATE_ROOT)


def clear_gate(gate, run_path):
    if (gate.path / 'active.json').exists():
        active = json.loads(read_receipt(gate, 'active.json'))
        require(active['run_path'] == str(run_path), '活动指针不属于本次运行')
        os.unlink('active.json', dir_fd=gate.descriptor)
        os.fsync(gate.descriptor)


class Frequency:
    def __init__(self, cpu, cpu_root=CPU_ROOT):
        self.cpu_root = Path(cpu_root)
        self.root = self.cpu_root / 'cpufreq'
        self.cpu = cpu
        self.policy = (self.cpu_root / ('cpu' + str(cpu)) / 'cpufreq').resolve().name
        require(re.fullmatch(r'policy[0-9]+', self.policy), 'CPU policy 映射不明')
        require((self.root / self.policy / 'related_cpus').read_text().strip() == str(cpu),
                '当前合同仅接受 singleton CPU policy')
        self.paths = {'boost': self.root / 'boost'}
        for policy_path in sorted(self.root.glob('policy[0-9]*')):
            for field in CONTROL_FIELDS + IDENTITY_FIELDS + ('boost',):
                path = policy_path / field
                if path.is_file():
                    self.paths[policy_path.name + '/' + field] = path
        for field in ('status', 'prefcore'):
            path = self.cpu_root / 'amd_pstate' / field
            if path.is_file():
                self.paths['amd_pstate/' + field] = path
        self.identities = {}
        for name, path in self.paths.items():
            metadata = path.stat(follow_symlinks=False)
            require(stat.S_ISREG(metadata.st_mode), '频率属性类型不符')
            self.identities[name] = (metadata.st_dev, metadata.st_ino, metadata.st_uid)

    def read(self, name):
        path = self.paths[name]
        descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
        try:
            metadata = os.fstat(descriptor)
            require((metadata.st_dev, metadata.st_ino, metadata.st_uid) == self.identities[name],
                    '频率属性身份变化')
            contents = os.read(descriptor, 4096)
            require(len(contents) < 4096, '频率属性过长')
            return contents.decode().strip()
        finally:
            os.close(descriptor)

    def snapshot(self):
        return {name: self.read(name) for name in sorted(self.paths)}

    def write(self, name, value):
        self.read(name)
        descriptor = os.open(self.paths[name], os.O_WRONLY | os.O_NOFOLLOW)
        try:
            metadata = os.fstat(descriptor)
            require((metadata.st_dev, metadata.st_ino, metadata.st_uid) == self.identities[name],
                    '频率写入属性身份变化')
            require(os.write(descriptor, (value + '\n').encode()) == len(value) + 1,
                    '频率写入不完整')
        finally:
            os.close(descriptor)

    def sample(self):
        path = self.root / self.policy / 'scaling_cur_freq'
        return {'monotonic_ns': time.monotonic_ns(), 'cur_khz': int(path.read_text().strip()),
                'controls': {name: self.read(name) for name in self.target_names()}}

    def target_names(self):
        return ('boost',) + tuple(self.policy + '/' + field for field in CONTROL_FIELDS)


class Transaction:
    def __init__(self, frequency, store):
        self.frequency = frequency
        self.store = store
        self.baseline = frequency.snapshot()
        require(all(name in self.baseline for name in frequency.target_names()), '缺少目标控制字段')
        self.sequence = 0
        self.errors = []
        self.is_dirty = False
        self.desired = {'boost': '0', frequency.policy + '/scaling_governor': 'performance',
                        frequency.policy + '/energy_performance_preference': 'performance',
                        frequency.policy + '/scaling_min_freq': TARGET_KHZ,
                        frequency.policy + '/scaling_max_freq': TARGET_KHZ}

    def record(self, suffix, value, restoring=False):
        name = str(self.sequence).zfill(4) + '-' + suffix + '.json'
        self.sequence += 1
        try:
            self.store.write(name, value)
        except OSError as error:
            if not restoring:
                raise
            self.errors.append('恢复记录失败：' + repr(error))

    def change(self, name, value, restoring=False):
        current = self.frequency.read(name)
        require(current in (self.baseline[name], self.desired[name]), '未知并发配置，拒绝覆盖：' + name)
        self.record('intent', {'name': name, 'before': current, 'requested': value,
                               'restoring': restoring}, restoring)
        if not restoring:
            self.is_dirty = True
        self.frequency.write(name, value)
        deadline = time.monotonic() + 1.0
        while self.frequency.read(name) != value:
            require(time.monotonic() < deadline, '频率写入回读超时：' + name)
            time.sleep(0.01)
        self.record('visible', {'name': name, 'value': value, 'restoring': restoring}, restoring)

    def limits(self, minimum, maximum, restoring=False):
        prefix = self.frequency.policy + '/'
        current_maximum = int(self.frequency.read(prefix + 'scaling_max_freq'))
        order = (('scaling_min_freq', minimum), ('scaling_max_freq', maximum))
        if int(minimum) > current_maximum:
            order = tuple(reversed(order))
        for field, value in order:
            self.change(prefix + field, value, restoring)

    def apply(self, check_cancel):
        prefix = self.frequency.policy + '/'
        require(int(self.baseline[prefix + 'cpuinfo_min_freq']) <= int(TARGET_KHZ) <=
                int(self.baseline[prefix + 'cpuinfo_max_freq']), '目标频率超出硬件声明范围')
        for name in ('boost', prefix + 'scaling_governor', prefix + 'energy_performance_preference'):
            check_cancel()
            self.change(name, self.desired[name])
        check_cancel()
        self.limits(TARGET_KHZ, TARGET_KHZ)
        self.assert_active()

    def assert_active(self):
        for name, value in self.desired.items():
            require(self.frequency.read(name) == value, '活动配置漂移：' + name)

    def restore(self):
        prefix = self.frequency.policy + '/'
        minimum = self.baseline[prefix + 'scaling_min_freq']
        maximum = self.baseline[prefix + 'scaling_max_freq']
        limit_order = [('scaling_min_freq', minimum), ('scaling_max_freq', maximum)]
        try:
            if int(minimum) > int(self.frequency.read(prefix + 'scaling_max_freq')):
                limit_order.reverse()
        except Exception as error:
            self.errors.append('恢复顺序读回失败：' + repr(error))
        operations = [lambda: self.change('boost', self.baseline['boost'], True),
                      lambda: self.change(prefix + 'scaling_governor',
                                          self.baseline[prefix + 'scaling_governor'], True)]
        operations += [lambda field=field, value=value: self.change(prefix + field, value, True)
                       for field, value in limit_order]
        operations.append(lambda: self.change(prefix + 'energy_performance_preference',
                                               self.baseline[prefix + 'energy_performance_preference'], True))
        for operation in operations:
            try:
                operation()
            except Exception as error:
                self.errors.append(repr(error))
        after = self.frequency.snapshot()
        self.record('restored', after, True)
        return after == self.baseline and not self.errors


def start_ticks(process_id):
    fields = Path('/proc/' + str(process_id) + '/stat').read_text().rsplit(')', 1)[1].split()
    return int(fields[19])


def group_members(process_group):
    members = []
    for path in Path('/proc').glob('[0-9]*/stat'):
        try:
            fields = path.read_text().rsplit(')', 1)[1].split()
            if int(fields[2]) == process_group and fields[0] != 'Z':
                members.append(int(path.parent.name))
        except (FileNotFoundError, ProcessLookupError):
            continue
    return members


def worker_identity(worker, expected_uid, expected_cpu):
    deadline = time.monotonic() + 2.0
    while True:
        values = {}
        for line in Path('/proc/' + str(worker.pid) + '/status').read_text().splitlines():
            if ':' in line:
                name, value = line.split(':', 1)
                values[name] = value.strip()
        require(all(int(value) == expected_uid for value in values['Uid'].split()), 'worker 未实际降权')
        if values['Cpus_allowed_list'] == str(expected_cpu):
            break
        require(time.monotonic() < deadline, 'worker 实际亲和性不符')
        time.sleep(0.01)
    return {'pid': worker.pid, 'start_ticks': start_ticks(worker.pid), 'pgid': os.getpgid(worker.pid),
            'sid': os.getsid(worker.pid), 'uid': expected_uid,
            'cpus_allowed_list': values['Cpus_allowed_list']}


def drain_worker(worker):
    # leader 保持未回收，避免 PID/进程组号复用后误杀。
    for termination_signal in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(worker.pid, termination_signal)
        except ProcessLookupError:
            pass
        deadline = time.monotonic() + 2.0
        while group_members(worker.pid) and time.monotonic() < deadline:
            time.sleep(0.02)
    remaining = group_members(worker.pid)
    require(not remaining, 'worker 进程组未排空：' + repr(remaining))
    return worker.wait(timeout=2.0)


def guardian(arguments, run_path, store, gate, lifetime_reader, ready_writer, worker_uid, worker_gid):
    reset_child_reaping()
    os.setsid()
    housekeeping_cpus = os.sched_getaffinity(0) - {2, 6}
    require(housekeeping_cpus, '无可用管理 CPU')
    os.sched_setaffinity(0, housekeeping_cpus)
    cancelled = []
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    signal.signal(signal.SIGPIPE, signal.SIG_IGN)
    for cancellation_signal in (signal.SIGTERM, signal.SIGINT):
        signal.signal(cancellation_signal, lambda number, frame: cancelled.append(number))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    worker = None
    transaction = None
    samples = []
    result = {'reason': 'preflight_failed', 'restore_match': 'not_required', 'worker_drained': True}
    try:
        store.write('guardian.json', {'pid': os.getpid(), 'start_ticks': start_ticks(os.getpid()),
                                      'cpus_allowed': sorted(os.sched_getaffinity(0)),
                                      'cgroup': Path('/proc/self/cgroup').read_text()})
        frequency = Frequency(arguments.cpu)
        transaction = Transaction(frequency, store)
        require(shutil.disk_usage(run_path).free >= 1024 * 1024 * 1024, '不足 1GiB 可用空间')
        store.write('baseline.json', transaction.baseline)
        store.write('baseline-identities.json', frequency.identities)
        store.write('baseline.sha256.json', sha256(run_path / 'baseline.json'))
        store.write('command.json', {'command': arguments.command, 'cpu': arguments.cpu,
                                    'plan_sha256': arguments.plan_sha256,
                                    'source_sha256': sha256(__file__), 'worker_uid': worker_uid,
                                    'worker_gid': worker_gid, 'policy': frequency.policy,
                                    'worker_sha256': sha256(arguments.command[0]),
                                    'boot_id': Path('/proc/sys/kernel/random/boot_id').read_text().strip(),
                                    'uname': tuple(os.uname())})

        def check_cancel():
            require(not cancelled, 'guardian_signal')
            if select.select([lifetime_reader], [], [], 0)[0]:
                require(os.read(lifetime_reader, 1) != b'', 'controller_lost')

        gate.write('active.json', {'run_path': str(run_path),
                                   'baseline_sha256': sha256(run_path / 'baseline.json')})
        transaction.apply(check_cancel)
        probes = []
        for probe_index in range(20):
            check_cancel()
            transaction.assert_active()
            probes.append(frequency.sample())
            time.sleep(0.05)
        store.write('entry-probes.json', probes)
        observed = [probe['cur_khz'] for probe in probes]
        require(all(4214000 <= value <= 4386000 for value in observed) and
                max(observed) - min(observed) <= 50000, 'frequency_probe_rejected')
        store.write('active.json', frequency.snapshot())
        worker_path = run_path / 'worker'
        worker_path.mkdir(mode=0o700)
        os.chown(worker_path, worker_uid, worker_gid)
        for name in ('tmp', 'cache'):
            path = worker_path / name
            path.mkdir(mode=0o700)
            os.chown(path, worker_uid, worker_gid)
        environment = dict(os.environ)
        environment.update({'TMPDIR': str(worker_path / 'tmp'), 'TMP': str(worker_path / 'tmp'),
                            'TEMP': str(worker_path / 'tmp'), 'XDG_CACHE_HOME': str(worker_path / 'cache')})
        stdout_descriptor = os.open('worker.stdout', os.O_CREAT | os.O_EXCL | os.O_WRONLY,
                                    0o640, dir_fd=store.descriptor)
        stderr_descriptor = os.open('worker.stderr', os.O_CREAT | os.O_EXCL | os.O_WRONLY,
                                    0o640, dir_fd=store.descriptor)
        try:
            check_cancel()
            store.write('worker-spawn-intent.json', {'cpu': arguments.cpu, 'worker_uid': worker_uid})
            worker = subprocess.Popen(['/usr/bin/taskset', '-c', str(arguments.cpu)] + arguments.command,
                                      stdin=subprocess.DEVNULL, stdout=stdout_descriptor,
                                      stderr=stderr_descriptor, cwd=worker_path, env=environment,
                                      start_new_session=True, close_fds=True, user=worker_uid,
                                      group=worker_gid, extra_groups=[])
        finally:
            os.close(stdout_descriptor)
            os.close(stderr_descriptor)
        store.write('worker.json', worker_identity(worker, worker_uid, arguments.cpu))
        os.write(ready_writer, b'1')
        deadline = time.monotonic() + arguments.timeout_seconds
        while True:
            check_cancel()
            transaction.assert_active()
            samples.append(frequency.sample())
            status = os.waitid(os.P_PID, worker.pid, os.WEXITED | os.WNOHANG | os.WNOWAIT)
            if status is not None:
                result['reason'] = 'worker_finished'
                break
            require(time.monotonic() < deadline, 'worker_timeout')
            time.sleep(0.05)
    except Exception as error:
        result['reason'] = str(error)
    finally:
        if worker is not None:
            try:
                result['worker_exit_code'] = drain_worker(worker)
            except Exception as error:
                result['worker_drained'] = False
                result['drain_error'] = repr(error)
        if transaction is not None and transaction.is_dirty:
            try:
                result['restore_match'] = 'yes' if transaction.restore() else 'no'
            except Exception as error:
                result['restore_match'] = 'no'
                transaction.errors.append(repr(error))
            result['restoration_errors'] = transaction.errors
        try:
            store.write('during.json', samples)
        except OSError as error:
            result['during_record_error'] = repr(error)
        store.write('terminal.json', result)
        if result['worker_drained'] and result['restore_match'] in ('yes', 'not_required'):
            clear_gate(gate, run_path)
    return 0 if (result['reason'] == 'worker_finished' and result.get('worker_exit_code') == 0 and
                 result['restore_match'] == 'yes' and result['worker_drained']) else 1


def run(arguments):
    require(sys.platform == 'linux' and os.geteuid() == 0, 'run 仅限 Linux root 管理入口')
    require(os.uname().machine == 'x86_64', '真实采集主机须为 x86_64')
    worker_uid = int(os.environ.get('SUDO_UID', '0'))
    require(worker_uid != 0, '必须由 sudo 原用户启动，禁止 root worker')
    worker_gid = pwd.getpwuid(worker_uid).pw_gid
    reset_child_reaping()
    control_root = contained(arguments.control_root)
    require(re.fullmatch(r'platform-control-20261016-[0-9a-f]{12}', control_root.name), '控制根名称不符')
    require(control_root.is_dir(), '先创建并上传独立控制根')
    plan = contained(arguments.plan)
    require(sha256(plan) == arguments.plan_sha256, '冻结 PLAN 摘要不符')
    require(re.fullmatch(r'[a-z0-9][a-z0-9-]{0,63}', arguments.run_name), '运行名不符')
    require(arguments.command or arguments.qualification, '缺少 worker 命令')
    if arguments.qualification:
        commands = {'normal': ['/usr/bin/true'], 'failure': ['/usr/bin/false'],
                    'timeout': ['/usr/bin/sleep', '20'], 'controller-loss': ['/usr/bin/sleep', '20']}
        arguments.command = commands[arguments.qualification]
    else:
        executable = contained(arguments.command[0])
        require(executable.is_file() and os.access(executable, os.X_OK), 'worker ELF 不可执行')
        for argument in arguments.command[1:]:
            require('..' not in Path(argument).parts, 'worker 参数含上级路径')
            if argument.startswith('/'):
                contained(argument)
    lock_descriptor = os.open(control_root / 'collection.lock',
                              os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    lock_metadata = os.fstat(lock_descriptor)
    require(lock_metadata.st_uid == 0 and stat.S_ISREG(lock_metadata.st_mode) and
            stat.S_IMODE(lock_metadata.st_mode) == 0o600, '控制锁身份不符')
    fcntl.flock(lock_descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
    common_lock = os.open(CRY_ROOT / 'partition-admin.lock', os.O_RDONLY | os.O_NOFOLLOW)
    common_metadata = os.fstat(common_lock)
    require(common_metadata.st_uid == 0 and stat.S_ISREG(common_metadata.st_mode) and
            stat.S_IMODE(common_metadata.st_mode) == 0o600, '全局既有锁身份不符')
    fcntl.flock(common_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    gate = state_gate()
    require(not (gate.path / 'active.json').exists(), '存在未签收恢复，禁止新运行；先核对并 recover')
    runs_path = control_root / 'runs'
    if not runs_path.exists():
        runs_path.mkdir(mode=0o750)
        os.chown(runs_path, 0, worker_gid)
        os.chmod(runs_path, 0o2750)
    require(not runs_path.is_symlink() and runs_path.stat().st_uid == 0 and
            runs_path.stat().st_mode & 0o022 == 0, 'runs 目录身份不符')
    run_path = runs_path / arguments.run_name
    run_path.mkdir(mode=0o750)
    os.chown(run_path, 0, worker_gid)
    os.chmod(run_path, 0o2750)
    store = Store(run_path)
    lifetime_reader, lifetime_writer = os.pipe()
    ready_reader, ready_writer = os.pipe()
    for descriptor in (lifetime_reader, lifetime_writer, ready_reader, ready_writer):
        os.set_inheritable(descriptor, False)
    process_id = os.fork()
    if process_id == 0:
        os.close(lifetime_writer)
        os.close(ready_reader)
        try:
            status = guardian(arguments, run_path, store, gate, lifetime_reader, ready_writer,
                              worker_uid, worker_gid)
        except BaseException:
            status = 1
        os._exit(status)
    os.close(lock_descriptor)
    os.close(common_lock)
    os.close(store.descriptor)
    os.close(gate.descriptor)
    os.close(lifetime_reader)
    os.close(ready_writer)
    writer_open = True

    def cancel(number, frame):
        nonlocal writer_open
        if writer_open:
            os.close(lifetime_writer)
            writer_open = False

    for cancellation_signal in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(cancellation_signal, cancel)
    try:
        if arguments.qualification == 'controller-loss':
            require(os.read(ready_reader, 1) == b'1', '未进入 controller-loss 资格状态')
            os.kill(os.getpid(), signal.SIGKILL)
        status = os.waitpid(process_id, 0)[1]
        return os.waitstatus_to_exitcode(status)
    finally:
        cancel(None, None)
        os.close(ready_reader)


def recover(arguments):
    require(sys.platform == 'linux' and os.geteuid() == 0, 'recover 仅限 Linux root')
    control_root = contained(arguments.control_root)
    require(re.fullmatch(r'platform-control-20261016-[0-9a-f]{12}', control_root.name), '控制根名称不符')
    require(re.fullmatch(r'[a-z0-9][a-z0-9-]{0,63}', arguments.run_name), '运行名不符')
    run_path = contained(control_root / 'runs' / arguments.run_name)
    require(run_path.stat().st_uid == 0 and run_path.stat().st_mode & 0o022 == 0,
            '恢复目录所有者或权限不符')
    store = Store(run_path)
    lock_descriptor = os.open(control_root / 'collection.lock', os.O_RDONLY | os.O_NOFOLLOW)
    lock_metadata = os.fstat(lock_descriptor)
    require(lock_metadata.st_uid == 0 and stat.S_ISREG(lock_metadata.st_mode) and
            stat.S_IMODE(lock_metadata.st_mode) == 0o600, '控制锁身份不符')
    fcntl.flock(lock_descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
    common_lock = os.open(CRY_ROOT / 'partition-admin.lock', os.O_RDONLY | os.O_NOFOLLOW)
    common_metadata = os.fstat(common_lock)
    require(common_metadata.st_uid == 0 and stat.S_ISREG(common_metadata.st_mode) and
            stat.S_IMODE(common_metadata.st_mode) == 0o600, '全局既有锁身份不符')
    fcntl.flock(common_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    gate = state_gate()
    active = json.loads(read_receipt(gate, 'active.json'))
    require(active['run_path'] == str(run_path), '该运行不是全局待恢复运行')
    guardian_identity = json.loads(read_receipt(store, 'guardian.json'))
    try:
        require(start_ticks(guardian_identity['pid']) != guardian_identity['start_ticks'], 'guardian 仍存在')
    except FileNotFoundError:
        pass
    require(not (run_path / 'worker-spawn-intent.json').exists() or
            (run_path / 'worker.json').exists(), 'worker 创建可能发生但身份未登记，停止并人工核对')
    if (run_path / 'worker.json').exists():
        worker = json.loads(read_receipt(store, 'worker.json'))
        require(not group_members(worker['pgid']), '仍有 worker 组成员，停止并人工核对')
    baseline_contents = read_receipt(store, 'baseline.json')
    require(hashlib.sha256(baseline_contents).hexdigest() ==
            json.loads(read_receipt(store, 'baseline.sha256.json')), '恢复原快照摘要不符')
    require(hashlib.sha256(baseline_contents).hexdigest() == active['baseline_sha256'],
            '活动指针绑定的原快照不符')
    command = json.loads(read_receipt(store, 'command.json'))
    require(Path('/proc/sys/kernel/random/boot_id').read_text().strip() == command['boot_id'],
            'boot_id 已变化，停止自动恢复')
    recovery_path = run_path / ('recovery-' + os.urandom(6).hex())
    recovery_path.mkdir(mode=0o750)
    os.chown(recovery_path, 0, command['worker_gid'])
    os.chmod(recovery_path, 0o2750)
    frequency = Frequency(command['cpu'])
    require(frequency.policy == command['policy'], 'CPU policy 映射变化')
    require({name: list(value) for name, value in frequency.identities.items()} ==
            json.loads(read_receipt(store, 'baseline-identities.json')), '原 sysfs 属性身份变化')
    transaction = Transaction(frequency, Store(recovery_path))
    transaction.baseline = json.loads(baseline_contents)
    matched = transaction.restore()
    transaction.store.write('terminal.json', {'restore_match': 'yes' if matched else 'no',
                                              'errors': transaction.errors})
    if matched:
        clear_gate(gate, run_path)
    return 0 if matched else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='mode', required=True)
    run_parser = commands.add_parser('run')
    run_parser.add_argument('--control-root', required=True)
    run_parser.add_argument('--run-name', required=True)
    run_parser.add_argument('--cpu', type=int, choices=(2, 6), required=True)
    run_parser.add_argument('--timeout-seconds', type=int, choices=range(1, 1801), required=True)
    run_parser.add_argument('--plan', required=True)
    run_parser.add_argument('--plan-sha256', required=True)
    run_parser.add_argument('--qualification', choices=('normal', 'failure', 'timeout', 'controller-loss'))
    run_parser.add_argument('command', nargs=argparse.REMAINDER)
    recovery_parser = commands.add_parser('recover')
    recovery_parser.add_argument('--control-root', required=True)
    recovery_parser.add_argument('--run-name', required=True)
    arguments = parser.parse_args()
    if arguments.mode == 'run' and arguments.command and arguments.command[0] == '--':
        arguments.command = arguments.command[1:]
    try:
        return run(arguments) if arguments.mode == 'run' else recover(arguments)
    except Exception as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
