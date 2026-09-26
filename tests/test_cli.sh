#!/bin/sh
set -eu
build_directory=${1:-build}
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
for implementation in reference vulnerable; do
    program="$build_directory/$implementation/baseline"
    "$program" version
    "$program" selftest
    "$program" demo
    for category in valid bit-flipped random message-zero message-ones; do
        "$program" generate-test "$category" 42 "$test_directory/$implementation-$category"
        "$program" decapsulate-test 42 "$test_directory/$implementation-$category"
    done
    if "$program" generate-test unknown 42 "$test_directory/no-file" 2>/dev/null; then exit 1; fi
    if "$program" generate-test valid -1 "$test_directory/no-file" 2>/dev/null; then exit 1; fi
    if "$program" generate-test valid 18446744073709551616 "$test_directory/no-file" 2>/dev/null; then exit 1; fi
    if "$program" generate-test valid 42 "$test_directory/$implementation-valid" 2>/dev/null; then exit 1; fi
    head -c 1087 "$test_directory/$implementation-valid" > "$test_directory/short"
    cat "$test_directory/$implementation-valid" "$test_directory/short" > "$test_directory/long"
    if "$program" decapsulate-test 42 "$test_directory/short" 2>/dev/null; then exit 1; fi
    if "$program" decapsulate-test 42 "$test_directory/long" 2>/dev/null; then exit 1; fi
done
for category in valid bit-flipped random message-zero message-ones; do
    cmp "$test_directory/reference-$category" "$test_directory/vulnerable-$category"
done
