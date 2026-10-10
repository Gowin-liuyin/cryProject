import ast
import base64
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile
import zlib

root = Path(__file__).resolve().parent
archive_path = root / 'core-window-20261010-51d37af52b90.tar'
assert hashlib.sha256(archive_path.read_bytes()).hexdigest() == '7c902223592dfc0705bfb28c2e7352b42febf15075528091ed9dc45a887c8191'
payloads = {}
with tarfile.open(archive_path) as archive:
    for member in archive.getmembers():
        name = PurePosixPath(member.name)
        assert member.isfile() and not name.is_absolute() and '..' not in name.parts
        assert member.name not in payloads
        data = archive.extractfile(member).read()
        assert data == (root / 'originals' / member.name).read_bytes()
        payloads[member.name] = data
assert len(payloads) == 87
assert set(payloads) == {str(path.relative_to(root / 'originals'))
                         for path in (root / 'originals').rglob('*') if path.is_file()}
source = json.loads(payloads['source.json'])
expected = subprocess.check_output(['git', 'show', '0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac:docs/research/aris-core-partition-20261010/rehearse_partition.py'], cwd=root.parents[3])
assert source['source'].encode() == expected
assert source['sha256'] == hashlib.sha256(expected).hexdigest() == '8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4'
for name in ('root-execution-bootstrap.py', 'root-postcheck-source.py'):
    tree = ast.parse((root / name).read_text())
    encoded = max((node.value for node in ast.walk(tree)
                   if isinstance(node, ast.Constant) and isinstance(node.value, str)), key=len)
    assert zlib.decompress(base64.b64decode(encoded)) == expected
assert json.loads(payloads['run.json'])['success'] is True
receipts = json.loads((root / 'tool-results.json').read_text())
assert receipts['completion']['exit_code'] == 0 and receipts['postcheck_completion']['exit_code'] == 0
post = json.loads((root / 'postcheck.json').read_text())
assert post == json.loads(next(line for line in receipts['postcheck_completion']['output'].splitlines() if line.startswith('{')))
assert post['status'] == 'postcheck_passed' and post['original_files_equal_archive'] == 87
assert post['all32_frequency_and_global_equal_baseline'] and post['owned_groups_absent'] and post['lock_acquired_and_released']
assert post['root_cpus'] == list(range(32)) and post['isolated'] == []
for case in ('normal', 'parent-loss'):
    load = lambda name: json.loads(payloads[case + '/' + name])
    baseline = load('frequency-baseline.json')
    observer = load('observer.json')
    terminal = load('terminal.json')
    worker = load('worker-exit.json')
    assert observer['frequency_readback'] == baseline
    assert observer['success'] and observer['guard_pidfd_exit_observed'] and observer['worker_pidfd_exit_observed']
    assert terminal['success'] and terminal['evidence_complete'] and terminal['restoration_visible']
    assert worker['reaped'] and worker['worker_exit_code'] == (0 if case == 'normal' else -9)
    assert worker['measurement_complete'] == (case == 'normal')
    assert len([name for name in payloads if name.startswith(case + '/frequency-dirty-')]) == 8
    assert len([name for name in payloads if name.startswith(case + '/frequency-visible-')]) == 8
    assert hashlib.sha256(payloads[case + '/worker.bin']).hexdigest() == '023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b'
    for record in post['cases'][case]['identities'].values():
        assert record['state'] == 'absent'
    if case == 'parent-loss':
        assert worker['cancel_while_running'] and worker['registered_cancel']
        assert payloads[case + '/worker.stdout.jsonl'] == b''
raw = payloads['normal/worker.stdout.jsonl']
assert len(raw) == 29266316 and hashlib.sha256(raw).hexdigest() == 'c29a9ca0e28ffad53aaeb0e0c0097fd560d048f5eee4803885cb56850a989028'
counts = Counter()
for line in raw.splitlines():
    counts[json.loads(line)['type']] += 1
assert counts == {'contract': 1, 'device': 2, 'public_input': 8, 'snapshot': 251,
                  'checkpoint': 1977, 'decap': 126528, 'summary': 1}
analysis = root / 'analysis'
provenance = json.loads((analysis / 'provenance.json').read_text())
for name, record in provenance['files'].items():
    data = (analysis / name).read_bytes()
    assert len(data) == record['bytes'] and hashlib.sha256(data).hexdigest() == record['sha256']
assert hashlib.sha256((analysis / 'analyze_windows-macos-arm64').read_bytes()).hexdigest() == provenance['analyzer_binary_sha256']
outcomes = json.loads((analysis / 'tool-results.json').read_text())
assert outcomes['normal']['value']['exit_code'] == 0 and outcomes['parent_loss']['value']['exit_code'] == 1
summary = json.loads((analysis / 'normal-summary.json').read_text())
assert summary['validation'] == 'passed' and summary['producer_completed'] and summary['engineering_diagnostic'] == 'yes'
assert summary['observed_main_pairs'] == summary['passing_main_pairs'] == 200
assert summary['boundary_straddle_pairs'] == 1 and summary['main_call_records'] == 101248
assert all(value == 0 for value in summary['all_phase_failure_ledger'].values())
assert (int(summary['pure_main_coverage_wall_numerator_ns']) + int(summary['head_boundary_blind_ns']) +
        int(summary['tail_frame_blind_ns']) + int(summary['interior_bracket_or_uncovered_ns']) -
        int(summary['head_tail_blind_overlap_ns'])) == int(summary['main_wall_ns'])
assert not summary['full_main_coverage_certified'] and not summary['physical_precision_certified']
assert not summary['r02_signed_off'] and not summary['r04_signed_off']
with (analysis / 'normal-windows.csv').open() as source_file:
    rows = list(csv.DictReader(source_file))
primary = [row for row in rows if row['role'] == 'primary']
assert len(rows) == 400 and len(primary) == 200
assert all(row['exact_band'] == 'in_band' and row['primary_rules_and_band_pass'] == 'true' for row in primary)
assert (analysis / 'parent-loss-windows.csv').read_bytes() == b''
assert json.loads((analysis / 'parent-loss-summary.json').read_text())['validation'] == 'failed'
print(json.dumps({'status': 'passed', 'original_members': 87, 'raw_call_records': 126528,
                  'completed_processes': 1, 'main_pairs': 200, 'engineering_pass_pairs': 200,
                  'parent_loss_output_role': 'partial_or_unknown', 'visible_restoration_verified': True,
                  'full_main_coverage_certified': False, 'r02_signed_off': False,
                  'r04_signed_off': False}, indent=2))
