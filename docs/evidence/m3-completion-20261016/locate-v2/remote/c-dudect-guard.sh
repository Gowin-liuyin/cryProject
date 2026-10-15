#!/bin/bash
# C) 放宽 M5 dudect 的实现名守卫（仅该守卫与注释），重建 on/off 两臂 dudect 并自检。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"; SRC="$NEWROOT/source"; B="$NEWROOT/build-ordinary"; LOGS="$NEWROOT/logs"
EV="$NEWROOT/evidence"; mkdir -p "$EV"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache" CCACHE_DIR="$NEWROOT/cache/ccache"
mkdir -p "$TMPDIR" "$HOME" "$XDG_CACHE_HOME" "$CCACHE_DIR"

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

# c1: 保存改动前原件
cp -a "$SRC/tools/platform_m5/dudect.c" "$EV/dudect.c.original"
run c1-original-identity "sha256sum $EV/dudect.c.original; sed -n '36,50p' $SRC/tools/platform_m5/dudect.c"

# c2: 仅替换守卫（含注释），不改统计内核/批预算/类域/输出格式
python3 - "$SRC/tools/platform_m5/dudect.c" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
old = '    return strcmp(mlkem_implementation_name(), "reference") != 0;\n'
new = (
    '    /* 采数准入：M5 参考臂与 M3 人工 LUT 夹具的开/关两臂共用同一套自检；\n'
    '       其他实现名仍拒绝，避免把未审查的实现当成可采数对象。 */\n'
    '    const char *implementation_name = mlkem_implementation_name();\n'
    '    return strcmp(implementation_name, "reference") != 0 &&\n'
    '        strcmp(implementation_name, "platform-m3-lut-on") != 0 &&\n'
    '        strcmp(implementation_name, "platform-m3-lut-off") != 0;\n'
)
assert text.count(old) == 1, "guard anchor count != 1"
open(path, "w", encoding="utf-8").write(text.replace(old, new, 1))
PY
run c2-patched-guard "sed -n '36,56p' $SRC/tools/platform_m5/dudect.c; sha256sum $SRC/tools/platform_m5/dudect.c"
run c3-diff "diff -u $EV/dudect.c.original $SRC/tools/platform_m5/dudect.c; echo diff_exit=\$?"

# c4: 重建两臂 dudect（各自链接自己的 overlay）
for mode in on off; do
    if [ "$mode" = on ]; then leak=1; else leak=0; fi
    OV="$B/platform-m3-${mode}-source/mlkem"
    run "c4-build-m3dudect-${mode}" "clang -O2 -g -DNDEBUG -std=c11 -DMLK_CONFIG_FILE='\"baseline_config.h\"' -DPLATFORM_IMPLEMENTATION_NAME='\"platform-m3-lut-${mode}\"' -DPLATFORM_M3_LUT_LEAK=${leak} -I$OV -I$SRC/include -I$SRC/vendor/mlkem-native/mlkem -I$SRC/third_party/dudect/src $SRC/tools/platform_m5/dudect.c $SRC/src/inputs.c $B/platform-m3/${mode}/libmlkem.a -lm -o $PROBE/m3dudect-${mode}"
done
run c5-identity "ls -l $PROBE/m3dudect-on $PROBE/m3dudect-off; sha256sum $PROBE/m3dudect-on $PROBE/m3dudect-off; file $PROBE/m3dudect-on"
run c6-implementation-strings "strings $PROBE/m3dudect-on | grep -m3 'platform-m3-lut'; echo '--- off ---'; strings $PROBE/m3dudect-off | grep -m3 'platform-m3-lut'; echo '--- reference in on? ---'; strings $PROBE/m3dudect-on | grep -c '^reference$'"

# c7: 两臂自检
run c7-selftest-on "$PROBE/m3dudect-on --self-test; echo selftest_exit=\$?"
run c7-selftest-off "$PROBE/m3dudect-off --self-test; echo selftest_exit=\$?"
run c8-selftest-raw-on "$PROBE/m3dudect-on --self-test-raw $NEWROOT/tmp/m3dudect-on.selftest.csv; echo selftest_raw_exit=\$?; head -3 $NEWROOT/tmp/m3dudect-on.selftest.csv"
run c8-selftest-raw-off "$PROBE/m3dudect-off --self-test-raw $NEWROOT/tmp/m3dudect-off.selftest.csv; echo selftest_raw_exit=\$?; head -3 $NEWROOT/tmp/m3dudect-off.selftest.csv"

# c9: 采集件确认（M3 measure 两臂）+ CTest 计数
run c9-measure-identity "ls -l $B/platform-m3/on/measure $B/platform-m3/off/measure; sha256sum $B/platform-m3/on/measure $B/platform-m3/off/measure"
run c10-ctest "cd $B && ctest -R platform_m3 --output-on-failure 2>&1 | tail -15"
run c11-ref-target-still-selftest "$B/platform_m5_dudect --self-test; echo reference_dudect_selftest_exit=\$?"

printf 'dudect_guard_fix_complete\n'
