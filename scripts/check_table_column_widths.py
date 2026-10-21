#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对**表格列宽**：长内容列不允许被压到「每行只有几个字符」的窄列。

背景（2026-10-21 独立可读性复查）：官方报告的 DOCX 里 27 张表的列宽是**等宽硬编码**，
「证据路径」这类必然很长的列被压到 3–4 个字符宽，35 页表格被逐字断行——读者要把
竖排碎片在脑子里横向拼回去才能读出「这一格证明了什么」。**这已经不是不好看，而是
证据不可读**。

判据（本脚本按**生成的列宽**判，不靠渲染后的猜测）：

- 先看每列的**最长不可断开片段**（连续的 ASCII 串，如路径、commit 号）：
  - 内容短的列（例如只有「1」「2」「3」或计数）即使窄也没问题，**不判失败**；
  - 内容长且列窄 → 路径会被切成每行不足 12 个字符的碎片 → **判失败**。
- 9pt 字体下 ASCII 字符宽约 1.6 mm，据此把列宽换算成「每行能放下几个 ASCII 字符」。

覆盖两处：
1. 平台补充报告的 LaTeX（按 `generate_report.py` 同一套算法算出的列宽）；
2. 官方《作品设计报告》的 DOCX（直接读 `word/document.xml` 里的 `w:gridCol`）。

退出码 0 表示通过。
"""

import json
import re
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
TABLES = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report-tables.json"
OFFICIAL_DOCX = REPOSITORY / "CACR2026EA16XZ-作品设计报告.docx"

# 9pt 字体下 ASCII 字符的平均宽度（米）与「可接受的每行字符数下限」
ASCII_WIDTH_METERS = 0.0016
MINIMUM_CHARACTERS_PER_LINE = 12
# 一列里若存在超过这个长度的不可断开片段，才算「长内容列」
LONG_TOKEN_THRESHOLD = 24


def cell_weight(value):
    """一个单元格的「文字量」：中文按 2 个字符宽计，ASCII 按 1 计。"""
    return sum(2 if ord(character) > 0x2E80 else 1 for character in str(value))


def longest_token(value):
    """最长的不可断开片段（连续 ASCII，非空格）。中文可任意断行，不计入。"""
    tokens = re.findall(r"[!-~]{3,}", str(value))
    return max((len(token) for token in tokens), default=0)


def planned_widths(table, total_width=16.2):
    """与 generate_report.py 的 render_table() 同一套列宽算法。"""
    column_count = len(table["columns"])
    available = total_width - 0.30 * column_count
    weights = []
    for column_index in range(column_count):
        longest = len(str(table["columns"][column_index]))
        for row in table["rows"]:
            if column_index < len(row):
                longest = max(longest, cell_weight(row[column_index]))
        weights.append(min(longest, 110))
    weight_total = sum(weights) or column_count
    widths = [max(1.5, round(available * weight / weight_total, 2)) for weight in weights]
    difference = round(available - sum(widths), 2)
    index = widths.index(max(widths))
    widths[index] = round(widths[index] + difference, 2)
    return widths


def column_tokens(table, column_index):
    longest = 0
    for row in table["rows"]:
        if column_index < len(row):
            longest = max(longest, longest_token(row[column_index]))
    return longest


def check_platform_tables():
    failures = []
    tables = json.loads(TABLES.read_text(encoding="utf-8"))["tables"]
    for table in tables:
        widths = planned_widths(table, 24.4 if table.get("landscape") else 16.2)
        for column_index, width in enumerate(widths):
            token = column_tokens(table, column_index)
            if token <= LONG_TOKEN_THRESHOLD:
                continue
            characters_per_line = width / ASCII_WIDTH_METERS / 100.0
            if characters_per_line < MINIMUM_CHARACTERS_PER_LINE:
                failures.append(
                    "表 %s 第 %d 列宽 %.2f cm（每行约 %.0f 个 ASCII 字符），"
                    "而该列有 %d 字符长的路径/标识串，会被切成碎片"
                    % (table["id"], column_index + 1, width, characters_per_line, token))
    return failures


def check_official_docx():
    failures = []
    if not OFFICIAL_DOCX.is_file():
        return ["官方 DOCX 不存在：" + str(OFFICIAL_DOCX)]
    with zipfile.ZipFile(OFFICIAL_DOCX) as archive:
        document_xml = archive.read("word/document.xml").decode("utf-8")
    tables = re.findall(r"<w:tbl>(.*?)</w:tbl>", document_xml, flags=re.S)
    if not tables:
        return ["官方 DOCX 里没有表格：列宽无法核对"]
    for index, table_xml in enumerate(tables, start=1):
        grid = re.search(r"<w:tblGrid>(.*?)</w:tblGrid>", table_xml, flags=re.S)
        if grid is None:
            failures.append("第 %d 张表没有 w:tblGrid" % index)
            continue
        widths = [int(value) for value in re.findall(r'<w:gridCol w:w="(\d+)"', grid.group(1))]
        if not widths:
            failures.append("第 %d 张表没有列宽定义" % index)
            continue
        # 逐行取每个单元格的文字，按列号对齐
        column_tokens_found = [0] * len(widths)
        for row_xml in re.findall(r"<w:tr[ >].*?</w:tr>", table_xml, flags=re.S):
            cells = re.findall(r"<w:tc[ >].*?</w:tc>", row_xml, flags=re.S)
            for column_index, cell_xml in enumerate(cells):
                if column_index >= len(widths):
                    break
                text = "".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", cell_xml))
                column_tokens_found[column_index] = max(column_tokens_found[column_index],
                                                        longest_token(text))
        for column_index, width in enumerate(widths):
            token = column_tokens_found[column_index]
            if token <= LONG_TOKEN_THRESHOLD:
                continue
            characters_per_line = width / 20.0 / ASCII_WIDTH_METERS / 100.0
            if characters_per_line < MINIMUM_CHARACTERS_PER_LINE:
                failures.append(
                    "官方 DOCX 第 %d 张表第 %d 列宽 %d twips（每行约 %.0f 个 ASCII 字符），"
                    "而该列有 %d 字符长的路径/标识串，会被切成碎片"
                    % (index, column_index + 1, width, characters_per_line, token))
    return failures


def main():
    failures = check_platform_tables()
    failures.extend(check_official_docx())
    if failures:
        print("不通过：")
        for item in failures:
            print("  - " + item)
        return 1
    print("通过：平台报告与官方报告的表格列宽都够放下一行路径，没有被压成几字符宽的窄列。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
