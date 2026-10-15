"""锁频采数的独立频率快照：32 个 policy 控制字段 + 全局 boost。"""
import pathlib

root = pathlib.Path('/sys/devices/system/cpu')
boost = root / 'cpufreq/boost'
print('global_boost=' + (boost.read_text().strip() if boost.exists() else 'absent'))
for policy in sorted(root.glob('cpufreq/policy*'), key=lambda p: int(p.name[6:])):
    values = []
    for field in ('scaling_governor', 'scaling_min_freq', 'scaling_max_freq',
                  'energy_performance_preference'):
        path = policy / field
        values.append(field + '=' + (path.read_text().strip() if path.exists() else 'absent'))
    print(policy.name + ' ' + ' '.join(values))
