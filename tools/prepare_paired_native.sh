#!/bin/sh
set -eu
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
test "$(git rev-parse HEAD)" = "$expected_commit"
git diff --quiet HEAD -- CMakeLists.txt CMakePresets.json src include tests tools cmake vendor docs/patches
test -z "$(git ls-files --others --exclude-standard -- src include tests tools cmake vendor docs/patches)"
command -v timeout >/dev/null
command -v rg >/dev/null
mkdir "$output_directory"
output_directory=$(CDPATH= cd -- "$output_directory" && pwd)
cp "$execution_note" "$output_directory/execution-note.txt"
cp "$review_note" "$output_directory/review-note.txt"
printf 'step\texit_status\n' > "$output_directory/step-exits.tsv"
finish_preparation() {
    final_status=$?
    printf 'preparation_exit_status=%s\n' "$final_status" > "$output_directory/preparation-status.txt"
}
trap finish_preparation EXIT
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
cat > "$output_directory/bootstrap.sh" <<'BOOTSTRAP'
#!/bin/sh
set -eu
cmake -S "$1" -B "$2" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build "$2" --target paired_prepare --parallel 4
BOOTSTRAP
run_step bootstrap timeout 300 sh "$output_directory/bootstrap.sh" "$source_directory" "$build_directory"
shared_start_ns=$("$build_directory/paired_prepare" clock)
run_step reference-preflight sh tools/run_native_reference.sh "$expected_commit" \
    "$output_directory/reference-preflight" "$output_directory/execution-note.txt"
run_step paired-build cmake --build "$build_directory" --target check-reference reference_benchmark \
    reference_batch_benchmark analyze_paired paired_runner paired_prepare test_batch_measurement \
    test_reference_benchmark test_paired_statistics test_paired_data test_paired_runner paired_worker_fixture --parallel 4
run_step paired-tests ctest --test-dir "$build_directory" --output-on-failure \
    -R '^(batch_measurement|reference_benchmark|paired_statistics|paired_data|paired_runner)$'
run_step baseline-disassembly objdump -d "$build_directory/reference/benchmark"
run_step candidate-disassembly objdump -d "$build_directory/reference/batch_benchmark"
run_step library-type file "$build_directory/reference/libmlkem.a" "$build_directory/reference/benchmark" \
    "$build_directory/reference/batch_benchmark"
platform_review=$(sed -n 's/^platform_review=//p' "$output_directory/review-note.txt")
dependency_review=$(sed -n 's/^dependency_review=//p' "$output_directory/review-note.txt")
test "$platform_review" = accepted
case "$dependency_review" in accepted|pending) ;; *) exit 2 ;; esac
run_step shared-cost "$build_directory/paired_prepare" shared "$output_directory/shared.cost" \
    "$build_directory/reference/libmlkem.a" "$shared_start_ns" 300000000000 "$platform_review" "$dependency_review"
run_step initialize-budget "$build_directory/paired_runner" init "$output_directory/budget.meta" "$output_directory/shared.cost"
run_step proposed-development "$build_directory/paired_prepare" development-plans "$output_directory/plans"
rg --no-filename '^test_seed=' docs/evidence -g '*.meta' > "$output_directory/raw-seeds.txt"
sed 's/^test_seed=//' "$output_directory/raw-seeds.txt" | LC_ALL=C sort -u > "$output_directory/excluded-seeds.txt"
printf '20261029\n' >> "$output_directory/excluded-seeds.txt"
run_step check-plan-k4 "$build_directory/paired_prepare" validate-plan \
    "$output_directory/plans/development-k4.plan.csv" "$output_directory/excluded-seeds.txt"
run_step check-plan-k16 "$build_directory/paired_prepare" validate-plan \
    "$output_directory/plans/development-k16.plan.csv" "$output_directory/excluded-seeds.txt"
printf 'development=not_executed\nconfirmation_candidate=not_selected\nconfirmation=not_executed\n' > "$output_directory/experiment-status.txt"
