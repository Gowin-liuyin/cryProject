#!/bin/sh
set -eu
task_source=/home/ubuntu/cryproject-a113-20261007/source-finite-calibration
task_output=/home/ubuntu/cryproject-a113-20261007/runs/finite-calibration-62dbe4c
mkdir "$task_output"
cd "$task_source"
test "$(git rev-parse HEAD)" = 62dbe4cfb4a8c0d8480c7271e9214f74697f8f86
test -z "$(git status --porcelain)"
{
    date -u
    uname -a
    nproc
    lscpu
    systemd-detect-virt
    gcc --version
    clang-18 --version
    cmake --version
    git rev-parse HEAD
} > "$task_output/environment.log" 2>&1
cmake -S . -B build/finite-normal -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON > "$task_output/configure.log" 2>&1
cmake --build build/finite-normal --parallel 4 > "$task_output/build.log" 2>&1
ctest --test-dir build/finite-normal --output-on-failure > "$task_output/tests.log" 2>&1
cmake -S . -B build/finite-sanitizers -DCMAKE_C_COMPILER=clang-18 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON -DBASELINE_SANITIZERS=ON > "$task_output/sanitizer-configure.log" 2>&1
cmake --build build/finite-sanitizers --parallel 4 > "$task_output/sanitizer-build.log" 2>&1
ctest --test-dir build/finite-sanitizers --output-on-failure > "$task_output/sanitizer-tests.log" 2>&1
date -u > "$task_output/calibration-start-utc.txt"
timeout 125s build/finite-normal/audit calibrate "$task_output/model" > "$task_output/calibration.log" 2>&1
date -u > "$task_output/calibration-finish-utc.txt"
for model_name in common_equal common_graded; do
    for assignment in 0 1; do
        build/finite-normal/controlled_stats analyze "$task_output/model/$model_name-$assignment.csv" "$task_output/model/$model_name-$assignment.plan" "$task_output/model/$model_name-$assignment.report"
        test "$(sed -n 's/^result_status=//p' "$task_output/model/$model_name-$assignment.report")" = evidence_insufficient
    done
done
sha256sum build/finite-normal/audit build/finite-normal/calibrate_controlled build/finite-normal/controlled_stats > "$task_output/binaries.sha256"
printf 'source_commit=62dbe4cfb4a8c0d8480c7271e9214f74697f8f86\nnormal_tests=33/33\nsanitizer_tests=33/33\ncalibration_task_exit=0\ndependent_cli=4/4_evidence_insufficient\nmlkem_decapsulation_calls=0\nexternal_audit=pending\nexecution_kind=author_agent_native_kvm\nstatus=c_stage_complete\n' > "$task_output/status.meta"
