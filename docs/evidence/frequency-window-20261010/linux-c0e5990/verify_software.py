import io
import subprocess
import hashlib
import json
from pathlib import Path, PurePosixPath
import struct
import tarfile


ROOT = Path(__file__).resolve().parent
ARCHIVE = ROOT / 'window-source-c0e5990-software.tar'
assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == 'f487f59544aaab302303944463cd32daa99963725cef54eded4d220c578202e7'
with tarfile.open(ARCHIVE) as archive:
    payloads = {}
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        assert member.isfile() and not path.is_absolute() and '..' not in path.parts
        assert member.name not in payloads
        payloads[member.name] = archive.extractfile(member).read()
assert len(payloads) == 618
prefix = 'window-source-c0e5990/'
manifest = json.loads(payloads[prefix + 'export-manifest.json'])
assert len(manifest) == 617
assert set(payloads) == {prefix + name for name in manifest} | {prefix + 'export-manifest.json'}
for name, record in manifest.items():
    content = payloads[prefix + name]
    assert len(content) == record['bytes'] and hashlib.sha256(content).hexdigest() == record['sha256']
for path in (ROOT / 'selected').rglob('*'):
    if path.is_file():
        assert path.read_bytes() == payloads[prefix + str(path.relative_to(ROOT / 'selected'))]
run = json.loads(payloads[prefix + 'run.json'])
assert run['source_commit'] == 'c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2'
assert run['uname'][0:3] == ['Linux', 'nss-m', '6.17.0-35-generic'] and run['uname'][4] == 'x86_64'
assert run['ordinary_entry_run'] is False and run['msr_read_performed'] is False
assert len(run['steps']) == 6 and all(step['exit_code'] == 0 for step in run['steps'])
assert hashlib.sha256(payloads[prefix + 'window-source-c0e5990.tar']).hexdigest() == '9f9803943f6ae724f895c57cd60c41828d0cba6a71d9deb7eb6f78907d95a8f5'
assert hashlib.sha256(payloads[prefix + 'source/docs/research/aris-frequency-window-20261010/frequency_workload.c']).hexdigest() == '520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0'
with tarfile.open(fileobj=io.BytesIO(payloads[prefix + 'window-source-c0e5990.tar'])) as source_archive:
    source_count = 0
    for member in source_archive.getmembers():
        if member.isfile():
            relative = str(PurePosixPath(member.name).relative_to('source'))
            content = source_archive.extractfile(member).read()
            expected = subprocess.check_output(['git', 'show', run['source_commit'] + ':' + relative], cwd=ROOT.parents[3])
            assert content == expected and content == payloads[prefix + 'source/' + relative]
            source_count += 1
    assert source_count == 138
assert run['process_safety_entry_tested'] is True
artifacts = json.loads(payloads[prefix + 'artifact-digests.json'])
binary_count = 0
for config in ('normal', 'sanitize'):
    build = prefix + 'build-' + config + '/'
    compiler_path = next(name for name in payloads if name.startswith(build + 'CMakeFiles/') and name.endswith('/CMakeCCompiler.cmake'))
    compiler = payloads[compiler_path].decode()
    assert 'set(CMAKE_C_COMPILER_ID "GNU")' in compiler
    assert 'set(CMAKE_C_COMPILER_VERSION "13.3.0")' in compiler
    commands = json.loads(payloads[build + 'compile_commands.json'])
    assert len(commands) == 6
    for item in commands:
        command = item['command']
        assert '-std=c11' in command and '-Werror' in command
        assert all(token not in command for token in ('BASELINE_VULNERABLE', 'BASELINE_HARDENED', 'BASELINE_DEPLOYABLE', '-source/mlkem'))
        assert ('-fsanitize=address,undefined' in command) == (config == 'sanitize')
    log = payloads[build + 'Testing/Temporary/LastTest.log'].decode()
    assert log.count('Test Passed.') == 3 and 'frequency_workload_selfcheck' in log and 'frequency_reference_kat' in log
    assert 'crypto_workload_performed":false' in log
    assert '--selfcheck' in log and '--process-safety-check' in log
    assert '"process_dumping_disabled":true,"errno":0' in log
    for program in ('frequency_workload', 'frequency_reference_kat'):
        name = 'build-' + config + '/' + program
        binary = payloads[prefix + name]
        assert binary[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', binary, 18)[0] == 62
        assert len(binary) == artifacts[name]['bytes'] and hashlib.sha256(binary).hexdigest() == artifacts[name]['sha256']
        binary_count += 1
print(json.dumps({'status': 'passed', 'archive_members': 618, 'payloads_verified': 617,
                  'actual_compiler': 'GNU 13.3.0', 'linux_elfs_verified': binary_count,
                  'tests_per_configuration': 3, 'ordinary_entry_run': False,
                  'msr_read_performed': False, 'g2_workload_windows_run': False,
                  'r02_signed_off': False, 'r04_signed_off': False}, indent=2))
