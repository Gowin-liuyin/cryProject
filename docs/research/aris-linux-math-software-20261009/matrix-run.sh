#!/bin/sh
set -u

if [ "$#" -ne 2 ]; then
    printf '%s\n' 'usage: sh remote-run.sh ROOT_STAGE NEW_OUTPUT_ROOT' >&2
    exit 2
fi
case "$1" in
    /*) ;;
    *) exit 2 ;;
esac
case "$2" in
    /*) ;;
    *) exit 2 ;;
esac
stage_root=$(realpath -e -- "$1") || exit 2
output_root=$(realpath -m -- "$2") || exit 2
case "$stage_root" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf '%s\n' 'stage must be inside the fixed bare-metal work root' >&2; exit 2 ;;
esac
case "$output_root" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf '%s\n' 'output must be inside the fixed bare-metal work root' >&2; exit 2 ;;
esac
case "$output_root/" in
    "$stage_root/"*) printf '%s\n' 'output must be outside the read-only stage' >&2; exit 2 ;;
esac
test "$(uname -s)" = 'Linux' || exit 2
test "$(uname -m)" = 'x86_64' || exit 2
test ! -e "$output_root" || exit 2
mkdir "$output_root" || exit 2
trap 'printf "%s\n" "state=partial reason=signal" >> "$output_root/matrix-status.txt"; exit 143' TERM INT
unset CC CFLAGS CPPFLAGS LDFLAGS
umask 077
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$output_root/start-utc.txt" || exit 2
uname -a > "$output_root/uname.txt" || exit 2
hostname > "$output_root/hostname.txt" || exit 2
cmake --version > "$output_root/cmake-version.txt" || exit 2
ctest --version > "$output_root/ctest-version.txt" || exit 2
printf '%s\n' 'scope=software_only_archived_macos_rows' \
    'new_timing_collection_launches=0' 'failure_path_fixture=original_ctest_only' \
    'cryptographic_calls=0' 'build_jobs_maximum=2' \
    'wall_timeout_seconds=595 kill_grace_seconds=5' > "$output_root/scope.txt"
(
    cd "$stage_root" && find . \( -type f -o -type l \) | LC_ALL=C sort \
        > "$output_root/stage-before-paths.txt"
) || exit 1
cmp "$stage_root/STAGE_PATHS.txt" "$output_root/stage-before-paths.txt" \
    > "$output_root/stage-before-inventory.log" 2>&1 || exit 1
(
    cd "$stage_root" && sha256sum -c STAGE_SHA256SUMS
) > "$output_root/stage-before.log" 2>&1 || exit 1

record_binary()
(
    set -eu
    metadata_binary_path=$1
    metadata_binary_name=$(basename "$metadata_binary_path")
    sha256sum "$metadata_binary_path" > "$cell_root/$metadata_binary_name-sha256.txt"
    ldd "$metadata_binary_path" > "$cell_root/$metadata_binary_name-ldd.txt" 2>&1
    nm --defined-only "$metadata_binary_path" > "$cell_root/$metadata_binary_name-symbols.txt" 2>&1
)

failed_cells=0
for compiler_name in gcc-13 clang-18; do
    compiler_path=$(command -v "$compiler_name") || exit 2
    "$compiler_path" --version > "$output_root/$compiler_name-version.txt" 2>&1 || exit 2
    for check_mode in normal sanitize; do
        cell_root="$output_root/$compiler_name-$check_mode"
        mkdir "$cell_root" || exit 2
        if [ "$check_mode" = 'sanitize' ]; then
            sanitizers=ON
            audit_c_flags='-fsanitize=address,undefined -fno-omit-frame-pointer'
            audit_link_flags='-fsanitize=address,undefined'
        else
            sanitizers=OFF
            audit_c_flags=''
            audit_link_flags=''
        fi
        (
            set -eu
            cmake -S "$stage_root/math-source" -B "$cell_root/collector" \
                -G 'Unix Makefiles' -DCMAKE_C_COMPILER="$compiler_path" \
                -DBUILD_TESTING=ON -DUPDATE_COST_SANITIZERS="$sanitizers" \
                > "$cell_root/collector-configure.log" 2>&1
            cmake --build "$cell_root/collector" --parallel 2 --verbose \
                > "$cell_root/collector-build.log" 2>&1
            record_binary "$cell_root/collector/update_cost"
            ctest --test-dir "$cell_root/collector" --stop-on-failure --output-on-failure --verbose \
                > "$cell_root/collector-ctest.log" 2>&1
            cmake -S "$stage_root/summary-source" -B "$cell_root/summary" \
                -G 'Unix Makefiles' -DCMAKE_C_COMPILER="$compiler_path" \
                -DBUILD_TESTING=ON -DSUMMARY_SANITIZERS="$sanitizers" \
                > "$cell_root/summary-configure.log" 2>&1
            cmake --build "$cell_root/summary" --parallel 2 --verbose \
                > "$cell_root/summary-build.log" 2>&1
            record_binary "$cell_root/summary/process_summary"
            ctest --test-dir "$cell_root/summary" --stop-on-failure --output-on-failure --verbose \
                > "$cell_root/summary-ctest.log" 2>&1
            cmake -S "$stage_root/math-source/audit" -B "$cell_root/audit" \
                -G 'Unix Makefiles' -DCMAKE_C_COMPILER="$compiler_path" \
                -DBUILD_TESTING=ON -DCMAKE_C_FLAGS="$audit_c_flags" \
                -DCMAKE_EXE_LINKER_FLAGS="$audit_link_flags" \
                > "$cell_root/audit-configure.log" 2>&1
            cmake --build "$cell_root/audit" --parallel 2 --verbose \
                > "$cell_root/audit-build.log" 2>&1
            record_binary "$cell_root/audit/update_cost_result_review"
            ctest --test-dir "$cell_root/audit" --stop-on-failure --output-on-failure --verbose \
                > "$cell_root/audit-ctest.log" 2>&1
            cmake -S "$stage_root/verification" -B "$cell_root/readonly" \
                -DAUDITOR="$cell_root/audit/update_cost_result_review" \
                -DSUMMARY="$cell_root/summary/process_summary" \
                -DM02_ROOT="$stage_root/m02-frozen" \
                -DINPUT_ROOT="$stage_root/m02-frozen/preparation/fixed-inputs" \
                -DOUTPUT_ROOT="$cell_root/recomputed-json" \
                > "$cell_root/readonly-configure.log" 2>&1
            ctest --test-dir "$cell_root/readonly" --stop-on-failure --output-on-failure --verbose \
                > "$cell_root/readonly-ctest.log" 2>&1
        ) > "$cell_root/cell-stdout.log" 2> "$cell_root/cell-stderr.log"
        cell_status=$?
        printf 'exit_status=%s\n' "$cell_status" > "$cell_root/status.txt"
        if [ "$cell_status" -ne 0 ]; then
            failed_cells=$((failed_cells + 1))
        fi
    done
done
(
    cd "$stage_root" && find . \( -type f -o -type l \) | LC_ALL=C sort \
        > "$output_root/stage-after-paths.txt"
) || exit 1
cmp "$stage_root/STAGE_PATHS.txt" "$output_root/stage-after-paths.txt" \
    > "$output_root/stage-after-inventory.log" 2>&1 || exit 1
(
    cd "$stage_root" && sha256sum -c STAGE_SHA256SUMS
) > "$output_root/stage-after.log" 2>&1 || exit 1
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$output_root/end-utc.txt"
printf 'state=complete failed_cells=%s\n' "$failed_cells" > "$output_root/matrix-status.txt"
if [ "$failed_cells" -ne 0 ]; then
    exit 1
fi
