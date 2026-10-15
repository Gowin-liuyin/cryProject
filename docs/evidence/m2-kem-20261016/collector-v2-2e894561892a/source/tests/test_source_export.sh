#!/bin/sh
set -eu
identity_script=$1
compiler_command=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
mkdir -p "$test_directory/src" "$test_directory/include" "$test_directory/vendor" \
    "$test_directory/docs/patches" "$test_directory/tools" "$test_directory/cmake"
printf 'source fixture\n' > "$test_directory/src/fixture.c"
touch "$test_directory/Makefile" "$test_directory/CMakeLists.txt" "$test_directory/CMakePresets.json"
printf 'compile_commands=not_available\n' > "$test_directory/configuration.txt"
cd "$test_directory"
shasum -a 256 src/fixture.c > SOURCE_EXPORT.sha256
sh "$identity_script" "$test_directory/identity.h" "$compiler_command" "$test_directory/configuration.txt"
test "$(sed -n 's/^source_identity_kind=//p' "$test_directory/identity.h.txt")" = verified_source_export
test "$(sed -n 's/^source_commit_field_note=//p' "$test_directory/identity.h.txt")" = export_digest_prefix_not_git_commit
printf 'changed\n' >> src/fixture.c
if sh "$identity_script" "$test_directory/tampered.h" "$compiler_command" "$test_directory/configuration.txt"; then
    exit 1
fi
test ! -e "$test_directory/tampered.h"
