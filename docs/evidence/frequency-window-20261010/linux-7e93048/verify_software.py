import hashlib
import json
from pathlib import Path, PurePosixPath
import struct
import tarfile


ROOT = Path(__file__).resolve().parent
ARCHIVE = ROOT / 'window-source-7e93048-software.tar'
assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == '408931d4b09ba516e22fc01c3dc748ace7b69d527c456ad9d8251461853c2dbc'
with tarfile.open(ARCHIVE) as archive:
    payloads = {}
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        assert member.isfile() and not path.is_absolute() and '..' not in path.parts
        assert member.name not in payloads
        payloads[member.name] = archive.extractfile(member).read()
assert len(payloads) == 618
prefix = 'window-source-7e93048/'
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
assert run['source_commit'] == '7e93048f3af885d14f1577b3a198bd3d52b8ee8e'
assert run['uname'][0:3] == ['Linux', 'nss-m', '6.17.0-35-generic'] and run['uname'][4] == 'x86_64'
assert run['ordinary_entry_run'] is False and run['msr_read_performed'] is False
assert len(run['steps']) == 6 and all(step['exit_code'] == 0 for step in run['steps'])
assert hashlib.sha256(payloads[prefix + 'window-source-7e93048.tar']).hexdigest() == '9229b613ead32f49ee73285fa39dff6b060b20287e3fce3a6bb9db944d8e84a4'
assert hashlib.sha256(payloads[prefix + 'source/docs/research/aris-frequency-window-20261010/frequency_workload.c']).hexdigest() == 'ead1029864025047ca0df2bf1d7bea179040f151313589389c043e3a7b9ef68a'
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
    assert log.count('Test Passed.') == 2 and 'frequency_workload_selfcheck' in log and 'frequency_reference_kat' in log
    assert 'crypto_workload_performed":false' in log
    assert '--selfcheck' in log
    for program in ('frequency_workload', 'frequency_reference_kat'):
        name = 'build-' + config + '/' + program
        binary = payloads[prefix + name]
        assert binary[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', binary, 18)[0] == 62
        assert len(binary) == artifacts[name]['bytes'] and hashlib.sha256(binary).hexdigest() == artifacts[name]['sha256']
        binary_count += 1
print(json.dumps({'status': 'passed', 'archive_members': 618, 'payloads_verified': 617,
                  'actual_compiler': 'GNU 13.3.0', 'linux_elfs_verified': binary_count,
                  'tests_per_configuration': 2, 'ordinary_entry_run': False,
                  'msr_read_performed': False, 'g2_workload_windows_run': False,
                  'r02_signed_off': False, 'r04_signed_off': False}, indent=2))
