import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import struct
import subprocess
import tarfile

root = Path(__file__).resolve().parent
target = root / 'window-management-0ba4cd7-software.tar'
assert hashlib.sha256(target.read_bytes()).hexdigest() == 'f8d495de5318e46241dbaa6190ac58114e0cae627c94e6cf4085cfc7fbdf6a32'
payloads = {}
with tarfile.open(target) as archive:
    for member in archive.getmembers():
        name = PurePosixPath(member.name)
        assert member.isfile() and not name.is_absolute() and '..' not in name.parts
        assert name.parts[0] == 'window-management-0ba4cd7' and member.name not in payloads
        payloads[member.name] = archive.extractfile(member).read()
assert len(payloads) == 609
prefix = 'window-management-0ba4cd7/'
manifest = json.loads(payloads[prefix + 'export-manifest.json'])
assert len(manifest) == 608
assert set(payloads) == {prefix + name for name in manifest} | {prefix + 'export-manifest.json'}
for name, record in manifest.items():
    data = payloads[prefix + name]
    assert len(data) == record['bytes'] and hashlib.sha256(data).hexdigest() == record['sha256']
for path in (root / 'linux-check').rglob('*'):
    if path.is_file():
        assert path.read_bytes() == payloads[prefix + str(path.relative_to(root / 'linux-check'))]
run = json.loads(payloads[prefix + 'run.json'])
assert run['source_commit'] == '0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac'
assert len(run['steps']) == 8 and all(step['exit_code'] == 0 for step in run['steps'])
assert run['real_guard_run'] is False and run['crypto_workload_performed'] is False
assert run['hardware_data_analyzed'] is False and run['configuration_writes'] == 0
assert run['uname'][0:3] == ['Linux', 'nss-m', '6.17.0-35-generic'] and run['uname'][4] == 'x86_64'
source_count = 0
with tarfile.open(fileobj=io.BytesIO(payloads[prefix + 'source-0ba4cd7.tar'])) as archive:
    for member in archive.getmembers():
        if member.isfile():
            relative = str(PurePosixPath(member.name).relative_to('source'))
            data = archive.extractfile(member).read()
            expected = subprocess.check_output(['git', 'show', run['source_commit'] + ':' + relative],
                                               cwd=root.parents[3])
            assert data == expected and data == payloads[prefix + 'source/' + relative]
            source_count += 1
assert source_count == 6
for name in ('guard-check', 'analysis-normal', 'analysis-sanitize'):
    log = payloads[prefix + name + '/Testing/Temporary/LastTest.log'].decode()
    assert log.count('Test Passed.') == 1
    if name == 'guard-check':
        assert 'window_registered_eof' in log and 'kernel_writes=none; crypto_workload=none' in log
    else:
        assert 'fixture_only":true' in log and 'hardware_data_analyzed":false' in log
        program = payloads[prefix + name + '/analyze_windows']
        assert program[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', program, 18)[0] == 62
        assert hashlib.sha256(program).hexdigest() == run['artifacts'][name + '/analyze_windows']['sha256']
print(json.dumps({'status': 'passed', 'members': 609, 'payloads_verified': 608,
                  'source_git_files': source_count, 'actual_steps': 8, 'guard_ctest': '1/1',
                  'analysis_ctest_each': '1/1', 'real_guard_run': False,
                  'crypto_workload_performed': False, 'hardware_data_analyzed': False,
                  'r02_signed_off': False, 'r04_signed_off': False}, indent=2))
