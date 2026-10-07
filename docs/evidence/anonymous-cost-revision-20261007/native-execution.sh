#!/bin/sh
set -eu
task_archive=/home/ubuntu/cryproject-a113-20261007/transfer/anonymous-cost-697ddf8.zip
task_output=/home/ubuntu/cryproject-a113-20261007/runs/anonymous-cost-697ddf8
mkdir "$task_output"
cd "$task_output"
test "$(sha256sum "$task_archive" | cut -d ' ' -f 1)" = 2347e150258dc510e9374b8f7571cc0c51f485f739bc13c20d597fe4992d6932
sha256sum "$task_archive" > archive.sha256
{
    date -u
    uname -a
    nproc
    systemd-detect-virt
    gcc --version
} > environment.log
unzip -q "$task_archive"
task_package="$task_output/待编号-2026密码竞赛复赛相关支撑材料"
cd "$task_package"
shasum -a 256 -c SHA256SUMS > "$task_output/integrity.log"
cd source
shasum -a 256 -c SOURCE_EXPORT.sha256 > "$task_output/source-integrity.log"
cmake -S . -B "$task_output/build" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON > "$task_output/configure.log" 2>&1
cmake --build "$task_output/build" --parallel 4 > "$task_output/build.log" 2>&1
ctest --test-dir "$task_output/build" --output-on-failure > "$task_output/tests.log" 2>&1
"$task_output/build/audit" version > "$task_output/version.log"
"$task_output/build/audit" performance-replay docs/evidence/native-final-20261007/performance "$task_output/performance.report"
cmp docs/evidence/native-final-20261007/performance/performance.report "$task_output/performance.report"
"$task_output/build/audit" replay "$PWD" "$task_output/history-replay" > "$task_output/history-replay.log" 2>&1
"$task_output/build/audit" analyze-pairs docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.csv docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.plan "$task_output/exact.report" > "$task_output/exact.log" 2>&1
cmp docs/evidence/controlled-comparison-20261007/confirmation-results/task-2-r1-candidate.report "$task_output/exact.report"
printf 'archive_sha256=2347e150258dc510e9374b8f7571cc0c51f485f739bc13c20d597fe4992d6932\nsource_identity_kind=verified_source_export\nsource_export_manifest_sha256=55accfea99182d0614af0a6d954a2d483ae8bf94dbbb4b1be399e58b8fd3408c\nplatform=x86_64_linux_kvm\ndefault_tests=32/32\narchive_integrity=pass\nsource_integrity=pass\nperformance_replay=distributed_report_byte_equal\nhistory_replay=40_distributed_reports_byte_equal\nexact_replay=distributed_report_byte_equal\nnew_formal_measurement=not_performed\nexecution_kind=author_agent\nstatus=complete\n' > "$task_output/status.meta"
