#!/bin/sh
# M2 除法热点微基准的功能资格 + CLI 准入 + 解锁冒烟 + --format measure 兼容性。
# 只做功能与协议资格；不锁频、不改亲和性，产出的 ns 值不得用于任何统计或泄漏结论。
# usage: run_micro_qualification.sh <tree-root>
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: run_micro_qualification.sh <tree-root>" >&2
    exit 2
fi
tree_root=$1
source_dir=${tree_root}/source
frozen=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a
fixtures=${frozen}/qualification-ordinary/fixtures
collector_meta=${frozen}/qualification-ordinary/smoke/main_u_seed31337.meta
collector_validation_log=${frozen}/qualification-ordinary/logs/smoke_u_seed31337_replay.stdout
kat_response=${source_dir}/tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp
stats_bin=/home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
stats_bin_sha256=ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2
ordinary=${tree_root}/build-ordinary
sanitize=${tree_root}/build-sanitize
out=${tree_root}/qualification-ordinary
smoke=${tree_root}/qualification-smoke
failed_count=0

for required_path in "${ordinary}/microbench/unfixed/m2_hotspot_microbench" \
    "${sanitize}/microbench/fixed/m2_hotspot_microbench" "${fixtures}/pk.bin" "${fixtures}/sk.bin" \
    "${collector_meta}" "${kat_response}" "${stats_bin}"; do
    if [ ! -e "${required_path}" ]; then
        echo "missing required path: ${required_path}" >&2
        exit 2
    fi
done
if [ -e "${out}" ] || [ -e "${smoke}" ]; then
    echo "qualification output directories already exist; refusing to overwrite" >&2
    exit 2
fi
mkdir -p "${out}" "${smoke}"

check() {
    check_name=$1
    shift
    if "$@"; then
        printf 'guard=%s status=PASS\n' "${check_name}"
    else
        printf 'guard=%s status=FAIL\n' "${check_name}"
        failed_count=$((failed_count + 1))
    fi
}

# 期望失败的调用：非零退出，且不得留下任何输出文件。
expect_failure() {
    guard_name=$1
    expected_status=$2
    shift 2
    probe_csv=${smoke}/guard-${guard_name}.csv
    rm -f "${probe_csv}"
    set +e
    "$@" >"${smoke}/guard-${guard_name}.stdout" 2>&1
    actual_status=$?
    set -e
    if [ "${actual_status}" -ne "${expected_status}" ]; then
        printf 'guard=%s status=FAIL expected_exit=%s actual_exit=%s\n' "${guard_name}" \
            "${expected_status}" "${actual_status}"
        failed_count=$((failed_count + 1))
        return 0
    fi
    if [ -e "${probe_csv}" ]; then
        printf 'guard=%s status=FAIL leftover_output=%s\n' "${guard_name}" "${probe_csv}"
        failed_count=$((failed_count + 1))
        return 0
    fi
    printf 'guard=%s status=PASS exit=%s\n' "${guard_name}" "${actual_status}"
}

printf '=== 功能资格（普通构建，两臂）===\n'
for variant in unfixed fixed; do
    "${ordinary}/qualification/${variant}/m2_hotspot_qualification" \
        --public-key "${fixtures}/pk.bin" --secret-key "${fixtures}/sk.bin" \
        --kat-response "${kat_response}" --collector-meta "${collector_meta}" \
        --transcript "${out}/transcript-${variant}.txt" | tee "${out}/qualification-${variant}.log"
    if ! grep -q 'qualification_fail_count=0 qualification_skip_count=0' \
        "${out}/qualification-${variant}.log"; then
        printf 'guard=qualification_%s_summary status=FAIL\n' "${variant}"
        failed_count=$((failed_count + 1))
    else
        printf 'guard=qualification_%s_summary status=PASS\n' "${variant}"
    fi
done

printf '=== 动态资格（ASan/UBSan，两臂；只做内存/UB 检查，不用于机制或计时）===\n'
for variant in unfixed fixed; do
    "${sanitize}/qualification/${variant}/m2_hotspot_qualification" \
        --public-key "${fixtures}/pk.bin" --secret-key "${fixtures}/sk.bin" \
        --kat-response "${kat_response}" --collector-meta "${collector_meta}" \
        >"${out}/qualification-sanitize-${variant}.log" 2>&1
    if ! grep -q 'qualification_fail_count=0 qualification_skip_count=0' \
        "${out}/qualification-sanitize-${variant}.log"; then
        printf 'guard=qualification_sanitize_%s status=FAIL\n' "${variant}"
        failed_count=$((failed_count + 1))
    else
        printf 'guard=qualification_sanitize_%s status=PASS\n' "${variant}"
    fi
done

printf '=== 跨臂转录逐字节一致（只在函数等价意义上）===\n'
check transcript_arms_identical cmp -s "${out}/transcript-unfixed.txt" "${out}/transcript-fixed.txt"

