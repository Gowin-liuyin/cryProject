#!/bin/sh
set -eu
source_directory=$1
output_directory=$2
mkdir "$output_directory"
cd "$source_directory"
run_step() {
    step_name=$1
    shift
    started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '%s\n' "$*" > "$output_directory/$step_name.command"
    set +e
    "$@" > "$output_directory/$step_name.log" 2>&1
    step_exit_code=$?
    set -e
    printf '%s\t%s\t%s\t%s\n' "$step_name" "$started_utc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$step_exit_code" >> "$output_directory/step-exits.tsv"
    if test "$step_exit_code" -ne 0; then
        printf 'failed_step=%s exit_code=%s\n' "$step_name" "$step_exit_code"
        exit "$step_exit_code"
    fi
}
printf 'step\tstarted_utc\tfinished_utc\texit_code\n' > "$output_directory/step-exits.tsv"
run_step source-manifest shasum -a 256 -c SOURCE_EXPORT.sha256
run_step release-configure cmake -S . -B build/release -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF -DA113_ARCHIVED_CASE_ONLY=ON
run_step release-build cmake --build build/release --parallel 4
run_step release-tests build/release/audit check
run_step release-version build/release/audit version
run_step sanitizer-configure cmake -S . -B build/sanitizer -G Ninja -DCMAKE_C_COMPILER=clang-18 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=ON -DA113_ARCHIVED_CASE_ONLY=ON
run_step sanitizer-build cmake --build build/sanitizer --parallel 4
run_step sanitizer-tests build/sanitizer/audit check
run_step artifact-identity sh -c '
    getconf CHAR_BIT
    getconf INT_MAX
    cat build/release/generated/RelWithDebInfo/configuration.txt
    sha256sum SOURCE_EXPORT.sha256 build/release/audit build/release/reference/baseline build/release/reference/benchmark build/release/reference/libmlkem.a build/release/hardened/benchmark build/release/deployable/benchmark
    file build/release/audit build/release/reference/benchmark
    readelf -W -l build/release/reference/benchmark
    ldd build/release/reference/benchmark
    gcc -std=c11 -DMLK_CONFIG_FILE=\"baseline_config.h\" -Iinclude -Ivendor/mlkem-native/mlkem -dM -E src/kernel.c | LC_ALL=C sort
    nm build/release/reference/libmlkem.a
'
cp build/release/compile_commands.json "$output_directory/compile_commands.json"
cp build/release/generated/RelWithDebInfo/configuration.txt "$output_directory/build-configuration.txt"
for variant_name in reference hardened deployable; do
    run_step "disassembly-$variant_name" objdump -d "build/release/$variant_name/benchmark"
done
# 正式普通负载窗口期间不并行编译、动态检查或其他性能测量。
run_step performance taskset -c 2 build/release/audit performance "$output_directory/perf"
run_step history-replay build/release/audit replay "$source_directory" "$output_directory/history"
run_step performance-replay build/release/audit performance-replay docs/evidence/native-final-20261007/performance "$output_directory/performance-old.report"
run_step performance-compare cmp "$output_directory/performance-old.report" docs/evidence/native-final-20261007/performance/performance.report
run_step exact-replay build/release/audit analyze-pairs docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.csv docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.plan "$output_directory/exact.report"
run_step exact-compare cmp "$output_directory/exact.report" docs/evidence/controlled-comparison-20261007/confirmation-results/task-2-r1-candidate.report
run_step model-replay build/release/audit calibrate "$output_directory/model"
run_step model-compare cmp "$output_directory/model/raw.csv" docs/evidence/finite-calibration-20261007/model/raw.csv
run_step reference-control-replay build/release/audit reference-label-control docs/evidence/native-final-20261007/performance "$output_directory/reference-control"
run_step reference-control-compare cmp "$output_directory/reference-control/raw.csv" docs/evidence/reference-label-control-20261007/qualified/control/raw.csv
run_step selected-times-compare cmp "$output_directory/reference-control/selected.csv" docs/evidence/reference-label-control-20261007/qualified/control/selected.csv
printf 'execution_identity=author_agent\nnew_vulnerability_timing=not_executed\nresult_status=complete_engineering_checks_only\n' > "$output_directory/result.meta"
