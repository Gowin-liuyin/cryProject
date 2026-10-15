#!/bin/sh
set -eu
# 把 M2 collector 的 6 列 measure 长表投影成 Mona 适配器接受的两列宽表。
# 配对规则：类内出现顺序（文件按 sample_index 升序），第 i 个 message-zero 配第 i 个
# message-ones；同一规则曾把 M1 封存 samples.csv 还原成逐字节相同的宽表。
# 原始 CSV 只读；输出、临时与日志全部写在自有 Mona 根内。

root=/home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d
collect=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01
work=$root/m2
inputs=$work/inputs
log=$work/projection-verification.log
mapping=$work/input-mapping.csv
expected_header='run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit'

if [ -e "$log" ] || [ -e "$mapping" ]; then
    printf '%s\n' 'projection outputs must not exist.' >&2
    exit 2
fi
mkdir -p "$inputs" "$work/scratch"
{
    printf 'projection_time: %s\n' "$(date -Is)"
    printf 'rule: per-class rank-order pairing (message-zero i-th <-> message-ones i-th)\n'
    printf 'raw_source: %s/M2 (read-only)\n' "$collect"
    printf 'expected_header: %s\n' "$expected_header"
} > "$log"
printf 'dataset,arm,run,seed,cpu,cpu_source,raw_csv,raw_sha256,raw_bytes,projected_csv,projected_sha256,class0_count,class1_count,pairs\n' > "$mapping"

for dataset in m2-s1-unfixed m2-s1-fixed m2-s2-unfixed m2-s2-fixed m2-s3-unfixed m2-s3-fixed; do
    arm=unfixed
    case "$dataset" in
        *-fixed) arm=fixed ;;
    esac
    run_name=$(printf '%s\n' "$dataset" | cut -d- -f2)
    case "$run_name" in
        s1) cpu=CPU2 ;;
        s2) cpu=CPU2 ;;
        s3) cpu=CPU6 ;;
        *) printf 'unknown run: %s\n' "$run_name" >&2; exit 3 ;;
    esac
    raw=$collect/M2/$dataset/$arm-main.csv
    meta=$collect/M2/$dataset/$arm-main.meta
    projected=$inputs/$dataset.csv
    [ -f "$raw" ]
    [ -f "$meta" ]
    [ ! -e "$projected" ]
    seed=$(awk -F= '$1 == "test_seed" {print $2}' "$meta")
    [ -n "$seed" ]
    head -1 "$raw" | grep -qxF "$expected_header"
    awk -F, 'NR > 1 { if (NF != 6) exit 5; if ($6 != "ns") exit 6; if ($5 !~ /^[0-9]+$/) exit 7 }' "$raw"
    count_zero=$(awk -F, 'NR > 1 && $3 == "message-zero"' "$raw" | wc -l | tr -d ' ')
    count_ones=$(awk -F, 'NR > 1 && $3 == "message-ones"' "$raw" | wc -l | tr -d ' ')
    [ "$count_zero" -eq 10000 ]
    [ "$count_ones" -eq 10000 ]
    awk -F, 'NR > 1 { if (rows >= 1 && $4 + 0 <= previous_index) exit 8; previous_index = $4 + 0; rows++ }' "$raw"
    awk -F, 'NR == 1 { next } $3 == "message-zero" { z[++n0] = $5 }
        $3 == "message-ones" { o[++n1] = $5 }
        END {
            if (n0 != 10000 || n1 != 10000) exit 9
            print "message-zero,message-ones"
            for (i = 1; i <= n0; i++) print z[i] "," o[i]
        }' "$raw" > "$projected"
    [ "$(wc -l < "$projected" | tr -d ' ')" -eq 10001 ]
    scratch=$work/scratch
    tail -n +2 "$projected" | cut -d, -f1 | sort > "$scratch/zero.txt"
    tail -n +2 "$projected" | cut -d, -f2 | sort > "$scratch/ones.txt"
    awk -F, 'NR > 1 && $3 == "message-zero" { print $5 }' "$raw" | sort > "$scratch/zero-raw.txt"
    awk -F, 'NR > 1 && $3 == "message-ones" { print $5 }' "$raw" | sort > "$scratch/ones-raw.txt"
    cmp "$scratch/zero.txt" "$scratch/zero-raw.txt"
    cmp "$scratch/ones.txt" "$scratch/ones-raw.txt"
    raw_sha=$(sha256sum "$raw" | cut -d' ' -f1)
    raw_bytes=$(stat -c%s "$raw")
    projected_sha=$(sha256sum "$projected" | cut -d' ' -f1)
    stats=$(awk -F, 'NR > 1 {
            if (pairs == 0 || $1 + 0 < min0) min0 = $1 + 0
            if ($1 + 0 > max0) max0 = $1 + 0
            if (pairs == 0 || $2 + 0 < min1) min1 = $2 + 0
            if ($2 + 0 > max1) max1 = $2 + 0
            sum0 += $1; sum1 += $2; pairs++
        }
        END { printf "min0=%d max0=%d mean0=%.3f min1=%d max1=%d mean1=%.3f", min0, max0, sum0 / pairs, min1, max1, sum1 / pairs }' "$projected")
    {
        printf '== %s ==\n' "$dataset"
        printf 'raw=%s\n' "$raw"
        printf 'raw_sha256=%s raw_bytes=%s\n' "$raw_sha" "$raw_bytes"
        printf 'projected=%s\n' "$projected"
        printf 'projected_sha256=%s\n' "$projected_sha"
        printf 'class_counts=message-zero:%s,message-ones:%s pairs=10000\n' "$count_zero" "$count_ones"
        printf 'multiset_check=sort(col1)==sort(raw message-zero) and sort(col2)==sort(raw message-ones): OK\n'
        printf 'sample_index_strictly_ascending=OK header=OK time_unit=ns elapsed=nonneg-int:OK\n'
        printf 'projected_stats %s\n' "$stats"
    } >> "$log"
    printf '%s,%s,%s,%s,%s,lead-message-20261016,%s,%s,%s,%s,%s,%s,%s,10000\n' \
        "$dataset" "$arm" "$run_name" "$seed" "$cpu" "$raw" "$raw_sha" "$raw_bytes" \
        "$projected" "$projected_sha" "$count_zero" "$count_ones" >> "$mapping"
done
rm -rf "$work/scratch"
printf 'projection_done datasets=6\n' >> "$log"
cat "$mapping"
