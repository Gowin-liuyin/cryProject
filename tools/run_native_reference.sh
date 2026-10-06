#!/bin/sh
set -eu
if test "$#" -ne 3; then
    printf 'Usage: %s FULL_SOURCE_COMMIT NEW_OUTPUT_DIRECTORY EXECUTION_NOTE_FILE\n' "$0" >&2
    exit 2
fi
expected_commit=$1
output_directory=$2
execution_note=$3
if test "$(uname -s)" != Linux || test "$(uname -m)" != x86_64; then
    printf 'Native x86_64 Linux is required; current platform is not a target result.\n' >&2
    exit 2
fi
if test "${NATIVE_X86_64_LINUX_CONFIRMED:-no}" != yes || test ! -s "$execution_note"; then
    printf 'Provide the host/virtualization/translation note and explicit native confirmation.\n' >&2
    exit 2
fi
source_directory=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$source_directory"
if test "$(git rev-parse HEAD)" != "$expected_commit"; then
    printf 'HEAD must equal the supplied full fixed source commit.\n' >&2
    exit 2
fi
git diff --quiet HEAD -- CMakeLists.txt CMakePresets.json Makefile src include tests tools cmake vendor docs/patches
if test -n "$(git ls-files --others --exclude-standard -- src include tests tools cmake vendor docs/patches)"; then
    printf 'Untracked build/test inputs are not allowed in a fixed-source run.\n' >&2
    exit 2
fi
for required_tool in cmake ctest cc git patch shasum awk openssl objdump file; do
    command -v "$required_tool" >/dev/null
done
mkdir "$output_directory"
output_directory=$(CDPATH= cd -- "$output_directory" && pwd)
finish_run() {
    final_status=$?
    if test "$final_status" -eq 0; then
        printf 'run_status=complete\n' > "$output_directory/status.txt"
    else
        printf 'run_status=partial\nexit_status=%s\n' "$final_status" > "$output_directory/status.txt"
    fi
}
trap finish_run EXIT
cp "$execution_note" "$output_directory/execution-note.txt"
printf 'step\texit_status\n' > "$output_directory/step-exits.tsv"
run_step() {
    step_name=$1
    shift
    {
        printf 'arguments_begin\n'
        printf '%s\n' "$@"
        printf 'arguments_end\n'
        date -u
    } > "$output_directory/$step_name.log"
    if "$@" >> "$output_directory/$step_name.log" 2>&1; then
        step_status=0
    else
        step_status=$?
    fi
    date -u >> "$output_directory/$step_name.log"
    printf '%s\t%s\n' "$step_name" "$step_status" >> "$output_directory/step-exits.tsv"
    if test "$step_status" -ne 0; then
        printf '%s failed; preserve partial output in %s\n' "$step_name" "$output_directory" >&2
        exit "$step_status"
    fi
}
{
    date -u
    uname -a
    cat /etc/os-release
    cat /proc/cpuinfo
    printf 'virtualization_detection_begin\n'
    if command -v systemd-detect-virt >/dev/null; then
        systemd-detect-virt || true
    else
        printf 'systemd-detect-virt=unavailable\n'
    fi
    if command -v lscpu >/dev/null; then
        lscpu
    fi
    if test -r /proc/sys/fs/binfmt_misc/status; then
        cat /proc/sys/fs/binfmt_misc/status
    fi
    cat /proc/self/status
    printf 'cpu_affinity=not_pinned_by_script\nfrequency_control=not_configured_by_script\n'
    printf 'background_load_control=not_configured_by_script\n'
    cc --version
    cmake --version
    openssl version
    git rev-parse HEAD
    git status --short
} > "$output_directory/environment.log" 2>&1
release_directory="$output_directory/build-release"
sanitize_directory="$output_directory/build-sanitize"
run_step release-configure cmake -S "$source_directory" -B "$release_directory" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
run_step release-build cmake --build "$release_directory" --target check-reference \
    reference_benchmark reference_batch_benchmark inspect_timing analyze_paired paired_runner \
    paired_prepare native_digest test_reference_benchmark test_timing_diagnostics \
    test_batch_measurement test_paired_statistics test_paired_data test_paired_rejections \
    test_paired_runner test_paired_prepare test_native_digest paired_worker_fixture --parallel 4
run_step release-test ctest --test-dir "$release_directory" --output-on-failure \
    -R '^(reference_benchmark|timing_diagnostics|batch_measurement|paired_statistics|paired_data|paired_rejections|paired_runner|paired_prepare|native_digest)$'
run_step sanitize-configure cmake -S "$source_directory" -B "$sanitize_directory" \
    -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=ON
run_step sanitize-build cmake --build "$sanitize_directory" --target check-reference \
    reference_benchmark reference_batch_benchmark inspect_timing analyze_paired paired_runner \
    paired_prepare native_digest test_reference_benchmark test_timing_diagnostics \
    test_batch_measurement test_paired_statistics test_paired_data test_paired_rejections \
    test_paired_runner test_paired_prepare test_native_digest paired_worker_fixture --parallel 4
run_step sanitize-test ctest --test-dir "$sanitize_directory" --output-on-failure \
    -R '^(reference_benchmark|timing_diagnostics|batch_measurement|paired_statistics|paired_data|paired_rejections|paired_runner|paired_prepare|native_digest)$'
run_step executable-type file "$release_directory/reference/benchmark"
run_step disassembly objdump -d "$release_directory/reference/benchmark"
for test_seed in 20261006 20261007 20261008; do
    run_step "collect-$test_seed" "$release_directory/reference/benchmark" \
        "ordinary-native-$test_seed" "$test_seed" 1000 \
        "$output_directory/$test_seed.csv" "$output_directory/$test_seed.meta"
    run_step "summary-$test_seed" "$release_directory/inspect_timing" \
        "$output_directory/$test_seed.csv" "$output_directory/$test_seed.summary"
    run_step "executable-digest-$test_seed" openssl dgst -sha3-256 "$release_directory/reference/benchmark"
    expected_digest=$(sed -n 's/^executable_digest=//p' "$output_directory/$test_seed.meta")
    if actual_digest=$("$release_directory/native_digest" "$output_directory/executable-digest-$test_seed.log") && \
        test "$expected_digest" = "$actual_digest"; then
        printf 'digest-check-%s\t0\n' "$test_seed" >> "$output_directory/step-exits.tsv"
    else
        printf 'digest-check-%s\t1\n' "$test_seed" >> "$output_directory/step-exits.tsv"
        exit 1
    fi
done
shasum -a 256 "$release_directory/reference/benchmark" "$release_directory/inspect_timing" \
    "$release_directory/reference/baseline" > "$output_directory/binaries.sha256"
printf 'run_status=complete\n' > "$output_directory/status.txt"
find "$output_directory" -maxdepth 1 -type f ! -name SHA256SUMS -print | LC_ALL=C sort | \
    while IFS= read -r evidence_file; do
        shasum -a 256 "$evidence_file"
    done > "$output_directory/SHA256SUMS"
