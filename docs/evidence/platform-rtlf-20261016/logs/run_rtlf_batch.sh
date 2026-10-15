#!/bin/sh
# RTLF 批量执行（远端）：固定 α=0.01、固定 bootstrap 种子 2026101605。
# 退出码 10 = no_difference_detected，11 = difference_detected，其他 = failed。
# 失败原件先归档到 failed/ 再重试（重试由调用者显式发起，本脚本只跑一遍）。
set -eu

root=/home/nss-marker/yhr/Cry/platform-rtlf-20261016
rtlf_script=/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R

# 全部临时/缓存目录落在 Cry 新根内
mkdir -p "${root}/run/tmp" "${root}/run/cache" "${root}/logs" "${root}/results" "${root}/failed"
export TMPDIR="${root}/run/tmp"
export TMP="${TMPDIR}"
export TEMP="${TMPDIR}"
export R_BUILD_TMPDIR="${root}/run/tmp"
export R_SESSION_TMPDIR="${root}/run/tmp"
export R_LIBS_USER="${root}/rlib"
export XDG_CACHE_HOME="${root}/run/cache"
export R_HISTFILE=/dev/null

sha256sum "${rtlf_script}" > "${root}/logs/rtlf-script.sha256"

{
    printf 'run_started_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'host=%s\n' "$(hostname)"
    printf 'kernel=%s\n' "$(uname -srmo)"
    printf 'Rscript=%s\n' "$(Rscript --version 2>&1 | head -n1)"
    printf 'R.version=%s\n' "$(Rscript --vanilla -e 'cat(R.version.string)' 2>&1)"
    printf 'rtlf_script=%s\n' "${rtlf_script}"
    printf 'alpha=0.01\nseed=2026101605\n'
    printf 'TMPDIR=%s\n' "${TMPDIR}"
} > "${root}/logs/environment.txt"

# R 依赖预检：保存原始输出（stdout+stderr）
set +e
Rscript --vanilla -e 'required <- c("tidyverse","optparse","jsonlite","crayon","parallel"); quit(status=if (all(vapply(required, requireNamespace, logical(1), quietly=TRUE))) 0 else 1)' \
    > "${root}/logs/r-preflight.log" 2>&1
preflight_exit=$?
set -e
printf '%s\n' "${preflight_exit}" > "${root}/logs/r-preflight.exit_code"
printf 'command: Rscript --vanilla -e required(tidyverse,optparse,jsonlite,crayon,parallel)\n' >> "${root}/logs/r-preflight.log"
printf 'exit_code: %s\n' "${preflight_exit}" >> "${root}/logs/r-preflight.log"
if [ "${preflight_exit}" -ne 0 ]; then
    printf '%s\n' 'R dependency preflight failed; refusing to run RTLF.' >&2
    exit 3
fi

while IFS= read -r dataset; do
    [ -n "${dataset}" ] || continue
    input="${root}/inputs/${dataset}/normalized.csv"
    result_directory="${root}/results/${dataset}"
    mkdir -p "${result_directory}"
    sha256sum "${input}" > "${result_directory}/input.sha256"
    set +e
    PLATFORM_RTLF_SCRIPT="${rtlf_script}" Rscript --vanilla \
        -e 'set.seed(2026101605); source(Sys.getenv("PLATFORM_RTLF_SCRIPT"))' \
        -i "${input}" -a 0.01 -o "${result_directory}/rtlf.json" -q \
        > "${result_directory}/rtlf.log" 2>&1
    rtlf_exit_status=$?
    set -e
    printf '%s\n' "${rtlf_exit_status}" > "${result_directory}/exit_code.txt"
    case "${rtlf_exit_status}" in
        10) status=no_difference_detected ;;
        11) status=difference_detected ;;
        *) status=failed ;;
    esac
    if [ "${status}" = failed ]; then
        mkdir -p "${root}/failed/${dataset}"
        cp -a "${result_directory}/." "${root}/failed/${dataset}/"
    fi
    printf '%s\t%s\t%s\n' "${dataset}" "${rtlf_exit_status}" "${status}" >> "${root}/logs/run-summary.tsv"
    printf '%-28s exit=%s %s\n' "${dataset}" "${rtlf_exit_status}" "${status}"
done < "${root}/dataset-order.txt"

printf 'run_finished_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${root}/logs/environment.txt"
