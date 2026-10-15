#!/bin/sh
set -eu
is_stage=no
case "${1:-}" in
    --stages) is_stage=yes; shift ;;
    --bootstrap) is_stage=bootstrap; shift ;;
    --supervised) is_stage=outer; shift ;;
esac
if test "$is_stage" = yes; then
    test "$#" -eq 5
    shared_start_ns=$5
    set -- "$1" "$2" "$3" "$4"
fi
if test "$#" -ne 4; then
    printf 'Usage: %s FULL_SOURCE_COMMIT NEW_DIRECTORY EXECUTION_NOTE REVIEW_NOTE\n' "$0" >&2
    exit 2
fi
expected_commit=$1
output_directory=$2
execution_note=$3
review_note=$4
if test "$(uname -s)" != Linux || test "$(uname -m)" != x86_64; then
    printf 'Native x86_64 Linux is required; preparation is not target execution.\n' >&2
    exit 2
fi
if test "${NATIVE_X86_64_LINUX_CONFIRMED:-no}" != yes || test ! -s "$execution_note" || test ! -s "$review_note"; then
    exit 2
fi
source_directory=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$source_directory"
if test "$is_stage" = no; then
    exec timeout --kill-after=1 3599 sh "$source_directory/tools/prepare_paired_native.sh" \
        --supervised "$expected_commit" "$output_directory" "$execution_note" "$review_note"
fi
if test "$is_stage" = bootstrap; then
    mkdir "$output_directory"
    output_directory=$(CDPATH= cd -- "$output_directory" && pwd)
    printf 'step\texit_status\n' > "$output_directory/step-exits.tsv"
    printf 'format=paired_preparation_reservation_v1\nsource_commit=%s\npreparation_status=pending\ncost_closure=unclosed\nshared_calls_upper=40000\nshared_wall_upper_ns=3600000000000\nautomatic_retry=forbidden\n' \
        "$expected_commit" > "$output_directory/preparation-reservation.meta"
    printf 'preparation_status=pending\nsource_commit=%s\n' "$expected_commit" \
        > "$output_directory/budget.meta.preparation"
    cp "$execution_note" "$output_directory/execution-note.txt"
    cp "$review_note" "$output_directory/review-note.txt"
fi
finish_preparation() {
    final_status=$?
    if test "$final_status" -ne 0; then
        printf 'preparation_exit_status=%s\n' "$final_status" > "$output_directory/preparation-status.txt"
    fi
}
if test "$is_stage" = bootstrap; then
    trap finish_preparation EXIT
fi
run_step() {
    step_name=$1
    shift
    printf '%s\n' "$@" > "$output_directory/$step_name.log"
    if "$@" >> "$output_directory/$step_name.log" 2>&1; then
        step_status=0
    else
        step_status=$?
    fi
    printf '%s\t%s\n' "$step_name" "$step_status" >> "$output_directory/step-exits.tsv"
    test "$step_status" -eq 0 || exit "$step_status"
}
build_directory="$output_directory/build"
if test "$is_stage" = outer; then
    test ! -e "$output_directory"
    if timeout --kill-after=1 300 sh "$source_directory/tools/prepare_paired_native.sh" \
        --bootstrap "$expected_commit" "$output_directory" "$execution_note" "$review_note"; then
        :
    else
        bootstrap_status=$?
        if test -d "$output_directory"; then
            printf 'preparation_exit_status=%s\n' "$bootstrap_status" > "$output_directory/preparation-status.txt"
        fi
        exit "$bootstrap_status"
    fi
    output_directory=$(CDPATH= cd -- "$output_directory" && pwd)
    build_directory="$output_directory/build"
    trap finish_preparation EXIT
    shared_start_ns=$(cat "$output_directory/shared-start-ns.txt")
    run_step bounded-preparation timeout --kill-after=1 3297 sh "$source_directory/tools/prepare_paired_native.sh" \
        --stages "$expected_commit" "$output_directory" "$output_directory/execution-note.txt" \
        "$output_directory/review-note.txt" "$shared_start_ns"
    platform_review=$(sed -n 's/^platform_review=//p' "$output_directory/review-note.txt")
    dependency_review=$(sed -n 's/^dependency_review=//p' "$output_directory/review-note.txt")
    exec "$build_directory/paired_prepare" finish "$output_directory" \
        "$build_directory/reference/libmlkem.a" "$shared_start_ns" 301000000000 \
        "$platform_review" "$dependency_review" "$build_directory/paired_runner"
fi
test "$(git rev-parse HEAD)" = "$expected_commit"
git diff --quiet HEAD -- CMakeLists.txt CMakePresets.json src include tests tools cmake vendor docs/patches
test -z "$(git ls-files --others --exclude-standard -- src include tests tools cmake vendor docs/patches)"
command -v timeout >/dev/null
command -v rg >/dev/null
if test "$is_stage" = bootstrap; then
    run_step bootstrap-configure cmake -S "$source_directory" -B "$build_directory" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
    run_step bootstrap-build cmake --build "$build_directory" --target paired_prepare --parallel 4
    "$build_directory/paired_prepare" clock > "$output_directory/shared-start-ns.txt"
    exit 0
fi
run_step reference-preflight sh tools/run_native_reference.sh "$expected_commit" \
    "$output_directory/reference-preflight" "$output_directory/execution-note.txt"
run_step paired-build cmake --build "$build_directory" --target check-reference reference_benchmark \
    reference_batch_benchmark analyze_paired paired_runner paired_prepare test_batch_measurement \
    test_reference_benchmark test_paired_statistics test_paired_data test_paired_rejections \
    test_paired_prepare test_paired_runner paired_worker_fixture native_digest test_native_digest --parallel 4
run_step paired-tests ctest --test-dir "$build_directory" --output-on-failure \
    -R '^(batch_measurement|reference_benchmark|paired_statistics|paired_data|paired_rejections|paired_prepare|paired_runner|native_digest)$'
run_step baseline-disassembly objdump -d "$build_directory/reference/benchmark"
run_step candidate-disassembly objdump -d "$build_directory/reference/batch_benchmark"
run_step library-type file "$build_directory/reference/libmlkem.a" "$build_directory/reference/benchmark" \
    "$build_directory/reference/batch_benchmark"
platform_review=$(sed -n 's/^platform_review=//p' "$output_directory/review-note.txt")
dependency_review=$(sed -n 's/^dependency_review=//p' "$output_directory/review-note.txt")
test "$platform_review" = accepted
case "$dependency_review" in accepted|pending) ;; *) exit 2 ;; esac
run_step proposed-development "$build_directory/paired_prepare" development-plans "$output_directory/plans"
rg --no-filename '^test_seed=' docs/evidence -g '*.meta' > "$output_directory/raw-seeds.txt"
sed 's/^test_seed=//' "$output_directory/raw-seeds.txt" | LC_ALL=C sort -u > "$output_directory/excluded-seeds.txt"
printf '20261029\n' >> "$output_directory/excluded-seeds.txt"
run_step check-plan-k4 "$build_directory/paired_prepare" validate-plan \
    "$output_directory/plans/development-k4.plan.csv" "$output_directory/excluded-seeds.txt"
run_step check-plan-k16 "$build_directory/paired_prepare" validate-plan \
    "$output_directory/plans/development-k16.plan.csv" "$output_directory/excluded-seeds.txt"
printf 'development=not_executed\nconfirmation_candidate=not_selected\nconfirmation=not_executed\n' > "$output_directory/experiment-status.txt"