printf '=== 冻结采集件的公开 KAT（只读执行，不写冻结树）===\n'
for variant in unfixed fixed; do
    "${frozen}/build-ordinary/qualification/${variant}/m2_platform_kat" "${kat_response}" \
        >"${out}/kat-${variant}.log" 2>&1
    if ! grep -qi 'passed\|ok\|success' "${out}/kat-${variant}.log"; then
        printf 'guard=kat_%s status=FAIL\n' "${variant}"
        failed_count=$((failed_count + 1))
    else
        printf 'guard=kat_%s status=PASS\n' "${variant}"
    fi
done

printf '=== CLI 准入（未修臂，期望失败不留输出）===\n'
unfixed_elf=${ordinary}/microbench/unfixed/m2_hotspot_microbench
fixed_elf=${ordinary}/microbench/fixed/m2_hotspot_microbench
expect_failure no_arguments 2 "${unfixed_elf}"
expect_failure unknown_option 2 "${unfixed_elf}" --class message-zero --samples 2 --seed 1 \
    --raw "${smoke}/guard-unknown_option.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin" --bogus 1
expect_failure unknown_class 2 "${unfixed_elf}" --class message-zero,bogus --samples 2 --seed 1 \
    --raw "${smoke}/guard-unknown_class.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure malformed_class 2 "${unfixed_elf}" --class malformed-zero-tail --samples 2 --seed 1 \
    --raw "${smoke}/guard-malformed_class.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure duplicate_class 2 "${unfixed_elf}" --class message-zero,message-zero --samples 2 \
    --seed 1 --raw "${smoke}/guard-duplicate_class.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure zero_samples 2 "${unfixed_elf}" --class message-zero --samples 0 --seed 1 \
    --raw "${smoke}/guard-zero_samples.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure oversized_samples 2 "${unfixed_elf}" --class message-zero --samples 20001 --seed 1 \
    --raw "${smoke}/guard-oversized_samples.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure non_decimal_seed 2 "${unfixed_elf}" --class message-zero --samples 2 --seed abc \
    --raw "${smoke}/guard-non_decimal_seed.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure zero_warmup 2 "${unfixed_elf}" --class message-zero --samples 2 --seed 1 --warmup 0 \
    --raw "${smoke}/guard-zero_warmup.csv" --public-key "${fixtures}/pk.bin" \
    --secret-key "${fixtures}/sk.bin"
expect_failure missing_raw 2 "${unfixed_elf}" --class message-zero --samples 2 --seed 1 \
    --public-key "${fixtures}/pk.bin" --secret-key "${fixtures}/sk.bin"
expect_failure absent_public_key 1 "${unfixed_elf}" --class message-zero --samples 2 --seed 1 \
    --raw "${smoke}/guard-absent_public_key.csv" --public-key "${smoke}/absent-pk.bin" \
    --secret-key "${fixtures}/sk.bin"
head -c 100 "${fixtures}/pk.bin" >"${smoke}/short-pk.bin"
expect_failure short_public_key 1 "${unfixed_elf}" --class message-zero --samples 2 --seed 1 \
    --raw "${smoke}/guard-short_public_key.csv" --public-key "${smoke}/short-pk.bin" \
    --secret-key "${fixtures}/sk.bin"

printf '=== 解锁冒烟（不是统计结果；不得用于任何结论）===\n'
cat >"${smoke}/README.txt" <<'SMOKE_NOTE'
本目录是 M2 除法热点微基准的解锁冒烟与 format 兼容性检查。
未绑核、未锁频（meta 记 cpu_affinity=not_pinned、frequency_control=not_configured），
其中的 ns 数值不得用于任何统计、泄漏或性能结论，也不属于预注册微基准家族。
SMOKE_NOTE

run_smoke() {
    smoke_name=$1
    smoke_variant=$2
    smoke_seed=$3
    smoke_samples=$4
    if [ "${smoke_variant}" = unfixed ]; then
        smoke_elf=${unfixed_elf}
    else
        smoke_elf=${fixed_elf}
    fi
    rm -f "${smoke}/${smoke_name}.csv" "${smoke}/${smoke_name}.meta"
    "${smoke_elf}" --class message-zero,message-ones --samples "${smoke_samples}" \
        --seed "${smoke_seed}" --warmup 100 --raw "${smoke}/${smoke_name}.csv" \
        --meta "${smoke}/${smoke_name}.meta" --run-id "${smoke_name}" \
        --public-key "${fixtures}/pk.bin" --secret-key "${fixtures}/sk.bin" \
        >"${smoke}/${smoke_name}.stdout" 2>&1
}

run_smoke smoke-unfixed unfixed 31337 200
run_smoke smoke-fixed fixed 31337 200
run_smoke smoke-unfixed-replay unfixed 31337 200
run_smoke smoke-unfixed-seed424242 unfixed 424242 200
run_smoke smoke-unfixed-collector-params unfixed 31337 100

