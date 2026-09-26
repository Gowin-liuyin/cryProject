#!/bin/sh
set -eu
build_directory=${1:-build}
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
for implementation in reference vulnerable; do
    program="$build_directory/$implementation/measure"
    "$program" "check-$implementation" 42 10 "$test_directory/$implementation.csv" "$test_directory/$implementation.meta"
    if "$program" invalid 42 0 "$test_directory/zero.csv" "$test_directory/zero.meta" 2>/dev/null; then exit 1; fi
    if "$program" invalid 42 20001 "$test_directory/large.csv" "$test_directory/large.meta" 2>/dev/null; then exit 1; fi
    if "$program" 'bad,id' 42 10 "$test_directory/bad.csv" "$test_directory/bad.meta" 2>/dev/null; then exit 1; fi
    if "$program" duplicate 42 1 "$test_directory/$implementation.csv" "$test_directory/$implementation.meta" 2>/dev/null; then exit 1; fi
done
"$build_directory/test_measurement" "$test_directory/reference.csv" "$test_directory/vulnerable.csv" 10
