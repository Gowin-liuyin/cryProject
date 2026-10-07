#!/bin/sh
set -eu
comparison_program=$1
generator_program=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
mkdir "$test_directory/data"
for task_index in 1 2 3 4 5 6 7 8; do
    "$generator_program" generate null "$task_index" \
        "$test_directory/data/task-$task_index.csv" "$test_directory/data/task-$task_index.plan"
done
if "$comparison_program" "$generator_program" /usr/bin/false unused \
    "$test_directory/data" "$test_directory/failure"; then
    exit 1
fi
test -s "$test_directory/failure/attempts.tsv"
test ! -e "$test_directory/failure/comparison.report"
if "$comparison_program" "$generator_program" /usr/bin/false unused \
    "$test_directory/data" "$test_directory/failure"; then
    exit 1
fi
