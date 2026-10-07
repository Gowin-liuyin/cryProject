#!/bin/sh
set -eu
task_source=/home/ubuntu/cryproject-a113-20261007/source-697ddf8
task_output=/home/ubuntu/cryproject-a113-20261007/runs/cost-validation-697ddf8
mkdir "$task_output"
cd "$task_source"
test "$(git rev-parse HEAD)" = 697ddf867dfb1791ebcc4eba4e97f16197be3069
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
cmake -S . -B build/cost-normal -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON > "$task_output/configure.log" 2>&1
cmake --build build/cost-normal --parallel 4 > "$task_output/build.log" 2>&1
ctest --test-dir build/cost-normal --show-only=json-v1 > "$task_output/test-registration.json"
ctest --test-dir build/cost-normal --output-on-failure > "$task_output/tests.log" 2>&1
build/cost-normal/audit version > "$task_output/version.log"
build/cost-normal/audit performance-replay docs/evidence/native-final-20261007/performance "$task_output/performance.report"
cmp docs/evidence/native-final-20261007/performance/performance.report "$task_output/performance.report"
mkdir "$task_output/missing-cost-input"
cp docs/evidence/native-final-20261007/performance/*.csv docs/evidence/native-final-20261007/performance/*.meta "$task_output/missing-cost-input/"
if build/cost-normal/audit performance-replay "$task_output/missing-cost-input" "$task_output/missing-cost.report"; then
    exit 1
fi
if grep -q '^report_status=complete$' "$task_output/missing-cost.report"; then
    exit 1
fi
cmake -S . -B build/cost-sanitizers -DCMAKE_C_COMPILER=clang-18 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON -DBASELINE_SANITIZERS=ON > "$task_output/sanitizer-configure.log" 2>&1
cmake --build build/cost-sanitizers --parallel 4 > "$task_output/sanitizer-build.log" 2>&1
ctest --test-dir build/cost-sanitizers --output-on-failure > "$task_output/sanitizer-tests.log" 2>&1
sha256sum build/cost-normal/audit build/cost-sanitizers/audit > "$task_output/binaries.sha256"
printf 'source_commit=697ddf867dfb1791ebcc4eba4e97f16197be3069\nnormal_tests=32/32\nsanitizer_tests=32/32\nperformance_replay=byte_equal\nmissing_cost=rejected_no_complete\nnew_formal_measurement=not_performed\nexecution_kind=author_agent_native_kvm\nstatus=complete\n' > "$task_output/status.meta"
