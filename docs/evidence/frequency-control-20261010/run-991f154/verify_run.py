import copy
import hashlib
import json
from pathlib import Path, PurePosixPath
import tarfile


ROOT = Path(__file__).resolve().parent
ARCHIVE_NAME = 'core-frequency-20261010-d05b4396f082.tar'
ARCHIVE_SHA256 = '3c4951ac57b905b9fa232858f2bf017ef93daaf5f522d8d9a38126e53a7da122'
TARGETS = ('policy2', 'policy18')
LIMITS = ('scaling_min_freq', 'scaling_max_freq')


def read_tool_json(label):
    text = (ROOT / 'tool-receipts' / (label + '.log')).read_text()
    value, offset = json.JSONDecoder().raw_decode(text, text.index('{'))
    assert text[offset:].strip() == 'Shared connection to 10.144.144.5 closed.'
    assert json.loads((ROOT / 'tool-receipts' / (label + '.json')).read_text())['exit_code'] == 0
    return value


archive_path = ROOT / ARCHIVE_NAME
assert hashlib.sha256(archive_path.read_bytes()).hexdigest() == ARCHIVE_SHA256
with tarfile.open(archive_path) as archive:
    payloads = {}
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        assert member.isfile() and not path.is_absolute() and '..' not in path.parts
        assert member.name not in payloads
        payloads[member.name] = archive.extractfile(member).read()
assert len(payloads) == 68
originals = {str(path.relative_to(ROOT / 'originals')): path.read_bytes()
             for path in (ROOT / 'originals').rglob('*') if path.is_file()}
assert originals == payloads
source = json.loads(payloads['source.json'])
assert hashlib.sha256(source['source'].encode()).hexdigest() == source['sha256'] == 'b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661'
assert json.loads(payloads['run.json'])['success'] is True
assert json.loads(payloads['run.json'])['hardware_frequency_qualified'] is False
identities = {}
for mode, expected_exit, expected_reason in (('normal', 0, 'release'), ('parent-loss', -9, 'controller_eof')):
    def record(name):
        return json.loads(payloads[mode + '/' + name + '.json'])

    baseline = record('frequency-baseline')
    assert len(baseline['policies']) == 32
    expected_active = copy.deepcopy(baseline)
    for policy_name in TARGETS:
        for field in LIMITS:
            expected_active['policies'][policy_name][field]['value'] = '4300000'
    active = record('active')
    assert active['frequency'] == expected_active and active['hardware_frequency_qualified'] is False
    assert active['partition']['cpuset.cpus.partition'] == 'isolated'
    assert active['snapshot']['root_isolated'] == [2, 18]
    terminal = record('terminal')
    observer = record('observer')
    assert terminal['success'] and terminal['reason'] == expected_reason and not terminal['errors']
    assert observer['success'] and observer['controller_exit_code'] == expected_exit
    assert observer['guard_pidfd_exit_observed'] is True and observer['frequency_readback'] == baseline
    assert terminal['restored']['root_effective'] == list(range(32))
    assert terminal['restored']['root_isolated'] == []
    assert record('probe-exit')['exit_code'] == 0
    assert record('probe-before-exec')['allowed_cpus'] == [2, 18]
    pairs = {name: [baseline['policies'][name][field]['value'] for field in LIMITS] for name in TARGETS}
    pending = {name: {field: False for field in LIMITS} for name in TARGETS}
    order = [(name, field) for name in TARGETS for field in LIMITS] * 2
    for sequence, (name, field) in enumerate(order):
        dirty = record('frequency-dirty-' + str(sequence).zfill(4))
        visible = record('frequency-visible-' + str(sequence).zfill(4))
        assert dirty['sequence'] == sequence and dirty['policy_name'] == name and dirty['field'] == field
        assert dirty['before_pair'] == pairs[name]
        after = pairs[name].copy()
        after[LIMITS.index(field)] = '4300000' if sequence < 4 else baseline['policies'][name][field]['value']
        assert dirty['after_pair'] == after and visible['limits_khz'] == after and visible['policy_name'] == name
        pairs[name] = after
        pending[name][field] = sequence < 4
    assert not any(value for fields in pending.values() for value in fields.values())
    restores = [name for name in payloads if name.startswith(mode + '/frequency-restored-')]
    assert len(restores) == 1 and json.loads(payloads[restores[0]])['snapshot'] == baseline
    identities[mode] = {name: record(name)['pid'] for name in ('guard', 'controller', 'probe-before-exec')}
post = read_tool_json('root-postcheck')
assert post['root_effective'] == list(range(32)) and post['root_isolated'] == []
assert post['owned_groups_absent'] and post['lock_acquired_and_released']
assert post['archive_sha256'] == ARCHIVE_SHA256 and post['private_original_files_equal_archive'] == 68
for mode, names in identities.items():
    assert post['cases'][mode]['all_32_policies_and_global_equal_baseline'] is True
    for name, process_id in names.items():
        identity = post['cases'][mode]['identities'][name]
        assert identity['pid'] == process_id and identity['original_absent'] is True
linux_log = (ROOT / 'linux-check/LastTest.log').read_text()
assert 'Test Passed.' in linux_log and 'frequency_pending_superseded,frequency_cancel_failure' in linux_log
assert json.loads((ROOT / 'linux-check/test-result.json').read_text())['exit_code'] == 0
print(json.dumps({'status': 'passed', 'original_members_verified': 68, 'actual_cases': 2,
                  'frequency_write_intents_per_case': 8, 'visible_receipts_per_case': 8,
                  'all_32_policies_restored': True, 'original_processes_absent': 6,
                  'g1_visible_request_and_recovery': True, 'g2_workload_windows_run': False,
                  'hardware_frequency_qualified': False, 'r02_signed_off': False,
                  'r04_signed_off': False}, indent=2))
