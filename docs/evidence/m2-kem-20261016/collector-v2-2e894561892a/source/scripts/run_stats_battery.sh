#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "${script_directory}/.." && pwd)
input_csv=
output_directory=
input_format=wide
first_class=message-zero
second_class=message-ones
stats_program="${repository_root}/build/cmake/platform_stats"
dudect_replay_program=
dudect_log=
rtlf_script="${repository_root}/third_party/RTLF/rtlf.R"
run_external=1

usage() {
    cat <<'USAGE'
usage: run_stats_battery.sh --input CSV --output-dir NEW_DIRECTORY [options]
  --format wide|measure       wide: class0_ns,class1_ns; integer ns, >=2 per class
  --classes CLASS0 CLASS1      selected measure categories (default zero/ones)
  --stats-bin PATH             CMake-built platform_stats executable
  --dudect-replay-bin PATH     optional x86 upstream-header offline replay
  --dudect-log PATH            import an existing online dudect log (no new run)
  --rtlf-script PATH           reviewed upstream rtlf.R; alpha always 0.01
  --no-external               CI + explicit skipped statuses (synthetic self-test)
No collection, trimming, Holm correction, or automatic dependency installation.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --input|--output-dir|--format|--stats-bin|--dudect-replay-bin|--dudect-log|--rtlf-script)
            if [ "$#" -lt 2 ]; then
                usage >&2
                exit 2
            fi
            option=$1
            value=$2
            case "${option}" in
                --input) input_csv=${value} ;;
                --output-dir) output_directory=${value} ;;
                --format) input_format=${value} ;;
                --stats-bin) stats_program=${value} ;;
                --dudect-replay-bin) dudect_replay_program=${value} ;;
                --dudect-log) dudect_log=${value} ;;
                --rtlf-script) rtlf_script=${value} ;;
            esac
            shift 2
            ;;
        --classes)
            if [ "$#" -lt 3 ]; then
                usage >&2
                exit 2
            fi
            first_class=$2
            second_class=$3
            shift 3
            ;;
        --no-external)
            run_external=0
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "${input_csv}" ] || [ -z "${output_directory}" ] || [ ! -f "${input_csv}" ] ||
    [ ! -x "${stats_program}" ]; then
    usage >&2
    printf '%s\n' 'Require readable input and CMake-built platform_stats.' >&2
    exit 2
fi
case "${input_format}" in
    wide|measure) ;;
    *) usage >&2; exit 2 ;;
esac
# 新建输出目录，防止覆盖原件；失败时保留已生成文件供排查。
if [ -e "${output_directory}" ] || [ -L "${output_directory}" ]; then
    printf '%s\n' 'Output directory must not exist.' >&2
    exit 2
fi
mkdir -p -- "$(dirname -- "${output_directory}")"
mkdir -- "${output_directory}"
output_directory=$(CDPATH= cd -- "${output_directory}" && pwd -P)
cp -- "${input_csv}" "${output_directory}/input.csv"
shasum -a 256 "${output_directory}/input.csv" > "${output_directory}/input.sha256"
if [ "${input_format}" = wide ]; then
    first_class=class0_ns
    second_class=class1_ns
fi
case "${first_class}:${second_class}" in
    *[!a-zA-Z0-9_:-]*)
        printf '%s\n' 'Class labels must use letters, digits, underscores or hyphens.' >&2
        exit 2
        ;;
esac
printf 'input_format=%s\nclass0_name=%s\nclass1_name=%s\nstats_binary=%s\nrtlf_script=%s\ndudect_replay_binary=%s\ndudect_online_log=%s\n' \
    "${input_format}" "${first_class}" "${second_class}" "${stats_program}" "${rtlf_script}" \
    "${dudect_replay_program}" "${dudect_log}" > "${output_directory}/configuration.txt"
uname -a >> "${output_directory}/configuration.txt"
shasum -a 256 "${stats_program}" "${script_directory}/run_stats_battery.sh" \
    > "${output_directory}/tools.sha256"
for tool_path in "${rtlf_script}" "${dudect_replay_program}"; do
    if [ -n "${tool_path}" ] && [ -f "${tool_path}" ]; then
        shasum -a 256 "${tool_path}" >> "${output_directory}/tools.sha256"
    fi
done
"${stats_program}" "${output_directory}/input.csv" "${input_format}" "${first_class}" "${second_class}" \
    "${output_directory}"

mkdir "${output_directory}/runtime"
TMPDIR="${output_directory}/runtime"
TMP=${TMPDIR}
TEMP=${TMPDIR}
export TMPDIR TMP TEMP
rtlf_status=unavailable
rtlf_exit_status=not_run
dudect_status=unavailable
dudect_online_status=unavailable
if [ "${run_external}" -eq 0 ]; then
    rtlf_status=skipped_explicitly
    dudect_status=skipped_explicitly
