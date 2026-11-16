#!/bin/sh
# 对既有 M1 两列宽表逐文件跑 platform_shape_stats，只写 r20 新证据目录。
# 输入目录严格只读；每个 meta 追加 sha256sum 行；RESULT.md 由本次输出生成。
# 用法：run_shape_replay.sh [platform_shape_stats 可执行文件]
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
statistics_program=${1:-"$repository_root/build/cmake-platform/platform_shape_stats"}

if [ ! -x "$statistics_program" ]; then
    printf 'missing platform_shape_stats executable: %s\n' "$statistics_program" >&2
    exit 1
fi

# 统一在仓库根下工作，让 meta 的 input_path/label 保持可移植的相对路径。
cd "$repository_root"
input_directory="docs/evidence/r02-r04-close-20261016/raw"
output_directory="docs/evidence/r20-shape-tests-20261116"
expected_input_count=4

if [ ! -d "$input_directory" ]; then
    printf 'missing input directory: %s\n' "$input_directory" >&2
    exit 1
fi

# 只清理本任务自己的证据目录；路径先过白名单，避免误删既有证据。
case "$output_directory" in
    docs/evidence/r20-shape-tests-20261116) ;;
    *)
        printf 'refusing to remove unexpected path: %s\n' "$output_directory" >&2
        exit 1
        ;;
esac
rm -rf "$output_directory"
mkdir -p "$output_directory"

input_count=0
for input_csv in "$input_directory"/*/csv/*.csv; do
    if [ ! -f "$input_csv" ]; then
        printf 'no CSV matched %s\n' "$input_directory" >&2
        exit 1
    fi
    run_directory=$(basename "$(dirname "$(dirname "$input_csv")")")
    csv_name=$(basename "$input_csv" .csv)
    stem="$run_directory-$csv_name"
    relative_path="$input_directory/$run_directory/csv/$csv_name.csv"
    output_csv="$output_directory/$stem.csv"
    meta_path="$output_directory/$stem.meta.txt"
    "$statistics_program" --input "$input_csv" --format wide \
        --output "$output_csv" --meta "$meta_path" --label "$relative_path"
    input_sha256=$(sha256sum "$input_csv" | cut -d' ' -f1)
    printf 'input_sha256=%s\n' "$input_sha256" >> "$meta_path"
    input_count=$((input_count + 1))
done

if [ "$input_count" -ne "$expected_input_count" ]; then
    printf 'expected %s wide CSVs, processed %s\n' "$expected_input_count" "$input_count" >&2
    exit 1
fi

# RESULT.md 由本次输出 CSV 生成；行序与上面的 glob 顺序一致。
result_path="$output_directory/RESULT.md"
{
    printf '# R20 形状/方差检验探索性回放\n\n'
    printf '日期：%s  \n' "$(date +%F)"
    printf '输入：`docs/evidence/r02-r04-close-20261016/raw/*/csv/*.csv`（4 个 M1 两列宽表，各 10000 对调用）  \n'
    printf '工具：`platform_shape_stats`（brown_forsythe / ks_two_sample / within_class_second_order_zero / within_class_second_order_ones）  \n'
    printf '口径：alpha=0.05；p<0.05 记 flag，否则 clear；全部为族外探索性结果，不进 Holm。\n\n'
    printf '| 输入文件 | Brown–Forsythe p / flag | KS p / flag | 类内二阶 zero p / flag | 类内二阶 ones p / flag |\n'
    printf '|---|---|---|---|---|\n'
    for input_csv in "$input_directory"/*/csv/*.csv; do
        run_directory=$(basename "$(dirname "$(dirname "$input_csv")")")
        csv_name=$(basename "$input_csv" .csv)
        stem="$run_directory-$csv_name"
        relative_path="$input_directory/$run_directory/csv/$csv_name.csv"
        output_csv="$output_directory/$stem.csv"
        row=$(awk -F, '
            $1 == "brown_forsythe" {bf = $3 " / " $6}
            $1 == "ks_two_sample" {ks = $3 " / " $6}
            $1 == "within_class_second_order_zero" {wz = $3 " / " $6}
            $1 == "within_class_second_order_ones" {wo = $3 " / " $6}
            END {printf "%s | %s | %s | %s", bf, ks, wz, wo}
        ' "$output_csv")
        printf '| `%s` | %s |\n' "$relative_path" "$row"
    done
    printf '\n本目录为探索性族外回放，不进 Holm、不改任何既有判定。\n'
} > "$result_path"

printf 'shape replay: %s inputs, output in %s\n' "$input_count" "$output_directory"
