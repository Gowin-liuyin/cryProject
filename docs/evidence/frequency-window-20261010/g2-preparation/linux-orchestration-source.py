from pathlib import Path, PurePosixPath
import datetime, hashlib, io, json, os, platform, subprocess, tarfile, time

project = Path('/home/nss-marker/yhr/Cry')
root = project / 'window-management-0ba4cd7'
assert Path.cwd() == project and root.resolve() == root and os.geteuid() != 0
assert os.uname().nodename == 'nss-m' and os.uname().machine == 'x86_64'
data = (root / 'source-0ba4cd7.tar').read_bytes()
assert hashlib.sha256(data).hexdigest() == 'afdca56c93b9ce70ce4b9b32b47e4ad7ff321ab6d3b4683e6904ced99e4cc948'
with tarfile.open(fileobj=io.BytesIO(data)) as archive:
    members = archive.getmembers()
    assert len(members) < 32 and sum(member.size for member in members) < 1024 * 1024
    assert len({member.name for member in members}) == len(members)
    for member in members:
        name = PurePosixPath(member.name)
        assert not name.is_absolute() and '..' not in name.parts and name.parts[0] == 'source'
        assert member.isdir() or member.isfile()
    for member in members:
        target = root / member.name
        if member.isdir():
            target.mkdir(mode=0o700)
        else:
            with target.open('xb') as output:
                output.write(archive.extractfile(member).read())
guard_source = root / 'source/docs/research/aris-core-partition-20261010'
analysis_source = root / 'source/docs/research/aris-frequency-window-analysis-20261010'
assert hashlib.sha256((guard_source / 'rehearse_partition.py').read_bytes()).hexdigest() == '8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4'
assert hashlib.sha256((analysis_source / 'analyze_windows.c').read_bytes()).hexdigest() == '5c028abf419df5b5459c167469f44724faba12542b446799c5c5fc6b02d5a9f4'
for name in ('tmp', 'cache'):
    (root / name).mkdir(mode=0o700)
environment = os.environ.copy()
environment.update({'TMPDIR': str(root / 'tmp'), 'TMP': str(root / 'tmp'),
                    'TEMP': str(root / 'tmp'), 'XDG_CACHE_HOME': str(root / 'cache'),
                    'CCACHE_DIR': str(root / 'cache'), 'PYTHONDONTWRITEBYTECODE': '1',
                    'LC_ALL': 'C'})
guard_build = root / 'guard-check'
steps = [('guard-configure', ['/usr/bin/cmake', '-S', str(guard_source), '-B', str(guard_build),
                            '-DPython3_EXECUTABLE=/usr/bin/python3']),
         ('guard-test', ['/usr/bin/ctest', '--test-dir', str(guard_build), '--output-on-failure'])]
for config, sanitizers in (('normal', 'OFF'), ('sanitize', 'ON')):
    build = root / ('analysis-' + config)
    steps.extend([(config + '-configure', ['/usr/bin/cmake', '-S', str(analysis_source), '-B', str(build),
                                          '-DCMAKE_C_COMPILER=/usr/bin/gcc', '-DCMAKE_BUILD_TYPE=RelWithDebInfo',
                                          '-DBUILD_TESTING=ON', '-DFREQUENCY_ANALYSIS_SANITIZERS=' + sanitizers]),
                  (config + '-build', ['/usr/bin/cmake', '--build', str(build), '--parallel', '2']),
                  (config + '-test', ['/usr/bin/ctest', '--test-dir', str(build), '--output-on-failure'])])
results = []
for label, arguments in steps:
    started = time.monotonic()
    with (root / (label + '.log')).open('xb') as output:
        process = subprocess.Popen(arguments, cwd=root, env=environment, stdout=output, stderr=subprocess.STDOUT)
        record = {'label': label, 'arguments': arguments, 'pid': process.pid}
        try:
            record['start_ticks'] = Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]
        except (OSError, IndexError) as error:
            record['identity_error'] = type(error).__name__
        try:
            record['exit_code'] = process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            record.update({'observation_timeout': True, 'process_exit_unconfirmed': True})
            with (root / (label + '-timeout.json')).open('x') as output:
                json.dump(record, output, indent=2)
            print(json.dumps(record), flush=True)
            raise
    record['wall_seconds'] = time.monotonic() - started
    with (root / (label + '-result.json')).open('x') as output:
        json.dump(record, output, indent=2)
    results.append(record)
    print(json.dumps(record), flush=True)
    if record['exit_code'] != 0:
        raise SystemExit(1)
artifacts = {}
for config in ('normal', 'sanitize'):
    name = 'analysis-' + config + '/analyze_windows'
    binary = root / name
    artifacts[name] = {'sha256': hashlib.sha256(binary.read_bytes()).hexdigest(), 'bytes': binary.stat().st_size}
with (root / 'run.json').open('x') as output:
    json.dump({'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'uname': list(os.uname()),
               'python': platform.python_version(), 'source_commit': '0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac',
               'steps': results, 'artifacts': artifacts, 'real_guard_run': False,
               'crypto_workload_performed': False, 'hardware_data_analyzed': False,
               'configuration_writes': 0, 'temporary_environment': {name: environment[name] for name in
               ('TMPDIR', 'TMP', 'TEMP', 'XDG_CACHE_HOME', 'CCACHE_DIR', 'PYTHONDONTWRITEBYTECODE')}}, output, indent=2)
paths = sorted(path for path in root.rglob('*') if path.is_file())
assert not any(path.is_symlink() for path in root.rglob('*'))
tree_bytes = sum(path.stat().st_size for path in paths)
assert tree_bytes < 16 * 1024 * 1024
manifest = {str(path.relative_to(root)): {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                                       'bytes': path.stat().st_size} for path in paths}
with (root / 'export-manifest.json').open('x') as output:
    json.dump(manifest, output, indent=2)
paths.append(root / 'export-manifest.json')
target = project / 'window-management-0ba4cd7-software.tar'
descriptor = os.open(target, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
with os.fdopen(descriptor, 'w+b') as output:
    with tarfile.open(fileobj=output, mode='w') as saved:
        for path in paths:
            content = path.read_bytes()
            member = tarfile.TarInfo(root.name + '/' + str(path.relative_to(root)))
            member.mode = 0o600
            member.size = len(content)
            saved.addfile(member, io.BytesIO(content))
    output.flush()
    output.seek(0)
    digest = hashlib.file_digest(output, 'sha256').hexdigest()
print(json.dumps({'status': 'native_software_passed', 'archive': str(target), 'sha256': digest,
                  'members': len(paths), 'tree_bytes': tree_bytes, 'artifacts': artifacts,
                  'real_guard_run': False, 'crypto_workload_performed': False,
                  'hardware_data_analyzed': False, 'configuration_writes': 0}), flush=True)
