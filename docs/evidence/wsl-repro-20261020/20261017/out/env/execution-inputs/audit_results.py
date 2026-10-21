#!/usr/bin/env python3
"""Read-only audit of raw data; writes only audit outputs under out/audit/."""
import collections
import csv
import datetime
import hashlib
import json
import math
import pathlib
import re
import subprocess
import sys

work = pathlib.Path(sys.argv[1])
mode = sys.argv[2]
samples, repeats = (2000, 1) if mode == 'quick' else (20000, 3)
out = work / 'out'
audit = out / 'audit'
audit.mkdir(exist_ok=True)
issues = []
records = []
groups = collections.defaultdict(list)
external_statuses = collections.Counter()
expected_arms = ([f'm1-{v}-{o}' for v in ('unfixed', 'fixed') for o in ('O0', 'O2', 'O3', 'Os')]
                 + [f'm5-{o}' for o in ('O0', 'O2', 'O3', 'Os', 'O2default')]
                 + ['m2-unfixed', 'm2-fixed', 'm4-vulnerable', 'm4-ct'])
expected_names = {f'{a}-s{s}-r{r}' for a in expected_arms for s in (31337, 424242, 7) for r in range(1, repeats + 1)}
paths = sorted(p for p in (out / 'raw').glob('*.csv') if not p.name.startswith('dudect-'))
found = {p.stem for p in paths}
if found != expected_names:
    issues.append({'file_set': {'missing': sorted(expected_names-found), 'extra': sorted(found-expected_names)}})
