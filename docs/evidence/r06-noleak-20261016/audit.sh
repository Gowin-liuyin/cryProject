#!/usr/bin/env bash
# R06 日志/异常/返回码泄露专项审计——可重跑驱动脚本。
#
# 用法：
#   R06_BIN=/abs/path/r06_observable_probe \
#   R06_OUT=/abs/path/diff/remote \
#   bash audit.sh dynamic-diff
#
#   R06_BIN=... \
#   R06_POISON=/abs/path/platform_m5_poison \
#   R06_OUT=/abs/path/memcheck \
#   bash audit.sh memcheck
#
#   bash audit.sh static-scan      # 需要 R06_REPO 指向仓库根
#   bash audit.sh timing-window    # 需要 R06_REPO 指向仓库根
#   bash audit.sh all
#
# 环境变量：
#   R06_REPO   仓库根（默认：脚本所在目录向上四级）
#   R06_OUT    结果目录（默认：脚本所在目录）
#   R06_BIN    可观察面探针 ELF（dynamic-diff 必需）
#   R06_POISON 秘密标记 harness ELF（memcheck 必需）
#   R06_REPEAT 每个模式的重复次数（默认 120，须 >= 100）
#   R06_SEED   公开测试种子（默认 31337）
#   R06_RUNNER 运行包装命令（远端正跑用："taskset -c 0,1,3"；本机留空）
#
# 硬约束：本脚本只在本轮证据目录/结果目录下新增文件，不修改 src/、tests/、fixtures/。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R06_REPO="${R06_REPO:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
R06_OUT="${R06_OUT:-${SCRIPT_DIR}}"
R06_REPEAT="${R06_REPEAT:-120}"
R06_SEED="${R06_SEED:-31337}"
R06_RUNNER="${R06_RUNNER:-}"
R06_DIFF_DIR="${R06_OUT}/diff"

# 七个输入模式：1 个合法 + 6 个隐式拒绝（含 M2 同口径的两个尾部对照类）。
R06_MODES=(valid bit-flipped random message-zero message-ones malformed-zero-tail malformed-ff-tail)

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

log() { printf '%s\n' "$*" | tee -a "${R06_OUT}/audit.sh.log"; }

# ---------------------------------------------------------------------------
# 1) 静态扫描：找出所有可能把内容送出进程边界的调用点，逐条判定是否接触秘密
# ---------------------------------------------------------------------------
cmd_static_scan() {
    local out="${R06_OUT}/static"
    mkdir -p "${out}"
    # 覆盖范围：自有实现 + harness；排除 vendor/、sources/、deliverables/ 内的封存副本。
    ( cd "${R06_REPO}" && find src include tools tests fixtures scripts -type f \
        \( -name '*.c' -o -name '*.h' \) | LC_ALL=C sort ) > "${out}/scanned-files.txt"
    log "[static] 扫描文件数=$(wc -l < "${out}/scanned-files.txt" | tr -d ' ')"

    python3 "${SCRIPT_DIR}/src/r06_static_classify.py" \
        < "${out}/scanned-files.txt" > "${out}/call-sites.tsv" 2> "${out}/call-sites.summary.txt"
    cat "${out}/call-sites.summary.txt" | tee -a "${R06_OUT}/audit.sh.log"

    # 关键词命中明细：便于人工复核"是否接触秘密"。
    local patterns='printf|fprintf|sprintf|snprintf|vsnprintf|vfprintf|puts|fputs|putchar|fputc|fwrite|perror|syslog|write|assert|abort|exit|_exit|errno'
    ( cd "${R06_REPO}" && grep -rEnH "\b(${patterns})\s*\(" src include tools tests fixtures scripts \
        --include='*.c' --include='*.h' ) > "${out}/grep-raw.txt" 2>/dev/null
    log "[static] grep 原始命中行数=$(wc -l < "${out}/grep-raw.txt" | tr -d ' ')"

    # 秘密相关标识符出现位置，供人工核对"输出语句是否可能引用秘密"。
    ( cd "${R06_REPO}" && grep -rEnH \
        '\b(shared_secret|decapsulation_key|secret_key|private_key|m_prime|decapsulated_secret|expected_secret|row_secrets|is_equal|memcmp|rejection_key|indcpa_dec|verify|comparison_result|accept_mismatch|failed_decapsulation)\b' \
        src include tools tests fixtures scripts --include='*.c' --include='*.h' ) \
        > "${out}/secret-identifier-hits.txt" 2>/dev/null
    log "[static] 秘密标识符命中行数=$(wc -l < "${out}/secret-identifier-hits.txt" | tr -d ' ')"
    log "[static] 结果：${out}/call-sites.tsv"
}

