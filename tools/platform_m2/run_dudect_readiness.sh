#!/bin/sh
# M2 online dudect 就绪运行：--describe、少量批次冒烟、可选整轮就绪采集。
# 输出全部落在 --output-dir 内；不写该目录之外的任何路径，不 fork。
# 这不是正式统计：正式运行必须按 PLAN 在绑核+锁频控制器内执行。
set -u

build_root=
fixture_dir=
output_dir=
seed=31337
batches=20
usage() {
    cat <<'USAGE'
usage: run_dudect_readiness.sh --build-root DIR --fixture-dir DIR --output-dir NEW_DIR
                               [--seed N] [--batches N]
  build-root 需含 collector/{unfixed,fixed}/m2_dudect
  fixture-dir 需含 pk.bin / sk.bin（collector 资格生成的公开测试夹具）
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-root) build_root=${2:-}; shift 2 ;;
        --fixture-dir) fixture_dir=${2:-}; shift 2 ;;
        --output-dir) output_dir=${2:-}; shift 2 ;;
        --seed) seed=${2:-}; shift 2 ;;
        --batches) batches=${2:-}; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [ -z "${build_root}" ] || [ -z "${fixture_dir}" ] || [ -z "${output_dir}" ]; then
    usage >&2
    exit 2
fi
if [ -e "${output_dir}" ]; then
    printf 'output-dir already exists: %s\n' "${output_dir}" >&2
    exit 2
fi
mkdir -p "${output_dir}/logs"

failures=0
log_dir=${output_dir}/logs

record_step() {
    step_name=$1
    shift
    {
        printf 'command:'
        for step_argument in "$@"; do
            printf ' %s' "${step_argument}"
        done
        printf '\n'
    } > "${log_dir}/${step_name}.command"
    "$@" > "${log_dir}/${step_name}.stdout" 2> "${log_dir}/${step_name}.stderr"
    step_status=$?
    printf '%s\n' "${step_status}" > "${log_dir}/${step_name}.status"
    printf '%-40s exit=%s\n' "${step_name}" "${step_status}"
    if [ "${step_status}" -ne 0 ]; then
        failures=$((failures + 1))
    fi
}

check_status() {
    check_label=$1
    shift
    if "$@"; then
        printf 'check pass: %s\n' "${check_label}"
    else
        printf 'check FAIL: %s\n' "${check_label}"
        failures=$((failures + 1))
    fi
}

average_mhz() {
    awk -F: '/MHz/ {total += $2; count += 1} END {if (count > 0) printf "%.0f", total / count; else printf "unknown"}' \
        /proc/cpuinfo
}

SMOKE_BATCHES=3
SMOKE_ROWS=$((SMOKE_BATCHES * 9999 + 1))
EXPECTED_ROWS=$((batches * 9999 + 1))

{
    printf 'date_utc=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'build_root=%s\nfixture_dir=%s\nseed=%s\nbatches=%s\n' \
        "${build_root}" "${fixture_dir}" "${seed}" "${batches}"
    uname -a
    printf 'nproc=%s\n' "$(nproc)"
    sha256sum "${build_root}/collector/unfixed/m2_dudect" "${build_root}/collector/fixed/m2_dudect"
} > "${log_dir}/environment.txt"

for variant in unfixed fixed; do
    dudect_binary=${build_root}/collector/${variant}/m2_dudect
    check_status "dudect ELF exists (${variant})" test -x "${dudect_binary}"
    record_step "describe-${variant}" "${dudect_binary}" --describe
    printf '%s %s\n' "${variant}" "$(average_mhz)" >> "${log_dir}/smoke-mhz-before.txt"
    record_step "smoke-${variant}" "${dudect_binary}" --collect \
        "${output_dir}/${variant}-smoke-${SMOKE_BATCHES}batches.csv" "${SMOKE_BATCHES}" "${seed}" \
        "${fixture_dir}/pk.bin" "${fixture_dir}/sk.bin"
    printf '%s %s\n' "${variant}" "$(average_mhz)" >> "${log_dir}/smoke-mhz-after.txt"
    check_status "smoke row count (${variant})" \
        test "$(wc -l < "${output_dir}/${variant}-smoke-${SMOKE_BATCHES}batches.csv")" -eq \
        "${SMOKE_ROWS}"
    check_status "smoke has battery status (${variant})" \
        grep -q '^battery_dudect_status=online_' "${log_dir}/smoke-${variant}.stdout"
    check_status "smoke reports 3 batches and 1 warmup (${variant})" \
        grep -q "completed_batches=${SMOKE_BATCHES} total_calls=$((SMOKE_BATCHES * 10000)) warmup_batches=1" \
        "${log_dir}/smoke-${variant}.stdout"
    check_status "describe reports upstream online mode (${variant})" \
        grep -q 'mode=upstream_dudect_online' "${log_dir}/describe-${variant}.stdout"
    cut -d, -f4 "${output_dir}/${variant}-smoke-${SMOKE_BATCHES}batches.csv" \
        > "${output_dir}/${variant}-smoke.labels"
done

check_status "smoke label order identical across variants" \
    cmp -s "${output_dir}/unfixed-smoke.labels" "${output_dir}/fixed-smoke.labels"
check_status "smoke class counts balanced" \
    test "$(tail -n +2 "${output_dir}/unfixed-smoke-${SMOKE_BATCHES}batches.csv" | cut -d, -f4 |
        sort -u | tr '\n' ' ')" = "0 1 "
check_status "second write to same raw path fails" \
    test "$( "${build_root}/collector/unfixed/m2_dudect" --collect \
        "${output_dir}/unfixed-smoke-${SMOKE_BATCHES}batches.csv" "${SMOKE_BATCHES}" "${seed}" \
        "${fixture_dir}/pk.bin" "${fixture_dir}/sk.bin" > /dev/null 2>&1; echo $?)" -ne 0

for variant in unfixed fixed; do
    dudect_binary=${build_root}/collector/${variant}/m2_dudect
    printf '%s %s\n' "${variant}" "$(average_mhz)" >> "${log_dir}/readiness-mhz-before.txt"
    record_step "readiness-${variant}" "${dudect_binary}" --collect \
        "${output_dir}/${variant}-readiness-${batches}batches.csv" "${batches}" "${seed}" \
        "${fixture_dir}/pk.bin" "${fixture_dir}/sk.bin"
    printf '%s %s\n' "${variant}" "$(average_mhz)" >> "${log_dir}/readiness-mhz-after.txt"
    check_status "readiness row count (${variant})" \
        test "$(wc -l < "${output_dir}/${variant}-readiness-${batches}batches.csv")" -eq \
        "${EXPECTED_ROWS}"
done
grep -h '^battery_dudect_status=' "${log_dir}"/readiness-*.stdout > "${output_dir}/readiness-status.txt" || true
grep -h 'max t:' "${log_dir}"/readiness-*.stdout > "${output_dir}/readiness-max-t.txt" || true

printf 'failures=%s\n' "${failures}" | tee "${output_dir}/dudect-readiness-summary.txt"
printf 'note=readiness only; official online dudect requires pinned CPU and locked frequency\n' \
    >> "${output_dir}/dudect-readiness-summary.txt"
if [ "${failures}" -ne 0 ]; then
    printf 'dudect readiness FAILED with %s failing check(s)\n' "${failures}" >&2
    exit 1
fi
printf 'dudect readiness passed\n'
