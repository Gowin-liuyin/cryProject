#!/bin/sh
# 一键复现入口。两档：
#   quick : 配置 + 构建 + CTest（平台开 / 普通 / sanitize，可三选一）+ 每类小样本统计演练。
#           全程不需要 sudo，也不写任何 sysfs 频率节点，可在干净 clone 中直接跑。
#   full  : 按四份冻结 PLAN 生成完整采集命令。默认只打印（dry-run）；加 --execute 才真跑。
#           真跑需要 sudo、需要串行、需要独占 CPU2/CPU6，因此不在 quick 档内。
# 本脚本只做编排，不改变任何既有证据；所有输出写在 --work-dir 下。
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "${script_directory}/.." && pwd)

default_samples_quick=1000
default_run_count=3
default_alpha=0.05
default_configs=platform,ordinary,sanitize,historical-fixed
default_modules=M2,M3,M4,M5
default_full_samples=10000
default_full_timeout=1800
# 与四份冻结 PLAN 一致的三次运行：(seed, cpu)；quick 档不绑核，只沿用种子。
plan_seed_list="31337 424242 31337"
plan_cpu_list="2 2 6"

mode=
configs=${default_configs}
modules=${default_modules}
samples=
run_count=${default_run_count}
jobs=
work_directory=
execute=0
keep_going=0
skip_statistics=0
control_root=
timeout_seconds=${default_full_timeout}
plan_override=
fetch_vendors=0

usage() {
    cat <<'USAGE'
usage: reproduce_all.sh quick [options]
       reproduce_all.sh full  [--execute] [options]

quick（无 sudo；默认在 build/reproduce-quick 下工作）
  --configs LIST       逗号分隔，取值 platform,ordinary,sanitize,historical-fixed（默认四个全跑）
  --samples N          每类样本数，1..20000（默认 1000）
  --runs N             统计演练的重复运行数，1..3（默认 3）
  --jobs N             构建并行度（默认按 CPU 数，最多 8）
  --work-dir DIR       工作目录（默认 <仓库>/build/reproduce-quick）
  --skip-stats         只做配置/构建/CTest，不做小样本统计演练
  --keep-going         某个配置失败后继续跑其余配置（退出码仍非 0）
  --fetch              开工前先跑 tools/fetch_all_vendors.sh，把 M1/M2 需要的 vendor 树取齐并校验 SHA-256

full（默认 dry-run，只打印命令）
  --execute            真正执行；需要 sudo、需要串行，且必须给出 --control-root
  --modules LIST       逗号分隔，取值 M2,M3,M4,M5（默认四个全做）
  --control-root DIR   锁频控制根；真跑时其下必须有 controller.py（dry-run 可用 <控制根> 占位）
  --samples N          每类样本数（默认 10000）
  --timeout-seconds N  单次控制器超时秒数（默认 1800）
  --plan PATH          用指定的 PLAN 副本覆盖默认路径（真跑必须与执行版逐字节一致）
  --work-dir DIR       工作目录（默认 <仓库>/build/reproduce-full）
  --jobs N             构建并行度，同 quick
  --fetch              同 quick；真跑前把 vendor 树取齐

干净 clone 的两条命令：
  sh tools/fetch_all_vendors.sh          # 取齐 M1/M2 的 vendor 树并校验 SHA-256
  sh scripts/reproduce_all.sh quick      # 配置 + 构建 + CTest + 小样本统计演练

不带参数或 --help 时打印本说明。
USAGE
}

log_line() {
    printf '%s\n' "$*"
    if [ -n "${log_file:-}" ]; then
        printf '%s\n' "$*" >>"${log_file}"
    fi
}

fail() {
    log_line "错误：$*"
    exit 1
}

# 逗号列表拆成空白分隔的单词；列表项只允许简单标识符。
split_list() {
    printf '%s\n' "$1" | tr ',' ' '
}

# 记录并执行一条命令；输出同时进日志文件。
run_logged() {
    log_line "+ $*"
    if [ -n "${log_file:-}" ]; then
        "$@" >>"${log_file}" 2>&1 || return $?
    else
        "$@" || return $?
    fi
    return 0
}

# 同上，但在指定目录下执行（platform_holm 的 --output-dir 只接受相对名字）。
run_logged_in_directory() {
    target_directory=$1
    shift
    log_line "+ (cd ${target_directory} && $*)"
    if [ -n "${log_file:-}" ]; then
        (CDPATH= cd -- "${target_directory}" && "$@") >>"${log_file}" 2>&1 || return $?
    else
        (CDPATH= cd -- "${target_directory}" && "$@") || return $?
    fi
    return 0
}

