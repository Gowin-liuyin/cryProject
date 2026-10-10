#!/usr/bin/env python3
"""Read-only, standard-library arithmetic cross-reference for the G2 C outputs."""

from collections import Counter, defaultdict
from fractions import Fraction
from pathlib import Path
import csv
import hashlib
import io
import json
import math
import re


ROOT = Path('/Users/yin/code/cryProject')
RUN = Path(__file__).resolve().parent
RAW = ROOT / 'docs/evidence/frequency-window-20261010/run-0ba4cd7/originals/normal/worker.stdout.jsonl'
EMPTY = ROOT / 'docs/evidence/frequency-window-20261010/run-0ba4cd7/originals/parent-loss/worker.stdout.jsonl'
C_SOURCE = ROOT / 'docs/research/aris-frequency-window-analysis-20261010/analyze_windows.c'
CMAKE = C_SOURCE.parent / 'CMakeLists.txt'
PLAN = ROOT / 'docs/research/aris-g2-timing-description-20261010/EXPERIMENT_PLAN.md'
MAX_U64 = 2 ** 64 - 1


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def pairs_without_duplicates(pairs):
    output = {}
    for key, value in pairs:
        require(key not in output, 'duplicate JSON key: ' + key)
        output[key] = value
    return output


def strict_json(text):
    def invalid_constant(value):
        raise AssertionError('nonfinite JSON constant: ' + value)
    return json.loads(text, object_pairs_hook=pairs_without_duplicates, parse_constant=invalid_constant)


def integer_string(value):
    require(isinstance(value, str) and re.fullmatch(r'(0|[1-9][0-9]*)', value) is not None,
            'noncanonical uint64 string')
    integer = int(value)
    require(integer <= MAX_U64, 'uint64 range')
    return integer


def clock_value(value):
    require(set(value) == {'ns', 'errno'} and value['errno'] is None, 'clock validity')
    return integer_string(value['ns'])


