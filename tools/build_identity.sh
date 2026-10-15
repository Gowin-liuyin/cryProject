#!/bin/sh
set -eu
output_header=$1
compiler_command=$2
configuration_file=$3
identity_text="$output_header.txt"
mkdir -p "$(dirname "$output_header")"
repository_directory=$(git rev-parse --show-toplevel 2>/dev/null || true)
is_git_source=no
if test "$repository_directory" = "$(pwd -P)"; then
    is_git_source=yes
elif test -s SOURCE_EXPORT.sha256; then
    shasum -a 256 -c SOURCE_EXPORT.sha256 >/dev/null
else
    printf 'Use the repository root or a verified source export with SOURCE_EXPORT.sha256.\n' >&2
    exit 1
fi
{
    if test "$is_git_source" = yes; then
        printf 'source_commit=%s\nsource_identity_kind=git_commit\n' "$(git rev-parse HEAD)"
    else
        export_digest=$(shasum -a 256 SOURCE_EXPORT.sha256 | cut -d ' ' -f 1)
        printf 'source_commit=%.40s\nsource_identity_kind=verified_source_export\nsource_export_manifest_sha256=%s\nsource_commit_field_note=export_digest_prefix_not_git_commit\n' \
            "$export_digest" "$export_digest"
    fi
    printf 'compiler_command=%s\n' "$compiler_command"
    cat "$configuration_file"
    "$compiler_command" --version | head -n 1
    printf 'git_worktree_status_begin\n'
    if test "$is_git_source" = yes; then
        git status --porcelain
    else
        printf 'not_available_for_source_export\n'
    fi
    printf 'git_worktree_status_end\ntracked_delta_sha256='
    if test "$is_git_source" = yes; then
        git diff HEAD --binary | shasum -a 256 | cut -d ' ' -f 1
    else
        printf 'not_applicable_source_export\n'
    fi
    printf 'build_input_manifest_begin\n'
    # vendor/liboqs-0.10.0 is an optional fetched snapshot (gitignored); its
    # integrity is pinned by vendor/liboqs-0.10.0.PIN.md archive SHA-256, not
    # by hashing every upstream file into every build identity.
    find src include vendor/mlkem-native docs/patches tools cmake -type f | LC_ALL=C sort | while IFS= read -r source_file; do
        shasum -a 256 "$source_file"
    done
    find vendor -maxdepth 1 -type f | LC_ALL=C sort | while IFS= read -r source_file; do
        shasum -a 256 "$source_file"
    done
    shasum -a 256 Makefile CMakeLists.txt CMakePresets.json "$configuration_file"
    compile_commands_file=$(sed -n 's/^compile_commands=//p' "$configuration_file")
    if test -f "$compile_commands_file"; then
        shasum -a 256 "$compile_commands_file"
    fi
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