# macOS 有 shasum，多数 Linux 只有 sha256sum。
sha256_of() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        printf '%s\n' "unavailable"
    fi
}

detect_jobs() {
    if [ -n "${jobs}" ]; then
        printf '%s\n' "${jobs}"
        return 0
    fi
    detected=$( (getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) )
    case "${detected}" in
        ''|*[!0-9]*) detected=4 ;;
    esac
    if [ "${detected}" -gt 8 ]; then
        detected=8
    fi
    printf '%s\n' "${detected}"
}

# BUILD_TESTING 需要一个能算 SHA3-256 的 openssl；macOS 自带的是 LibreSSL。
# 这里只做能力探测，找不到就退回 CMake 的逃生开关（native_digest 记为 Skipped）。
detect_openssl3() {
    for candidate in \
        "${OPENSSL_EXECUTABLE:-}" \
        /opt/homebrew/opt/openssl@3/bin/openssl \
        /opt/homebrew/opt/openssl/bin/openssl \
        /usr/local/opt/openssl@3/bin/openssl \
        /usr/local/opt/openssl/bin/openssl \
        "$(command -v openssl 2>/dev/null || true)"; do
        if [ -n "${candidate}" ] && [ -x "${candidate}" ]; then
            case "$("${candidate}" version 2>/dev/null || true)" in
                OpenSSL\ 3*) printf '%s\n' "${candidate}"; return 0 ;;
            esac
        fi
    done
    return 1
}

# 一条配置：$1 配置名 $2 构建目录，其余为 CMake 参数。
configure_and_build() {
    config_name=$1
    build_directory=$2
    shift 2
    log_line ""
    log_line "=== [${config_name}] 配置 ${build_directory} ==="
    if [ -n "${openssl3}" ]; then
        run_logged "${CMAKE}" -S "${repository_root}" -B "${build_directory}" \
            "-DOPENSSL_EXECUTABLE=${openssl3}" "$@" || return 1
    else
        run_logged "${CMAKE}" -S "${repository_root}" -B "${build_directory}" \
            -DBASELINE_ALLOW_NON_SHA3_OPENSSL=ON "$@" || return 1
    fi
    log_line "=== [${config_name}] 构建 ==="
    run_logged "${CMAKE}" --build "${build_directory}" --parallel "$(detect_jobs)" || return 1
    log_line "=== [${config_name}] CTest ==="
    run_logged "${CTEST}" --test-dir "${build_directory}" --output-on-failure || return 1
    return 0
}

# vendor 树是 M1（liboqs 0.10.0 历史阳性对照）与 M2（KyberSlash 两臂）的前提。
# 这些目录都在 .gitignore 内，干净 clone 默认没有；本函数报出缺件并给出取件命令。
vendor_state_line() {
    case "$1" in
        liboqs-base) vendor_path="${repository_root}/vendor/liboqs-0.10.0/CMakeLists.txt" ;;
        liboqs-fixed) vendor_path="${repository_root}/vendor/liboqs-0.10.0-982c762/CMakeLists.txt" ;;
        kyber-unfixed) vendor_path="${repository_root}/vendor/kyber-kyberslash-unfixed/ref/kem.c" ;;
        kyber-fixed) vendor_path="${repository_root}/vendor/kyber-kyberslash-fixed/ref/kem.c" ;;
        *) return 1 ;;
    esac
    if [ -f "${vendor_path}" ]; then
        log_line "  [就位] $1"
        return 0
    fi
    log_line "  [缺件] $1 -> ${vendor_path}"
    return 1
}

# 取件：先看缺不缺，缺则按需调用 tools/fetch_all_vendors.sh，再复核一次。
vendor_preflight() {
    missing_count=0
    log_line ""
    log_line "=== vendor 树预检（M1 历史阳性对照 / M2 KyberSlash 两臂）==="
    for vendor_entry in liboqs-base liboqs-fixed kyber-unfixed kyber-fixed; do
        vendor_state_line "$vendor_entry" || missing_count=$((missing_count + 1))
    done
    if [ "${missing_count}" -eq 0 ]; then
        log_line "四棵 vendor 树齐备，M1/M2 两组历史案例都进本轮构建。"
        return 0
    fi
    if [ "${fetch_vendors}" -eq 1 ]; then
        log_line ""
        log_line "=== 取件：tools/fetch_all_vendors.sh ==="
        if ! run_logged sh "${repository_root}/tools/fetch_all_vendors.sh"; then
            fail "取件失败；请检查网络后重跑 sh tools/fetch_all_vendors.sh"
        fi
        missing_count=0
        for vendor_entry in liboqs-base liboqs-fixed kyber-unfixed kyber-fixed; do
            vendor_state_line "$vendor_entry" || missing_count=$((missing_count + 1))
        done
        if [ "${missing_count}" -eq 0 ]; then
            log_line "取件后四棵 vendor 树齐备。"
            return 0
        fi
        log_line "取件后仍有 ${missing_count} 处缺件；相关臂按缺件跳过。"
        return 0
    fi
    log_line ""
    log_line "缺 ${missing_count} 处 vendor 树（.gitignore 内，干净 clone 默认没有）。"
    log_line "取件命令（一键，含 SHA-256 校验）："
    log_line "    sh tools/fetch_all_vendors.sh"
    log_line "或直接在本脚本上加 --fetch："
    log_line "    sh scripts/reproduce_all.sh quick --fetch"
    log_line "缺件的臂按『缺件即跳过并打印原因』处理，不伪造结果。"
    return 0
}

