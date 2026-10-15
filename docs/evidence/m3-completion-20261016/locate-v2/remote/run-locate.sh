#!/bin/bash
# M3 locate-v2：在新的完整解封装普通构建上重跑四组合 Memcheck。全部落盘在 NEWROOT 内。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
if [ "$(realpath "$NEWROOT")" != "$NEWROOT" ]; then echo "not canonical" >&2; exit 2; fi

LOGS="$NEWROOT/logs"
SUP="$LOGS/supplementary"
mkdir -p "$LOGS" "$SUP"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export XDG_CACHE_HOME="$NEWROOT/cache" CCACHE_DIR="$NEWROOT/cache/ccache"
export HOME="$NEWROOT/home"
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$CCACHE_DIR" "$HOME"

{
  date -Is
  hostname
  uname -a
  clang --version | head -2
  cmake --version | head -1
  valgrind --version
  objdump --version | head -1
  printf 'NEWROOT=%s\n' "$NEWROOT"
  printf 'TMPDIR=%s\nXDG_CACHE_HOME=%s\nHOME=%s\n' "$TMPDIR" "$XDG_CACHE_HOME" "$HOME"
  printf 'nproc=%s\n' "$(nproc)"
} > "$LOGS/identity.log" 2>&1

# 1) 全新配置与构建（普通、完整解封装、CTGRIND 开启）
cmake -S "$NEWROOT/source" -B "$NEWROOT/build-ordinary" -DCMAKE_C_COMPILER=clang \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF \
    -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF -DPLATFORM_M3_CTGRIND=ON \
    > "$LOGS/configure-ordinary.log" 2>&1
configure_status=$?
printf '%s\n' "$configure_status" > "$LOGS/configure-ordinary.exit"
cmake --build "$NEWROOT/build-ordinary" --parallel 8 \
    --target platform_m3 platform_m3_check platform_m3_on_probe platform_m3_off_probe \
    > "$LOGS/build-ordinary.log" 2>&1
build_status=$?
printf '%s\n' "$build_status" > "$LOGS/build-ordinary.exit"

# 2) 源码与产物摘要
( cd "$NEWROOT/source" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) \
    > "$LOGS/source-SHA256SUMS" 2>&1
for artifact in \
    "$NEWROOT/build-ordinary/platform_m3_on_probe" \
    "$NEWROOT/build-ordinary/platform_m3_off_probe" \
    "$NEWROOT/build-ordinary/platform-m3/on/baseline" \
    "$NEWROOT/build-ordinary/platform-m3/on/measure" \
    "$NEWROOT/build-ordinary/platform-m3/off/baseline" \
    "$NEWROOT/build-ordinary/platform-m3/off/measure" \
    "$NEWROOT/build-ordinary/platform_m3_on_equivalence" \
    "$NEWROOT/build-ordinary/platform_m3_off_equivalence" \
    "$NEWROOT/build-ordinary/platform_m3_reference_equivalence" \
    "$NEWROOT/build-ordinary/platform_m3_on_test_mlkem" \
    "$NEWROOT/build-ordinary/platform_m3_off_test_mlkem" \
    "$NEWROOT/build-ordinary/platform_m3_on_test_random_failure" \
    "$NEWROOT/build-ordinary/platform_m3_off_test_random_failure" ; do
    if [ -f "$artifact" ]; then
        sha256sum "$artifact"
    else
        printf 'MISSING %s\n' "$artifact"
    fi
done > "$LOGS/binary-SHA256SUMS" 2>&1

# 3) 四组合标准 Memcheck（命令与 tools/platform_m3/README.md 一致）
run_combo() {
    fixture_mode="$1"
    marking="$2"
    probe="$NEWROOT/build-ordinary/platform_m3_${fixture_mode}_probe"
    base="$LOGS/${fixture_mode}-${marking}"
    set +e
    if [ "$marking" = secret ]; then
        # 与 tools/platform_m3/README.md 第一条命令逐字一致
        valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 \
            --log-file="$base.memcheck.log" \
            "$probe" "--$marking" > "$base.stdout.log" 2> "$base.stderr.log"
    else
        # 与 tools/platform_m3/README.md 第三条命令逐字一致
        valgrind --tool=memcheck --error-exitcode=97 \
            --log-file="$base.memcheck.log" \
            "$probe" "--$marking" > "$base.stdout.log" 2> "$base.stderr.log"
    fi
    status=$?
    set -e
    printf '%s\n' "$status" > "$base.exit"
    printf 'combo=%s-%s exit=%s\n' "$fixture_mode" "$marking" "$status" >> "$LOGS/combos.summary"
}
: > "$LOGS/combos.summary"
run_combo on secret
run_combo off secret
run_combo on defined
run_combo off defined

# 3b) 补充：带 -s --num-callers=20 的同 ELF 复跑，用于展开抑制与更深的栈
for fixture_mode in on off; do
    for marking in secret defined; do
        probe="$NEWROOT/build-ordinary/platform_m3_${fixture_mode}_probe"
        set +e
        valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 -s --num-callers=20 \
            --log-file="$SUP/${fixture_mode}-${marking}.memcheck-s.log" \
            "$probe" "--$marking" > "$SUP/${fixture_mode}-${marking}.stdout.log" 2>&1
        status=$?
        set -e
        printf '%s\n' "$status" > "$SUP/${fixture_mode}-${marking}.exit"
    done
done

# 3c) 守卫：不在 Valgrind 下运行必须返回 77
for fixture_mode in on off; do
    for marking in secret defined; do
        set +e
        "$NEWROOT/build-ordinary/platform_m3_${fixture_mode}_probe" "--$marking" \
            > "$SUP/${fixture_mode}-${marking}.novg.stdout.log" 2> "$SUP/${fixture_mode}-${marking}.novg.stderr.log"
        status=$?
        set -e
        printf '%s\n' "$status" > "$SUP/${fixture_mode}-${marking}.novg.exit"
    done
done

# 4) 反汇编与 PC 定位
for fixture_mode in on off; do
    objdump -d --demangle "$NEWROOT/build-ordinary/platform_m3_${fixture_mode}_probe" \
        > "$LOGS/${fixture_mode}.probe.disasm" 2>&1
    objdump -d --demangle "$NEWROOT/build-ordinary/platform-m3/${fixture_mode}/measure" \
        > "$LOGS/${fixture_mode}.measure.disasm" 2>&1
done

# 5) 结束核对
{
    printf '== remaining platform_m3 processes (excluding this script) ==\n'
    ps -eo pid,etimes,args | grep -E 'platform_m3|valgrind' | grep -v grep | grep -v run-locate || true
    printf '== symlinks under NEWROOT ==\n'
    find "$NEWROOT" -type l -print
    printf '== du ==\n'
    du -sh "$NEWROOT"
} > "$LOGS/final-check.log" 2>&1

printf 'locate_run_complete configure=%s build=%s\n' "$configure_status" "$build_status"
