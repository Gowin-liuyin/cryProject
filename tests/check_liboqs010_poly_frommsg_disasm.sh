#!/bin/sh
# 核对已保存的 poly_frommsg 反汇编：未修有消息位条件分支，修后是 setb + call。
set -eu

unfixed=${1:-docs/evidence/liboqs010-locked-20261015/logs/locked-poly-frommsg-vulnerable.s}
fixed=${2:-docs/evidence/tooling-strengthen-20261015/logs/poly-frommsg-fixed-reloc.s}

if ! grep -q 'pqcrystals_ml_kem_768_ipd_ref_poly_frommsg' "$unfixed"; then
    echo "unfixed listing is missing poly_frommsg" >&2
    exit 1
fi
if ! grep -q 'pqcrystals_ml_kem_768_ipd_ref_poly_frommsg' "$fixed"; then
    echo "fixed listing is missing poly_frommsg" >&2
    exit 1
fi
if ! grep -q $'\tbt' "$unfixed"; then
    echo "unfixed listing has no message-bit bt" >&2
    exit 1
fi
if ! grep -q $'\tjae' "$unfixed"; then
    echo "unfixed listing has no message-bit jae" >&2
    exit 1
fi
if ! grep -q '81 06' "$unfixed"; then
    echo "unfixed listing does not write 0x681" >&2
    exit 1
fi
if ! grep -q $'\tsetb' "$fixed"; then
    echo "fixed listing has no setb" >&2
    exit 1
fi
if ! grep -q 'cmov_int16' "$fixed"; then
    echo "fixed listing has no cmov_int16" >&2
    exit 1
fi
if grep -q $'\tjae' "$fixed"; then
    echo "fixed listing still has jae" >&2
    exit 1
fi
echo "disasm_check=pass"
echo "unfixed=$unfixed"
echo "fixed=$fixed"