print_quick_summary() {
    log_line ""
    log_line "=== quick 汇总（配置 / 结果 / CTest）==="
    while IFS= read -r line; do
        log_line "  ${line}"
    done <"${work_directory}/quick-summary.tsv"
    log_line "  日志：${log_file}"
}

quick_main() {
    work_directory=${work_directory:-"${repository_root}/build/reproduce-quick"}
    samples=${samples:-${default_samples_quick}}
    case "${samples}" in
        ''|*[!0-9]*) fail "--samples 必须是整数" ;;
    esac
    if [ "${samples}" -lt 1 ] || [ "${samples}" -gt 20000 ]; then
        fail "--samples 取值 1..20000（measure 的每类上限）"
    fi
    case "${run_count}" in
        ''|*[!0-9]*) fail "--runs 必须是整数" ;;
    esac
    if [ "${run_count}" -lt 1 ] || [ "${run_count}" -gt 3 ]; then
        fail "--runs 取值 1..3"
    fi
    if command -v cmake >/dev/null 2>&1; then
        CMAKE=${CMAKE:-cmake}
    else
        fail "找不到 cmake"
    fi
    if command -v ctest >/dev/null 2>&1; then
        CTEST=${CTEST:-ctest}
    else
        fail "找不到 ctest"
    fi
    mkdir -p "${work_directory}/logs"
    # 工作目录统一取绝对路径：演练里有一处要在子目录中执行（platform_holm 的
    # --output-dir 只接受相对名字），相对路径在 cd 之后会失效。
    work_directory=$(CDPATH= cd -- "${work_directory}" && pwd -P)
    log_file="${work_directory}/logs/quick-$(date -u +%Y%m%dT%H%M%SZ).log"
    : >"${log_file}"
    openssl3=$(detect_openssl3 || true)

    log_line "quick 档：仓库 ${repository_root}"
    log_line "工作目录 ${work_directory}"
    log_line "每类样本 ${samples}，重复运行 ${run_count}，配置 ${configs}"
    log_line "并行度 $(detect_jobs)；cmake ${CMAKE}；ctest ${CTEST}"
    if [ -n "${openssl3}" ]; then
        log_line "SHA3-256 可用的 openssl：${openssl3}"
    else
        log_line "未找到 OpenSSL 3；配置加 -DBASELINE_ALLOW_NON_SHA3_OPENSSL=ON（native_digest 记为 Skipped，不伪装通过）"
    fi
    log_line "本档不写任何 sysfs、不调用 sudo、不绑定 CPU 亲和性。"

    vendor_preflight

    failed_configs=
    : >"${work_directory}/quick-summary.tsv"
    for config_name in $(split_list "${configs}"); do
        status=ok
        build_directory="${work_directory}/build-${config_name}"
        log_start_line=$(wc -l <"${log_file}" | tr -d ' ')
        case "${config_name}" in
            platform)
                if [ -f "${repository_root}/vendor/liboqs-0.10.0/CMakeLists.txt" ]; then
                    # vendor 齐备时把 M1 的 liboqs 0.10.0 历史阳性对照一并编进来。
                    configure_and_build "${config_name}" "${build_directory}" \
                        -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF \
                        -DBASELINE_ENABLE_LIBOQS010=ON || status=failed
                else
                    configure_and_build "${config_name}" "${build_directory}" \
                        -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF || status=failed
                fi
                ;;
            ordinary)
                configure_and_build "${config_name}" "${build_directory}" || status=failed
                ;;
            sanitize)
                configure_and_build "${config_name}" "${build_directory}" \
                    -DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug || status=failed
                ;;
            historical-fixed)
                if [ -f "${repository_root}/vendor/liboqs-0.10.0-982c762/CMakeLists.txt" ]; then
                    # 已修臂要单独一个构建目录：LIBOQS010_SOURCE_DIR 是缓存变量，
                    # 换源树必须换构建目录，否则 ExternalProject 不会重建。
                    configure_and_build "${config_name}" "${build_directory}" \
                        -DBASELINE_ENABLE_LIBOQS010=ON -DA113_ARCHIVED_CASE_ONLY=OFF \
                        "-DLIBOQS010_SOURCE_DIR=${repository_root}/vendor/liboqs-0.10.0-982c762" ||
                        status=failed
                else
                    log_line ""
                    log_line "=== [${config_name}] 跳过：缺 vendor/liboqs-0.10.0-982c762（官方补丁 982c762 已修臂）==="
                    log_line "  取件命令：sh tools/fetch_all_vendors.sh"
                    status=skipped
                fi
                ;;
            *)
                fail "--configs 只接受 platform,ordinary,sanitize,historical-fixed，收到 ${config_name}"
                ;;
        esac
        ctest_summary=$(tail -n "+$((log_start_line + 1))" "${log_file}" |
            grep -E 'tests passed, .* tests failed out of' | tail -1 || true)
        if [ "${status}" = skipped ]; then
            ctest_summary="（本配置未构建）"
        fi
        printf '%s | %s | %s\n' "${config_name}" "${status}" "${ctest_summary}" \
            >>"${work_directory}/quick-summary.tsv"
        if [ "${status}" = failed ]; then
            failed_configs="${failed_configs} ${config_name}"
            if [ "${keep_going}" -eq 0 ]; then
                log_line "配置 ${config_name} 失败；未加 --keep-going，停止。"
                print_quick_summary
                exit 1
            fi
        fi
    done

    rehearsal_failed=0
    if [ "${skip_statistics}" -eq 0 ]; then
        if [ -d "${work_directory}/build-platform" ]; then
            if ! rehearsal_main "${work_directory}/build-platform" "${work_directory}/build-historical-fixed"; then
                rehearsal_failed=1
            fi
        else
            log_line ""
            log_line "统计演练跳过：platform 配置未构建（--configs 未包含 platform，或该配置失败）。"
        fi
    else
        log_line ""
        log_line "统计演练按 --skip-stats 跳过。"
    fi

    print_quick_summary
    if [ -n "${failed_configs}" ]; then
        log_line "失败配置：${failed_configs}"
        exit 1
    fi
    if [ "${rehearsal_failed}" -ne 0 ]; then
        log_line "统计演练失败；一键复现不算跑通。"
        exit 1
    fi
    log_line "quick 档完成。"
    return 0
}

