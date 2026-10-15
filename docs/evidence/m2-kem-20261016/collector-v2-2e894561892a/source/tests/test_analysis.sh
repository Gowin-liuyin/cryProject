#!/bin/sh
set -eu
build_directory=${1:-build}
analyze_program="$build_directory/analyze"
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

# 合成 CSV 的预期统计量来自秩和检验定义，不由被测程序生成。
write_pair_csv() {
    csv_path=$1
    zero_values=$2
    ones_values=$3
    sample_index=0
    printf 'run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n' \
        > "$csv_path"
    for elapsed_nanoseconds in $zero_values; do
        printf 'synthetic,reference,message-zero,%s,%s,ns\n' \
            "$sample_index" "$elapsed_nanoseconds" >> "$csv_path"
        sample_index=$((sample_index + 1))
    done
    for elapsed_nanoseconds in $ones_values; do
        printf 'synthetic,reference,message-ones,%s,%s,ns\n' \
            "$sample_index" "$elapsed_nanoseconds" >> "$csv_path"
        sample_index=$((sample_index + 1))
    done
}

repeated_values() {
    value_count=$1
    repeated_value=$2
    value_index=0
    while [ "$value_index" -lt "$value_count" ]; do
        printf '%s ' "$repeated_value"
        value_index=$((value_index + 1))
    done
}

alternating_values() {
    value_count=$1
    value_index=0
    while [ "$value_index" -lt "$value_count" ]; do
        if [ $((value_index % 2)) -eq 0 ]; then
            printf '1000 '
        else
            printf '2000 '
        fi
        value_index=$((value_index + 1))
    done
}

# 完全分离的两组：U1=0、效应量 0、秩检验必须判显著。
write_pair_csv "$test_directory/separated.csv" "$(repeated_values 20 1000)" \
    "$(repeated_values 20 2000)"
"$analyze_program" "$test_directory/separated.csv" "$test_directory/separated.report"
grep -q '^alpha_family=0.001000$' "$test_directory/separated.report"
grep -q '^comparison_count=10$' "$test_directory/separated.report"
grep -q '^alpha_per_comparison=0.00010000$' "$test_directory/separated.report"
grep -q '^record_count=40$' "$test_directory/separated.report"
grep -q '^csv_digest=[0-9a-f]\{64\}$' "$test_directory/separated.report"
grep -q '^significant_comparison_count=1$' "$test_directory/separated.report"
grep -q '^category=message-zero count=20 min=1000 .*median=1000 .*distinct_values=1$' \
    "$test_directory/separated.report"
grep -q '^category=valid count=0$' "$test_directory/separated.report"
grep -q '^comparison=message-zero:message-ones primary=yes n1=20 n2=20 .*rank_u1=0.0 .*result=significant$' \
    "$test_directory/separated.report"
grep -q '^comparison=message-zero:message-ones .*effect_size_first_greater=0.000000 ' \
    "$test_directory/separated.report"
grep -q '^comparison=valid:bit-flipped primary=no n1=0 n2=0 result=insufficient_samples$' \
    "$test_directory/separated.report"
test "$(grep -c '^category=' "$test_directory/separated.report")" -eq 5
test "$(grep -c '^comparison=' "$test_directory/separated.report")" -eq 10

# 两组分布相同：U1 正好等于期望值，连续性校正后 z=0，必须判不显著。
write_pair_csv "$test_directory/identical.csv" "$(alternating_values 20)" \
    "$(alternating_values 20)"
"$analyze_program" "$test_directory/identical.csv" "$test_directory/identical.report"
grep -q '^comparison=message-zero:message-ones primary=yes n1=20 n2=20 .*rank_u1=200.0 rank_z=0.0000 rank_p=1 effect_size_first_greater=0.500000 result=not_significant$' \
    "$test_directory/identical.report"
grep -q '^significant_comparison_count=0$' "$test_directory/identical.report"

# 全部取值相同：方差为零，不得给出显著结论。
write_pair_csv "$test_directory/constant.csv" "$(repeated_values 20 1000)" \
    "$(repeated_values 20 1000)"
"$analyze_program" "$test_directory/constant.csv" "$test_directory/constant.report"
grep -q '^comparison=message-zero:message-ones primary=yes n1=20 n2=20 median_difference_ns=0.0 mean_difference_ns=0.000 result=degenerate_no_variation$' \
    "$test_directory/constant.report"
grep -q '^significant_comparison_count=0$' "$test_directory/constant.report"

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
    if "$analyze_program" "$test_directory/corrupt.csv" "$test_directory/corrupt.report" \
        2>/dev/null; then
        exit 1
    fi
    test ! -e "$test_directory/corrupt.report"
done

{
    cat "$test_directory/valid.csv"
    printf 'synthetic,reference,message-ones,40,1000,ns'
} > "$test_directory/unterminated.csv"
if "$analyze_program" "$test_directory/unterminated.csv" "$test_directory/unterminated.report" \
    2>/dev/null; then
    exit 1
fi
head -2 "$test_directory/valid.csv" > "$test_directory/single.csv"
if "$analyze_program" "$test_directory/single.csv" "$test_directory/single.report" 2>/dev/null; then
    exit 1
fi
if "$analyze_program" "$test_directory/missing.csv" "$test_directory/missing.report" 2>/dev/null; then
    exit 1
fi
if "$analyze_program" "$test_directory/valid.csv" "$test_directory/separated.report" 2>/dev/null; then
    exit 1
fi
if "$analyze_program" "$test_directory/valid.csv" 2>/dev/null; then
    exit 1
else
    test "$?" -eq 2
fi

# 真实采集数据：四个变体各跑一次完整流程，报告必须覆盖五类和十个固定比较。
for implementation in reference vulnerable hardened deployable; do
    "$build_directory/$implementation/measure" "analysis-$implementation" 42 50 \
        "$test_directory/$implementation.csv" "$test_directory/$implementation.meta"
    "$analyze_program" "$test_directory/$implementation.csv" \
        "$test_directory/$implementation.report"
    grep -q "^implementation=$implementation\$" "$test_directory/$implementation.report"
    grep -q "^run_id=analysis-$implementation\$" "$test_directory/$implementation.report"
    grep -q '^record_count=250$' "$test_directory/$implementation.report"
    grep -q '^note=statistical_difference_only_no_exploitability_claim$' \
        "$test_directory/$implementation.report"
    grep -q '^significant_comparison_count=[0-9]*$' "$test_directory/$implementation.report"
    test "$(grep -c '^category=' "$test_directory/$implementation.report")" -eq 5
    test "$(grep -c '^comparison=' "$test_directory/$implementation.report")" -eq 10
    test "$(grep -c 'count=50 ' "$test_directory/$implementation.report")" -eq 5
done
