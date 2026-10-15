#!/usr/bin/env python3
"""T24 图：优化级别 vs Δ(message-zero - message-ones) ± 95% CI，按臂分色，零线参考。

输入：docs/evidence/r09-optlevel-20261016/result.csv.cells.csv（analyze_r09_optlevel.py 的输出）
输出：docs/evidence/r09-optlevel-20261016/figures/r09_delta_by_optlevel.pdf（矢量）+ .png（预览）

说明：这是**族外**描述图，不做多重比较校正，不含任何 Holm 家族。
"""

from __future__ import annotations

import argparse
import csv
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

LEVEL_ORDER = ("-O0", "-O2", "-O3", "-Os")
ARM_STYLE = {
    "m1unfixed": ("#c0392b", "o", "M1 unfixed (liboqs 0.10.0 clangover)"),
    "m1fixed": ("#2471a3", "s", "M1 fixed (+982c762)"),
    "m5ref": ("#1e8449", "^", "M5 mlkem-native reference (b3ba7b3)"),
}


def main() -> int:
    parser = argparse.ArgumentParser(description="R09 Δ 图（T24 交付）")
    parser.add_argument(
        "--cells-csv", default="docs/evidence/r09-optlevel-20261016/result.csv.cells.csv"
    )
    parser.add_argument(
        "--out-pdf", default="docs/evidence/r09-optlevel-20261016/figures/r09_delta_by_optlevel.pdf"
    )
    parser.add_argument(
        "--out-png", default="docs/evidence/r09-optlevel-20261016/figures/r09_delta_by_optlevel.png"
    )
    arguments = parser.parse_args()

    rows: dict[tuple[str, str], dict[str, str]] = {}
    with open(arguments.cells_csv, "r", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            rows[(row["arm"], row["optimization_level"])] = row

    figure, axes = plt.subplots(figsize=(8.2, 5.0), dpi=200)
    offsets = {"m1unfixed": -0.16, "m1fixed": 0.0, "m5ref": 0.16}
    for arm, (color, marker, label) in ARM_STYLE.items():
        x_values = []
        y_values = []
        lower_errors = []
        upper_errors = []
        for level_index, level in enumerate(LEVEL_ORDER):
            row = rows.get((arm, level))
            if row is None or not row.get("delta_ns_run_mean"):
                continue
            mean = float(row["delta_ns_run_mean"])
            low = float(row["delta_ns_run_ci_low"])
            high = float(row["delta_ns_run_ci_high"])
            x_values.append(level_index + offsets[arm])
            y_values.append(mean)
            lower_errors.append(mean - low)
            upper_errors.append(high - mean)
        axes.errorbar(
            x_values,
            y_values,
            yerr=[lower_errors, upper_errors],
            fmt=marker,
            color=color,
            ecolor=color,
            markersize=7,
            capsize=4,
            elinewidth=1.4,
            label=label,
        )

    axes.axhline(0.0, color="#555555", linewidth=1.0, linestyle="--")
    axes.set_xticks(range(len(LEVEL_ORDER)))
    axes.set_xticklabels(LEVEL_ORDER)
    axes.set_xlabel("optimization level (clang-18, whole-tree same level)")
    axes.set_ylabel("delta of decapsulation mean, ns\n(message-zero − message-ones)")
    axes.set_title(
        "R09: end-to-end timing delta by optimization level\n"
        "3 seeds per cell, error bars = 95% bootstrap CI over the 3 seed deltas (family-external)"
    )
    axes.grid(True, axis="y", alpha=0.25)
    axes.legend(loc="lower left", fontsize=8, framealpha=0.9)
    axes.annotate(
        "positive = message-zero slower\nnegative = message-zero faster",
        xy=(0.995, 0.02),
        xycoords="axes fraction",
        ha="right",
        va="bottom",
        fontsize=7,
        color="#444444",
    )
    figure.tight_layout()

    for path in (arguments.out_pdf, arguments.out_png):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        figure.savefig(path, bbox_inches="tight")
    print(f"wrote {arguments.out_pdf} and {arguments.out_png}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
