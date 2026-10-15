#!/bin/sh
set -eu
if test "$#" -ne 3; then
    printf 'Usage: %s ANALYZER SEALED_DIRECTORY NEW_REPORT_FILE\n' "$0" >&2
    exit 2
fi
analyzer_program=$1
sealed_directory=$2
report_path=$3
test ! -e "$report_path"
test -f "$sealed_directory/SHA256SUMS"
(
    cd "$sealed_directory"
    shasum -a 256 -c SHA256SUMS
)
"$analyzer_program" "$sealed_directory" "$report_path"
