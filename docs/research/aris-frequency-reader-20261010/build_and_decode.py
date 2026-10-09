from pathlib import Path, PurePosixPath
import datetime
import hashlib
import io
import json
import os
import shutil
import subprocess
import tarfile
import time


PROJECT_ROOT = Path('/home/nss-marker/yhr/Cry')
RUN_ROOT = PROJECT_ROOT / 'feedback-reader-eed81a7'
SOURCE_DIGEST = '78572cc80804f2b5d44b0308a8e46ce027f0cb0d70331962568e6dfcdcffdb1c'
PACKAGE_DIGEST = '1282c3e0f5f3e53759350e98e68b96bf31d1f381aaf1e0abdbd750f7a131841c'
FIRMWARE_DIGEST = '5de3dd6af737bca1e8a47a9aa6729313be084612e788eab287fb968ebbaef431'


def verified_bytes(path, expected):
    if path.is_symlink() or not path.is_file():
        raise RuntimeError('expected regular file')
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError('source digest mismatch')
    return data


def save_new(path, content, mode=0o600):
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, mode)
    with os.fdopen(descriptor, 'wb') as output:
        output.write(content)


def execute(label, arguments, working_directory, environment):
    started = time.monotonic()
    record = {'label': label, 'arguments': arguments, 'cwd': str(working_directory),
              'started_utc': datetime.datetime.now(datetime.timezone.utc).isoformat()}
    with (RUN_ROOT / (label + '.log')).open('xb') as output:
        process = subprocess.Popen(arguments, cwd=working_directory, env=environment,
                                   stdout=output, stderr=subprocess.STDOUT)
        record['pid'] = process.pid
        record['start_ticks'] = Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]
        record['process_group_id'] = os.getpgid(process.pid)
        save_new(RUN_ROOT / (label + '-started.json'), (json.dumps(record, indent=2) + '\n').encode())
        try:
            returncode = process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            record.update({'observation_timeout': True, 'process_exit_unconfirmed': True})
            save_new(RUN_ROOT / (label + '-timeout.json'), (json.dumps(record, indent=2) + '\n').encode())
            print(json.dumps(record), flush=True)
            raise RuntimeError('step remains live; inspect saved process handle before continuing')
    record.update({'exit_code': returncode, 'wall_seconds': time.monotonic() - started})
    save_new(RUN_ROOT / (label + '-result.json'), (json.dumps(record, indent=2) + '\n').encode())
    print(json.dumps(record), flush=True)
    if returncode != 0:
        raise RuntimeError('step failed; preserving original logs')