# ---------------------------------------------------------------------------
# 2) 动态 diff：合法密文 vs 隐式拒绝密文，各跑 >=100 次，比较 rc / stdout / stderr
# ---------------------------------------------------------------------------
run_probe_once() {
    local mode="$1" out_prefix="$2"
    local rc
    if [ -n "${R06_RUNNER}" ]; then
        # shellcheck disable=SC2086
        ${R06_RUNNER} "${R06_BIN}" "${mode}" 1 "${R06_SEED}" \
            > "${out_prefix}.out" 2> "${out_prefix}.err"
    else
        "${R06_BIN}" "${mode}" 1 "${R06_SEED}" > "${out_prefix}.out" 2> "${out_prefix}.err"
    fi
    rc=$?
    printf '%s\n' "${rc}" > "${out_prefix}.rc"
    return 0
}

cmd_dynamic_diff() {
    : "${R06_BIN:?dynamic-diff 需要 R06_BIN 指向 r06_observable_probe}"
    if [ ! -x "${R06_BIN}" ]; then
        log "[dynamic] 错误：${R06_BIN} 不可执行"; return 1
    fi
    mkdir -p "${R06_DIFF_DIR}"
    local mode repeat
    log "[dynamic] 探针=${R06_BIN}"
    log "[dynamic] 重复次数/模式=${R06_REPEAT}，种子=${R06_SEED}，运行包装='${R06_RUNNER}'"
    for mode in "${R06_MODES[@]}"; do
        local dir="${R06_DIFF_DIR}/raw-${mode}"
        rm -rf "${dir}"; mkdir -p "${dir}"
        : > "${dir}/rc.txt"; : > "${dir}/stdout.sha256.txt"; : > "${dir}/stderr.sha256.txt"
        for repeat in $(seq 1 "${R06_REPEAT}"); do
            run_probe_once "${mode}" "${dir}/$(printf '%04d' "${repeat}")"
            cat "${dir}/$(printf '%04d' "${repeat}").rc" >> "${dir}/rc.txt"
            sha256_of "${dir}/$(printf '%04d' "${repeat}").out" >> "${dir}/stdout.sha256.txt"
            sha256_of "${dir}/$(printf '%04d' "${repeat}").err" >> "${dir}/stderr.sha256.txt"
        done
        # 归并：删除逐次文件，只保留唯一结果（首个）与汇总。
        cp "${dir}/0001.out" "${dir}/stdout.txt"
        cp "${dir}/0001.err" "${dir}/stderr.txt"
        ( cd "${dir}" && rm -f [0-9][0-9][0-9][0-9].out [0-9][0-9][0-9][0-9].err [0-9][0-9][0-9][0-9].rc )
        log "[dynamic] ${mode}: rc唯一集=[$(sort -u "${dir}/rc.txt" | tr '\n' ',')] stdout唯一数=$(sort -u "${dir}/stdout.sha256.txt" | wc -l | tr -d ' ') stderr唯一数=$(sort -u "${dir}/stderr.sha256.txt" | wc -l | tr -d ' ')"
    done

    # 汇总表
    local summary="${R06_DIFF_DIR}/matrix.tsv"
    printf 'mode\truns\trc_set\tstdout_sha256\tstderr_sha256\n' > "${summary}"
    for mode in "${R06_MODES[@]}"; do
        local dir="${R06_DIFF_DIR}/raw-${mode}"
        printf '%s\t%s\t%s\t%s\t%s\n' "${mode}" "${R06_REPEAT}" \
            "$(sort -u "${dir}/rc.txt" | tr '\n' ',')" \
            "$(sort -u "${dir}/stdout.sha256.txt" | tr '\n' ',')" \
            "$(sort -u "${dir}/stderr.sha256.txt" | tr '\n' ',')" >> "${summary}"
    done

    # 逐字节 diff：以 valid 为基准，与每个隐式拒绝模式互 diff。
    local diff_log="${R06_DIFF_DIR}/diff-results.txt"
    : > "${diff_log}"
    for mode in "${R06_MODES[@]}"; do
        local dir="${R06_DIFF_DIR}/raw-${mode}"
        for stream in stdout stderr; do
            {
                printf '=== diff valid.%s %s.%s ===\n' "${stream}" "${mode}" "${stream}"
                diff -u "${R06_DIFF_DIR}/raw-valid/${stream}.txt" "${dir}/${stream}.txt" \
                    && printf '(no difference)\n'
            } >> "${diff_log}"
        done
        {
            printf '=== rc valid=%s %s=%s ===\n' \
                "$(sort -u "${R06_DIFF_DIR}/raw-valid/rc.txt" | tr '\n' ',')" \
                "${mode}" "$(sort -u "${dir}/rc.txt" | tr '\n' ',')"
        } >> "${diff_log}"
    done
    local differing
    differing=$(grep -c '^@@' "${diff_log}" || true)
    log "[dynamic] diff 差异块数=${differing}（0 表示 stdout/stderr 逐字节一致）"
    log "[dynamic] 结果：${summary} 与 ${diff_log}"
}

