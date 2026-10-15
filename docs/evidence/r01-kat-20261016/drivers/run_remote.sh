#!/bin/sh
# T05 向量来源总表 / T06 修复语义等价的远端构建与运行脚本。
# 在远端唯一可写根 Cry/r01-kat-20261016-<nonce>/ 内执行；只读其他已冻结树。
# 不使用 /tmp：所有临时目录指向本新根 tmp/。
set -u

R=/home/nss-marker/yhr/Cry
N=$R/r01-kat-20261016-2ff55778bc52
M1=$R/liboqs010-historical-20261015-86131c2
M1A=$M1/build/historical-clangover
M1B=$M1/build/historical-fixed-982c762
M2=$R/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a
M3=$R/platform-m3-locate-20261016-4b102a339cc8
M4ROOT=$R/platform-m4-20261016-6hRHRUxH
M4=$M4ROOT/build-software-v3
M5=$R/platform-m5-20261016-30efdf66eb26

VEC_MLKEM_M1=$M1/tests/vectors/mlkem768.txt
VEC_MLKEM_M3=$M3/source/tests/vectors/mlkem768.txt
VEC_MLKEM_M5=$M5/source-v2/tests/vectors/mlkem768.txt
VEC_RSP=$M2/source/tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp

DRV=$N/drivers
BLD=$N/build
LOG=$N/logs
OUT=$N/out
export TMPDIR=$N/tmp TMP=$N/tmp TEMP=$N/tmp A113_TEST_TMPDIR=$N/tmp
CC=${CC:-cc}
EXTRA=${EXTRA:-1000}

mkdir -p "$BLD" "$LOG" "$OUT"

echo "== environment =="
date -Is
"$CC" --version | head -1
uname -a
nproc
uptime
echo

echo "== provenance =="
sha256sum "$VEC_MLKEM_M1" "$VEC_MLKEM_M3" "$VEC_MLKEM_M5" "$VEC_RSP" 2>&1
sha256sum "$M1A/historical/libmlkem.a" "$M1A/liboqs010-install/lib/liboqs.a" \
          "$M1B/historical/libmlkem.a" "$M1B/liboqs010-install/lib/liboqs.a" 2>&1
sha256sum "$M2/build-ordinary/libm2_collector_unfixed.a" "$M2/build-ordinary/libm2_collector_unfixed_vendor.a" \
          "$M2/build-ordinary/libm2_collector_fixed.a" "$M2/build-ordinary/libm2_collector_fixed_vendor.a" 2>&1
sha256sum "$M3/build-ordinary/platform-m3/on/libmlkem.a" "$M3/build-ordinary/platform-m3/off/libmlkem.a" 2>&1
sha256sum "$M3/build-ordinary/platform_m3_on_test_mlkem" "$M3/build-ordinary/platform_m3_off_test_mlkem" 2>&1
sha256sum "$M5/build-v2-ordinary/reference/test_mlkem" "$M5/build-v2-ordinary/reference/libmlkem.a" 2>&1
sha256sum "$M4/test_platform_m4_vulnerable" "$M4/test_platform_m4_ct" 2>&1
grep -h "LIBOQS010_SOURCE_DIR\|LIBOQS010_C_FLAGS\|CMAKE_C_COMPILER:" "$M1A/CMakeCache.txt" "$M1B/CMakeCache.txt" 2>&1 | sort -u
sha256sum "$M1/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/kem.c" \
          "$M1/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c" 2>&1
echo

echo "== compile =="
set -x
"$CC" -O2 -std=c11 -Wall -Wextra -I "$M1/include" \
    -DRR_IMPL_NAME='"m1-liboqs010-0.10.0-clangover"' \
    "$DRV/m1_kat.c" -o "$BLD/m1_kat_clangover" \
    "$M1A/historical/libmlkem.a" "$M1A/liboqs010-install/lib/liboqs.a" -lpthread -lm
"$CC" -O2 -std=c11 -Wall -Wextra -I "$M1/include" \
    -DRR_IMPL_NAME='"m1-liboqs010-0.10.0-fixed-982c762"' \
    "$DRV/m1_kat.c" -o "$BLD/m1_kat_fixed" \
    "$M1B/historical/libmlkem.a" "$M1B/liboqs010-install/lib/liboqs.a" -lpthread -lm

