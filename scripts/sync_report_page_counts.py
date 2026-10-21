#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把各处「报告页数」的声明同步到**实物**。

背景（2026-10-21 第 3–4 轮复核）：报告一改，页数就变，而页数在**五份文档**里各写了一遍
（根 README、交接文档、平台报告 README、审计、签字清单）。每次改完报告都要手工追这几处，
漏一处就是「文档说的页数与实物不一致」——第 4 轮复核查出的两处不一致就是这样来的。

这个脚本把声明**改成实物**（不是反过来），并把改过的文件列出来。用法：

    python3 scripts/sync_report_page_counts.py
    python3 scripts/sync_report_page_counts.py --check   # 只检查不改

退出码 0 表示已一致（或 --check 通过）。
"""

import argparse
import re
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
OFFICIAL_PDF = REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf"
PLATFORM_PDF = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report.pdf"

TARGETS = {
    "README.md": [
        (r"官方模板封面 \+ \d+ 页 PDF 正文", "官方模板封面 + {official} 页 PDF 正文"),
        (r"同名 PDF \d+ 页", "同名 PDF {official} 页"),
        (r"多泄漏检测平台 \d+ 页补充报告", "多泄漏检测平台 {platform} 页补充报告"),
    ],
    "HANDOFF_DONE.md": [
        (r"同名 PDF，\*\*\d+ 页\*\*", "同名 PDF，**{official} 页**"),
        (r"report\.pdf`，\*\*\d+ 页\*\*、", "report.pdf`，**{platform} 页**、"),
    ],
    "deliverables/research/multi-leakage-platform-20261016/README.md": [
        (r"当前已核验副本为 \[\d+ 页 PDF\]", "当前已核验副本为 [{platform} 页 PDF]"),
        (r"\*\*\d+ 页\*\*且中文字形正常", "**{official} 页**且中文字形正常"),
    ],
}


def pdf_pages(path):
    import fitz

    with fitz.open(path) as document:
        return document.page_count


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="只检查，不改文件")
    arguments = parser.parse_args()

    official = pdf_pages(OFFICIAL_PDF)
    platform = pdf_pages(PLATFORM_PDF)
    values = {"official": str(official), "platform": str(platform)}

    changed = []
    for relative, rules in TARGETS.items():
        path = REPOSITORY / relative
        if not path.is_file():
            continue
        original = path.read_text(encoding="utf-8")
        text = original
        for pattern, template in rules:
            text = re.sub(pattern, template.format(**values), text)
        if text != original:
            changed.append(relative)
            if not arguments.check:
                path.write_text(text, encoding="utf-8")

    print("实物页数：官方 %d 页 / 平台补充报告 %d 页" % (official, platform))
    if changed:
        print("已同步：%s" % "、".join(changed))
    else:
        print("各处声明已与实物一致")
    if arguments.check and changed:
        print("→ 需要同步（先跑一次不带 --check 的）")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