# ---------------------------------------------------------------------------
# 3) Memcheck：秘密是否作为 syscall 参数流向内核
# ---------------------------------------------------------------------------
cmd_memcheck() {
    : "${R06_POISON:?memcheck 需要 R06_POISON 指向平台秘密标记 harness}"
    mkdir -p "${R06_OUT}/memcheck"
    local runner=()
    if [ -n "${R06_RUNNER}" ]; then
        # shellcheck disable=SC2206
        runner=(${R06_RUNNER})
    fi
    log "[memcheck] harness=${R06_POISON}"
    # 3.1 先跑功能自检（不读钟），确认标记路径本身可运行。
    "${runner[@]}" "${R06_POISON}" --self-test > "${R06_OUT}/memcheck/selftest.out" 2> "${R06_OUT}/memcheck/selftest.err"
    log "[memcheck] --self-test rc=$?（stdout=$(wc -c < "${R06_OUT}/memcheck/selftest.out" | tr -d ' ')B）"
    # 3.2 Valgrind 下运行秘密标记路径；--error-exitcode 使任何命中都反映在 rc 上。
    "${runner[@]}" valgrind --tool=memcheck --error-exitcode=99 \
        --log-file="${R06_OUT}/memcheck/poison.valgrind.log" \
        "${R06_POISON}" --poison > "${R06_OUT}/memcheck/poison.out" 2> "${R06_OUT}/memcheck/poison.err"
    local rc=$?
    log "[memcheck] --poison rc=${rc}"
    grep -E 'ERROR SUMMARY|Syscall param|Conditional jump|uninitialised' \
        "${R06_OUT}/memcheck/poison.valgrind.log" | tee -a "${R06_OUT}/audit.sh.log"
    # 3.3 明确 grep "秘密作为 syscall 参数"这一类报错。
    if grep -qE 'Syscall param .* (contains|points to) uninitialised byte' \
        "${R06_OUT}/memcheck/poison.valgrind.log"; then
        log "[memcheck] 发现：秘密值出现在 syscall 参数中"
    else
        log "[memcheck] 未发现 Syscall param 未初始化/秘密传播报错"
    fi
}

# ---------------------------------------------------------------------------
# 4) 计时窗口：窗口内不得有 I/O 或日志
# ---------------------------------------------------------------------------
cmd_timing_window() {
    local out="${R06_OUT}/window"
    mkdir -p "${out}"
    python3 "${SCRIPT_DIR}/src/r06_window_check.py" \
        "${R06_REPO}/tools/platform_m2/collector.c::M2 collector 计时窗口" \
        "${R06_REPO}/src/measure.c::M5 reference measure 计时窗口" \
        "${R06_REPO}/tools/platform_m2_micro/m2_hotspot_microbench.c::M2 micro 热点窗口" \
        "${R06_REPO}/tools/platform_m4/measure.c::M4 measure 窗口" \
        "${R06_REPO}/tools/platform_perf/perf_measure.c::perf_measure 计时窗口" \
        > "${out}/window-check.txt" 2>&1
    cat "${out}/window-check.txt" | tee -a "${R06_OUT}/audit.sh.log"
    # meta 断言核对
    grep -rn 'window_scope=\|io_window=\|result_consumption_window=\|input_generation_window=' \
        "${R06_REPO}/tools/platform_m2/collector.c" > "${out}/meta-window-claims.txt"
    log "[window] 结果：${out}/window-check.txt"
}

case "${1:-all}" in
    static-scan) cmd_static_scan ;;
    dynamic-diff) cmd_dynamic_diff ;;
    memcheck) cmd_memcheck ;;
    timing-window) cmd_timing_window ;;
    all) cmd_static_scan; cmd_timing_window; cmd_dynamic_diff; cmd_memcheck ;;
    *) printf 'usage: %s {static-scan|dynamic-diff|memcheck|timing-window|all}\n' "$0"; exit 2 ;;
esac