elif awk -F, 'NR > 1 {count[$1]++} END {exit !(count["X"] < 100 || count["Y"] < 100)}' "${output_directory}/normalized.csv"; then
    rtlf_status=insufficient_measurements
    printf '%s\n' 'Pinned RTLF requires at least 100 measurements per class.' \
        > "${output_directory}/rtlf.log"
elif awk -F, 'NR > 1 && $2 == 0 {found=1} END {exit !found}' "${output_directory}/normalized.csv"; then
    rtlf_status=blocked_upstream_zero_filter
    printf '%s\n' 'RTLF filters zero values; raw input retained, RTLF not executed.' \
        > "${output_directory}/rtlf.log"
elif [ -f "${rtlf_script}" ] && command -v Rscript >/dev/null 2>&1; then
    if Rscript --vanilla -e 'required <- c("tidyverse", "optparse", "jsonlite", "crayon", "parallel"); quit(status=if (all(vapply(required, requireNamespace, logical(1), quietly=TRUE))) 0 else 1)' \
        > "${output_directory}/rtlf-preflight.log" 2>&1; then
        set +e
        PLATFORM_RTLF_SCRIPT="${rtlf_script}" Rscript --vanilla \
            -e 'set.seed(2026101605); source(Sys.getenv("PLATFORM_RTLF_SCRIPT"))' \
            -i "${output_directory}/normalized.csv" -a 0.01 \
            -o "${output_directory}/rtlf.json" -q > "${output_directory}/rtlf.log" 2>&1
        rtlf_exit_status=$?
        set -e
        case "${rtlf_exit_status}" in
            10) rtlf_status=no_difference_detected ;;
            11) rtlf_status=difference_detected ;;
            *) rtlf_status=failed ;;
        esac
        if [ ! -s "${output_directory}/rtlf.json" ]; then
            rtlf_status=failed_missing_result
        fi
    else
        rtlf_status=unavailable_r_packages
    fi
else
    printf '%s\n' 'Upstream RTLF or Rscript unavailable; no inferred result.' \
        > "${output_directory}/rtlf.log"
fi

if [ "${run_external}" -eq 1 ] && [ -n "${dudect_replay_program}" ]; then
    if [ ! -x "${dudect_replay_program}" ]; then
        dudect_status=unavailable_replay_executable
    elif "${dudect_replay_program}" "${output_directory}/normalized.csv" \
        > "${output_directory}/dudect-replay.log" 2>&1; then
        dudect_status=$(sed -n 's/^battery_dudect_status=//p' "${output_directory}/dudect-replay.log" | tail -n 1)
        case "${dudect_status}" in
            offline_leakage_found|offline_no_evidence_yet|insufficient_measurements) ;;
            *) dudect_status=failed_missing_status ;;
        esac
    else
        dudect_status=failed
    fi
fi
if [ -n "${dudect_log}" ]; then
    if [ ! -f "${dudect_log}" ]; then
        printf '%s\n' 'Supplied online dudect log unavailable.' >&2
        exit 2
    fi
    cp -- "${dudect_log}" "${output_directory}/dudect-online.log"
    dudect_online_status=imported_unverified_provenance
fi

cat > "${output_directory}/summary.json" <<JSON
{
  "schema": "cryproject_stats_battery_v1",
  "ci_welch": "ci_welch.json",
  "input_format": "${input_format}",
  "class0_name": "${first_class}",
  "class1_name": "${second_class}",
  "configuration": "configuration.txt",
  "tool_digests": "tools.sha256",
  "rtlf": {"status": "${rtlf_status}", "alpha": 0.01, "seed": 2026101605, "exit_status": "${rtlf_exit_status}"},
  "dudect_offline": {"status": "${dudect_status}", "holm_member": false},
  "dudect_online": {"status": "${dudect_online_status}", "holm_member": false},
  "holm": "not_applied_requires_preregistered_family",
  "raw_input": "input.csv",
  "normalized_input": "normalized.csv"
}
JSON
cat > "${output_directory}/RESULT.md" <<MARKDOWN
# 统计电池摘要

- CI/Welch：见 ci_welch.json；95% 正态近似区间、双侧正态近似 p，非精确 Student t 分布。
- RTLF：${rtlf_status}；α=0.01；固定 bootstrap 种子 2026101605；退出码 ${rtlf_exit_status}。
- dudect 离线回放：${dudect_status}；用原上游统计内核，输入 ns，无新采数，不等同于在线 rdtsc 检测。
- dudect 在线日志：${dudect_online_status}；导入日志只保全原文，需单独核对来源、环境、预算。
- 原始 CSV 完整保留；主 CI 与 RTLF 无删尾。上游 dudect 自带预热、端点丢弃、裁剪与高阶检验单列记账。
- 不自行生成 Holm 家族；dudect 不进 Holm。不显著或工具不可用不构成恒时证明。
MARKDOWN
printf '%s\n' "${output_directory}/summary.json"