# 小样本统计演练：每个可用臂各跑 run_count 次，platform_stats 做 Welch，
# platform_holm 做族内 Holm。它是流程演练，不是任何模块的正式统计证据。
rehearsal_main() {
    platform_build=$1
    historical_fixed_build=$2
    rehearsal_root="${work_directory}/rehearsal"
    mkdir -p "${rehearsal_root}"
    log_line ""
    log_line "=== 小样本统计演练（每类 ${samples} 次 × ${run_count} 次运行）==="

    stats_program="${platform_build}/platform_stats"
    holm_program="${platform_build}/platform_holm"
    rehearsal_failure=0
    if [ ! -x "${stats_program}" ]; then
        log_line "演练跳过：缺少 ${stats_program}"
        return 0
    fi
    if [ ! -x "${holm_program}" ]; then
        log_line "演练跳过：缺少 ${holm_program}"
        return 0
    fi
    log_line "平台二进制根 ${platform_build}"

    # 臂表：模块|臂名|可执行文件|调用形式|类对
    arm_table="${rehearsal_root}/arms.txt"
    : >"${arm_table}"
    add_arm() {
        if [ -x "$3" ]; then
            printf '%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "$5" >>"${arm_table}"
        else
            log_line "臂未构建，跳过：$1/$2 -> $3"
        fi
    }
    # M1：liboqs 0.10.0 历史阳性对照（未修在 platform 配置里，已修在单独构建目录里）。
    if [ -x "${platform_build}/historical/measure" ]; then
        add_arm M1 unfixed "${platform_build}/historical/measure" measure-ns \
            message-zero,message-ones
    else
        log_line "M1 未修臂未构建，跳过：缺 vendor/liboqs-0.10.0（sh tools/fetch_all_vendors.sh）"
    fi
    if [ -x "${historical_fixed_build}/historical/measure" ]; then
        add_arm M1 fixed "${historical_fixed_build}/historical/measure" measure-ns \
            message-zero,message-ones
    else
        log_line "M1 已修臂未构建，跳过：缺 vendor/liboqs-0.10.0-982c762（sh tools/fetch_all_vendors.sh）"
    fi
    if [ -x "${platform_build}/platform-m2/unfixed/measure" ]; then
        add_arm M2 unfixed "${platform_build}/platform-m2/unfixed/measure" measure-ns \
            message-zero,message-ones
        add_arm M2 fixed "${platform_build}/platform-m2/fixed/measure" measure-ns \
            message-zero,message-ones
    else
        log_line "M2 未构建，跳过：缺 vendor/kyber-kyberslash-{unfixed,fixed}（.gitignore 内，sh tools/fetch_all_vendors.sh）"
    fi
    add_arm M3 on "${platform_build}/platform-m3/on/measure" measure-ns message-zero,message-ones
    add_arm M3 off "${platform_build}/platform-m3/off/measure" measure-ns message-zero,message-ones
    add_arm M4 vulnerable "${platform_build}/platform_m4_measure_vulnerable" m4 \
        mismatch-first,mismatch-last
    add_arm M4 ct "${platform_build}/platform_m4_measure_ct" m4 mismatch-first,mismatch-last
    add_arm M5 reference "${platform_build}/reference/measure" measure-ns message-zero,message-ones

    if [ ! -s "${arm_table}" ]; then
        log_line "没有任何可用采集臂；演练跳过。"
        return 0
    fi

    : >"${rehearsal_root}/members.index"
    seed_number=0
    for seed in ${plan_seed_list}; do
        seed_number=$((seed_number + 1))
        if [ "${seed_number}" -gt "${run_count}" ]; then
            break
        fi
        while IFS='|' read -r module_name arm_name arm_binary arm_form class_pair; do
            run_name="quick-${module_name}-${arm_name}-r${seed_number}"
            run_directory="${rehearsal_root}/${module_name}/${arm_name}/r${seed_number}"
            mkdir -p "${run_directory}"
            raw_csv="${run_directory}/${run_name}.csv"
            meta_file="${run_directory}/${run_name}.meta"
            if [ -f "${raw_csv}" ]; then
                log_line "演练复用已存在：${raw_csv}"
            else
                case "${arm_form}" in
                    measure-ns)
                        run_logged "${arm_binary}" "${run_name}" "${seed}" "${samples}" \
                            "${raw_csv}" "${meta_file}" || {
                            log_line "采集失败：${run_name}"
                            continue
                        }
                        ;;
                    m4)
                        run_logged "${arm_binary}" --collect "${raw_csv}" "${samples}" \
                            "${seed}" "${run_name}" --compare-bytes 32 || {
                            log_line "采集失败：${run_name}"
                            continue
                        }
                        ;;
                esac
            fi
            stats_directory="${run_directory}/stats"
            class0=${class_pair%%,*}
            class1=${class_pair##*,}
            if [ ! -f "${stats_directory}/ci_welch.json" ]; then
                # platform_stats 用 "wx" 打开输出文件，要求目录已存在。
                mkdir -p "${stats_directory}"
                run_logged "${stats_program}" "${raw_csv}" measure "${class0}" "${class1}" \
                    "${stats_directory}" || {
                    log_line "统计失败：${run_name}"
                    continue
                }
            fi
            printf '%s|%s|%s\n' "${module_name}" "${module_name}-${arm_name}-r${seed_number}" \
                "${stats_directory}" >>"${rehearsal_root}/members.index"
        done <"${arm_table}"
    done

    if [ ! -s "${rehearsal_root}/members.index" ]; then
        log_line "演练没有产出任何统计目录。"
        return 0
    fi

    for module_name in M1 M2 M3 M4 M5; do
        module_family="${module_name}_quick_rehearsal"
        members_csv="${rehearsal_root}/${module_name}-members.csv"
        printf '%s\n' \
            'family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,ci95_high_ns' \
            >"${members_csv}"
        member_count=0
        while IFS='|' read -r row_module member_id stats_directory; do
            if [ "${row_module}" != "${module_name}" ]; then
                continue
            fi
            json_file="${stats_directory}/ci_welch.json"
            normalized_file="${stats_directory}/normalized.csv"
            if [ ! -f "${json_file}" ] || [ ! -f "${normalized_file}" ]; then
                log_line "缺少 ${json_file}；${member_id} 不计入 ${module_family}"
                continue
            fi
            awk -F, '
                NR > 1 && $1 == "X" {n0++; s0 += $2; q0 += $2 * $2}
                NR > 1 && $1 == "Y" {n1++; s1 += $2; q1 += $2 * $2}
                END {
                    if (n0 < 2 || n1 < 2) {print "0 0 0 0 0 0"; exit}
                    m0 = s0 / n0; m1 = s1 / n1
                    v0 = (q0 - n0 * m0 * m0) / (n0 - 1)
                    v1 = (q1 - n1 * m1 * m1) / (n1 - 1)
                    printf "%.10g %.10g %.10g %.10g %d %d\n", m0, m1, sqrt(v0), sqrt(v1), n0, n1
                }' "${normalized_file}" >"${stats_directory}/welch-raw.txt"
            read -r mean0 mean1 sd0 sd1 n0 n1 <"${stats_directory}/welch-raw.txt"
            if [ "${n0}" = "0" ]; then
                log_line "${member_id} 的 normalized.csv 不足两列样本；跳过"
                continue
            fi
            p_value=$(sed -n 's/.*"p_two_sided_normal_approximation": *\([-0-9.eE+]*\).*/\1/p' \
                "${json_file}" | head -1)
            ci_low=$(sed -n 's/.*"ci95_normal_lower_ns": *\([-0-9.eE+]*\).*/\1/p' \
                "${json_file}" | head -1)
            ci_high=$(sed -n 's/.*"ci95_normal_upper_ns": *\([-0-9.eE+]*\).*/\1/p' \
                "${json_file}" | head -1)
            if [ -z "${p_value}" ] || [ -z "${ci_low}" ] || [ -z "${ci_high}" ]; then
                log_line "${member_id} 的 ci_welch.json 字段不全；跳过"
                continue
            fi
            printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' "${module_family}" "${member_id}" \
                "${mean0}" "${mean1}" "${sd0}" "${sd1}" "${n0}" "${n1}" "${p_value}" \
                "${ci_low}" "${ci_high}" >>"${members_csv}"
            member_count=$((member_count + 1))
        done <"${rehearsal_root}/members.index"
        if [ "${member_count}" -eq 0 ]; then
            log_line "${module_name}：无成员，跳过 Holm 演练"
            continue
        fi
        log_line ""
        log_line "--- ${module_name} Holm 演练：${member_count} 个成员，alpha=${default_alpha} ---"
        holm_parent="${rehearsal_root}/${module_name}"
        holm_name="${module_name}-holm"
        mkdir -p "${holm_parent}"
        if run_logged_in_directory "${holm_parent}" "${holm_program}" --input "${members_csv}" \
            --output-dir "${holm_name}" --alpha "${default_alpha}"; then
            for holm_output in holm.csv pooled.csv; do
                if [ -f "${holm_parent}/${holm_name}/${holm_output}" ]; then
                    while IFS= read -r output_line; do
                        log_line "  ${output_line}"
                    done <"${holm_parent}/${holm_name}/${holm_output}"
                fi
            done
        else
            log_line "错误：${module_name} 的 platform_holm 运行失败（见日志）"
            rehearsal_failure=1
        fi
    done

    log_line ""
    log_line "演练产物根：${rehearsal_root}"
    log_line "注意：演练不锁频、不绑核、每臂只 ${run_count} 次运行，不是任何模块的正式统计结论。"
    if [ "${rehearsal_failure}" -ne 0 ]; then
        log_line "错误：统计演练未全部完成（一键复现不能算跑通），按失败返回。"
        return 1
    fi
    return 0
}