def quantile(sorted_values, percentile):
    # A Fraction specifies the rank; this does not call or reproduce a C helper.
    position = Fraction(len(sorted_values) - 1) * Fraction(percentile, 100) + Fraction(1, 2)
    return sorted_values[position.numerator // position.denominator]


def statistics(records):
    values = sorted(record['elapsed'] for record in records)
    require(values, 'empty description group')
    total = sum(values)
    require(total <= MAX_U64, 'description sum overflow')
    center = quantile(values, 50)
    deviations = sorted(abs(value - center) for value in values)
    return {'count': len(values), 'sum_elapsed_ns': total, 'min_ns': values[0],
            'p50_ns': center, 'p90_ns': quantile(values, 90), 'p99_ns': quantile(values, 99),
            'max_ns': values[-1], 'mad_ns': quantile(deviations, 50)}


def positions(records, main_begin, call_count):
    phases = Counter(record['phase'] for record in records)
    counts = {'all': len(records), 'warmup_phase': phases['warmup'], 'main_phase': phases['main'],
              'main_head': 0, 'main_interior': 0, 'main_tail': 0}
    for record in records:
        if record['phase'] != 'main':
            continue
        boundary = record['call_records']
        if boundary == main_begin:
            counts['main_head'] += 1
        elif main_begin < boundary < call_count:
            counts['main_interior'] += 1
        elif boundary == call_count:
            counts['main_tail'] += 1
        else:
            raise AssertionError('main record outside call boundary range')
    require(sum(counts[key] for key in ('main_head', 'main_interior', 'main_tail')) == phases['main'],
            'position count conservation')
    return counts


raw_bytes = RAW.read_bytes()
empty_bytes = EMPTY.read_bytes()
raw_sha = digest(raw_bytes)
require(raw_sha == 'c29a9ca0e28ffad53aaeb0e0c0097fd560d048f5eee4803885cb56850a989028', 'normal original identity')
require(len(raw_bytes) == 29266316 and raw_bytes.endswith(b'\n'), 'normal bytes or newline')
require(empty_bytes == b'', 'interrupted original must remain empty')
grouped = defaultdict(list)
input_line_count = 0
for input_line_count, line in enumerate(raw_bytes.splitlines(), 1):
    record = strict_json(line)
    require(record['type'] in {'contract', 'device', 'public_input', 'snapshot', 'checkpoint', 'decap', 'summary'},
            'unexpected record type')
    grouped[record['type']].append(record)
require(input_line_count == 128768, 'all original line count')
require(len(grouped['contract']) == 1 and len(grouped['summary']) == 1, 'singleton contract/summary')
require(len(grouped['device']) == 2 and len(grouped['public_input']) == 8, 'device/input counts')
contract = grouped['contract'][0]
require(contract['schema_version'] == 1 and contract['clock'] == 'CLOCK_MONOTONIC_RAW'
        and contract['input_order'] == 'index_modulo_8' and contract['iid_claimed'] is False,
        'producer contract')
summary = grouped['summary'][0]
require(summary['status'] == 'completed' and summary['valid_final_snapshot'] is True, 'completed original')
for kind, field in (('decap', 'call_records'), ('snapshot', 'snapshot_records'), ('checkpoint', 'checkpoint_records')):
    require(len(grouped[kind]) == summary[field], 'producer ' + field)

calls = []
for index, record in enumerate(grouped['decap']):
    require(record['index'] == index and record['input_index'] == index % 8, 'global index/input mismatch')
    require(record['operation_performed'] is True and record['operation_status'] == 0, 'unsuccessful original call')
    require(record['phase'] in ('warmup', 'main'), 'unknown call phase')
    before = clock_value(record['before'])
    after = clock_value(record['after'])
    elapsed = integer_string(record['elapsed_ns'])
    require(after >= before and after - before == elapsed, 'call clock difference mismatch')
    calls.append({'index': index, 'input_index': record['input_index'], 'phase': record['phase'],
                  'before': before, 'after': after, 'elapsed': elapsed})
main_begin = next(index for index, record in enumerate(calls) if record['phase'] == 'main')
warmup = calls[:main_begin]
main = calls[main_begin:]
require(all(record['phase'] == 'warmup' for record in warmup)
        and all(record['phase'] == 'main' for record in main), 'single ordered phase transition')
require(len(warmup) == 25280 and len(main) == 101248, 'published phase counts')
frames = grouped['snapshot']
checkpoints = grouped['checkpoint']
require(len(frames) == 251 and len(checkpoints) == 1977, 'published event counts')
boundary_frames = [record for record in frames if record['kind'] == 'warmup_to_main']
require(len(boundary_frames) == 1, 'exactly one transition snapshot')
boundary_frame = boundary_frames[0]
require(boundary_frame['phase'] == 'warmup' and boundary_frame['call_records'] == main_begin,
        'transition retains warmup phase')
require(frames[0]['kind'] == 'start' and frames[0]['call_records'] == 0,
        'start snapshot position')
require(frames[-1]['kind'] == 'end' and frames[-1]['call_records'] == len(calls),
        'end snapshot position')
main_start = integer_string(summary['main_start_ns'])
main_end = clock_value(frames[-1]['raw_after'])
require(main_start == clock_value(boundary_frame['raw_after']), 'main start identity')
require(integer_string(summary['warmup_start_ns']) == clock_value(frames[0]['raw_after']), 'warmup start identity')

# Reconstruct event time order from call-boundary positions. JSONL is grouped by type.
frames_by_boundary = defaultdict(list)
checkpoints_by_boundary = {}
last_frame_call_boundary = 0
for index, record in enumerate(frames):
    require(record['index'] == index and record['valid_reads_and_clocks'] is True, 'snapshot index/validity')
    call_boundary = record['call_records']
    require(last_frame_call_boundary <= call_boundary <= len(calls), 'snapshot call order')
    last_frame_call_boundary = call_boundary
    expected_phase = 'warmup' if index <= boundary_frame['index'] else 'main'
    require(record['phase'] == expected_phase, 'snapshot original phase')
    frames_by_boundary[call_boundary].append(record)
for index, record in enumerate(checkpoints):
    require(record['index'] == index and record['call_records'] == (index + 1) * 64,
            'checkpoint index and position')
    expected_phase = 'warmup' if record['call_records'] <= main_begin else 'main'
    require(record['phase'] == expected_phase, 'checkpoint original phase')
    require(record['call_records'] not in checkpoints_by_boundary, 'duplicate checkpoint boundary')
    checkpoints_by_boundary[record['call_records']] = record
previous_raw = None
previous_thread = None
raw_clock_values_checked = 0
thread_clock_values_checked = 0
for call_boundary in range(len(calls) + 1):
    event_clocks = []
    if call_boundary:
        event_clocks.extend((calls[call_boundary - 1]['before'], calls[call_boundary - 1]['after']))
    if call_boundary in checkpoints_by_boundary:
        event_clocks.append(clock_value(checkpoints_by_boundary[call_boundary]['raw']))
    for frame in frames_by_boundary[call_boundary]:
        event_clocks.append(clock_value(frame['raw_before']))
        require([item['cpu_index'] for item in frame['cpu_reads']] == [2, 18], 'snapshot CPU order')
        for cpu in frame['cpu_reads']:
            require([item['register'] for item in cpu['reads']] == ['0xe7', '0xe8', '0xe7'], 'register order')
            for read in cpu['reads']:
                require(read['bytes_read'] == 8 and read['errno'] is None, 'counter read status')
                integer_string(read['value_u64'])
                event_clocks.extend((clock_value(read['before']), clock_value(read['after'])))
        event_clocks.append(clock_value(frame['raw_after']))
        for value in (clock_value(frame['thread_cpu_before']), clock_value(frame['thread_cpu_after'])):
            require(previous_thread is None or previous_thread <= value, 'thread clock reversal')
            previous_thread = value
            thread_clock_values_checked += 1
    for value in event_clocks:
        require(previous_raw is None or previous_raw <= value, 'RAW event sequence reversal')
        previous_raw = value
        raw_clock_values_checked += 1

wall = main_end - main_start
head = main[0]['before'] - main_start
gaps = [following['before'] - preceding['after'] for preceding, following in zip(main, main[1:])]
tail = main_end - main[-1]['after']
call_sum = sum(record['elapsed'] for record in main)
require(main_end >= main_start and head >= 0 and tail >= 0 and all(value >= 0 for value in gaps),
        'main boundary or overlap')
require(call_sum + head + sum(gaps) + tail == wall, 'exact main wall conservation')
require(all(value <= MAX_U64 for value in (wall, head, tail, call_sum, sum(gaps), head + sum(gaps) + tail)),
        'main ledger uint64 range')
expected_ledger = {'call_records': len(calls), 'warmup_call_records': len(warmup), 'main_call_records': len(main),
                   'main_start_ns': str(main_start), 'main_end_ns': str(main_end), 'main_wall_ns': str(wall),
                   'main_call_elapsed_sum_ns': str(call_sum), 'main_outside_call_windows_ns': str(head + sum(gaps) + tail),
                   'main_head_outside_ns': str(head), 'main_intercall_gap_sum_ns': str(sum(gaps)),
                   'main_tail_outside_ns': str(tail), 'main_intercall_gap_count': len(gaps)}
expected_positions = {'snapshots': positions(frames, main_begin, len(calls)),
                      'checkpoints': positions(checkpoints, main_begin, len(calls))}

expected_rows = []
blocks = [('whole_phase', 'warmup', 'all', warmup), ('whole_phase', 'main', 'all', main)]
quarter_boundaries = [index * len(main) // 4 for index in range(5)]
for quarter in range(4):
    blocks.append(('main_quarter', 'main', str(quarter), main[quarter_boundaries[quarter]:quarter_boundaries[quarter + 1]]))
for scope, phase, quarter, block in blocks:
    for input_id in ['all'] + [str(index) for index in range(8)]:
        subset = block if input_id == 'all' else [record for record in block if record['input_index'] == int(input_id)]
        expected_rows.append({'scope': scope, 'phase': phase, 'quarter_index': quarter,
                              'input_index': input_id, **statistics(subset)})

csv_bytes = (RUN / 'normal-timing.csv').read_bytes()
actual_reader = csv.DictReader(io.StringIO(csv_bytes.decode('ascii'), newline=''))
header = ['scope', 'phase', 'quarter_index', 'input_index', 'count', 'sum_elapsed_ns', 'mean_ns',
          'min_ns', 'p50_ns', 'p90_ns', 'p99_ns', 'max_ns', 'mad_ns']
require(actual_reader.fieldnames == header, 'description CSV header')
actual_rows = list(actual_reader)
require(len(actual_rows) == len(expected_rows) == 54, 'description row count')
integer_fields_checked = 0
maximum_mean_absolute_error = Fraction(0)
maximum_mean_display_allowance = Fraction(0)
for row_number, (actual, expected) in enumerate(zip(actual_rows, expected_rows), 1):
    for key, value in expected.items():
        if isinstance(value, int):
            require(integer_string(actual[key]) == value, f'row {row_number} integer {key}')
            integer_fields_checked += 1
        else:
            require(actual[key] == value, f'row {row_number} grouping {key}')
    require(re.fullmatch(r'[0-9]+\.[0-9]{12}', actual['mean_ns']) is not None, 'mean display decimal shape')
    exact_mean = Fraction(expected['sum_elapsed_ns'], expected['count'])
    display_mean = Fraction(actual['mean_ns'])
    error = abs(display_mean - exact_mean)
    # Apple Silicon long double may be binary64: allow half its ULP plus decimal formatting rounding.
    # The two exact CSV integers, not this display tolerance, define the authoritative mean.
    allowance = Fraction.from_float(math.ulp(float(exact_mean))) / 2 + Fraction(1, 2 * 10 ** 12)
    require(error <= allowance, f'row {row_number} mean exceeds representation/formatting allowance')
    maximum_mean_absolute_error = max(maximum_mean_absolute_error, error)
    maximum_mean_display_allowance = max(maximum_mean_display_allowance, allowance)

summary_bytes = (RUN / 'normal-timing-summary.json').read_bytes()
require(summary_bytes.count(b'\n') == 1 and summary_bytes.endswith(b'\n'), 'one normal summary JSON line')
actual_summary = strict_json(summary_bytes)
for key, value in expected_ledger.items():
    require(actual_summary[key] == value, 'summary ledger field ' + key)
require(actual_summary['record_position_counts'] == expected_positions, 'summary record positions')
required_flags = {'validation': 'passed', 'mode': 'timing_description', 'descriptive_only': True,
                  'producer_completed': True, 'timing_rows': 54, 'main_wall_conservation_exact': True,
                  'record_positions_are_call_boundary_allocations_only': True,
                  'causal_overhead_identified': False, 'long_tails_removed': 0,
                  'quantile_rule': 'floor(percentile*(count-1)/100+1/2),no_interpolation',
                  'mad_rule': 'same_p50_of_absolute_deviations_from_p50', 'mean_decimal_places': 12,
                  'mean_is_display_only': True, 'iid_asserted': False, 'stationarity_asserted': False,
                  'physical_precision_certified': False, 'r02_signed_off': False, 'r04_signed_off': False}
for key, value in required_flags.items():
    require(actual_summary[key] == value, 'normal summary flag ' + key)
require(set(actual_summary) == set(expected_ledger) | set(required_flags) | {'record_position_counts'},
        'unreviewed normal summary field')

parent_csv = (RUN / 'parent-loss-timing.csv').read_bytes()
parent_summary_bytes = (RUN / 'parent-loss-timing-summary.json').read_bytes()
require(parent_csv == b'', 'interrupted CSV stays empty')
require(parent_summary_bytes.count(b'\n') == 1 and parent_summary_bytes.endswith(b'\n'), 'one interrupted summary line')
parent_summary = strict_json(parent_summary_bytes)
require(parent_summary == {'validation': 'failed', 'mode': 'timing_description',
                           'reason': 'missing_summary_or_count_mismatch', 'line': 0, 'column': 0,
                           'timing_description': 'unknown', 'partial_or_unknown': True,
                           'r02_signed_off': False, 'r04_signed_off': False}, 'interrupted remains unknown')
execution = strict_json((RUN / 'execution.json').read_bytes())
require(execution['source_commit'] == '6b9fa923cdd4747f0f9fd38b86b4ab40f9dde680', 'execution source commit')
require(execution['formal_normal_description_runs'] == 1 and execution['partial_unknown_rejection_runs'] == 1,
        'recorded C case counts')
require(len(execution['commands']) == 2, 'recorded C command count')
require([(item['case'], item['exit_code'], item['C_process_started']) for item in execution['commands']]
        == [('normal', 0, True), ('parent-loss', 1, True)], 'recorded C exit states')
binary = Path(execution['commands'][0]['argv'][0])
require(binary == Path(execution['commands'][1]['argv'][0]), 'same ordinary binary for two cases')
require(digest(binary.read_bytes()) == execution['ordinary_binary_sha256'], 'ordinary binary identity')
require(digest(C_SOURCE.read_bytes()) == execution['source_sha256'], 'C source identity')
require(digest(CMAKE.read_bytes()) == execution['CMake_sha256'], 'CMake identity')
require(digest(PLAN.read_bytes()) == execution['plan_sha256'], 'plan identity')
for item in execution['commands']:
    require(digest((RUN / item['stdout_file']).read_bytes()) == item['stdout_sha256'], 'recorded stdout identity')
    require(digest((RUN / item['stderr_file']).read_bytes()) == item['stderr_sha256'], 'recorded stderr identity')
earlier = strict_json((RUN.parent / 'analysis-run-6b9fa92/execution.json').read_bytes())
require(earlier['C_process_started'] is False and earlier['commands'] == []
        and earlier['formal_normal_description_runs'] == 0 and earlier['partial_unknown_rejection_runs'] == 0
        and earlier['status'] == 'launch_rejected_before_C_process_started', 'earlier recorded launch rejection')
require(RAW.read_bytes() == raw_bytes and EMPTY.read_bytes() == empty_bytes, 'raw bytes unchanged by oracle')

identities = {'raw_normal': RAW, 'raw_parent_loss': EMPTY, 'C_source': C_SOURCE, 'CMake': CMAKE,
              'frozen_plan': PLAN, 'normal_CSV': RUN / 'normal-timing.csv',
              'normal_JSON': RUN / 'normal-timing-summary.json', 'parent_loss_CSV': RUN / 'parent-loss-timing.csv',
              'parent_loss_JSON': RUN / 'parent-loss-timing-summary.json', 'ordinary_binary': binary,
              'execution_record': RUN / 'execution.json', 'earlier_execution_record': RUN.parent / 'analysis-run-6b9fa92/execution.json',
              'oracle_source': Path(__file__)}
verification = {'status': 'passed', 'review_kind': 'independent_standard_library_integer_fraction_cross_reference',
                'reviewer': 'timing_precision_audit', 'external_codex_review': 'pending',
                'source_commit': execution['source_commit'], 'new_C_description_runs_by_oracle': 0,
                'new_cryptographic_calls': 0, 'new_hardware_collection': False, 'ssh_used': False,
                'original_input_lines_checked': input_line_count, 'all_original_decaps_checked': len(calls),
                'raw_clock_values_checked_in_event_order': raw_clock_values_checked,
                'thread_clock_values_checked_in_event_order': thread_clock_values_checked,
                'description_rows_checked': len(actual_rows), 'integer_CSV_fields_checked': integer_fields_checked,
                'grouping_fields_per_row_checked': 4, 'mean_display_rows_checked': 54,
                'mean_authority': 'exact sum_elapsed_ns/count; decimal display only',
                'mean_display_allowance': 'half binary64 ULP at exact mean plus half 10^-12 ns; not physical precision',
                'maximum_mean_absolute_error_ns_exact': str(maximum_mean_absolute_error),
                'maximum_mean_display_allowance_ns_exact': str(maximum_mean_display_allowance),
                'quantile_reference': 'Fraction rank floor(p*(n-1)+1/2); upper median, no interpolation',
                'main_quarter_boundaries': quarter_boundaries, 'main_ledger': expected_ledger,
                'record_position_counts': expected_positions, 'normal_all': expected_rows[9],
                'warmup_all': expected_rows[0], 'main_quarters_all': [expected_rows[18 + index * 9] for index in range(4)],
                'parent_loss_remains_unknown': True, 'raw_bytes_unchanged': True,
                'earlier_launch_rejection_interpretation': 'record says EACCES before process creation; not a completed or failed C numerical run',
                'causal_overhead_identified': False, 'iid_asserted': False, 'stationarity_asserted': False,
                'physical_precision_certified': False, 'r02_signed_off': False, 'r04_signed_off': False,
                'identities': {key: {'path': str(path), 'sha256': digest(path.read_bytes()), 'bytes': path.stat().st_size}
                               for key, path in identities.items()}}
(RUN / 'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': verification['status'], 'rows': len(actual_rows), 'calls': len(calls),
                  'normal_all': verification['normal_all'], 'main_ledger': expected_ledger,
                  'maximum_mean_absolute_error_ns_exact': str(maximum_mean_absolute_error)}, ensure_ascii=False))
