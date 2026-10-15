#!/bin/sh
set -eu
program=$1
input_directory=$2
label_program=$3
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
mkdir "$test_directory/missing-cost"
cp "$input_directory/ordinary-reference-block1.csv" "$test_directory/missing-cost/"
cp "$input_directory/ordinary-reference-block1.meta" "$test_directory/missing-cost/"
if "$program" --reference-labels "$test_directory/missing-cost" "$test_directory/failed"; then
    exit 1
fi
test ! -e "$test_directory/failed/summary.report"
cp "$input_directory/ordinary-reference-block1.csv.cost" "$test_directory/missing-cost/"
sed 's/final_state=complete/final_state=partial/' \
    "$input_directory/ordinary-reference-block1.csv.cost" \
    > "$test_directory/missing-cost/ordinary-reference-block1.csv.cost"
if "$program" --reference-labels "$test_directory/missing-cost" "$test_directory/bad-cost"; then
    exit 1
fi
test ! -e "$test_directory/bad-cost/summary.report"
test "$(wc -l < "$test_directory/bad-cost/selected.csv")" -eq 1
test "$(wc -l < "$test_directory/bad-cost/raw.csv")" -eq 1
if "$label_program" label-control "$test_directory/missing-cost/ordinary-reference-block1.csv" \
    1 "$test_directory/invalid-labels.csv" "$test_directory/invalid-labels.plan"; then
    exit 1
fi
test ! -e "$test_directory/invalid-labels.csv"
test ! -e "$test_directory/invalid-labels.plan"
"$label_program" label-control "$input_directory/ordinary-reference-block1.csv" \
    1 "$test_directory/valid-labels.csv" "$test_directory/valid-labels.plan"
test "$(wc -l < "$test_directory/valid-labels.csv")" -eq 21
if "$program" --reference-labels "$input_directory" "$test_directory/failed"; then
    exit 1
fi