def main():
    if os.geteuid() == 0 or os.uname().nodename != 'nss-m':
        raise RuntimeError('ordinary user on the admitted host required')
    if Path.cwd() != PROJECT_ROOT or RUN_ROOT.resolve(strict=True) != RUN_ROOT:
        raise RuntimeError('unexpected physical run root')
    source_data = verified_bytes(RUN_ROOT / 'source-eed81a7.tar', SOURCE_DIGEST)
    with tarfile.open(fileobj=io.BytesIO(source_data)) as archive:
        members = archive.getmembers()
        if len(members) > 64 or sum(member.size for member in members) > 1024 * 1024:
            raise RuntimeError('source archive budget exceeded')
        for member in members:
            name = PurePosixPath(member.name)
            if name.is_absolute() or '..' in name.parts or name.parts[0] != 'source':
                raise RuntimeError('source archive path rejected')
            if not (member.isdir() or member.isfile()):
                raise RuntimeError('source archive type rejected')
        for member in members:
            target = RUN_ROOT / member.name
            if member.isdir():
                target.mkdir(mode=0o700)
            else:
                with archive.extractfile(member) as source:
                    save_new(target, source.read(member.size + 1))
    package = RUN_ROOT / 'acpica-tools_20230628-1_amd64.deb'
    verified_bytes(package, PACKAGE_DIGEST)
    extracted = subprocess.run(['/usr/bin/dpkg-deb', '--fsys-tarfile', str(package)],
                               check=True, stdout=subprocess.PIPE, timeout=10).stdout
    if len(extracted) > 6 * 1024 * 1024:
        raise RuntimeError('package extraction budget exceeded')
    (RUN_ROOT / 'tools').mkdir(mode=0o700)
    with tarfile.open(fileobj=io.BytesIO(extracted)) as archive:
        selected = {'./usr/bin/iasl': ('iasl', 0o500),
                    './usr/share/doc/acpica-tools/copyright': ('copyright', 0o600)}
        for member_name, (filename, mode) in selected.items():
            member = archive.getmember(member_name)
            if not member.isfile() or member.size > 2 * 1024 * 1024:
                raise RuntimeError('package member rejected')
            with archive.extractfile(member) as source:
                save_new(RUN_ROOT / 'tools' / filename, source.read(member.size + 1), mode)
    original = PROJECT_ROOT / 'feedback-mapping-20261010-62ce88b02a82.tar'
    firmware = verified_bytes(original, FIRMWARE_DIGEST)
    save_new(RUN_ROOT / original.name, firmware)
    (RUN_ROOT / 'decode').mkdir(mode=0o700)
    with tarfile.open(fileobj=io.BytesIO(firmware)) as archive:
        for member in archive.getmembers():
            name = PurePosixPath(member.name)
            if len(name.parts) != 2 or name.parts[0] != 'feedback-mapping-20261010-62ce88b02a82' or not member.isfile():
                raise RuntimeError('firmware archive member rejected')
            with archive.extractfile(member) as source:
                save_new(RUN_ROOT / 'decode' / name.name, source.read(member.size + 1))
    environment = os.environ.copy()
    for name in ('tmp', 'cache'):
        (RUN_ROOT / name).mkdir(mode=0o700)
    for name in ('TMPDIR', 'TMP', 'TEMP'):
        environment[name] = str(RUN_ROOT / 'tmp')
    environment.update({'XDG_CACHE_HOME': str(RUN_ROOT / 'cache'),
                        'CCACHE_DIR': str(RUN_ROOT / 'cache'), 'LC_ALL': 'C'})
    save_new(RUN_ROOT / 'environment.json', (json.dumps({name: environment[name] for name in (
        'TMPDIR', 'TMP', 'TEMP', 'XDG_CACHE_HOME', 'CCACHE_DIR', 'LC_ALL')}, indent=2) + '\n').encode())
    source_root = RUN_ROOT / 'source/docs/research/aris-frequency-reader-20261010'
    for label, sanitizers in (('normal', 'OFF'), ('sanitize', 'ON')):
        build = RUN_ROOT / ('build-' + label)
        execute(label + '-configure', ['/usr/bin/cmake', '-S', str(source_root), '-B', str(build),
                '-DCMAKE_BUILD_TYPE=Debug', '-DBUILD_TESTING=ON',
                '-DMSR_READER_SANITIZERS=' + sanitizers], RUN_ROOT, environment)
        execute(label + '-build', ['/usr/bin/cmake', '--build', str(build), '--parallel', '2'], RUN_ROOT, environment)
        execute(label + '-test', ['/usr/bin/ctest', '--test-dir', str(build), '--output-on-failure'], RUN_ROOT, environment)
    iasl = str(RUN_ROOT / 'tools/iasl')
    execute('iasl-version', [iasl, '-v'], RUN_ROOT, environment)
    inputs = sorted(str(path) for path in (RUN_ROOT / 'decode').glob('*.dat'))
    execute('iasl-disassemble', [iasl, '-da', *inputs], RUN_ROOT / 'decode', environment)
    artifacts = {}
    for relative in ('tools/iasl', 'tools/copyright', 'build-normal/msr_counter_snapshot',
                     'build-sanitize/msr_counter_snapshot'):
        path = RUN_ROOT / relative
        artifacts[relative] = {'bytes': path.stat().st_size,
                                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    save_new(RUN_ROOT / 'artifact-digests.json', (json.dumps(artifacts, indent=2) + '\n').encode())
    links = [str(path.relative_to(RUN_ROOT)) for path in RUN_ROOT.rglob('*') if path.is_symlink()]
    total_bytes = sum(path.stat().st_size for path in RUN_ROOT.rglob('*') if path.is_file())
    if links or total_bytes > 30 * 1024 * 1024:
        raise RuntimeError('run tree symlink or disk budget check failed')
    print(json.dumps({'status': 'built_and_decoded', 'tree_bytes': total_bytes, 'symlinks': links,
                      'hardware_read_performed': False, 'configuration_writes': 0}), flush=True)


if __name__ == '__main__':
    main()
