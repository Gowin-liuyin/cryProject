#!/bin/sh
# T2.3 额外等价驱动构建：分别链接 M2 未修/已修（当前已打主候选补丁）静态库。
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work_root="$repository_root/build/m2-equiv-work"
build_root="$repository_root/build/cmake-platform"
toolchain_clang="/home/ubuntu/miniconda3/envs/cry/bin/clang"

for variant in unfixed fixed; do
    variant_root="$repository_root/vendor/kyber-kyberslash-$variant/ref"
    "$toolchain_clang" -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wconversion \
        -Werror -I"$repository_root/include" -I"$variant_root" \
        -c "$work_root/equiv_driver.c" -o "$work_root/equiv-$variant.o"
    "$toolchain_clang" "$work_root/equiv-$variant.o" \
        "$build_root/libplatform_m2_${variant}.a" \
        "$build_root/libplatform_m2_${variant}_vendor.a" \
        -o "$work_root/equiv-$variant"
    printf 'built: %s/equiv-%s\n' "$work_root" "$variant"
done
