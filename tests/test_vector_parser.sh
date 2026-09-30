#!/bin/sh
set -eu
build_directory=$1
vector_file=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
cp "$vector_file" "$test_directory/incomplete.txt"
printf 'keygen' >> "$test_directory/incomplete.txt"
sed '1s/[0-9][0-9]*/-1/' "$vector_file" > "$test_directory/negative-case.txt"
sed '1s/\([[:xdigit:]]\)[[:xdigit:]]\([[:xdigit:]]\{126\}\)/\1z\2/' "$vector_file" > "$test_directory/invalid-hex.txt"
for implementation in reference vulnerable hardened; do
    for invalid_file in "$test_directory"/*.txt; do
        if "$build_directory/$implementation/test_mlkem" "$invalid_file" >/dev/null 2>&1; then
            exit 1
        fi
    done
done