total_rows = 0
max_delta_difference = 0.0
max_se_difference = 0.0
digest_cache = {}
historical_binary_matches = []
evidence_file = out/'env'/'build-evidence'/'binary-digests.json'
recorded_digests = {entry['path']:entry['sha3_256'] for entry in json.loads(evidence_file.read_text())} if evidence_file.exists() else {}
for path in paths:
    counts = collections.Counter()
    sums = collections.Counter()
    squares = collections.Counter()
    maxima = collections.Counter()
    minima = {}
    nrows = 0
    row_errors = 0
    with path.open() as f:
        for i, row in enumerate(csv.DictReader(f)):
            category = row['input_category']
            value = int(row['elapsed_nanoseconds'])
            if row['run_id'] != path.stem or row['time_unit'] != 'ns' or value < 0 or int(row['sample_index']) != i:
                row_errors += 1
            counts[category] += 1
            sums[category] += value
            squares[category] += value * value
            maxima[category] = max(maxima[category], value)
            minima[category] = min(minima.get(category, value), value)
            nrows += 1
    is_m4 = path.stem.startswith('m4-')
    categories = {'mismatch-first', 'mismatch-last'} if is_m4 else {'valid', 'bit-flipped', 'random', 'message-zero', 'message-ones'}
    if set(counts) != categories or any(n != samples for n in counts.values()) or row_errors:
        issues.append({'raw_file': path.name, 'counts': dict(counts), 'row_errors': row_errors})
    total_rows += nrows
    c0, c1 = ('mismatch-first', 'mismatch-last') if is_m4 else ('message-zero', 'message-ones')
    means = {c: sums[c] / counts[c] for c in (c0, c1)}
    # Integer arithmetic until division; independent from C Welford and original Python analyzer.
    variances = {c: (counts[c]*squares[c] - sums[c]**2) / (counts[c]*(counts[c]-1)) for c in (c0, c1)}
    delta = means[c0] - means[c1]
    se = math.sqrt(sum(variances[c] / counts[c] for c in (c0, c1)))
    statpath = out / 'stats' / 'runs' / path.stem / 'ci_welch.json'
    battery_path = statpath.with_name('summary.json')
    if battery_path.exists():
        battery = json.loads(battery_path.read_text())
        external_statuses[battery['rtlf']['status']] += 1
    if not statpath.exists():
        issues.append({'missing_stats': path.stem})
    else:
        stats = json.loads(statpath.read_text())
        dd = abs(delta - stats['mean_difference_class0_minus_class1_ns'])
        sd = abs(se - stats['standard_error_ns'])
        max_delta_difference = max(max_delta_difference, dd)
        max_se_difference = max(max_se_difference, sd)
        if dd > 1e-5 or sd > max(1e-5, se*1e-9) or stats['dropped_tail_count'] != 0 or stats['class0_count'] != samples or stats['class1_count'] != samples:
            issues.append({'stats_mismatch': path.stem, 'delta_error_ns': dd, 'se_error_ns': sd})
    if not is_m4 and not path.with_suffix('.meta').exists():
        issues.append({'missing_meta': path.stem})
    elif not is_m4:
        meta = dict(line.split('=',1) for line in path.with_suffix('.meta').read_text().splitlines() if '=' in line)
        arm_name = re.sub(r'-s\d+-r\d+$','',path.stem)
        if arm_name.startswith('m1-'):
            executable = work/'build'/arm_name/'historical'/'measure'
        elif arm_name.startswith('m2-'):
            executable = work/'build'/'platform'/'platform-m2'/arm_name.split('-')[1]/'measure'
        elif arm_name == 'm5-O2default':
            executable = work/'build'/'platform'/'reference'/'measure'
        else:
            executable = work/'build'/arm_name/'reference'/'measure'
        if executable not in digest_cache:
            digest_cache[executable] = hashlib.sha3_256(executable.read_bytes()).hexdigest()
        if meta.get('executable_digest') != digest_cache[executable]:
            # QUICK was independently audited before adding optional KAT targets.
            # Preserve and disclose the old build identity; full runs require the live binary.
            historical = recorded_digests.get(str(executable.relative_to(work)))
            if mode == 'quick' and historical == meta.get('executable_digest'):
                historical_binary_matches.append({'run':path.stem,'sha3_256':historical,'evidence':'env/build-evidence/binary-digests.json','reason':'platform reconfigured after collection to enable M2 public KAT'})
            else:
                issues.append({'binary_digest_mismatch':path.stem})
    record = {'run': path.stem, 'rows': nrows, 'class_counts': dict(counts), 'mean_class0_ns': means[c0], 'mean_class1_ns': means[c1], 'delta_ns': delta, 'se_ns': se, 'min_ns': minima, 'max_ns': dict(maxima), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    records.append(record)
    arm = re.sub(r'-s\d+-r\d+$', '', path.stem)
    groups[arm].append(record)

pooled = {}
for arm, runs in groups.items():
    eligible = [r for r in runs if r['se_ns'] > 0]
    sw = sum(1/r['se_ns']**2 for r in eligible)
    d = sum(r['delta_ns']/r['se_ns']**2 for r in eligible)/sw
    se = 1/math.sqrt(sw)
    pooled[arm] = {'runs': len(runs), 'delta_ns': d, 'se_ns': se, 'ci95': [d-1.96*se, d+1.96*se], 'positive_runs': sum(r['delta_ns'] > 0 for r in runs), 'negative_runs': sum(r['delta_ns'] < 0 for r in runs), 'zero_runs': sum(r['delta_ns'] == 0 for r in runs)}

perf_records = []
perf_paths = sorted((out/'perf').glob('*.csv'))
expected_perf = {f'perf-{a}-b{b}' for a in ('m1unfixed','m1fixed','m5ref') for b in range(1,5)}
if {p.stem for p in perf_paths} != expected_perf:
    issues.append({'performance_file_set_mismatch': True})
for path in perf_paths:
    count = collections.Counter()
    elapsed_sums = collections.Counter()
    row_errors = 0
    with path.open() as f:
        for row in csv.DictReader(f):
            c = row['input_category']
            if row['run_id'] != path.stem or row['time_unit'] != 'ns' or int(row['sample_index']) != count[c] or int(row['elapsed_nanoseconds']) < 0:
                row_errors += 1
            count[c] += 1
            elapsed_sums[c] += int(row['elapsed_nanoseconds'])
    if count != {'decaps':25000, 'keygen':5000, 'encaps':5000} or row_errors:
        issues.append({'perf_file':path.name,'counts':dict(count),'row_errors':row_errors})
    metapath = path.with_suffix('.meta')
    if not metapath.exists():
        issues.append({'missing_perf_meta':path.stem})
    else:
        perf_meta = dict(line.split('=',1) for line in metapath.read_text().splitlines() if '=' in line)
        perf_arm = re.sub(r'^perf-|-b\d+$','',path.stem)
        perf_executable = work/'build'/f'perf-{perf_arm}'
        if perf_meta.get('executable_sha256') != hashlib.sha256(perf_executable.read_bytes()).hexdigest() or perf_meta.get('run_status') != 'complete' or perf_meta.get('long_tail_trimmed') != 'no':
            issues.append({'perf_identity_or_status_mismatch':path.stem})
    perf_records.append({'run':path.stem,'counts':dict(count),'means_ns':{c:elapsed_sums[c]/count[c] for c in count},'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

expected_dudect = {'dudect-m1-unfixed-Os.log','dudect-m1-fixed-Os.log','dudect-m5.log','dudect-m4-vulnerable.log','dudect-m4-ct.log'}
if {p.name for p in (out/'raw').glob('dudect-*.log')} != expected_dudect:
    issues.append({'dudect_logs_mismatch':True})
dudect_records = []
for name in sorted(expected_dudect):
    logpath = out/'raw'/name
    if not logpath.exists():
        continue
    log = logpath.read_text()
    terms = [line for line in log.splitlines() if line.startswith(('stopped_after_batches=', 'completed_batches=', 'battery_dudect_status='))]
    if not terms:
        issues.append({'missing_dudect_terminal_record':name})
    record = {'log':name,'terminal_records':terms}
    rawpath = logpath.with_suffix('.csv')
    if 'm4-' in name or name == 'dudect-m5.log':
        if not rawpath.exists():
            issues.append({'missing_dudect_raw':name})
        else:
            data = rawpath.read_bytes()
            rows = data.count(b'\n')-1
            if 'm4-' in name:
                expected = 10*19999
            else:
                expected = int(re.search(r'stopped_after_batches=(\d+)',log).group(1))*10000
            if rows != expected:
                issues.append({'dudect_row_count':name,'rows':rows,'expected':expected})
            record.update({'raw_rows':rows,'raw_sha256':hashlib.sha256(data).hexdigest()})
    dudect_records.append(record)
ctest = (out/'stats'/'ctest_summary.txt').read_text().strip().splitlines()
if len(ctest) != 3 or any('0 tests failed' not in l for l in ctest):
    issues.append({'ctest':ctest})
platform_ctest = (out/'logs'/'ctest-platform.log').read_text()
kat_passes = [l for l in platform_ctest.splitlines() if 'public_kat' in l and 'Passed' in l]
if mode == 'full' and len(kat_passes) != 2:
    issues.append({'M2_public_KAT_passes':kat_passes})
git_head = subprocess.check_output(['git','-C',str(work/'repo'),'rev-parse','HEAD'],text=True).strip()
git_status = subprocess.check_output(['git','-C',str(work/'repo'),'status','--porcelain'],text=True)
expected_untracked = '?? vendor/liboqs-0.10.0-982c762/'
unexpected_status = [line for line in git_status.splitlines() if line != expected_untracked]
if git_head != '04baad45ebb5ea4dba8d143d64c5031c906503d2' or unexpected_status:
    issues.append({'repository_identity':git_head,'status':git_status})
error_text = (out/'ERRORS.tsv').read_text() if (out/'ERRORS.tsv').exists() else ''
summary = {'status':'PASS' if not issues else 'FAIL','mode':mode,'samples_per_class':samples,'seeds':[31337,424242,7],'repeats':repeats,'ordinary_files':len(paths),'ordinary_rows':total_rows,'performance_files':len(perf_paths),'performance_rows':sum(sum(r['counts'].values()) for r in perf_records),'dudect_log_count':len(expected_dudect),'dudect':dudect_records,'M2_public_KAT_passes':kat_passes,'max_delta_difference_ns':max_delta_difference,'max_se_difference_ns':max_se_difference,'git_head':git_head,'git_status':git_status,'ctest':ctest,'recorded_errors':error_text,'issues':issues,'pooled':pooled}
summary['historical_binary_matches'] = historical_binary_matches
summary['rtlf_status_counts'] = dict(external_statuses)
if (audit/'validation.json').exists():
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    (audit/f'validation-before-{stamp}.json').write_bytes((audit/'validation.json').read_bytes())
(audit/'validation.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
(audit/'raw-manifest.json').write_text(json.dumps({'ordinary':records,'performance':perf_records},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k != 'pooled'},ensure_ascii=False,indent=2))
sys.exit(0 if not issues else 1)
