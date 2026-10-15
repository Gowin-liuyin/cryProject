#!/bin/sh
set -eu
build_directory=${1:-build}
groups_program="$build_directory/analyze_groups"
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

# 合成 CSV 的预期统计量全部由秩和检验定义手算，不由被测程序生成。
# 每个 token 形如 `category=elapsed_nanoseconds`，写出顺序即 CSV 行序。
write_tokens_csv() {
    csv_path=$1
    shift
    sample_index=0
    printf 'run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n' \
        > "$csv_path"
    for token in "$@"; do
        printf 'synthetic,reference,%s,%s,%s,ns\n' \
            "${token%%=*}" "$sample_index" "${token#*=}" >> "$csv_path"
        sample_index=$((sample_index + 1))
    done
}

repeat_token() {
    token_category=$1
    token_value=$2
    token_count=$3
    token_index=0
    while [ "$token_index" -lt "$token_count" ]; do
        printf '%s=%s ' "$token_category" "$token_value"
        token_index=$((token_index + 1))
    done
}

# 按类别分段写出：恒定类 10×1000ns，变化类 10×2000ns。
separated_tokens() {
    repeat_token message-zero 1000 10
    repeat_token message-ones 1000 10
    repeat_token valid 2000 10
    repeat_token bit-flipped 2000 10
    repeat_token random 2000 10
}

# 同样的取值，但行序按类别交替；用来捕获漏掉整份排序的实现错误。
shuffled_tokens() {
    token_index=0
    while [ "$token_index" -lt 10 ]; do
        printf 'valid=2000 message-zero=1000 bit-flipped=2000 message-ones=1000 random=2000 '
        token_index=$((token_index + 1))
    done
}

# 每类各 5 个 1000ns 与 5 个 2000ns，两组分布完全相同。
identical_tokens() {
    for category_name in valid bit-flipped random message-zero message-ones; do
        repeat_token "$category_name" 1000 5
        repeat_token "$category_name" 2000 5
    done
}

constant_tokens() {
    for category_name in valid bit-flipped random message-zero message-ones; do
        repeat_token "$category_name" 1000 10
    done
}

assert_separated_report() {
    report_path=$1
    grep -q '^analysis_tool=fixed_prespecified_group_test$' "$report_path"
    grep -q '^analysis_round=2$' "$report_path"
    grep -q '^prespecified_after_round1_data=yes$' "$report_path"
    grep -q '^hypothesis=direction_constant_vs_direction_varying$' "$report_path"
    grep -q '^record_count=50$' "$report_path"
    grep -q '^csv_digest=[0-9a-f]\{64\}$' "$report_path"
    grep -q '^alpha_family=0.001000$' "$report_path"
    grep -q '^comparison_count=1$' "$report_path"
    grep -q '^multiplicity_correction=none_single_prespecified_comparison$' "$report_path"
    grep -q '^alpha_per_comparison=0.00100000$' "$report_path"
    grep -q '^round1_alpha_per_comparison_for_reference=0.00010000$' "$report_path"
    grep -q '^group=direction-constant members=message-zero,message-ones count=20 min=1000 .*median=1000 .*max=1000 mean=1000.000 stddev=0.000 distinct_values=1$' \
        "$report_path"
    grep -q '^group=direction-varying members=valid,bit-flipped,random count=30 min=2000 .*median=2000 .*max=2000 mean=2000.000 stddev=0.000 distinct_values=1$' \
        "$report_path"
    grep -q '^comparison=direction-constant:direction-varying primary=yes n1=20 n2=30 .*rank_u1=0.0 rank_z=-.*result=significant$' \
        "$report_path"
    grep -q '^comparison=.*effect_size_first_greater=0.000000 ' "$report_path"
    grep -q '^significant_comparison_count=1$' "$report_path"
    grep -q '^note=statistical_difference_only_no_exploitability_claim$' "$report_path"
    grep -q '^sample_independence_note=direction_constant_group_reuses_two_fixed_ciphertexts_under_one_key$' \
        "$report_path"
    test "$(grep -c '^group=' "$report_path")" -eq 2
    test "$(grep -c '^comparison=' "$report_path")" -eq 1
}

# 完全分离的两组：U1=0、效应量 0、z 为负，必须判显著。
write_tokens_csv "$test_directory/separated.csv" $(separated_tokens)
"$groups_program" "$test_directory/separated.csv" "$test_directory/separated.report"
assert_separated_report "$test_directory/separated.report"

# 类别乱序输入：取值与上一例相同，只有行序不同，断言必须完全相同。
# 若实现漏掉「整份按类别排序」这一步，切到的是乱序数组的前 20 条与后 30 条，
# 两组都会混有 1000ns 与 2000ns，U1 不会是 0，效应量也不会是 0.000000。
write_tokens_csv "$test_directory/shuffled.csv" $(shuffled_tokens)
test "$(sed -n '2,6p' "$test_directory/shuffled.csv" | cut -d, -f3 | tr '\n' ' ')" \
    = "valid message-zero bit-flipped message-ones random "
"$groups_program" "$test_directory/shuffled.csv" "$test_directory/shuffled.report"
assert_separated_report "$test_directory/shuffled.report"