check smoke_header_exact \
    grep -q '^run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit$' \
    "${smoke}/smoke-unfixed.csv"
check smoke_row_count test "$(wc -l <"${smoke}/smoke-unfixed.csv")" -eq 401
check smoke_unit_ns test "$(grep -c ',ns$' "${smoke}/smoke-unfixed.csv")" -eq 400
check smoke_meta_warmup \
    grep -q '^warmup_hotspot_calls=100$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_warmup_attempted \
    grep -q '^warmup_attempted_calls=100$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_warmup_completed \
    grep -q '^warmup_completed_calls=100$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_scope \
    grep -q '^window_scope=one_poly_tomsg_call$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_symbol \
    grep -q '^hotspot_symbol=pqcrystals_kyber768_ref_poly_tomsg$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_status grep -q '^run_status=complete$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_no_zero_elapsed grep -q '^zero_elapsed_count=0$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_no_mismatch \
    grep -q '^chosen_message_hotspot_mismatch_count=0$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_affinity grep -q '^cpu_affinity=not_pinned$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_frequency grep -q '^frequency_control=not_configured$' "${smoke}/smoke-unfixed.meta"
check smoke_meta_self_hash \
    grep -q "^executable_sha3_256=$(openssl dgst -sha3-256 "${unfixed_elf}" | sed 's/.*= //')$" \
    "${smoke}/smoke-unfixed.meta"
check smoke_minimum_not_trimmed \
    test "$(sed -n 's/^minimum_elapsed_nanoseconds=//p' "${smoke}/smoke-unfixed.meta")" \
    -eq "$(awk -F, 'NR>1 {if (min==""||$5<min) min=$5} END {print min}' "${smoke}/smoke-unfixed.csv")"
tail -n +2 "${smoke}/smoke-unfixed.csv" | cut -d, -f3 >"${smoke}/smoke-unfixed.classes"
tail -n +2 "${smoke}/smoke-unfixed-replay.csv" | cut -d, -f3 >"${smoke}/smoke-unfixed-replay.classes"
tail -n +2 "${smoke}/smoke-unfixed-seed424242.csv" | cut -d, -f3 >"${smoke}/smoke-unfixed-seed424242.classes"
check smoke_replay_order_identical cmp -s "${smoke}/smoke-unfixed.classes" \
    "${smoke}/smoke-unfixed-replay.classes"
if cmp -s "${smoke}/smoke-unfixed.classes" "${smoke}/smoke-unfixed-seed424242.classes"; then
    printf 'guard=smoke_seed_changes_order status=FAIL\n'
    failed_count=$((failed_count + 1))
else
    printf 'guard=smoke_seed_changes_order status=PASS\n'
fi
check smoke_seed_keeps_counts test "$(sort "${smoke}/smoke-unfixed-seed424242.classes" | uniq -c |
    awk '{print $1}' | sort -u | tr -d ' ')" = "200"
check smoke_per_class_counts \
    test "$(tail -n +2 "${smoke}/smoke-unfixed.csv" | cut -d, -f3 | sort | uniq -c | awk '{print $1}' | sort -u | tr -d ' ')" = "200"
check smoke_cross_arm_input_digest \
    test "$(sed -n 's/^input_sequence_digest=//p' "${smoke}/smoke-unfixed.meta")" = \
    "$(sed -n 's/^input_sequence_digest=//p' "${smoke}/smoke-fixed.meta")"
check smoke_collector_input_digest \
    test "$(sed -n 's/^input_sequence_digest=//p' "${smoke}/smoke-unfixed-collector-params.meta")" = \
    "$(sed -n 's/^input_sequence_digest=//p' "${collector_meta}")"
check stats_binary_sha256 \
    test "$(sha256sum "${stats_bin}" | cut -d' ' -f1)" = "${stats_bin_sha256}"

printf '=== --format measure 兼容性（冻结 platform_stats 解析器，仅格式检查）===\n'
mkdir -p "${smoke}/measure-format-check"
"${stats_bin}" "${smoke}/smoke-unfixed.csv" measure message-zero message-ones \
    "${smoke}/measure-format-check" >"${smoke}/measure-format-check.log" 2>&1
check measure_format_parsed test -s "${smoke}/measure-format-check/ci_welch.json"
check measure_format_normalized test -s "${smoke}/measure-format-check/normalized.csv"
check measure_format_excluded_none \
    grep -q '"excluded_other_category_count": 0' "${smoke}/measure-format-check/ci_welch.json"
check measure_format_class_counts \
    grep -q '"class0_count": 200' "${smoke}/measure-format-check/ci_welch.json"
check measure_format_class_counts_second \
    grep -q '"class1_count": 200' "${smoke}/measure-format-check/ci_welch.json"

printf 'failed_guard_count=%s\n' "${failed_count}"
if [ "${failed_count}" -ne 0 ]; then
    printf 'micro_qualification_status=FAIL\n'
    exit 1
fi
printf 'micro_qualification_status=PASS\n'
