#!/bin/sh
# T2.2：按 docs/evidence/m2-kem-20261016 记录的口径，用本地 clang-18.1.8
# 复刻 M2 已修臂 vendor 编译并链接一次 keygen/encaps/decaps 的驱动，产出反汇编。
# 只写 build/，不改 vendor。目录约定：<work>/<variant>/ref/*.c
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work_root="$repository_root/build/m2-branchfix-work"
toolchain_clang="/home/ubuntu/miniconda3/envs/cry/bin/clang"

# 证据口径：CMake RelWithDebInfo = -O2 -g -DNDEBUG；M2 vendor 另加
# -Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3 -Drandombytes=platform_m2_randombytes；
# 工程 C 标准为 -std=c11（C_EXTENSIONS OFF）。
vendor_flags="-O2 -g -DNDEBUG -Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3 -Drandombytes=platform_m2_randombytes -std=c11"

variant=${1:-baseline}
vendor_root="$work_root/$variant/ref"
object_root="$work_root/objects-$variant"

if [ ! -f "$vendor_root/poly.c" ]; then
    printf 'missing variant tree: %s\n' "$vendor_root" >&2
    exit 1
fi
mkdir -p "$object_root"

for source_name in kem indcpa poly polyvec ntt cbd reduce verify fips202 symmetric-shake; do
    "$toolchain_clang" $vendor_flags -I"$vendor_root" -c "$vendor_root/$source_name.c" \
        -o "$object_root/$source_name.o"
done
"$toolchain_clang" -O2 -g -DNDEBUG -std=c11 -I"$vendor_root" -c "$work_root/driver.c" \
    -o "$object_root/driver.o"
"$toolchain_clang" "$object_root"/*.o -o "$work_root/$variant-driver"

"$toolchain_clang" --version | head -1 > "$work_root/$variant-clang-version.txt"
objdump --version | head -1 > "$work_root/$variant-objdump-version.txt"
objdump -d --no-show-raw-insn --disassemble=pqcrystals_kyber768_ref_poly_frommsg \
    "$work_root/$variant-driver" > "$work_root/$variant-poly_frommsg.asm"
printf 'built: %s\n' "$work_root/$variant-driver"
