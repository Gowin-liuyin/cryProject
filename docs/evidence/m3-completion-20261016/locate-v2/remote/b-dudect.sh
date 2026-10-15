#!/bin/bash
# B) 尝试在 M3 新根普通构建里启用 platform_m5_dudect，并单独链接 on/off 臂。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"; SRC="$NEWROOT/source"; B="$NEWROOT/build-ordinary"; LOGS="$NEWROOT/logs"
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
    printf 'step=%-44s exit=%s\n' "$name" "$status"
}

run b1-third-party-dudect-present "ls -la $SRC/third_party/dudect/src/dudect.h && sha256sum $SRC/third_party/dudect/src/dudect.h && find $SRC/third_party/dudect -type f | sort | head -30"
run b2-reconfigure "cmake -S $SRC -B $B -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF -DPLATFORM_M3_CTGRIND=ON"
run b3-target-list "cd $B && cmake --build . --target help 2>/dev/null | grep -i 'dudect'"
run b4-build-dudect "cmake --build $B --parallel 4 --target platform_m5_dudect"
run b5-dudect-identity "ls -l $B/platform_m5_dudect; sha256sum $B/platform_m5_dudect; file $B/platform_m5_dudect"
run b6-dudect-linkline "find $B -name link.txt | xargs grep -l platform_m5_dudect | head -1 | xargs cat"
run b7-dudect-selftest "cd $B && ./platform_m5_dudect --self-test; echo selftest_exit=\$?"
run b8-dudect-describe "cd $B && ./platform_m5_dudect --describe; echo describe_exit=\$?"
run b9-dudect-collect-usage-only "cd $B && ./platform_m5_dudect --help; echo help_exit=\$?"

# 单独把 dudect 目标链到 M3 on/off 臂上（不改仓库源码，只在构建目录里手工链接）
for mode in on off; do
    if [ "$mode" = on ]; then leak=1; else leak=0; fi
    OV="$B/platform-m3-${mode}-source/mlkem"
    run "b10-build-m3dudect-${mode}" "clang -O2 -g -DNDEBUG -std=c11 -DMLK_CONFIG_FILE='\"baseline_config.h\"' -DPLATFORM_IMPLEMENTATION_NAME='\"platform-m3-lut-${mode}\"' -DPLATFORM_M3_LUT_LEAK=${leak} -I$OV -I$SRC/include -I$SRC/vendor/mlkem-native/mlkem -I$SRC/third_party/dudect/src $SRC/tools/platform_m5/dudect.c $SRC/src/inputs.c $B/platform-m3/${mode}/libmlkem.a -lm -o $PROBE/m3dudect-${mode} && ls -l $PROBE/m3dudect-${mode} && sha256sum $PROBE/m3dudect-${mode}"
    run "b11-m3dudect-${mode}-selftest" "$PROBE/m3dudect-${mode} --self-test; echo selftest_exit=\$?"
done
run b12-implementation-names "strings $B/platform_m3_on_probe | grep -m2 'platform-m3-lut'; strings $B/platform_m3_off_probe | grep -m2 'platform-m3-lut'; strings $SRC/tools/platform_m5/dudect.c | grep -m2 'reference'; grep -n 'strcmp(mlkem_implementation_name' $SRC/tools/platform_m5/dudect.c"

printf 'dudect_probe_complete\n'
