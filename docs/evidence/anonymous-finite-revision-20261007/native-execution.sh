#!/bin/sh
set -eu
task_archive=/home/ubuntu/cryproject-a113-20261007/transfer/anonymous-finite-calibration.zip
task_output=/home/ubuntu/cryproject-a113-20261007/runs/anonymous-finite-calibration
mkdir "$task_output"
cd "$task_output"
test "$(sha256sum "$task_archive" | cut -d ' ' -f 1)" = f46abe7d667e5ef07b55875b6d39db678dce6ed58093c15bb6824c17738ce053
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
"$task_output/build/audit" calibrate "$task_output/model-replay" > "$task_output/model-replay.log" 2>&1
cmp docs/evidence/finite-calibration-20261007/model/raw.csv "$task_output/model-replay/raw.csv"
printf 'archive_sha256=f46abe7d667e5ef07b55875b6d39db678dce6ed58093c15bb6824c17738ce053\nsource_identity_kind=verified_source_export\nsource_export_manifest_sha256=c1e8af5e85bf38dffebf9f9fe896b64fc618603be1a713c7ff3161875deaa026\nplatform=x86_64_linux_kvm\ndefault_tests=33/33\narchive_integrity=pass\nsource_integrity=pass\nperformance_replay=distributed_report_byte_equal\nhistory_replay=40_distributed_reports_byte_equal\nexact_replay=distributed_report_byte_equal\nfinite_model_raw_replay=40964_rows_byte_equal\nnew_formal_measurement=not_performed\nexecution_kind=author_agent\nstatus=complete\n' > "$task_output/status.meta"
