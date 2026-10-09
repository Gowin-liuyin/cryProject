import hashlib
import json
from pathlib import Path


EVIDENCE_ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = EVIDENCE_ROOT.parents[2]


def read_snapshot(stem):
    raw = (EVIDENCE_ROOT / (stem + '.log')).read_bytes().decode('utf-8')
    leading_length = len(raw) - len(raw.lstrip())
    result, end_index = json.JSONDecoder().raw_decode(raw, leading_length)
    assert raw[end_index:].strip() == 'Shared connection to 10.144.144.5 closed.'
    normalized = json.loads((EVIDENCE_ROOT / (stem + '.json')).read_text())
    assert result == normalized
    assert result['effective_uid'] == 0
    assert result['configuration_writes'] == 0
    return result


verified_files = []
for line in (EVIDENCE_ROOT / 'SHA256SUMS').read_text().splitlines():
    expected_digest, relative_path = line.split('  ', 1)
    path = REPOSITORY_ROOT / relative_path
    assert not path.is_symlink()
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected_digest, relative_path
    verified_files.append(relative_path)

system = read_snapshot('preflight')
cppc = read_snapshot('cppc')
assert system['uname'][0:3] == ['Linux', 'nss-m', '6.17.0-35-generic']
assert system['uname'][4] == 'x86_64'
assert len(system['policies']) == 32
for cpu_index in ('2', '18'):
    policy = system['policies']['policy' + cpu_index]
    assert policy['related_cpus']['value'] == cpu_index
    assert policy['affected_cpus']['value'] == cpu_index
    assert policy['scaling_driver']['value'] == 'amd-pstate-epp'
    assert system['cpu_links'][cpu_index]['thread_siblings']['value'] == '2,18'
    assert cppc['cppc'][cpu_index]['nominal_freq']['value'] == '4300'
    assert cppc['cppc'][cpu_index]['nominal_perf']['value'] == '124'
    assert cppc['cppc'][cpu_index]['reference_perf']['value'] == '124'
    assert cppc['cppc'][cpu_index]['wraparound_time']['value'] == '18446744073709551615'
assert json.loads((EVIDENCE_ROOT / 'cppc-execution.json').read_text())['exit_code'] == 0
print(json.dumps({'status': 'passed', 'files_sha256_checked': len(verified_files),
                  'raw_json_pairs_checked': 2, 'hardware_frequency_qualified': False,
                  'r02_signed_off': False, 'r04_signed_off': False}, indent=2))