for pair in clangover:historical-clangover fixed:historical-fixed-982c762; do
    name=${pair%%:*}
    build=${pair##*:}
    "$CC" -O2 -std=c11 -Wall -Wextra -I "$M1/include" \
        -DRR_IMPL_NAME="\"m1-liboqs010-$name\"" -DRR_HASH_STYLE=1 -DRR_REJECTION_STYLE=1 \
        "$DRV/rr_pair_probe.c" -o "$BLD/rr_m1_$name" \
        "$M1/build/$build/historical/libmlkem.a" "$M1/build/$build/liboqs010-install/lib/liboqs.a" -lpthread -lm
done

for variant in unfixed fixed; do
    "$CC" -O2 -std=c11 -Wall -Wextra -I "$M2/source/include" \
        -DRR_IMPL_NAME="\"m2-pqcrystals-kyber768-$variant\"" -DRR_HASH_STYLE=2 -DRR_REJECTION_STYLE=2 \
        "$DRV/rr_pair_probe.c" -o "$BLD/rr_m2_$variant" \
        "$M2/build-ordinary/libm2_collector_$variant.a" "$M2/build-ordinary/libm2_collector_${variant}_vendor.a" -lm
done

for variant in on off; do
    "$CC" -O2 -std=c11 -Wall -Wextra -I "$M3/source/include" \
        -DRR_IMPL_NAME="\"m3-lut-$variant\"" -DRR_HASH_STYLE=3 -DRR_REJECTION_STYLE=1 \
        "$DRV/rr_pair_probe.c" -o "$BLD/rr_m3_$variant" \
        "$M3/build-ordinary/platform-m3/$variant/libmlkem.a" -lm
done
set +x
echo

run_logged() {
    log_name=$1
    shift
    "$@" > "$LOG/$log_name" 2>&1
    status=$?
    echo "exit_status=$status" >> "$LOG/$log_name"
    printf '%-46s exit=%s\n' "$log_name" "$status"
    return 0
}

echo "== T05 public KAT runs =="
run_logged t05_m1_clangover_kat.log "$BLD/m1_kat_clangover" "$VEC_MLKEM_M1"
run_logged t05_m1_fixed982c762_kat.log "$BLD/m1_kat_fixed" "$VEC_MLKEM_M1"
run_logged t05_m2_unfixed_kat.log "$M2/build-ordinary/qualification/unfixed/m2_platform_kat" "$VEC_RSP"
run_logged t05_m2_fixed_kat.log "$M2/build-ordinary/qualification/fixed/m2_platform_kat" "$VEC_RSP"
run_logged t05_m3_on_kat.log "$M3/build-ordinary/platform_m3_on_test_mlkem" "$VEC_MLKEM_M3"
run_logged t05_m3_off_kat.log "$M3/build-ordinary/platform_m3_off_test_mlkem" "$VEC_MLKEM_M3"
run_logged t05_m4_vulnerable_inputs.log "$M4/test_platform_m4_vulnerable"
run_logged t05_m4_ct_inputs.log "$M4/test_platform_m4_ct"
run_logged t05_m4_vulnerable_describe.log "$M4/platform_m4_measure_vulnerable" --describe
run_logged t05_m4_ct_describe.log "$M4/platform_m4_measure_ct" --describe
run_logged t05_m5_reference_kat.log "$M5/build-v2-ordinary/reference/test_mlkem" "$VEC_MLKEM_M5"
tail -n +1 "$LOG"/t05_*.log | sed -n '1,80p'
echo

echo "== T06 equivalence probes =="
"$BLD/rr_m1_clangover" --vectors "$VEC_MLKEM_M1" --format txt --extra "$EXTRA" --digest "$OUT/m1_clangover.digest" > "$LOG/t06_m1_clangover.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m1_clangover.log"
"$BLD/rr_m1_fixed" --vectors "$VEC_MLKEM_M1" --format txt --extra "$EXTRA" --digest "$OUT/m1_fixed.digest" > "$LOG/t06_m1_fixed.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m1_fixed.log"
"$BLD/rr_m2_unfixed" --vectors "$VEC_RSP" --format rsp --extra "$EXTRA" --digest "$OUT/m2_unfixed.digest" > "$LOG/t06_m2_unfixed.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m2_unfixed.log"
"$BLD/rr_m2_fixed" --vectors "$VEC_RSP" --format rsp --extra "$EXTRA" --digest "$OUT/m2_fixed.digest" > "$LOG/t06_m2_fixed.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m2_fixed.log"
"$BLD/rr_m3_on" --vectors "$VEC_MLKEM_M3" --format txt --extra "$EXTRA" --digest "$OUT/m3_on.digest" > "$LOG/t06_m3_on.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m3_on.log"
"$BLD/rr_m3_off" --vectors "$VEC_MLKEM_M3" --format txt --extra "$EXTRA" --digest "$OUT/m3_off.digest" > "$LOG/t06_m3_off.log" 2>&1
echo "exit_status=$?" >> "$LOG/t06_m3_off.log"

for pair in "m1:M1 clangover vs 982c762" "m2:M2 a621b8d vs 272125f" "m3:M3 on vs off"; do
    name=${pair%%:*}
    case "$name" in
        m1) left=m1_clangover; right=m1_fixed ;;
        m2) left=m2_unfixed; right=m2_fixed ;;
        m3) left=m3_on; right=m3_off ;;
    esac
    cmp "$OUT/$left.digest" "$OUT/$right.digest" > "$LOG/t06_${name}_cmp.log" 2>&1
    echo "cmp_exit_status=$?" >> "$LOG/t06_${name}_cmp.log"
    cmp -l "$OUT/$left.digest" "$OUT/$right.digest" 2>/dev/null | wc -l >> "$LOG/t06_${name}_cmp.log"
    sha256sum "$OUT/$left.digest" "$OUT/$right.digest" >> "$LOG/t06_${name}_cmp.log"
