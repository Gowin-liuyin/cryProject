"""T26 + T27 一键复算：POWER.md + QUANTILE_CI.md + figures/*.pdf。

运行（在仓库根目录）：
    python3 docs/evidence/r04-stats-20261016/robustness-src/r04_run_all.py

只读仓库内已有证据 CSV；不联网、不重新采集、不改动任何已有证据文件、不做密钥恢复。
预计耗时约 4 分钟，其中 ~1.5 分钟是 T27 的 bootstrap（B = 10000 × 41 个主类对）。
"""

from __future__ import annotations

import time

import r04_power
import r04_quantile
import r04_figures


def main() -> None:
    started = time.time()
    print("=== T26 功效分析 / MDE ===")
    r04_power.main()
    print()
    print("=== T27 分位数差 + bootstrap CI ===")
    r04_quantile.main()
    print()
    print("=== T27 图（ECDF + 箱线图） ===")
    r04_figures.main()
    print()
    print("全部完成，总耗时 %.1f s" % (time.time() - started))


if __name__ == "__main__":
    main()
