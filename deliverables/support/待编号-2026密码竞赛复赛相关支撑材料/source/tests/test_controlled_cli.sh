#!/bin/sh
set -eu
program=$1
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
for scenario in null effect ties drift dependent; do
    "$program" generate "$scenario" 202610079001 "$test_directory/$scenario.csv" "$test_directory/$scenario.plan"
    "$program" analyze "$test_directory/$scenario.csv" "$test_directory/$scenario.plan" "$test_directory/$scenario.report"
    test "$(sed -n 's/^report_status=//p' "$test_directory/$scenario.report")" = complete
done
test "$(sed -n 's/^result_status=//p' "$test_directory/dependent.report")" = evidence_insufficient
test "$(sed -n 's/^result_status=//p' "$test_directory/ties.report")" = evidence_insufficient
test "$(sed -n 's/^interval_status=//p' "$test_directory/drift.report")" = unavailable
if "$program" analyze "$test_directory/null.csv" "$test_directory/null.plan" "$test_directory/null.report"; then
    exit 1
fi
printf 'truncated' >> "$test_directory/null.csv"
if "$program" analyze "$test_directory/null.csv" "$test_directory/null.plan" "$test_directory/bad.report"; then
    exit 1
fi
test ! -e "$test_directory/bad.report"