# 两组分布完全相同：U1 恰为 n1·n2/2=300，连续性校正后 z=0，必须判不显著。
write_tokens_csv "$test_directory/identical.csv" $(identical_tokens)
"$groups_program" "$test_directory/identical.csv" "$test_directory/identical.report"
grep -q '^comparison=direction-constant:direction-varying primary=yes n1=20 n2=30 median_difference_ns=0.0 mean_difference_ns=0.000 .*rank_u1=300.0 rank_z=0.0000 rank_p=1 effect_size_first_greater=0.500000 result=not_significant$' \
    "$test_directory/identical.report"
grep -q '^significant_comparison_count=0$' "$test_directory/identical.report"

# 全部取值相同：方差为零，不得给出显著结论，也不得写出秩检验字段。
write_tokens_csv "$test_directory/constant.csv" $(constant_tokens)
"$groups_program" "$test_directory/constant.csv" "$test_directory/constant.report"
grep -q '^comparison=direction-constant:direction-varying primary=yes n1=20 n2=30 median_difference_ns=0.0 mean_difference_ns=0.000 result=degenerate_no_variation$' \
    "$test_directory/constant.report"
grep -q '^significant_comparison_count=0$' "$test_directory/constant.report"

# 缺一个类别：五类必须全部出现。
write_tokens_csv "$test_directory/missing-category.csv" \
    $(repeat_token message-zero 1000 10) $(repeat_token message-ones 1000 10) \
    $(repeat_token valid 2000 10) $(repeat_token bit-flipped 2000 10)
if "$groups_program" "$test_directory/missing-category.csv" \
    "$test_directory/missing-category.report" 2>/dev/null; then
    exit 1
fi
test ! -e "$test_directory/missing-category.report"

# 各类数量不等：分组按等量切区间，不等量必须拒绝。
write_tokens_csv "$test_directory/unequal.csv" \
    $(repeat_token message-zero 1000 10) $(repeat_token message-ones 1000 9) \
    $(repeat_token valid 2000 10) $(repeat_token bit-flipped 2000 10) \
    $(repeat_token random 2000 10)
if "$groups_program" "$test_directory/unequal.csv" "$test_directory/unequal.report" \
    2>/dev/null; then
    exit 1
fi
test ! -e "$test_directory/unequal.report"

# 第一轮已覆盖的畸形 CSV 场景在第二轮同样必须被拒绝。
cp "$test_directory/separated.csv" "$test_directory/valid.csv"
for corruption in \
    '1s/run_id/runid/' \
    '2s/,1000,ns$/,-1000,ns/' \
    '2s/,1000,ns$/,0,ns/' \
    '2s/,1000,ns$/,18446744073709551616,ns/' \
    '2s/,ns$/,us/' \
    '2s/,ns$/,ns,extra/' \
    '2s/,message-zero,0,/,message-zero,1,/' \
    '2s/,message-zero,/,message-two,/' \
    '3s/^synthetic/other/' \
    '3s/,reference,/,hardened,/'; do
    sed "$corruption" "$test_directory/valid.csv" > "$test_directory/corrupt.csv"
    if "$groups_program" "$test_directory/corrupt.csv" "$test_directory/corrupt.report" \
        2>/dev/null; then
        exit 1
    fi
    test ! -e "$test_directory/corrupt.report"
done

{
    cat "$test_directory/valid.csv"
    printf 'synthetic,reference,random,50,2000,ns'
} > "$test_directory/unterminated.csv"
if "$groups_program" "$test_directory/unterminated.csv" \
    "$test_directory/unterminated.report" 2>/dev/null; then
    exit 1
fi
if "$groups_program" "$test_directory/absent.csv" "$test_directory/absent.report" 2>/dev/null; then
    exit 1
fi
# 报告路径必须是新文件，不覆盖已有结果。
if "$groups_program" "$test_directory/valid.csv" "$test_directory/separated.report" \
    2>/dev/null; then
    exit 1
fi
if "$groups_program" "$test_directory/valid.csv" 2>/dev/null; then
    exit 1
else
    test "$?" -eq 2
fi

# 真实采集数据：四个变体各跑一次完整流程，报告必须含两组与一个比较。
for implementation in reference vulnerable hardened deployable; do
    "$build_directory/$implementation/measure" "groups-$implementation" 42 50 \
        "$test_directory/$implementation.csv" "$test_directory/$implementation.meta"
    "$groups_program" "$test_directory/$implementation.csv" \
        "$test_directory/$implementation.report"
    grep -q "^implementation=$implementation\$" "$test_directory/$implementation.report"
    grep -q "^run_id=groups-$implementation\$" "$test_directory/$implementation.report"
    grep -q '^record_count=250$' "$test_directory/$implementation.report"
    grep -q '^group=direction-constant members=message-zero,message-ones count=100 ' \
        "$test_directory/$implementation.report"
    grep -q '^group=direction-varying members=valid,bit-flipped,random count=150 ' \
        "$test_directory/$implementation.report"
    grep -q '^comparison=direction-constant:direction-varying primary=yes n1=100 n2=150 ' \
        "$test_directory/$implementation.report"
    grep -q '^significant_comparison_count=[01]$' "$test_directory/$implementation.report"
    test "$(grep -c '^group=' "$test_directory/$implementation.report")" -eq 2
    test "$(grep -c '^comparison=' "$test_directory/$implementation.report")" -eq 1
done
