#!/usr/bin/env python3
"""T24：把 RESULT.md 里的两张溯源表（产物摘要、逐次运行清单）就地重建。

表格内容全部从 `result.csv` / `result.csv.cells.csv` 读取，替换 RESULT.md 中
"### 2.1" 与 "### 2.2" 两节下的表格，正文其余部分不动。
这样"文档里的表 = 机读 CSV 的表"，可重复生成。

用法：python3 tools/platform_optlevel/emit_r09_resolution_tables.py
"""

from __future__ import annotations

import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OPTLEVEL_DIR = os.path.join(ROOT, "docs/evidence/r09-optlevel-20261016")

ARTIFACT_HEADER = (
    "| 格 | 判定产物 sha256（T22 `disasm/CELLS.sha256`） | 计时产物 digest（T23 meta，自报 SHA3-256） |\n"
    "|---|---|---|\n"
)
RUN_HEADER = (
    "| 格 | run-name | 种子 | CPU | zero 均值 ns | ones 均值 ns | Δ ns | 原始 CSV（相对仓库根） |\n"
    "|---|---|---:|---|---:|---:|---:|---|\n"
)


def read_rows(path: str) -> list[dict[str, str]]:
    with open(path, "r", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def artifact_table(rows: list[dict[str, str]]) -> str:
    body = "\n".join(
        f"| `{row['cell']}` | `{row['judged_artifact_sha256']}` | `{row['timed_artifact_sha3_256']}` |"
        for row in rows
    )
    return ARTIFACT_HEADER + body


def run_table(rows: list[dict[str, str]]) -> str:
    body = "\n".join(
        "| `{cell}` | `{run}` | {seed} | {cpu} | {zero} | {ones} | {delta} | `{path}` |".format(
            cell=row["cell"],
            run=row["run_name"],
            seed=row["seed_index"],
            cpu=row["cpu_policy_hint"],
            zero=f"{float(row['mean_message_zero_ns']):,.2f}",
            ones=f"{float(row['mean_message_ones_ns']):,.2f}",
            delta=f"{float(row['delta_ns']):+.3f}",
            path=row["csv_relative_path"],
        )
        for row in rows
    )
    return RUN_HEADER + body


def replace_section_table(document: str, heading: str, next_heading: str, table: str) -> str:
    """只替换小节里"从表头行开始到下一节标题之前"的那一段表格，保留小节内的说明文字。"""
    start = document.index(heading) + len(heading)
    end = document.index(next_heading, start)
    section = document[start:end]
    table_start = section.index("| ")
    last_row_end = section.rindex("|") + 1
    table_end = section.index("\n", last_row_end) if "\n" in section[last_row_end:] else len(section)
    # 表格末尾的换行由 section[table_end:] 自带，这里不再额外补，保证重复运行幂等
    rebuilt = section[:table_start] + table + section[table_end:]
    _ = rebuilt
    return document[:start] + rebuilt + document[end:]


def main() -> int:
    cells = read_rows(os.path.join(OPTLEVEL_DIR, "result.csv.cells.csv"))
    runs = read_rows(os.path.join(OPTLEVEL_DIR, "result.csv"))
    document_path = os.path.join(OPTLEVEL_DIR, "RESULT.md")
    document = open(document_path, encoding="utf-8").read()

    document = replace_section_table(
        document,
        "### 2.1 产物溯源（两种摘要算法并列，不做等式断言）",
        "### 2.2 逐次运行清单（36 次有效运行，每次指回原始 CSV）",
        artifact_table(cells),
    )
    # 说明文字与表格之间保留一个空行

    document = replace_section_table(
        document,
        "### 2.2 逐次运行清单（36 次有效运行，每次指回原始 CSV）",
        "## 3. 三个问题的答案（只用数据说话）",
        run_table(runs),
    )
    with open(document_path, "w", encoding="utf-8") as handle:
        handle.write(document)
    print(f"rebuilt provenance tables in {document_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
