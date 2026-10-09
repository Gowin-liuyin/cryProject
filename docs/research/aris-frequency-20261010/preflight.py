import datetime
import json
import os
from pathlib import Path
import shutil
import stat
import time


CPU_ROOT = Path('/sys/devices/system/cpu')
FIELDS = ('affected_cpus', 'related_cpus', 'scaling_driver', 'scaling_governor',
          'scaling_available_governors', 'scaling_min_freq', 'scaling_max_freq',
          'cpuinfo_min_freq', 'cpuinfo_max_freq', 'cpuinfo_cur_freq', 'cpuinfo_avg_freq',
          'scaling_cur_freq', 'scaling_available_frequencies', 'cpuinfo_transition_latency',
          'energy_performance_preference', 'energy_performance_available_preferences',
          'boost', 'bios_limit', 'base_frequency', 'amd_pstate_highest_perf',
          'amd_pstate_lowest_nonlinear_freq', 'amd_pstate_max_freq')


def read(path):
    try:
        metadata = path.stat()
        return {'value': path.read_text().strip(), 'owner_uid': metadata.st_uid,
                'mode': oct(stat.S_IMODE(metadata.st_mode))}
    except OSError as error:
        return {'error_type': type(error).__name__, 'errno': error.errno}


result = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'uname': list(os.uname()), 'effective_uid': os.geteuid(),
          'configuration_writes': 0, 'project_file_writes': 0,
          'cpu_online': read(CPU_ROOT / 'online'), 'policies': {},
          'cpu_links': {}, 'observation_interfaces': {}, 'thermal': {}}
for path in sorted((CPU_ROOT / 'cpufreq').glob('policy*')):
    result['policies'][path.name] = {name: read(path / name) for name in FIELDS}
for cpu_index in (2, 18):
    path = CPU_ROOT / f'cpu{cpu_index}'
    result['cpu_links'][str(cpu_index)] = {
        'cpufreq_realpath': str((path / 'cpufreq').resolve()),
        'thread_siblings': read(path / 'topology/thread_siblings_list'),
        'msr_device_present': Path(f'/dev/cpu/{cpu_index}/msr').exists()}
for relative in ('cpufreq/boost', 'amd_pstate/status', 'amd_pstate/prefcore'):
    result['observation_interfaces'][relative] = read(CPU_ROOT / relative)
for name in ('aperf', 'mperf', 'tsc'):
    result['observation_interfaces']['msr_event_' + name] = read(
        Path('/sys/bus/event_source/devices/msr/events') / name)
result['msr_module_present'] = Path('/sys/module/msr').exists()
result['perf_event_paranoid'] = read(Path('/proc/sys/kernel/perf_event_paranoid'))
result['clocksource'] = read(Path('/sys/devices/system/clocksource/clocksource0/current_clocksource'))
result['clocksource_available'] = read(Path('/sys/devices/system/clocksource/clocksource0/available_clocksource'))
result['reported_clock_resolution_seconds'] = time.clock_getres(time.CLOCK_MONOTONIC_RAW)
result['tools'] = {name: shutil.which(name) for name in ('perf', 'turbostat', 'cpupower')}
for path in sorted(Path('/sys/class/hwmon').glob('hwmon*')):
    if read(path / 'name').get('value') == 'k10temp':
        result['thermal'][path.name] = {file.name: read(file)
                                      for file in sorted(path.glob('temp*')) if file.is_file()}
print(json.dumps(result, indent=2))
