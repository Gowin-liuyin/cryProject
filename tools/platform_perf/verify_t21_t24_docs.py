#!/usr/bin/env python3
"""T21/T24 文档数字复核：把 PERF.md / RESULT.md 里的数字与已发布的机读 CSV 逐项对照。

只读：不重算 bootstrap，只做"文档里写的数是否等于 CSV 里的数"这一件事。
用法：python3 tools/platform_perf/verify_t21_t24_docs.py
"""

from __future__ import annotations

import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PERF_DIR = os.path.join(ROOT, "docs/evidence/r08-perf-20261016")
OPTLEVEL_DIR = os.path.join(ROOT, "docs/evidence/r09-optlevel-20261016")


def read_rows(path: str, delimiter: str = ",") -> list[dict[str, str]]:
    with open(path, "r", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter=delimiter))


def check_r08(problems: list[str]) -> None:
    summary = read_rows(os.path.join(PERF_DIR, "perf.csv"))
    comparison = read_rows(os.path.join(PERF_DIR, "perf.csv.comparison.csv"))
    blocks = read_rows(os.path.join(PERF_DIR, "perf.csv.blocks.csv"))
    document = open(os.path.join(PERF_DIR, "PERF.md"), encoding="utf-8").read()

    if len(summary) != 25:
        problems.append(f"perf.csv 期望 25 行，实际 {len(summary)}")
    if len(comparison) != 11:
        problems.append(f"perf.csv.comparison.csv 期望 11 行，实际 {len(comparison)}")
    if len(blocks) != 150:
        problems.append(f"perf.csv.blocks.csv 期望 150 行，实际 {len(blocks)}")
    for row in summary:
        for column in ("pooled_mean_ns", "pooled_median_ns", "pooled_p90_ns", "pooled_p99_ns"):
            token = f"{float(row[column]):,.1f}"
            if token not in document:
                problems.append(f"PERF.md 缺 {row['arm']}/{row['operation']} 的 {column}={token}")
        cycles_token = f"{float(row['pooled_mean_cycles']):,.0f}"
        if cycles_token not in document:
            problems.append(f"PERF.md 缺 {row['arm']}/{row['operation']} 的均值周期={cycles_token}")
    for row in comparison:
        token = f"{float(row['overhead_percent_paired']):.3f}"
        if token not in document:
            problems.append(f"PERF.md 缺 {row['module']}/{row['operation']} 的开销%={token}")
    for row in blocks:
        if row["csv_relative_path"] not in document:
            problems.append(f"PERF.md 缺原始 CSV 路径 {row['csv_relative_path']}")


def check_r09(problems: list[str]) -> None:
    per_run = read_rows(os.path.join(OPTLEVEL_DIR, "result.csv"))
    per_cell = read_rows(os.path.join(OPTLEVEL_DIR, "result.csv.cells.csv"))
    document = open(os.path.join(OPTLEVEL_DIR, "RESULT.md"), encoding="utf-8").read()

    if len(per_run) != 36:
        problems.append(f"result.csv 期望 36 行，实际 {len(per_run)}")
    if len(per_cell) != 12:
        problems.append(f"result.csv.cells.csv 期望 12 行，实际 {len(per_cell)}")
    for row in per_cell:
        for column in ("delta_ns_run_mean", "delta_ns_run_ci_low", "delta_ns_run_ci_high"):
            token = f"{float(row[column]):+.2f}"
            if token not in document:
                problems.append(f"RESULT.md 缺 {row['cell']} 的 {column}={token}")
        sequence = " / ".join(
            f"{float(value):+.2f}" for value in row["delta_ns_per_seed"].split("|")
        )
        if sequence not in document:
            problems.append(f"RESULT.md 缺 {row['cell']} 的逐种子序列 {sequence}")
        if row["judged_artifact_sha256"] not in document:
            problems.append(f"RESULT.md 缺 {row['cell']} 的判定产物 sha256")
        if row["timed_artifact_sha3_256"] not in document:
            problems.append(f"RESULT.md 缺 {row['cell']} 的计时产物 digest")
        if row["memcheck_contexts"] == "0" and row["memcheck_errors"] == "0":
            if "**0 / 0**" not in document:
                problems.append("RESULT.md 缺 Memcheck 0 / 0 的写法")
        else:
            token = f"**{row['memcheck_contexts']} / {row['memcheck_errors']}**"
            if token not in document:
                problems.append(f"RESULT.md 缺 {row['cell']} 的 Memcheck {token}")
    for row in per_run:
        if row["csv_relative_path"] not in document and row["run_name"] not in document:
            problems.append(f"RESULT.md 未提及运行 {row['run_name']}")


def main() -> int:
    problems: list[str] = []
    check_r08(problems)
    check_r09(problems)
    if problems:
        print(f"发现 {len(problems)} 处不一致：")
        for item in problems[:40]:
            print(" -", item)
        return 1
    print("T21/T24 文档数字与机读 CSV 全部一致（PERF.md / RESULT.md）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
