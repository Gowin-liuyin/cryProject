#!/bin/sh
set -eu
build_directory=${1:-build}
test_scope=${2:-all}
case "$test_scope" in
    reference)
        implementation_names=reference
        input_categories='valid bit-flipped random'
        ;;
    all)
        implementation_names='reference vulnerable hardened deployable'
        input_categories='valid bit-flipped random message-zero message-ones'
        ;;
    *)
        exit 2
        ;;
esac
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
for implementation in $implementation_names; do
    program="$build_directory/$implementation/baseline"
    version_output=$("$program" version)
    test "$version_output" = "$implementation ML-KEM-768 FIPS203"
    printf '%s\n' "$version_output"
    "$program" selftest
    "$program" demo
    for category in $input_categories; do
        "$program" generate-test "$category" 42 "$test_directory/$implementation-$category"
        "$program" generate-test "$category" 42 "$test_directory/repeated-$implementation-$category"
        cmp "$test_directory/$implementation-$category" "$test_directory/repeated-$implementation-$category"
        "$program" decapsulate-test 42 "$test_directory/$implementation-$category"
    done
    if "$program" generate-test unknown 42 "$test_directory/no-file" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 2
    fi
    if "$program" generate-test valid -1 "$test_directory/no-file" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 2
    fi
    if "$program" generate-test valid 18446744073709551616 "$test_directory/no-file" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 2
    fi
    if "$program" generate-test valid 42 "$test_directory/$implementation-valid" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 1
    fi
    cmp "$test_directory/$implementation-valid" "$test_directory/repeated-$implementation-valid"
    head -c 1087 "$test_directory/$implementation-valid" > "$test_directory/short"
    cat "$test_directory/$implementation-valid" "$test_directory/short" > "$test_directory/long"
    if "$program" decapsulate-test 42 "$test_directory/short" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 1
    fi
    if "$program" decapsulate-test 42 "$test_directory/long" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 1
    fi
    if "$program" decapsulate-test 42 "$test_directory" 2>/dev/null; then
        exit 1
    else
        test "$?" -eq 1
    fi
done
if test "$test_scope" = all; then
    for category in $input_categories; do
        for variant in vulnerable hardened deployable; do
            cmp "$test_directory/reference-$category" "$test_directory/$variant-$category"
        done
    done
fi