done

# M4：人工夹具只做接口等价说明（同一 describe 文本 + 同一观测判定）。
cmp "$LOG/t05_m4_vulnerable_describe.log" "$LOG/t05_m4_ct_describe.log" > "$LOG/t06_m4_interface_cmp.log" 2>&1
echo "describe_cmp_exit_status=$?" >> "$LOG/t06_m4_interface_cmp.log"
cmp "$LOG/t05_m4_vulnerable_inputs.log" "$LOG/t05_m4_ct_inputs.log" >> "$LOG/t06_m4_interface_cmp.log" 2>&1
echo "inputs_cmp_exit_status=$?" >> "$LOG/t06_m4_interface_cmp.log"

{
    echo "=== t06 logs ==="
    tail -n +1 "$LOG"/t06_*.log
} | sed -n '1,120p'
echo

echo "== summary tsv =="
summarize() {
    module_name=$1
    version_name=$2
    log_name=$3
    exit_status=$(sed -n 's/^exit_status=//p' "$LOG/$log_name" | tail -1)
    counts=$(grep -v '^exit_status=' "$LOG/$log_name" | tr '\n' ' ' | cut -c1-200)
    printf '%s\t%s\tlogs/%s\t%s\t%s\n' "$module_name" "$version_name" "$log_name" "$exit_status" "$counts"
}
{
    printf 'module\tversion\tlog\texit\tcounts\n'
    summarize M1 liboqs010-historical-clangover t05_m1_clangover_kat.log
    summarize M1 liboqs010-fixed-982c762 t05_m1_fixed982c762_kat.log
    summarize M2 pqcrystals-kyber768-a621b8d-unfixed t05_m2_unfixed_kat.log
    summarize M2 pqcrystals-kyber768-272125f-fixed t05_m2_fixed_kat.log
    summarize M3 platform-m3-lut-on t05_m3_on_kat.log
    summarize M3 platform-m3-lut-off t05_m3_off_kat.log
    summarize M4 artificial-fixture-vulnerable t05_m4_vulnerable_inputs.log
    summarize M4 artificial-fixture-ct t05_m4_ct_inputs.log
    summarize M5 reference-path t05_m5_reference_kat.log
    summarize M1 pair-clangover-vs-982c762 t06_m1_cmp.log
    summarize M2 pair-unfixed-vs-fixed t06_m2_cmp.log
    summarize M3 pair-on-vs-off t06_m3_cmp.log
    summarize M4 pair-vulnerable-vs-ct t06_m4_interface_cmp.log
} > "$LOG/T05_T06_summary.tsv"
cat "$LOG/T05_T06_summary.tsv"
echo "done"
