#!/bin/sh
set -eu
program=$1
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
"$program" --help > "$test_directory/help.txt"
test -s "$test_directory/help.txt"
if "$program" unknown-command > "$test_directory/invalid-command.txt" 2>&1; then
    exit 1
else
    command_exit_code=$?
    test "$command_exit_code" -eq 2
fi
"$program" version
"$program" case
printf 'run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\nfixture,reference,valid,0,1000,ns\nfixture,reference,bit-flipped,1,2000,ns\nfixture,reference,random,2,3000,ns\n' > "$test_directory/data.csv"
zero_digest=$(printf '%064d' 0)
printf 'run_id=fixture\nimplementation=reference\nsample_count=3\nrun_status=complete\nsanitizers=OFF\nsource_commit=software_fixture\nordered_input_digest=%s\ntest_seed=1\nexecutable_digest=%s\nclock=CLOCK_MONOTONIC\ntime_unit=ns\nmeasurement_format=reference_ordinary_v1\nformal_attempted_calls=3\nformal_completed_calls=3\nwarmup_attempted_calls=100\nwarmup_completed_calls=100\noutputs_consumed=103\n' \
    "$zero_digest" "$zero_digest" > "$test_directory/data.meta"
cat > "$test_directory/complete.cost" <<'EOF'
cost_format=measurement_cost_v1
initial_state=started
run_id=fixture
final_state=complete
start_ns=100
preparation_end_ns=200
warmup_end_ns=300
collection_end_ns=6300
finish_ns=7000
child_total_wall_ns=6900
warmup_attempted_calls=100
warmup_completed_calls=100
formal_attempted_calls=3
formal_completed_calls=3
outputs_consumed=103
EOF
cp "$test_directory/complete.cost" "$test_directory/data.csv.cost"
"$program" export "$test_directory/data.csv" "$test_directory/data.meta" "$test_directory/result.html"
test -s "$test_directory/result.html"
if "$program" export "$test_directory/data.csv" "$test_directory/data.meta" "$test_directory/result.html"; then
    exit 1
fi
sed 's/run_status=complete/run_status=partial/' "$test_directory/data.meta" > "$test_directory/partial.meta"
if "$program" export "$test_directory/data.csv" "$test_directory/partial.meta" "$test_directory/partial.html"; then
    exit 1
fi
test ! -e "$test_directory/partial.html"
for replacement in 'clock=CLOCK_MONOTONIC/clock=CLOCK_REALTIME' \
    'time_unit=ns/time_unit=us' \
    'measurement_format=reference_ordinary_v1/measurement_format=unknown' \
    'formal_completed_calls=3/formal_completed_calls=2' \
    'warmup_completed_calls=100/warmup_completed_calls=99' \
    'outputs_consumed=103/outputs_consumed=102'; do
    sed "s/$replacement/" "$test_directory/data.meta" > "$test_directory/invalid.meta"
    if "$program" export "$test_directory/data.csv" "$test_directory/invalid.meta" "$test_directory/invalid.html"; then
        exit 1
    fi
    test ! -e "$test_directory/invalid.html"
done
for replacement in 'run_id=fixture/run_id=another-run' \
    'initial_state=started/initial_state=unknown' \
    'final_state=complete/final_state=partial' \
    'collection_end_ns=6300/collection_end_ns=6299' \
    'child_total_wall_ns=6900/child_total_wall_ns=6901' \
    'formal_completed_calls=3/formal_completed_calls=2' \
    'outputs_consumed=103/outputs_consumed=102'; do
    sed "s/$replacement/" "$test_directory/complete.cost" > "$test_directory/data.csv.cost"
    if "$program" export "$test_directory/data.csv" "$test_directory/data.meta" "$test_directory/invalid.html"; then
        exit 1
    fi
    test ! -e "$test_directory/invalid.html"
done
rm "$test_directory/data.csv.cost"
if "$program" export "$test_directory/data.csv" "$test_directory/data.meta" "$test_directory/missing-cost.html"; then
    exit 1
fi
test ! -e "$test_directory/missing-cost.html"
if "$program" collect bad-run invalid 3 "$test_directory/failed-collection"; then
    exit 1
fi
test ! -e "$test_directory/failed-collection/index.html"
mkdir "$test_directory/existing-calibration"
if "$program" calibrate "$test_directory/existing-calibration"; then
    exit 1
fi
test ! -e "$test_directory/existing-calibration/raw.csv"
test ! -e "$test_directory/existing-calibration/summary.report"
