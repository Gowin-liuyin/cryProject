#!/bin/sh
set -eu
output_header=$1
compiler_command=$2
compiler_flags=$3
identity_text="$output_header.txt"
mkdir -p "$(dirname "$output_header")"
{
    printf 'source_commit=%s\n' "$(git rev-parse HEAD)"
    printf 'compiler_command=%s\ncompiler_flags=%s\n' "$compiler_command" "$compiler_flags"
    printf 'measure_additional_flags=-I%s\n' "$(dirname "$output_header")"
    printf 'vulnerable_additional_flags=-DBASELINE_VULNERABLE=1\n'
    printf 'vulnerable_kernel_include=-I%s/vulnerable/mlkem\n' "$(dirname "$output_header")"
    "$compiler_command" --version | head -n 1
    printf 'git_worktree_status_begin\n'
    git status --porcelain
    printf 'git_worktree_status_end\ntracked_delta_sha256='
    git diff HEAD --binary | shasum -a 256 | cut -d ' ' -f 1
    printf 'build_input_manifest_begin\n'
    find src include vendor docs/patches tools -type f | LC_ALL=C sort | while IFS= read -r source_file; do
        shasum -a 256 "$source_file"
    done
    shasum -a 256 Makefile
    printf 'build_input_manifest_end\n'
} > "$identity_text"
{
    printf '#ifndef BASELINE_BUILD_IDENTITY_H\n#define BASELINE_BUILD_IDENTITY_H\nstatic const char *const build_identity_lines[] = {\n'
    awk '{gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "\"%s\\n\",\n", $0}' "$identity_text"
    printf '};\n#endif\n'
} > "$output_header.new"
if test -f "$output_header" && cmp -s "$output_header" "$output_header.new"; then
    rm "$output_header.new"
else
    mv "$output_header.new" "$output_header"
fi
