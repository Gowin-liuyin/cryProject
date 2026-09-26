#!/bin/sh
set -eu
build_directory=${1:-build}
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
for implementation in reference vulnerable; do
    program="$build_directory/$implementation/measure"
    "$program" "check-$implementation" 42 10 "$test_directory/$implementation.csv" "$test_directory/$implementation.meta"
    if "$program" invalid 42 0 "$test_directory/zero.csv" "$test_directory/zero.meta" 2>/dev/null; then
        exit 1
    fi
    if "$program" invalid 42 20001 "$test_directory/large.csv" "$test_directory/large.meta" 2>/dev/null; then
        exit 1
    fi
    for invalid_run_id in '' 'bad,id' '12345678901234567890123456789012345678901234567890123456789012345'; do
        if "$program" "$invalid_run_id" 42 10 "$test_directory/bad.csv" "$test_directory/bad.meta" 2>"$test_directory/error.txt"; then
            exit 1
        else
            test "$?" -eq 2
        fi
        test -s "$test_directory/error.txt"
        test ! -e "$test_directory/bad.csv"
        test ! -e "$test_directory/bad.meta"
    done
    if "$program" duplicate 42 1 "$test_directory/$implementation.csv" "$test_directory/$implementation.meta" 2>/dev/null; then
        exit 1
    fi
done
"$build_directory/test_measurement" "$test_directory/reference.csv" "$test_directory/vulnerable.csv" 10
for corruption in '2s/,[0-9][0-9]*,ns$/,-1,ns/' '2s/,ns$/,ns trailing/' '3s/^[^,]*/different-run/' '2s/,[0-9][0-9]*,ns$/,18446744073709551616,ns/'; do
    sed "$corruption" "$test_directory/reference.csv" > "$test_directory/corrupt.csv"
    if "$build_directory/test_measurement" "$test_directory/corrupt.csv" "$test_directory/vulnerable.csv" 10 2>/dev/null; then
        exit 1
    fi
done
