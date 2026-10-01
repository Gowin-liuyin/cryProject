#!/bin/sh
# 第一轮固定族必须保持逐字可复现：把共用部分抽到 timing_statistics.c 之后，
# 对已归档的 CSV 重放 analyze，报告须与归档报告逐字相同。
# 本脚本必须从仓库根目录运行（CTest 的 WORKING_DIRECTORY 保证），
# 因为归档报告的 csv_path 是仓库相对路径，路径不同报告就不会一致。
set -eu
build_directory=${1:-build}
analyze_program="$build_directory/analyze"

# welch_p= 与 rank_p= 由 libm 的 erfc 计算，跨平台不保证逐位一致，比较前置空；
# 其余字段（含 rank_u1、rank_z、welch_t、effect_size_first_greater、各 category=
# 行、result= 标签与 csv_digest）必须逐字相同。本机实测屏蔽前也完全一致。
mask_platform_dependent_fields() {
    sed -e 's/welch_p=[^ ]*/welch_p=/g' -e 's/rank_p=[^ ]*/rank_p=/g' "$1"
}

replay_count=0
for archived_case in \
    'statistics-vulnerable:docs/evidence/statistics/vulnerable' \
    'mitigation-hardened:docs/evidence/mitigation/hardened'; do
    replay_name=${archived_case%%:*}
    archived_prefix=${archived_case#*:}
    replay_report="$build_directory/round1-replay-$replay_name.report"
    # analyze 用 fopen(..., "wx")，目标必须是新文件，否则第二次 ctest 直接失败。
    rm -f "$replay_report"
    test -f "$archived_prefix.csv"
    test -f "$archived_prefix.report"
    "$analyze_program" "$archived_prefix.csv" "$replay_report" > /dev/null
    mask_platform_dependent_fields "$archived_prefix.report" > "$replay_report.archived.masked"
    mask_platform_dependent_fields "$replay_report" > "$replay_report.replayed.masked"
    cmp "$replay_report.archived.masked" "$replay_report.replayed.masked"
    replay_count=$((replay_count + 1))
done

# 两份归档数据都必须重放成功；只跑一份不算通过。
test "$replay_count" -eq 2
