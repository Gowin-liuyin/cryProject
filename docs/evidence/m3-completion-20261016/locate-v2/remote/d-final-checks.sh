#!/bin/bash
# D) 最终核对：实现名直接打印、两臂 dudect 差异、collect CLI 形态（不执行采集）。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"; SRC="$NEWROOT/source"; B="$NEWROOT/build-ordinary"; LOGS="$NEWROOT/logs"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache"

run() {
    name="$1"; shift
    log="$LOGS/$name.log"
    printf '### step=%s\n### date=%s\n### cmd=%s\n### begin-output\n' "$name" "$(date -Is)" "$*" > "$log"
    set +e
    bash -o pipefail -c "$*" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$LOGS/$name.exit"
    printf 'step=%-46s exit=%s\n' "$name" "$status"
}

cat > "$PROBE/impl_name.c" <<'C'
#include "mlkem.h"

#include <stdio.h>

int main(void)
{
    printf("implementation=%s\n", mlkem_implementation_name());
    return 0;
}
C

for mode in on off; do
    if [ "$mode" = on ]; then leak=1; else leak=0; fi
    OV="$B/platform-m3-${mode}-source/mlkem"
    run "d1-build-implname-${mode}" "clang -O2 -g -std=c11 -DMLK_CONFIG_FILE='\"baseline_config.h\"' -DPLATFORM_IMPLEMENTATION_NAME='\"platform-m3-lut-${mode}\"' -DPLATFORM_M3_LUT_LEAK=${leak} -I$OV -I$SRC/include -I$SRC/vendor/mlkem-native/mlkem $PROBE/impl_name.c $B/platform-m3/${mode}/libmlkem.a -o $PROBE/impl-name-${mode}"
    run "d2-implname-${mode}" "$PROBE/impl-name-${mode}; echo implname_exit=\$?"
done
run d3-arm-libraries "sha256sum $B/platform-m3/on/libmlkem.a $B/platform-m3/off/libmlkem.a"
run d4-poly-frommsg-disasm-on "objdump -d --demangle $PROBE/m3dudect-on | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p' | head -28"
run d4-poly-frommsg-disasm-off "objdump -d --demangle $PROBE/m3dudect-off | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p' | head -28"
run d4b-disasm-diff "diff <(objdump -d --demangle $PROBE/m3dudect-on | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p') <(objdump -d --demangle $PROBE/m3dudect-off | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p') | head -40; echo disasm_diff_lines=\$(diff <(objdump -d --demangle $PROBE/m3dudect-on | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p') <(objdump -d --demangle $PROBE/m3dudect-off | sed -n '/<baseline_native_poly_frommsg>:/,/^$/p') | wc -l)"

# 只跑“参数不合法”的形态以取得 usage；绝不跑合法的 --collect
run d5-collect-usage-form "TERM=dumb $PROBE/m3dudect-on --collect --seed 1 --raw probe.csv; echo malformed_collect_exit=\$?"
run d6-describe-unsupported "$PROBE/m3dudect-on --describe; echo describe_exit=\$?"
run d7-no-csv-writer "grep -c 'fprintf(raw_file' $SRC/evidence/../source/tools/platform_m5/dudect.c 2>/dev/null; grep -n 'raw_file\|--raw' $SRC/tools/platform_m5/dudect.c | head; echo '--- 与本地仓库当前版本差异（本地被后续提交改过） ---'"

printf 'final_checks_complete\n'
