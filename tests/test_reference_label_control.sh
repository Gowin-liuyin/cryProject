#!/bin/sh
set -eu
program=$1
input_directory=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
mkdir "$test_directory/missing-cost"
cp "$input_directory/ordinary-reference-block1.csv" "$test_directory/missing-cost/"
cp "$input_directory/ordinary-reference-block1.meta" "$test_directory/missing-cost/"
if "$program" --reference-labels "$test_directory/missing-cost" "$test_directory/failed"; then
    exit 1
fi
test ! -e "$test_directory/failed/summary.report"
if "$program" --reference-labels "$input_directory" "$test_directory/failed"; then
    exit 1
fi
