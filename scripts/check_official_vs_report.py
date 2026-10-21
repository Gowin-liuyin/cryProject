#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对官方《作品设计报告》与平台补充报告**没有脱节**。

为什么要有这个门禁：官方 DOCX 是从平台报告 `report.md` 合流出来的，
一旦平台报告改了而官方件没重出，两份文档就会给出**不同的事实**——
2026-10-21 复查轮就实测到过：平台报告写「网络预算差约 1.3/4.5/5.7/7.7 个数量级」，
官方报告还写着「1/4/5/7」。纯页数与目录检查抓不到这类脱节。

做法：从平台报告正文里**自动抽取若干条带数字的事实句**，要求它们逐字出现在官方 DOCX 的
文本层里；抽不到或对不上就以非 0 退出。抽取项由 `FACT_PATTERNS` 定义，新增事实类型只需加一条正则。

- `scope = "both"`：该事实必须在平台报告里出现，并且逐字出现在官方 DOCX 里；
- `scope = "docx_only"`：该事实只存在于官方件（封面日期来自官方模板封面），只在 DOCX 里查。

用法：
  python3 scripts/check_official_vs_report.py
退出码 0 表示两份文档的事实口径一致。
"""

import re
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
REPORT_MARKDOWN = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report.md"
OFFICIAL_DOCX = REPOSITORY / "CACR2026EA16XZ-作品设计报告.docx"

FACT_PATTERNS = [
    ("封面日期", r"2026 年 10 月 \d+ 日", "docx_only"),
    ("R05 四类计数", r"存在 \d+ / 不存在 \d+ / 不适用 \d+ / 未检查 \d+", "both"),
    ("题面 12 条状态", r"10 条满足 \+ 2 条部分", "both"),
    ("网络预算量级", r"回环差约[^；。]*数量级", "both"),
    ("网络结论上限", r"只写「本预算下未检出」", "both"),
    ("F1 闭合口径", r"B 类（内部验证结果泄露）由 1 条降为 0 条", "both"),
    ("R16 计时基准", r"TSC 速率实测 [\d ]+kHz", "both"),
    ("官方补丁描述更正", r"值屏障不是该补丁带来的", "both"),
    ("种子范围用法更正", r"不得把该范围当成区间证据", "both"),
    ("附录 A 可选三项", r"可选三项在? ?\d{4}-\d{2}-\d{2} (均已执行|全部完成)", "both"),
]


def official_text():
    xml = zipfile.ZipFile(OFFICIAL_DOCX).read("word/document.xml").decode("utf-8")
    return re.sub(r"<[^>]+>", "", xml)


def main():
    if not REPORT_MARKDOWN.is_file() or not OFFICIAL_DOCX.is_file():
        print("缺少平台报告或官方 DOCX，无法核对。")
        return 1
    report_text = REPORT_MARKDOWN.read_text(encoding="utf-8")
    document_text = official_text()

    failures = []
    for name, pattern, scope in FACT_PATTERNS:
        if scope == "docx_only":
            if not re.findall(pattern, document_text):
                failures.append("官方 DOCX 里找不到事实项「%s」（正则 %s）" % (name, pattern))
            continue
        matches = re.findall(pattern, report_text)
        if not matches:
            failures.append("平台报告里找不到事实项「%s」（正则 %s）——"
                            "要么平台报告被改得没有这条事实，要么抽取规则过时" % (name, pattern))
            continue
        for value in dict.fromkeys(matches):
            if value not in document_text:
                failures.append("官方 DOCX 缺少平台报告的事实「%s」：%s" % (name, value))

    print("平台报告：%s" % REPORT_MARKDOWN.relative_to(REPOSITORY))
    print("官方 DOCX：%s" % OFFICIAL_DOCX.relative_to(REPOSITORY))
    print("核对事实项：%d 类" % len(FACT_PATTERNS))
    if failures:
        print("不一致：")
        for item in failures:
            print("  - " + item)
        print("→ 官方件落后于平台报告：重跑 `sh scripts/build_official_report.sh` 再核对。")
        return 1
    print("通过：官方《作品设计报告》与平台补充报告的事实口径一致。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
