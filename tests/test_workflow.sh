#!/bin/sh
set -eu
program=$1
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
"$program" version
"$program" case
printf 'run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\nfixture,reference,valid,0,1000,ns\nfixture,reference,bit-flipped,1,2000,ns\nfixture,reference,random,2,3000,ns\n' > "$test_directory/data.csv"
zero_digest=$(printf '%064d' 0)
printf 'run_id=fixture\nimplementation=reference\nsample_count=3\nrun_status=complete\nsanitizers=OFF\nsource_commit=software_fixture\nordered_input_digest=%s\ntest_seed=1\nexecutable_digest=%s\n' \
    "$zero_digest" "$zero_digest" > "$test_directory/data.meta"
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
if "$program" collect bad-run invalid 3 "$test_directory/failed-collection"; then
    exit 1
fi
test ! -e "$test_directory/failed-collection/index.html"
