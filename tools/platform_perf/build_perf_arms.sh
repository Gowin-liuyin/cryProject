#!/bin/sh
# T20 性能采集件构建：7 个完整 KEM 臂各一份 perf_measure 普通 ELF。
# 只读冻结树；所有对象、ELF、日志都落在新根 <new-root> 内。
# TMPDIR/TMP/TEMP/XDG_CACHE_HOME 显式指向新根（/tmp 零落盘）。
#
# usage: build_perf_arms.sh <new-root>
# 输出: <new-root>/build/<arm>/perf_measure 与 <new-root>/ARM.sha256
set -eu

NEW_ROOT=$1
CRY=/home/nss-marker/yhr/Cry

M1=$CRY/liboqs010-historical-20261015-86131c2
M2=$CRY/platform-m2kem-20261016-d75a4019
M3=$CRY/platform-m3-20261016-8b6f2d91
M5=$CRY/platform-m5-20261016-30efdf66eb26

CLANG18=/usr/bin/clang-18
STRICT="-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion \
-Wstrict-prototypes -Werror"

export TMPDIR="$NEW_ROOT/tmp" TMP="$NEW_ROOT/tmp" TEMP="$NEW_ROOT/tmp"
export XDG_CACHE_HOME="$NEW_ROOT/cache"
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$NEW_ROOT/build" "$NEW_ROOT/logs"

SOURCE="$NEW_ROOT/src/perf_measure.c"
SOURCE_SHA256=$(sha256sum "$SOURCE" | cut -d ' ' -f 1)

build_arm() {
    arm_name=$1
    arm_id=$2
    implementation=$3
    include_directory=$4
    shift 4
    arm_directory="$NEW_ROOT/build/$arm_id"
    mkdir -p "$arm_directory"
    # shellcheck disable=SC2086
    $CLANG18 $STRICT \
        -DPERF_ARM_NAME="\"$arm_name\"" \
        -DPERF_BUILD_FLAGS="\"$CLANG18 $STRICT\"" \
        -I "$include_directory" \
        "$SOURCE" \
        -o "$arm_directory/perf_measure" \
        "$@" \
        -lm -lpthread
    printf '%s\n' "$implementation" > "$arm_directory/implementation.txt"
    printf '%s\n' "$include_directory" > "$arm_directory/include_directory.txt"
    printf '%s\n' "$*" > "$arm_directory/link_objects.txt"
}

# ---- M1：liboqs 0.10.0 historical-clangover（未修 / 官方 982c762） ----
build_arm "m1-historical-unfixed" "m1unfixed" \
    "liboqs-0.10.0-clangover-unfixed" \
    "$M1/include" \
    "$M1/build/historical-clangover/historical/libmlkem.a" \
    "$M1/build/historical-clangover/liboqs010-install/lib/liboqs.a"

build_arm "m1-historical-fixed-982c762" "m1fixed" \
    "liboqs-0.10.0-plus-982c762-fixed" \
    "$M1/include" \
    "$M1/build/historical-fixed-982c762/historical/libmlkem.a" \
    "$M1/build/historical-fixed-982c762/liboqs010-install/lib/liboqs.a"

# ---- M2：KyberSlash a621b8d（未修）/ 272125f（已修） ----
build_arm "m2-kyberslash-unfixed" "m2unfixed" \
    "kyber-kyberslash-unfixed" \
    "$M2/collector-v2-2e894561892a/source/include" \
    "$M2/build-ordinary/libplatform_m2_unfixed.a" \
    "$M2/build-ordinary/libplatform_m2_unfixed_vendor.a"

build_arm "m2-kyberslash-fixed" "m2fixed" \
    "kyber-kyberslash-fixed" \
    "$M2/collector-v2-2e894561892a/source/include" \
    "$M2/build-ordinary/libplatform_m2_fixed.a" \
    "$M2/build-ordinary/libplatform_m2_fixed_vendor.a"

# ---- M3：内存访问变体 on / off ----
build_arm "m3-memaccess-on" "m3on" \
    "mlkem-native-m3-memaccess-on" \
    "$M3/source/include" \
    "$M3/build-ordinary/platform-m3/on/libmlkem.a"

build_arm "m3-memaccess-off" "m3off" \
    "mlkem-native-m3-memaccess-off" \
    "$M3/source/include" \
    "$M3/build-ordinary/platform-m3/off/libmlkem.a"

# ---- M5：mlkem-native b3ba7b3 portable reference ----
build_arm "m5-native-reference" "m5ref" \
    "mlkem-native-b3ba7b3-portable-reference" \
    "$M5/source-v2/include" \
    "$M5/build-v2-ordinary/reference/libmlkem.a"

{
    printf 'source=%s\nsource_sha256=%s\n' "$SOURCE" "$SOURCE_SHA256"
    for arm_id in m1unfixed m1fixed m2unfixed m2fixed m3on m3off m5ref; do
        elf="$NEW_ROOT/build/$arm_id/perf_measure"
        printf '%s %s\n' "$(sha256sum "$elf" | cut -d ' ' -f 1)" "$elf"
    done
} > "$NEW_ROOT/ARM.sha256"

cat "$NEW_ROOT/ARM.sha256"
