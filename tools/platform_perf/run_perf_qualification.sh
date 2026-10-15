#!/bin/sh
# T20 性能采集件资格检查（**不锁频、不写频率、不用 sudo**）。
# 只做功能与格式资格：--describe、小样本试跑、CSV 表头/行数/time_unit/run_status 核对。
# 正式采集由主控经唯一锁频控制器串行执行，见 RUNS.sh。
#
# usage: run_perf_qualification.sh <new-root>
set -eu

NEW_ROOT=$1
ARMS="m1unfixed m1fixed m2unfixed m2fixed m3on m3off m5ref"
QUAL_DIR="$NEW_ROOT/qualification"
export TMPDIR="$NEW_ROOT/tmp" TMP="$NEW_ROOT/tmp" TEMP="$NEW_ROOT/tmp"

mkdir -p "$QUAL_DIR"
status=0

for arm in $ARMS; do
    arm_directory="$NEW_ROOT/build/$arm"
    mkdir -p "$QUAL_DIR/$arm"
    elf="$arm_directory/perf_measure"
    if ! "$elf" --describe > "$QUAL_DIR/$arm/describe.txt" 2>&1; then
        echo "$arm: describe FAILED"
        status=1
        continue
    fi
    if ! "$elf" \
        --run-id "perf-qual-$arm" --arm "$arm" \
        --seed 31337 --warmup 5 \
        --decaps-samples 200 --keygen-samples 50 --encaps-samples 50 \
        --block-index 0 --block-count 1 --order-seed 20261016 \
        --raw "$QUAL_DIR/$arm/smoke.csv" \
        --meta "$QUAL_DIR/$arm/smoke.meta" > "$QUAL_DIR/$arm/smoke.stdout" 2>&1; then
        echo "$arm: smoke run FAILED"
        cat "$QUAL_DIR/$arm/smoke.stdout"
        status=1
        continue
    fi
    head -1 "$QUAL_DIR/$arm/smoke.csv" > "$QUAL_DIR/$arm/header.txt"
    if [ "$(cat "$QUAL_DIR/$arm/header.txt")" != \
        "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit" ]; then
        echo "$arm: unexpected CSV header"
        status=1
    fi
    {
        printf 'arm=%s\n' "$arm"
        printf 'csv_rows_total=%s\n' "$(($(wc -l < "$QUAL_DIR/$arm/smoke.csv") - 1))"
        for category in decaps keygen encaps; do
            printf 'csv_rows_%s=%s\n' "$category" \
                "$(awk -F, -v wanted="$category" '$3==wanted' "$QUAL_DIR/$arm/smoke.csv" | wc -l)"
        done
        printf 'bad_time_unit_rows=%s\n' \
            "$(awk -F, 'NR>1 && $6!="ns"' "$QUAL_DIR/$arm/smoke.csv" | wc -l)"
        printf 'zero_elapsed_rows=%s\n' \
            "$(awk -F, 'NR>1 && $5==0' "$QUAL_DIR/$arm/smoke.csv" | wc -l)"
        printf 'implementation=%s\n' "$(sed -n 's/^implementation=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'run_status=%s\n' "$(sed -n 's/^run_status=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'operation_order=%s\n' "$(sed -n 's/^operation_order=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'cpu_affinity=%s\n' "$(sed -n 's/^cpu_affinity=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'frequency_control=%s\n' "$(sed -n 's/^frequency_control=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'encapsulation_key_sha256=%s\n' \
            "$(sed -n 's/^encapsulation_key_sha256=//p' "$QUAL_DIR/$arm/smoke.meta")"
        printf 'decaps_median_ns=%s\n' \
            "$(awk -F, '$3=="decaps"{print $5}' "$QUAL_DIR/$arm/smoke.csv" | sort -n | awk '{v[NR]=$1} END{if(NR%2)print v[(NR+1)/2]; else print int((v[NR/2]+v[NR/2+1])/2)}')"
        printf 'keygen_median_ns=%s\n' \
            "$(awk -F, '$3=="keygen"{print $5}' "$QUAL_DIR/$arm/smoke.csv" | sort -n | awk '{v[NR]=$1} END{if(NR%2)print v[(NR+1)/2]; else print int((v[NR/2]+v[NR/2+1])/2)}')"
        printf 'encaps_median_ns=%s\n' \
            "$(awk -F, '$3=="encaps"{print $5}' "$QUAL_DIR/$arm/smoke.csv" | sort -n | awk '{v[NR]=$1} END{if(NR%2)print v[(NR+1)/2]; else print int((v[NR/2]+v[NR/2+1])/2)}')"
    } > "$QUAL_DIR/$arm/summary.txt"
    cat "$QUAL_DIR/$arm/summary.txt"
    echo "---"
done

exit $status
