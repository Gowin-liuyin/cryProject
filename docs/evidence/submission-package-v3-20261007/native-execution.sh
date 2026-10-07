#!/bin/sh
set -eu
work_directory=$1
mkdir "$work_directory"
output_directory="$work_directory/results"
mkdir "$output_directory"
run_step() {
    step_name=$1
    shift
    printf '%s\n' "$*" > "$output_directory/$step_name.command"
    started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
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
run_step zip-sha256 sha256sum /tmp/cryproject-submission-v3.BwWNyE/submission-v3.zip
run_step unzip python3 -c 'import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); assert z.testzip() is None; z.extractall(sys.argv[2])' /tmp/cryproject-submission-v3.BwWNyE/submission-v3.zip "$work_directory/unpacked"
cd "$work_directory/unpacked/待编号-2026密码竞赛复赛相关支撑材料"
run_step package-manifest shasum -a 256 -c SHA256SUMS
cd source
source_directory=$(pwd)
run_step source-manifest shasum -a 256 -c SOURCE_EXPORT.sha256
run_step c04-input-manifest shasum -a 256 -c docs/reference-label-control-v1.inputs.sha256
run_step gcc-configure cmake -S . -B "$work_directory/build-gcc" -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF -DA113_ARCHIVED_CASE_ONLY=ON
run_step gcc-build cmake --build "$work_directory/build-gcc" --parallel 4
program="$work_directory/build-gcc/audit"
run_step gcc-tests "$program" check
run_step help "$program" help
run_step version "$program" version
run_step clang-sanitize-configure cmake -S . -B "$work_directory/build-sanitize" -G Ninja -DCMAKE_C_COMPILER=clang-18 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=ON -DA113_ARCHIVED_CASE_ONLY=ON
run_step clang-sanitize-build cmake --build "$work_directory/build-sanitize" --parallel 4
run_step clang-sanitize-tests "$work_directory/build-sanitize/audit" check
run_step artifact-identity sh -c 'file "$1" "$2"; sha256sum "$1" "$2"; readelf -W -l "$2"; cat "$3"; getconf CHAR_BIT; getconf INT_MAX' sh "$program" "$work_directory/build-gcc/reference/benchmark" "$work_directory/build-gcc/generated/RelWithDebInfo/configuration.txt"
run_step history-replay "$program" replay "$source_directory" "$output_directory/history"
run_step performance-replay "$program" performance-replay docs/evidence/native-final-20261007/performance "$output_directory/performance.report"
run_step performance-compare cmp "$output_directory/performance.report" docs/evidence/native-final-20261007/performance/performance.report
run_step exact-replay "$program" analyze-pairs docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.csv docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.plan "$output_directory/exact.report"
run_step exact-compare cmp "$output_directory/exact.report" docs/evidence/controlled-comparison-20261007/confirmation-results/task-2-r1-candidate.report
run_step model-replay "$program" calibrate "$output_directory/model"
run_step model-compare cmp "$output_directory/model/raw.csv" docs/evidence/finite-calibration-20261007/model/raw.csv
run_step reference-control-replay "$program" reference-label-control docs/evidence/native-final-20261007/performance "$output_directory/reference-control"
run_step reference-control-compare cmp "$output_directory/reference-control/raw.csv" docs/evidence/reference-label-control-20261007/qualified/control/raw.csv
run_step selected-times-compare cmp "$output_directory/reference-control/selected.csv" docs/evidence/reference-label-control-20261007/qualified/control/selected.csv
# 普通短演示仅验证新入口，不补成正式性能或防护复测。
run_step live-ordinary-demo "$program" collect submission-v3-demo 2026100703 20 "$output_directory/live"
printf 'execution_identity=author_agent\nresult_status=complete_package_engineering_acceptance\nnew_vulnerability_timing=not_executed\nindependent_human_execution=not_obtained\n' > "$output_directory/result.meta"
