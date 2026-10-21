#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对报告里的 R05 排查表计数与 `docs/R05-全流程排查表.md` 的 §4.1 合计行是否一致。

背景（2026-10-21 复查发现）：报告 §11 与表 T5 仍引用**补格之前**的计数
（存在 5 / 不存在 74 / 不适用 10 / 未检查 1）与补格前的分实现归属，
而同一报告的摘要、§24、附录 A 又写补格后的 5/75/10/0——同一份报告自相矛盾。
本脚本把「R05 文件的合计行」当作唯一权威，逐处核对报告里的写法，
并挡���「74/1」这种旧计数（只允许出现在「74→75」这种历史说明里）。

用法：
  python3 scripts/check_report_r05_counts.py
退出码 0 表示一致，非 0 表示不一致。
"""

import json
import re
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
R05_TABLE = REPOSITORY / "docs/R05-全流程排查表.md"
REPORT_DIRECTORY = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"


def r05_totals():
    """从 R05 文件 §4.1 的合计行取四类计数。"""
    text = R05_TABLE.read_text(encoding="utf-8")
    match = re.search(r"\|\s*\*\*合计\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|"
                      r"\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|", text)
    if match is None:
        raise SystemExit("R05 文件里找不到 §4.1 合计行")
    return tuple(int(value) for value in match.groups())


def main():
    exists, absent, inapplicable, unchecked = r05_totals()
    expected = "存在 %d、不存在 %d、不适用 %d、未检查 %d" % (exists, absent, inapplicable, unchecked)
    print("R05 §4.1 合计：%s" % expected)

    failures = []
    report_text = (REPORT_DIRECTORY / "report.md").read_text(encoding="utf-8")
    tables = json.loads((REPORT_DIRECTORY / "report-tables.json").read_text(encoding="utf-8"))

    # 1) 报告正文必须逐字出现权威计数
    if expected not in report_text:
        failures.append("report.md 未逐字出现「%s」" % expected)

    # 2) 表 T5 的 R05 行必须逐字出现权威计数
    t5_rows = []
    for table in tables["tables"]:
        if table["id"] == "T5":
            t5_rows = [row for row in table["rows"] if any("R05 全流程排查表" in str(cell) for cell in row)]
    if not t5_rows:
        failures.append("表 T5 里找不到 R05 行")
    elif not any(expected in str(cell) for row in t5_rows for cell in row):
        failures.append("表 T5 的 R05 行未逐字出现「%s」" % expected)

    # 3) 旧计数不得再作为现行口径出现（只允许「74→75」这类历史说明）
    for name, content in (("report.md", report_text),
                          ("report-tables.json", (REPORT_DIRECTORY / "report-tables.json").read_text(encoding="utf-8"))):
        for match in re.finditer(r"不存在\s*%d" % (absent - 1), content):
            window = content[max(0, match.start() - 12):match.end() + 12]
            if "→" not in window:
                failures.append("%s 里仍有旧计数「不存在 %d」且不是历史说明：…%s…"
                                % (name, absent - 1, window))
        for match in re.finditer(r"未检查\s*%d(?!\s*\))" % (unchecked + 1), content):
            window = content[max(0, match.start() - 12):match.end() + 12]
            if "→" not in window:
                failures.append("%s 里仍有旧计数「未检查 %d」且不是历史说明：…%s…"
                                % (name, unchecked + 1, window))

    # 4) 补格前的分实现归属不得再出现
    for name, content in (("report.md", report_text),
                          ("report-tables.json", (REPORT_DIRECTORY / "report-tables.json").read_text(encoding="utf-8"))):
        for stale in ("M1 两个、M2 两个、M5 一个", "M1 2（982c762 覆盖）、M2 2（272125f 覆盖）"):
            if stale in content:
                failures.append("%s 里仍有补格前的归属写法：%s" % (name, stale))

    if failures:
        print("不一致：")
        for item in failures:
            print("  - " + item)
        return 1
    print("通过：报告与表 T5 的 R05 计数、分实现归属均与 R05 文件 §4.1 一致。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