full_module_plan_path() {
    case "$1" in
        M2) printf '%s\n' "${repository_root}/docs/evidence/m2-kem-20261016/PLAN.md" ;;
        M3) printf '%s\n' "${repository_root}/docs/evidence/m3-completion-20261016/PLAN.md" ;;
        M4) printf '%s\n' "${repository_root}/docs/evidence/m4-completion-20261016/PLAN.md" ;;
        M5) printf '%s\n' "${repository_root}/docs/evidence/m5-completion-20261016/PLAN.md" ;;
        *) return 1 ;;
    esac
}

# 每模块的臂与调用尾；dry-run 逐条打印，与 PLAN 的执行入口同形。
# $1 模块 $2 样品数 打印 "<臂名>|<run-name 前缀>|<采集件路径占位>|<参数尾>"
full_module_arms() {
    case "$1" in
        M2)
            printf '%s\n' \
                "unfixed|m2-r0N-unfixed-main|<平台构建>/collector/unfixed/m2_decaps_collector|--class message-zero,message-ones --samples $2 --seed <SEED> --warmup 100 --raw <新目录>/<RUN>.csv --meta <新目录>/<RUN>.meta --run-id <RUN> --public-key <fixtures>/pk.bin --secret-key <fixtures>/sk.bin" \
                "fixed|m2-r0N-fixed-main|<平台构建>/collector/fixed/m2_decaps_collector|--class message-zero,message-ones --samples $2 --seed <SEED> --warmup 100 --raw <新目录>/<RUN>.csv --meta <新目录>/<RUN>.meta --run-id <RUN> --public-key <fixtures>/pk.bin --secret-key <fixtures>/sk.bin"
            ;;
        M3)
            printf '%s\n' \
                "on|m3-r0N-on|<平台构建>/platform-m3/on/measure|<RUN> <SEED> $2 <新目录>/<RUN>.csv <新目录>/<RUN>.meta" \
                "off|m3-r0N-off|<平台构建>/platform-m3/off/measure|<RUN> <SEED> $2 <新目录>/<RUN>.csv <新目录>/<RUN>.meta"
            ;;
        M4)
            printf '%s\n' \
                "vulnerable|m4-r0N-vulnerable|<平台构建>/platform_m4_measure_vulnerable|--collect <新目录>/<RUN>.csv $2 <SEED> <RUN> --compare-bytes 32" \
                "ct|m4-r0N-ct|<平台构建>/platform_m4_measure_ct|--collect <新目录>/<RUN>.csv $2 <SEED> <RUN> --compare-bytes 32" \
                "vulnerable-truncated|m4-r0N-vulnerable-trunc|<平台构建>/platform_m4_measure_vulnerable|--collect <新目录>/<RUN>.csv $2 <SEED> <RUN> --compare-bytes 16" \
                "ct-truncated|m4-r0N-ct-trunc|<平台构建>/platform_m4_measure_ct|--collect <新目录>/<RUN>.csv $2 <SEED> <RUN> --compare-bytes 16"
            ;;
        M5)
            printf '%s\n' \
                "reference|m5-r0N-reference|<平台构建>/reference/measure|<RUN> <SEED> $2 <新目录>/<RUN>.csv <新目录>/<RUN>.meta"
            ;;
        *) return 1 ;;
    esac
}

