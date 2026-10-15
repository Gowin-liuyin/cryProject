#!/usr/bin/env python3
"""仅在 CMake 构建目录内模拟 sysfs，不访问或修改主机频率。"""

import importlib.util
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from types import SimpleNamespace
from unittest import mock

specification = importlib.util.spec_from_file_location('platform_controller',
                                                       Path(__file__).with_name('controller.py'))
controller = importlib.util.module_from_spec(specification)
specification.loader.exec_module(controller)


class FakeFrequency:
    policy = 'policy2'

    def __init__(self):
        self.values = {'boost': '1', 'policy2/scaling_governor': 'powersave',
                       'policy2/scaling_min_freq': '2982259', 'policy2/scaling_max_freq': '5756452',
                       'policy2/energy_performance_preference': 'balance_performance',
                       'policy2/cpuinfo_min_freq': '545000', 'policy2/cpuinfo_max_freq': '5756452',
                       'policy6/scaling_governor': 'powersave'}
        self.write_count = 0
        self.fail_at = None
        self.writes = []

    def snapshot(self):
        return dict(self.values)

    def read(self, name):
        return self.values[name]

    def target_names(self):
        return ('boost',) + tuple(self.policy + '/' + field for field in controller.CONTROL_FIELDS)

    def write(self, name, value):
        self.write_count += 1
        self.values[name] = value
        self.writes.append((name, value))
        if self.write_count == self.fail_at:
            raise OSError('模拟写入已生效但系统调用报错')


class FailingStore(controller.Store):
    def write(self, name, value):
        if 'intent' in name or 'visible' in name or 'restored' in name:
            raise OSError('模拟日志空间不足')
        super().write(name, value)


def transaction(root, name):
    path = root / name
    path.mkdir()
    frequency = FakeFrequency()
    return frequency, controller.Transaction(frequency, controller.Store(path))


def qualification_commands(root):
    for run_name, (qualification, expected_command) in controller.QUALIFICATION_CASES.items():
        arguments = SimpleNamespace(run_name=run_name, qualification=None, command=list(expected_command))
        controller.prepare_worker_command(arguments)
        assert arguments.qualification == qualification
        assert arguments.command == expected_command
    arguments = SimpleNamespace(run_name='q-normal', qualification='normal', command=[])
    controller.prepare_worker_command(arguments)
    assert arguments.command == ['/usr/bin/true']
    rejected = [
        ('q-normal', None, ['/usr/bin/false']),
        ('q-normal', None, ['/usr/bin/true', 'extra']),
        ('q-normal', None, ['/bin/true']),
        ('q-normal', 'failure', ['/usr/bin/true']),
        ('q-controller-loss', None, ['/usr/bin/sleep', '21']),
        ('q-timeout', None, ['/usr/bin/sleep', '20', 'extra']),
        ('q-not-frozen', None, ['/usr/bin/true']),
        ('m2-production', 'normal', ['/usr/bin/true']),
        ('m2-production', None, ['/usr/bin/true']),
    ]
    for run_name, qualification, command in rejected:
        arguments = SimpleNamespace(run_name=run_name, qualification=qualification, command=command)
        try:
            controller.prepare_worker_command(arguments)
            raise AssertionError('接受了白名单外命令：' + repr(arguments))
        except RuntimeError:
            pass

    controller_path = Path(__file__).with_name('controller.py')
    cli_cases = [('q-normal', ['/usr/bin/false'], '资格命令与冻结白名单不符'),
                 ('q-timeout', ['/usr/bin/sleep', '21'], '资格命令与冻结白名单不符'),
                 ('m2-production', ['/usr/bin/true'], '项目路径超出 Cry'),
                 ('q-not-frozen', ['/usr/bin/true'], '项目路径超出 Cry')]
    for run_name, command, expected_error in cli_cases:
        result = subprocess.run([sys.executable, '-I', '-B', str(controller_path), 'run',
                                 '--control-root', '/unused', '--run-name', run_name, '--cpu', '2',
                                 '--timeout-seconds', '3', '--plan', '/unused/PLAN.md',
                                 '--plan-sha256', '0' * 64, '--'] + command,
                                capture_output=True, text=True, check=False)
        assert result.returncode == 1 and expected_error in result.stderr
    with mock.patch.object(controller, 'run', return_value=0) as run_entry:
        with mock.patch.object(sys, 'argv', ['controller.py', 'run', '--control-root', '/unused',
                                             '--run-name', 'q-controller-loss', '--cpu', '6',
                                             '--timeout-seconds', '5', '--plan', '/unused/PLAN.md',
                                             '--plan-sha256', '0' * 64, '--', '/usr/bin/sleep', '20']):
            assert controller.main() == 0
        assert run_entry.call_args.args[0].qualification == 'controller-loss'
    collector = root / 'collector'
    collector.write_bytes(b'fixture-only-not-executed\n')
    collector.chmod(0o700)
    with mock.patch.object(controller, 'CRY_ROOT', root.resolve()):
        arguments = SimpleNamespace(run_name='m2-production', qualification=None,
                                    command=[str(collector), 'samples.csv'])
        controller.prepare_worker_command(arguments)
        assert arguments.command == [str(collector), 'samples.csv']


