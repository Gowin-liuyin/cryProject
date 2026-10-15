#!/bin/sh
# r03 三臂构建：只读冻结树，产物全部落在新根内；TMPDIR/TMP/TEMP 显式指向新根 tmp/。
# 用法: r03_build_arms.sh <new-root>
set -eu

ROOT=$1
CRY=/home/nss-marker/yhr/Cry
M1=$CRY/liboqs010-historical-20261015-86131c2
M5=$CRY/platform-m5-20261016-30efdf66eb26
CLANG18=/usr/bin/clang-18
CLANG=/usr/bin/clang
STRICT="-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror"
DUDECT_FLAGS="-std=c11 -O2 -g -DNDEBUG"

export TMPDIR="$ROOT/tmp" TMP="$ROOT/tmp" TEMP="$ROOT/tmp" XDG_CACHE_HOME="$ROOT/cache"

# M5 参考臂：链接 build-v2-ordinary/reference/libmlkem.a（kernel.c.o + mlkem.c.o + random.c.o + inputs.c.o）
$CLANG18 $STRICT \
    -DR03_ARM_NAME='"m5-native-reference"' \
    -DR03_LINKED_IMPLEMENTATION='"mlkem-native-b3ba7b3-portable-reference"' \
    -DR03_BUILD_FLAGS="\"$CLANG18 $STRICT\"" \
    -I "$M5/source-v2/include" \
    "$ROOT/src/r03_malformed_measure.c" \
    -o "$ROOT/build/m5ref/r03_malformed_measure" \
    "$M5/build-v2-ordinary/reference/libmlkem.a"

# M1 两臂：链接各自 historical/libmlkem.a + liboqs010-install/lib/liboqs.a
for arm in m1unfixed:m1-historical-unfixed:liboqs-0.10.0-clangover-unfixed \
           m1fixed:m1-historical-fixed-982c762:liboqs-0.10.0-plus-982c762-fixed ; do
    arm_directory=${arm%%:*}
    rest=${arm#*:}
    arm_name=${rest%%:*}
    implementation=${rest#*:}
    if [ "$arm_directory" = "m1unfixed" ]; then
        build_directory="$M1/build/historical-clangover"
    else
        build_directory="$M1/build/historical-fixed-982c762"
    fi
    $CLANG $STRICT \
        -DR03_ARM_NAME="\"$arm_name\"" \
        -DR03_LINKED_IMPLEMENTATION="\"$implementation\"" \
        -DR03_BUILD_FLAGS="\"$CLANG $STRICT\"" \
        -I "$M1/include" \
        "$ROOT/src/r03_malformed_measure.c" \
        -o "$ROOT/build/$arm_directory/r03_malformed_measure" \
        "$build_directory/historical/libmlkem.a" \
        "$build_directory/liboqs010-install/lib/liboqs.a"
    # 族外 dudect 等价入口：同一份 tools/historical_dudect.c + 钉版上游 dudect.h
    $CLANG $DUDECT_FLAGS \
        -I "$M1/include" -isystem "$ROOT/src" \
        "$ROOT/src/historical_dudect.c" \
        -o "$ROOT/build/$arm_directory/r03_historical_dudect" \
        "$build_directory/historical/libmlkem.a" \
        "$build_directory/liboqs010-install/lib/liboqs.a" -lm
done
