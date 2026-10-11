#!/bin/sh
# 在 Cry 内跑留出确认：无插桩检测、诊断排名、同优化防护、新目录回滚。
set -eu

root=/home/nss-marker/yhr/Cry/seven-capabilities-20261011
source_root=${root}/source
export TMPDIR=${root}/tmp
export TEMP=${root}/tmp
export TMP=${root}/tmp
mkdir -p "${TMPDIR}"
cd "${source_root}"

find src include vendor docs/patches tools cmake tests Makefile CMakeLists.txt CMakePresets.json \
    -type f | LC_ALL=C sort | xargs shasum -a 256 > SOURCE_EXPORT.sha256

build_positive=${root}/build-positive
cmake -S "${source_root}" -B "${build_positive}" -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DBUILD_TESTING=ON \
    -DBASELINE_SANITIZERS=OFF \
    -DA113_ARCHIVED_CASE_ONLY=OFF \
    -DA113_MATRIX_OPT=O2
cmake --build "${build_positive}" --target \
    vulnerable_session_collect hardened_session_collect \
    vulnerable_diagnostic_trace hardened_diagnostic_trace \
    vulnerable_test_mlkem hardened_test_mlkem \
    protocol_analyze localize_rank -j 8

"${build_positive}/vulnerable/test_mlkem" "${source_root}/tests/vectors/mlkem768.txt"
"${build_positive}/hardened/test_mlkem" "${source_root}/tests/vectors/mlkem768.txt"

run_root=${root}/run-positive
rm -rf "${run_root}"
mkdir -p "${run_root}"
seed=20261111
protocol=${source_root}/docs/research/seven-capabilities-20261011/confirmation_protocol_v1.txt

collect_variant() {
    variant=$1
    binary=$2
    prefix=$3
    combined=${run_root}/${prefix}.csv
    : > "${combined}"
    session_index=1
    while [ "${session_index}" -le 6 ]; do
        "${binary}" "ryzen-${prefix}" "s${session_index}" "key-${seed}" "${seed}" 1000 50 \
            "${run_root}/${prefix}-s${session_index}.csv" \
            "${run_root}/${prefix}-s${session_index}.meta" \
            "${run_root}/${prefix}-s${session_index}.empty"
        if [ "${session_index}" -eq 1 ]; then
            cat "${run_root}/${prefix}-s${session_index}.csv" >> "${combined}"
        else
            tail -n +2 "${run_root}/${prefix}-s${session_index}.csv" >> "${combined}"
        fi
        session_index=$((session_index + 1))
    done
}

collect_variant vulnerable "${build_positive}/vulnerable/session_collect" vulnerable
collect_variant hardened "${build_positive}/hardened/session_collect" hardened

"${build_positive}/protocol_analyze" --phase confirmation --protocol "${protocol}" \
    --csv "${run_root}/vulnerable.csv" --seed "${seed}" > "${run_root}/vulnerable-decision.txt"
"${build_positive}/protocol_analyze" --phase confirmation --protocol "${protocol}" \
    --csv "${run_root}/hardened.csv" --seed "${seed}" > "${run_root}/hardened-decision.txt"

"${build_positive}/vulnerable/diagnostic_trace" --timing "${seed}" 40 \
    "${run_root}/vulnerable-events.csv" "${run_root}/vulnerable-summary.txt" \
    "${run_root}/vulnerable-candidates.csv"
"${build_positive}/hardened/diagnostic_trace" --timing "${seed}" 40 \
    "${run_root}/hardened-events.csv" "${run_root}/hardened-summary.txt" \
    "${run_root}/hardened-candidates.csv"

if grep -q 'holm_rejected_primary=yes' "${run_root}/vulnerable-decision.txt"; then
    printf 'end_to_end_detected=yes\n' > "${run_root}/detection.txt"
else
    printf 'end_to_end_detected=no\n' > "${run_root}/detection.txt"
fi
"${build_positive}/localize_rank" "${run_root}/vulnerable-candidates.csv" \
    "${run_root}/detection.txt" > "${run_root}/vulnerable-rank.txt"
printf 'end_to_end_detected=no\n' > "${run_root}/hardened-detection.txt"
if grep -q 'holm_rejected_primary=yes' "${run_root}/hardened-decision.txt"; then
    printf 'end_to_end_detected=yes\n' > "${run_root}/hardened-detection.txt"
fi
"${build_positive}/localize_rank" "${run_root}/hardened-candidates.csv" \
    "${run_root}/hardened-detection.txt" > "${run_root}/hardened-rank.txt"

build_rollback=${root}/build-rollback
cmake -S "${source_root}" -B "${build_rollback}" -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DBUILD_TESTING=ON \
    -DBASELINE_SANITIZERS=OFF \
    -DA113_ARCHIVED_CASE_ONLY=OFF \
    -DA113_MATRIX_OPT=O2
cmake --build "${build_rollback}" --target vulnerable_session_collect vulnerable_test_mlkem -j 8
"${build_rollback}/vulnerable/test_mlkem" "${source_root}/tests/vectors/mlkem768.txt"
collect_variant vulnerable "${build_rollback}/vulnerable/session_collect" rollback
"${build_positive}/protocol_analyze" --phase confirmation --protocol "${protocol}" \
    --csv "${run_root}/rollback.csv" --seed "${seed}" > "${run_root}/rollback-decision.txt"

{
    printf 'platform=ryzen-9950x\nseed=%s\nsessions=6\nsamples_per_class=1000\n' "${seed}"
    printf 'vulnerable_decision_begin\n'
    cat "${run_root}/vulnerable-decision.txt"
    printf 'vulnerable_decision_end\nhardened_decision_begin\n'
    cat "${run_root}/hardened-decision.txt"
    printf 'hardened_decision_end\nrollback_decision_begin\n'
    cat "${run_root}/rollback-decision.txt"
    printf 'rollback_decision_end\nvulnerable_rank_begin\n'
    cat "${run_root}/vulnerable-rank.txt"
    printf 'vulnerable_rank_end\n'
    printf 'vulnerable_summary_begin\n'
    cat "${run_root}/vulnerable-summary.txt"
    printf 'vulnerable_summary_end\nhardened_summary_begin\n'
    cat "${run_root}/hardened-summary.txt"
    printf 'hardened_summary_end\n'
} > "${run_root}/positive-loop.txt"
echo POSITIVE_LOOP_DONE