def main():
    root = Path(sys.argv[1]) / ('mock-' + os.urandom(6).hex())
    root.mkdir(parents=True)
    qualification_commands(root)
    frequency, operation = transaction(root, 'normal')
    original = frequency.snapshot()
    operation.apply(lambda: None)
    operation.assert_active()
    assert operation.restore()
    assert frequency.snapshot() == original

    frequency, operation = transaction(root, 'partial-write')
    original = frequency.snapshot()
    frequency.fail_at = 2
    try:
        operation.apply(lambda: None)
        raise AssertionError('未拒绝部分写失败')
    except OSError:
        pass
    assert operation.is_dirty
    assert operation.restore()
    assert frequency.snapshot() == original

    frequency, operation = transaction(root, 'restore-one-failure')
    operation.apply(lambda: None)
    frequency.fail_at = frequency.write_count + 1
    assert not operation.restore()
    assert frequency.values['policy2/scaling_governor'] == 'powersave'
    assert frequency.values['policy2/scaling_min_freq'] == '2982259'
    assert frequency.values['policy2/scaling_max_freq'] == '5756452'
    assert frequency.values['policy2/energy_performance_preference'] == 'balance_performance'

    frequency, operation = transaction(root, 'unknown-state')
    operation.apply(lambda: None)
    frequency.values['policy2/scaling_governor'] = 'external-controller'
    assert not operation.restore()
    assert frequency.values['policy2/scaling_governor'] == 'external-controller'
    assert frequency.values['boost'] == '1'

    frequency, operation = transaction(root, 'restore-initial-read-failure')
    operation.apply(lambda: None)
    original_read = frequency.read
    failed_reads = []

    def fail_once(name):
        if name == 'policy2/scaling_max_freq' and not failed_reads:
            failed_reads.append(name)
            raise OSError('模拟恢复顺序读取失败')
        return original_read(name)

    frequency.read = fail_once
    assert not operation.restore()
    assert frequency.values['boost'] == '1'
    assert frequency.values['policy2/scaling_governor'] == 'powersave'
    assert frequency.values['policy2/energy_performance_preference'] == 'balance_performance'

    frequency, operation = transaction(root, 'log-full')
    original = frequency.snapshot()
    operation.apply(lambda: None)
    operation.store = FailingStore(operation.store.path)
    assert not operation.restore()
    assert frequency.snapshot() == original
    assert operation.errors

    frequency, operation = transaction(root, 'preflight-cancel')
    try:
        operation.apply(lambda: controller.require(False, 'controller_lost'))
        raise AssertionError('未拒绝寿命取消')
    except RuntimeError:
        pass
    assert not operation.is_dirty and frequency.write_count == 0

    writer_path = root / 'immutable.json'
    store = controller.Store(root)
    store.write(writer_path.name, {'original': True})
    try:
        store.write(writer_path.name, {'overwritten': True})
        raise AssertionError('覆盖了原始证据')
    except FileExistsError:
        pass

    original_handler = signal.getsignal(signal.SIGCHLD)
    signal.signal(signal.SIGCHLD, signal.SIG_IGN)
    controller.reset_child_reaping()
    child = subprocess.Popen([sys.executable, '-I', '-B', '-c', 'import time; time.sleep(20)'],
                             start_new_session=True)
    try:
        time.sleep(0.05)
        os.killpg(child.pid, signal.SIGTERM)
        assert child.wait(timeout=2) == -signal.SIGTERM
    finally:
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait()
        signal.signal(signal.SIGCHLD, original_handler)

    print('mock_checks=9; qualification_allowed=6; qualification_rejected=9; cli_rejected=4; '
          'production_allowed=1; '
          'host_frequency_writes=0; native_guardian_qualification=not_run')
    return 0


if __name__ == '__main__':
    sys.exit(main())
