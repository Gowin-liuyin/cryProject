import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import struct
import tarfile


ROOT = Path(__file__).resolve().parent
ARCHIVES = {
    'feedback-mapping-20261010-62ce88b02a82.tar': '5de3dd6af737bca1e8a47a9aa6729313be084612e788eab287fb968ebbaef431',
    'feedback-counter-20261010-16ec7cf0d5fb.tar': '3457b6f8c729eac6209316f08f353486d5027eb17bc33489af84a8dc9ac2a601',
    'feedback-reader-eed81a7-results.tar': 'b187de98505e70f555d583be9e88add9e7cd603b9d5cf896e95be5862079382a',
}


def archive_payloads(name):
    data = (ROOT / name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == ARCHIVES[name], name
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        result = {}
        for member in archive.getmembers():
            path = PurePosixPath(member.name)
            assert member.isfile() and not path.is_absolute() and '..' not in path.parts
            assert member.name not in result
            result[member.name] = archive.extractfile(member).read()
            assert len(result[member.name]) == member.size
        return result


def decimal_u64(value):
    assert isinstance(value, str) and value.isascii() and value.isdecimal()
    converted = int(value)
    assert str(converted) == value and 0 <= converted <= 2**64 - 1
    return converted


firmware = archive_payloads('feedback-mapping-20261010-62ce88b02a82.tar')
firmware_prefix = 'feedback-mapping-20261010-62ce88b02a82/'
metadata = json.loads(firmware[firmware_prefix + 'metadata.json'])
assert len(metadata['tables']) == 14 and len(firmware) == 15
assert sum(record['length_bytes'] for record in metadata['tables'].values()) == 282915
for name, record in metadata['tables'].items():
    content = firmware[firmware_prefix + name]
    assert len(content) == record['length_bytes'] == struct.unpack_from('<I', content, 4)[0]
    assert sum(content) % 256 == 0 and hashlib.sha256(content).hexdigest() == record['sha256']
assert metadata['firmware_nodes']['2']['path'] == '\\_SB_.PLTF.C004'
assert metadata['firmware_nodes']['18']['path'] == '\\_SB_.PLTF.C005'

run = archive_payloads('feedback-reader-eed81a7-results.tar')
prefix = 'feedback-reader-eed81a7/'
manifest = json.loads(run[prefix + 'export-manifest.json'])
assert len(run) == 476 and len(manifest) == 475
assert set(run) == {prefix + name for name in manifest} | {prefix + 'export-manifest.json'}
for name, record in manifest.items():
    content = run[prefix + name]
    assert len(content) == record['bytes'] and hashlib.sha256(content).hexdigest() == record['sha256']
for label in ('normal', 'sanitize'):
    for step in ('configure', 'build', 'test'):
        assert json.loads(run[prefix + label + '-' + step + '-result.json'])['exit_code'] == 0
    log = run[prefix + 'build-' + label + '/Testing/Temporary/LastTest.log'].decode()
    assert 'Test Passed.' in log and 'msr_counter_snapshot_selfcheck' in log
    assert '{"selfcheck":"passed","hardware_read_performed":false}' in log
    flags = run[prefix + 'build-' + label + '/CMakeFiles/msr_counter_snapshot.dir/flags.make'].decode()
    assert '-std=c11' in flags and '-Werror' in flags
assert json.loads(run[prefix + 'iasl-disassemble-result.json'])['exit_code'] == 255
assert b'AE_ALREADY_EXISTS' in run[prefix + 'iasl-disassemble.log']
assert len(run[prefix + 'decode/DSDT.dsl']) == 631636
fresh = json.loads(run[prefix + 'decode-s01/result.json'])
assert fresh['exit_code'] == 0 and set(fresh['input_sha256']) == set(metadata['tables'])
for name, record in metadata['tables'].items():
    assert fresh['input_sha256'][name] == record['sha256']
    assert run[prefix + 'decode-s01/' + name] == firmware[firmware_prefix + name]
assert not re.search(rb'\b(error|warning|unresolved)\b', run[prefix + 'decode-s01/iasl.log'], re.I)
assert hashlib.sha256(run[prefix + 'decode-s01/SSDT3.dsl']).hexdigest() == '6528830e0f5d7b5e7933aaf653370f8e7c7754e641916a81c5426ed60b6d5bc7'
source_archive = run[prefix + 'source-eed81a7.tar']
assert hashlib.sha256(source_archive).hexdigest() == '78572cc80804f2b5d44b0308a8e46ce027f0cb0d70331962568e6dfcdcffdb1c'
with tarfile.open(fileobj=io.BytesIO(source_archive)) as archive:
    source = archive.extractfile('source/docs/research/aris-frequency-reader-20261010/msr_counter_snapshot.c').read()
    assert hashlib.sha256(source).hexdigest() == '6d21bf4e1d9c93956a9a4e5d25b07f0f4339a2d2b5e3df465ae663bd85170c66'

counter = archive_payloads('feedback-counter-20261010-16ec7cf0d5fb.tar')
counter_prefix = 'feedback-counter-20261010-16ec7cf0d5fb/'
assert len(counter) == 4
assert run[prefix + 'feedback-counter-20261010-16ec7cf0d5fb.tar'] == (ROOT / 'feedback-counter-20261010-16ec7cf0d5fb.tar').read_bytes()
binary = counter[counter_prefix + 'msr_counter_snapshot']
assert binary == run[prefix + 'build-normal/msr_counter_snapshot']
assert hashlib.sha256(binary).hexdigest() == 'acfa346972dd79dc614927e89697632fe71c3d68b5e2829522faeaa93cc422a7'
assert binary[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', binary, 18)[0] == 62
execution = json.loads(counter[counter_prefix + 'execution.json'])
assert execution['exit_code'] == 0 and not execution['execution_deadline_exceeded']
assert execution['source_commit'] == 'eed81a7620a1c929c52e96acb203104917ec3b5d'
assert not counter[counter_prefix + 'stderr.log']
snapshot = json.loads(counter[counter_prefix + 'stdout.json'])
assert snapshot['status'] == 'readable_snapshot' and snapshot['frequency_converted'] is False
assert [entry['cpu_index'] for entry in snapshot['cpu_snapshots']] == [2, 18]
previous_end = 0
rows = 0
for cpu in snapshot['cpu_snapshots']:
    assert cpu['device_status'] == 'ok' and cpu['device_errno'] is None and cpu['close_errno'] is None
    assert [row['read_name'] for row in cpu['reads']] == ['mperf_before', 'aperf', 'mperf_after']
    assert [row['register_offset'] for row in cpu['reads']] == ['0xe7', '0xe8', '0xe7']
    for row in cpu['reads']:
        assert row['read_status'] == 'ok' and row['bytes_read'] == 8 and row['read_errno'] is None
        assert row['clock_before_errno'] is None and row['clock_after_errno'] is None
        decimal_u64(row['counter_value_u64'])
        before = decimal_u64(row['clock_before_ns'])
        after = decimal_u64(row['clock_after_ns'])
        assert previous_end <= before <= after
        previous_end = after
        rows += 1
state = json.loads(run[prefix + 'final-visible-state.json'])
assert state['cpuset_root'] == {'cpuset.cpus.effective': '0-31', 'cpuset.cpus.isolated': ''}
assert all(row['scaling_governor'] == 'powersave' and row['scaling_min_freq'] == '2982259'
           and row['scaling_max_freq'] == '5756452' for row in state['policies'].values())
for path in (ROOT / 'selected').rglob('*'):
    if path.is_file():
        assert path.read_bytes() == run[prefix + str(path.relative_to(ROOT / 'selected'))]
for path in (ROOT / 'counter').iterdir():
    assert path.read_bytes() == counter[counter_prefix + path.name]
print(json.dumps({'status': 'passed', 'archives_verified': 3, 'firmware_tables_verified': 14,
                  'run_archive_members': len(run), 'run_payloads_verified': len(manifest),
                  'linux_software_tests_per_configuration': 1, 'counter_rows_verified': rows,
                  'original_decode_exit_code': 255, 'fresh_target_decode_exit_code': 0,
                  'hardware_frequency_qualified': False, 'r02_signed_off': False,
                  'r04_signed_off': False}, indent=2))