full_module_online_dudect() {
    case "$1" in
        M2) printf '%s\n' "<平台构建>/collector/{unfixed,fixed}/m2_dudect --collect <新目录>/<RUN>.csv <BATCHES> <SEED> <fixtures>/pk.bin <fixtures>/sk.bin" ;;
        M3) printf '%s\n' "<平台构建>/platform-m3/{on,off}/<M5 系 dudect 入口，本轮未重建逐样本 CSV 版>" ;;
        M4) printf '%s\n' "<平台构建>/platform_m4_dudect_{vulnerable,ct} --collect <新目录>/<RUN>.csv <BATCHES> <SEED>" ;;
        M5) printf '%s\n' "<平台构建>/platform_m5_dudect --collect --seed <SEED> --raw <新目录>/<RUN>.csv" ;;
    esac
}

full_main() {
    work_directory=${work_directory:-"${repository_root}/build/reproduce-full"}
    samples=${samples:-${default_full_samples}}
    mkdir -p "${work_directory}/logs"
    log_file="${work_directory}/logs/full-run.log"
    : >"${log_file}"
    control_root_display=${control_root:-<控制根>}

    log_line "full 档：仓库 ${repository_root}"
    log_line "工作目录 ${work_directory}"
    log_line "模块 ${modules}；每类 ${samples}；超时 ${timeout_seconds}s；模式 $([ "${execute}" -eq 1 ] && echo execute || echo dry-run)"
    log_line ""
    log_line "锁频调用点需要 sudo，且必须串行：同一时间只能有一个控制器任务持有"
    log_line "Cry/partition-admin.lock；CPU2 与 CPU6 不得与其他模块采数重叠。"
    log_line "控制器资格与合同见 tools/platform_control/README.md 与"
    log_line "docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md。"

    vendor_preflight

    if [ "${execute}" -eq 1 ]; then
        if [ -z "${control_root}" ]; then
            fail "--execute 必须同时给出 --control-root（其下需有 controller.py）"
        fi
        case "${control_root}" in
            */Cry|*/Cry/*) : ;;
            *) fail "--control-root 必须位于云端唯一存放边界 <...>/Cry 之下：${control_root}" ;;
        esac
        if [ ! -f "${control_root}/controller.py" ]; then
            fail "${control_root}/controller.py 不存在"
        fi
        log_line ""
        log_line "即将真跑：会请求 sudo、会写 sysfs 频率节点、会独占目标核。"
        log_line "本脚本只逐条执行下面的控制器命令；每条失败即停，不自动重试、不自动恢复频率。"
    fi

    for module_name in $(split_list "${modules}"); do
        plan_file=${plan_override:-$(full_module_plan_path "${module_name}" || true)}
        if [ -z "${plan_file}" ] || [ ! -f "${plan_file}" ]; then
            log_line "${module_name}：找不到 PLAN（${plan_file}），跳过"
            continue
        fi
        log_line ""
        log_line "=== ${module_name} ==="
        log_line "PLAN（工作区）：${plan_file}"
        log_line "工作区 PLAN 的 sha256：$(sha256_of "${plan_file}")"
        log_line "注意：控制器校验的是执行版 PLAN 的 sha256。四份 PLAN 在 efca8a1 冻结后又各做过一次"
        log_line "文档修订，工作区摘要与执行版不同；真跑必须用与执行版逐字节一致的副本，执行版摘要见"
        log_line "docs/evidence/platform-collection-20261016/README.md。"
        log_line "online dudect 入口：$(full_module_online_dudect "${module_name}")"

        run_ordinal=0
        for seed in ${plan_seed_list}; do
            run_ordinal=$((run_ordinal + 1))
            plan_cpu=$(printf '%s\n' ${plan_cpu_list} | sed -n "${run_ordinal}p")
            while IFS='|' read -r arm_name run_prefix collect_binary command_tail; do
                run_name=$(printf '%s' "${run_prefix}" | sed "s/r0N/r0${run_ordinal}/")
                resolved_tail=$(printf '%s' "${command_tail}" | sed "s/<SEED>/${seed}/g; s/<RUN>/${run_name}/g")
                log_line ""
                log_line "sudo -n /usr/bin/python3 -I -B ${control_root_display}/controller.py run \\"
                log_line "    --control-root ${control_root_display} --run-name ${run_name} \\"
                log_line "    --cpu ${plan_cpu} --timeout-seconds ${timeout_seconds} \\"
                log_line "    --plan ${control_root_display}/PLAN.md --plan-sha256 <执行版PLAN的sha256> \\"
                log_line "    -- ${collect_binary} ${resolved_tail}"
            done <<EOF
$(full_module_arms "${module_name}" "${samples}")
EOF
        done
        log_line "（以上逐条打印 measure/collector 主路径与截断臂；online dudect 每个 run 另有一次控制器调用，"
        log_line "入口见上面的『online dudect 入口』行，族外结果不进 Holm。）"
    done

    log_line ""
    log_line "每个模块跑完后的统计入口（只读 CSV，不采集硬件）："
    log_line "  scripts/run_stats_battery.sh --input <原CSV> --format measure --classes <class0> <class1> \\"
    log_line "      --output-dir <新目录> --stats-bin <平台构建>/platform_stats"
    log_line "  <平台构建>/platform_holm --input <members.csv> --output-dir <新目录> --alpha 0.05"
    log_line "族外 RTLF：Rscript third_party/RTLF/rtlf.R -i <normalized.csv> -a 0.01 -o <rtlf.json> -q"
    log_line ""
    if [ "${execute}" -eq 0 ]; then
        log_line "以上为 dry-run，未执行任何命令；加 --execute --control-root DIR 才会真正执行。"
    fi
    log_line "日志：${log_file}"
    return 0
}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

mode=$1
shift
case "${mode}" in
    quick|full) : ;;
    --help|-h|help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

while [ "$#" -gt 0 ]; do
    case "$1" in
        --configs|--modules|--samples|--runs|--jobs|--work-dir|--timeout-seconds|--control-root|--plan)
            if [ "$#" -lt 2 ]; then
                usage >&2
                exit 2
            fi
            option=$1
            value=$2
            case "${option}" in
                --configs) configs=${value} ;;
                --modules) modules=${value} ;;
                --samples) samples=${value} ;;
                --runs) run_count=${value} ;;
                --jobs) jobs=${value} ;;
                --work-dir) work_directory=${value} ;;
                --timeout-seconds) timeout_seconds=${value} ;;
                --control-root) control_root=${value} ;;
                --plan) plan_override=${value} ;;
            esac
            shift 2
            ;;
        --execute) execute=1; shift ;;
        --keep-going) keep_going=1; shift ;;
        --skip-stats) skip_statistics=1; shift ;;
        --fetch) fetch_vendors=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

if [ "${mode}" = quick ]; then
    if [ "${execute}" -eq 1 ] || [ -n "${control_root}" ]; then
        fail "quick 档不接受 --execute/--control-root；完整采集请用 full 档"
    fi
    quick_main
else
    full_main
fi
