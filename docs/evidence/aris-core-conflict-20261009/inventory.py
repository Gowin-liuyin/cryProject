import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path('/sys/fs/cgroup')
reserved = {2, 18}


def cpus(value):
    output = set()
    for section in value.strip().replace(' ', ',').split(','):
        if section:
            bounds = section.split('-')
            output.update(range(int(bounds[0]), int(bounds[-1]) + 1))
    return output


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError as error:
        return {'error_errno': error.errno}


online_before = read('/sys/devices/system/cpu/online')
top_before = sorted(entry.name for entry in root.iterdir() if entry.is_dir())
report = {
    'scope': 'read_only_core_conflict_inventory',
    'utc_started': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'settings_changed': False,
    'online_before': online_before,
    'reserved_cpus': [2, 18],
    'top_level_units_before': top_before,
    'top_level_units': [],
    'cgroup_count': 0,
    'descendant_requested_conflicts': [],
    'read_errors': [],
}
for unit in top_before:
    properties = ['Id', 'LoadState', 'ActiveState', 'ControlGroup', 'AllowedCPUs',
                  'EffectiveCPUs', 'Transient', 'FragmentPath', 'DropInPaths']
    command = ['systemctl', 'show', unit, '--no-pager']
    for name in properties:
        command.extend(['-p', name])
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        report['read_errors'].append({'unit': unit, 'stage': 'systemctl_show',
                                      'returncode': result.returncode})
    report['top_level_units'].append({
        'unit': unit, 'returncode': result.returncode,
        'properties': result.stdout.strip(), 'stderr': result.stderr.strip(),
        'subtree_control': read(root / unit / 'cgroup.subtree_control'),
        'cpuset_requested': read(root / unit / 'cpuset.cpus'),
        'cpuset_effective': read(root / unit / 'cpuset.cpus.effective'),
    })
def walk_error(error):
    report['read_errors'].append({'stage': 'enumerate_cgroups',
                                  'error_errno': error.errno})


for group, directories, files in os.walk(root, onerror=walk_error):
    directories.sort()
    report['cgroup_count'] += 1
    if 'cpuset.cpus' not in files:
        continue
    requested = read(Path(group) / 'cpuset.cpus')
    effective = read(Path(group) / 'cpuset.cpus.effective')
    if isinstance(requested, dict) or isinstance(effective, dict):
        report['read_errors'].append({
            'path': os.path.relpath(group, root),
            'requested': requested, 'effective': effective,
        })
    elif requested and not (cpus(requested) - reserved):
        report['descendant_requested_conflicts'].append({
            'cgroup': os.path.relpath(group, root),
            'requested': requested, 'effective': effective,
        })
report['root_subtree_control'] = read(root / 'cgroup.subtree_control')
report['ordinary_threads_checked'] = 0
report['kernel_threads_skipped'] = 0
report['vanished_threads'] = 0
report['affinity_conflicts'] = []
report['ordinary_threads_outside_top_units'] = []
for process in Path('/proc').iterdir():
    if not process.name.isdigit():
        continue
    try:
        tasks = list((process / 'task').iterdir())
    except FileNotFoundError:
        continue
    except OSError as error:
        report['read_errors'].append({
            'pid': int(process.name), 'stage': 'enumerate_threads',
            'error_errno': error.errno,
        })
        continue
    for task in tasks:
        try:
            fields = (task / 'stat').read_text().rsplit(')', 1)[1].split()
            if int(fields[6]) & 0x00200000:
                report['kernel_threads_skipped'] += 1
                continue
            affinity = set(os.sched_getaffinity(int(task.name)))
            groups = [line[3:] for line in (task / 'cgroup').read_text().splitlines()
                      if line.startswith('0::')]
            report['ordinary_threads_checked'] += 1
            if not affinity - reserved:
                report['affinity_conflicts'].append({
                    'tid': int(task.name), 'allowed_cpus': sorted(affinity),
                })
            if (len(groups) != 1 or groups[0] == '/' or
                    groups[0].split('/')[1] not in top_before):
                report['ordinary_threads_outside_top_units'].append({
                    'tid': int(task.name), 'cgroup': groups,
                })
        except (FileNotFoundError, ProcessLookupError):
            report['vanished_threads'] += 1
        except OSError as error:
            report['read_errors'].append({
                'tid': int(task.name), 'stage': 'thread_metadata',
                'error_errno': error.errno,
            })
report['frequency_feedback'] = {
    'perf_event_paranoid': read('/proc/sys/kernel/perf_event_paranoid'),
    'tools': {name: shutil.which(name) for name in ['turbostat', 'cpupower', 'perf']},
    'msr_cpu2_exists': Path('/dev/cpu/2/msr').exists(),
    'msr_cpu2_user_readable': os.access('/dev/cpu/2/msr', os.R_OK),
}
report['frequency_policies'] = []
for cpu in [2, 18]:
    policy = Path('/sys/devices/system/cpu/cpu' + str(cpu) + '/cpufreq')
    names = ['related_cpus', 'affected_cpus', 'scaling_driver', 'scaling_governor',
             'scaling_min_freq', 'scaling_max_freq', 'scaling_cur_freq',
             'cpuinfo_cur_freq', 'energy_performance_preference']
    report['frequency_policies'].append({
        'cpu': cpu, 'resolved_path': str(policy.resolve()),
        'fields': {name: read(policy / name) for name in names},
    })
report['online_after'] = read('/sys/devices/system/cpu/online')
report['top_level_units_after'] = sorted(entry.name for entry in root.iterdir() if entry.is_dir())
report['utc_finished'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
report['snapshot_conflicts_observed'] = bool(
    report['descendant_requested_conflicts'] or report['affinity_conflicts'] or
    report['ordinary_threads_outside_top_units'] or report['read_errors'] or
    report['online_before'] != report['online_after'] or
    report['top_level_units_before'] != report['top_level_units_after'])
report['reservation_applied'] = False
print(json.dumps(report, ensure_ascii=False, indent=2))
