#!/bin/sh
# 采集 collect ELF 的二进制证据：摘要、ldd、符号、热点反汇编与操作码直方图。
# usage: collect_binary_evidence.sh <elf> <output-dir> <label>
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: collect_binary_evidence.sh <elf> <output-dir> <label>" >&2
    exit 2
fi
elf=$1
output_dir=$2
label=$3
mkdir -p "${output_dir}"

sha256sum "${elf}" > "${output_dir}/${label}.sha256"
file "${elf}" > "${output_dir}/${label}.file"
ldd "${elf}" > "${output_dir}/${label}.ldd" 2>&1
readelf -h "${elf}" > "${output_dir}/${label}.elf-header.txt"
nm --defined-only "${elf}" | LC_ALL=C sort > "${output_dir}/${label}.defined-symbols.txt"
readelf --dyn-syms --wide "${elf}" > "${output_dir}/${label}.dynamic-symbols.txt"
nm "${elf}" | grep -i randombytes > "${output_dir}/${label}.randombytes-symbols.txt" || true

for symbol in pqcrystals_kyber768_ref_poly_tomsg pqcrystals_kyber768_ref_poly_compress \
    pqcrystals_kyber768_ref_polyvec_compress pqcrystals_kyber768_ref_dec mlkem_decapsulate; do
    objdump -d --disassemble="${symbol}" "${elf}" > "${output_dir}/${label}-${symbol}.asm"
    awk -F'\t' 'NF >= 3 {split($3, parts, " "); if (parts[1] != "") print parts[1]}' \
        "${output_dir}/${label}-${symbol}.asm" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn \
        > "${output_dir}/${label}-${symbol}.opcodes.txt"
done

{
    printf 'elf=%s\n' "${elf}"
    for symbol in pqcrystals_kyber768_ref_poly_tomsg pqcrystals_kyber768_ref_poly_compress \
        pqcrystals_kyber768_ref_polyvec_compress pqcrystals_kyber768_ref_dec mlkem_decapsulate; do
        division_count=$(grep -cE '^ +[0-9]+ +i?div[bwlq]?$' \
            "${output_dir}/${label}-${symbol}.opcodes.txt" || true)
        printf '%s: division_instructions=%s\n' "${symbol}" "${division_count}"
    done
} > "${output_dir}/${label}.division-counts.txt"

cat "${output_dir}/${label}.division-counts.txt"
