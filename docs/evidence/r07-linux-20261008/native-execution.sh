#!/bin/sh
set -u
source_directory=$1
output_directory=$2
plan_file=$3
if test -e "$output_directory"; then
    printf 'output directory already exists\n' >&2
    exit 2
fi
mkdir -p "$output_directory/raw"
cp "$plan_file" "$output_directory/plan.md"
{
    date -u +%Y-%m-%dT%H:%M:%SZ
    uname -a
    . /etc/os-release
    printf 'PRETTY_NAME=%s\nVERSION_ID=%s\n' "$PRETTY_NAME" "$VERSION_ID"
    systemd-detect-virt || true
    nproc
    awk '/MemTotal/ {print}' /proc/meminfo
    gcc --version | head -1
    cmake --version | head -1
    printf 'ninja=%s\n' "$(ninja --version)"
    printf 'taskset_cpus=2\n'
    printf 'frequency_control=not_configured\n'
    sha256sum "$output_directory/plan.md"
    git -C "$source_directory" rev-parse HEAD
    git -C "$source_directory" status --porcelain
} > "$output_directory/preflight.log"
printf 'step\tstarted_utc\tfinished_utc\texit_code\n' > "$output_directory/step-exits.tsv"
run_step() {
    step_name=$1
    shift
    printf '%s\n' "$*" > "$output_directory/$step_name.command"
    started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    set +e
    "$@" > "$output_directory/$step_name.log" 2>&1
    step_exit_code=$?
    set -e
    finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '%s\t%s\t%s\t%s\n' "$step_name" "$started_utc" "$finished_utc" "$step_exit_code" >> "$output_directory/step-exits.tsv"
    printf 'STEP %s %s\n' "$step_name" "$step_exit_code"
    if test "$step_exit_code" -ne 0; then
        printf 'failed_step=%s exit_code=%s\n' "$step_name" "$step_exit_code"
        exit "$step_exit_code"
    fi
}
run_step configure cmake -S "$source_directory" -B "$output_directory/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=gcc -DBUILD_TESTING=ON \
    -DBASELINE_SANITIZERS=OFF -DA113_ARCHIVED_CASE_ONLY=OFF
run_step build cmake --build "$output_directory/build" --parallel 4
run_step tests ctest --test-dir "$output_directory/build" --output-on-failure
{
    date -u +%Y-%m-%dT%H:%M:%SZ
    for variant in reference vulnerable hardened deployable; do
        program="$output_directory/build/$variant/measure"
        file "$program"
        sha256sum "$program"
    done
} > "$output_directory/artifact-identity.log"
for variant in reference vulnerable hardened deployable; do
    for test_seed in 31337 90210 20261111 8675309 141421356; do
        step_name="measure-${variant}-${test_seed}"
        program="$output_directory/build/$variant/measure"
        csv_path="$output_directory/raw/${variant}-seed${test_seed}.csv"
        meta_path="$output_directory/raw/${variant}-seed${test_seed}.meta"
        run_step "$step_name" taskset -c 2 "$program" "r07-${variant}-${test_seed}" "$test_seed" 5000 "$csv_path" "$meta_path"
        run_step "analyze-${variant}-${test_seed}" "$output_directory/build/analyze" "$csv_path" "$output_directory/raw/${variant}-seed${test_seed}.report"
        run_step "groups-${variant}-${test_seed}" "$output_directory/build/analyze_groups" "$csv_path" "$output_directory/raw/${variant}-seed${test_seed}.groups.report"
    done
done
printf 'result_status=complete\nnew_vulnerability_claim=no\nkey_recovery=not_executed\n' > "$output_directory/result.meta"
printf 'DONE\n'
