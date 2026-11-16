#!/usr/bin/env python3
"""在 build/m2-branchfix-work/ 内生成三份 poly_frommsg 候选修复工作副本。

目录约定：<work>/<variant>/ref/（与 vendor/kyber-kyberslash-fixed/ref 同构），
以便补丁用 `git apply --directory=<variant>` 或 `--directory=vendor/kyber-kyberslash-fixed`
同一套路径应用。只改 build/ 工作副本，不碰 vendor。
"""

import shutil
from pathlib import Path

WORK_ROOT = Path(__file__).resolve().parent
BASELINE_ROOT = WORK_ROOT / "baseline"
BASELINE_POLY = BASELINE_ROOT / "ref" / "poly.c"
CANDIDATE_NAMES = ("asm", "volatile", "ctselect")

ORIGINAL_LOOP_TAIL = """      mask = -(int16_t)((msg[i] >> j)&1);
      r->coeffs[8*i+j] = mask & ((KYBER_Q+1)/2);
"""

ASM_LOOP_TAIL = """      mask = -(int16_t)((msg[i] >> j)&1);
      /* 值屏障：让编译器无法把 mask 再识别成 0/-1 的位选择分支。 */
      __asm__("" : "+r"(mask));
      r->coeffs[8*i+j] = mask & ((KYBER_Q+1)/2);
"""

VOLATILE_LOOP_TAIL = """      mask = -(int16_t)((msg[i] >> j)&1);
      /* volatile 指针往返：把掩码值从可被位选择优化的表达式里隔开。 */
      int16_t volatile *mask_sink = &mask;
      mask = *mask_sink;
      r->coeffs[8*i+j] = mask & ((KYBER_Q+1)/2);
"""

CTSELECT_LOOP_TAIL = """      mask = -(int16_t)((msg[i] >> j)&1);
      r->coeffs[8*i+j] = mask_select_int16(mask, (KYBER_Q+1)/2);
"""

CTSELECT_HELPER = """/* 常量时间选择：noinline 阻止把掩码折回位选择分支。 */
static __attribute__((noinline)) int16_t mask_select_int16(int16_t mask, int16_t value)
{
  return mask & value;
}

"""

FROM_MSG_COMMENT = """/*************************************************
* Name:        poly_frommsg
"""


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit("error: %s matched %d times, expected 1" % (label, count))
    return text.replace(old, new)


def main():
    if not BASELINE_POLY.is_file():
        raise SystemExit("error: missing baseline copy %s" % BASELINE_POLY)
    for candidate_name in CANDIDATE_NAMES:
        candidate_root = WORK_ROOT / candidate_name
        if candidate_root.exists():
            shutil.rmtree(candidate_root)
        shutil.copytree(BASELINE_ROOT, candidate_root)
        poly_path = candidate_root / "ref" / "poly.c"
        source_text = poly_path.read_text(encoding="utf-8")
        if candidate_name == "asm":
            patched_text = replace_once(
                source_text, ORIGINAL_LOOP_TAIL, ASM_LOOP_TAIL, "asm loop tail"
            )
        elif candidate_name == "volatile":
            patched_text = replace_once(
                source_text, ORIGINAL_LOOP_TAIL, VOLATILE_LOOP_TAIL, "volatile loop tail"
            )
        else:
            patched_text = replace_once(
                source_text, ORIGINAL_LOOP_TAIL, CTSELECT_LOOP_TAIL, "ctselect loop tail"
            )
            patched_text = replace_once(
                patched_text,
                FROM_MSG_COMMENT,
                CTSELECT_HELPER + FROM_MSG_COMMENT,
                "ctselect helper insertion",
            )
        poly_path.write_text(patched_text, encoding="utf-8")
        print("candidate ready: %s" % candidate_root)


if __name__ == "__main__":
    main()
