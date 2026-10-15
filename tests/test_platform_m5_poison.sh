#!/bin/sh
set -eu
program=$1
"$program" --self-test
if "$program" --poison; then
    printf '%s\n' 'Uninstrumented secret marking incorrectly succeeded' >&2
    exit 1
else
    status=$?
    if [ "$status" -ne 77 ]; then
        printf 'Expected unavailable status 77, got %s\n' "$status" >&2
        exit 1
    fi
fi
if "$program"; then
    printf '%s\n' 'Missing mode incorrectly succeeded' >&2
    exit 1
fi
