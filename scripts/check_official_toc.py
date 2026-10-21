#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对官方《作品设计报告》PDF 里**打印出来的目录页码**与**该标题的实际页码**是否一致。

为什么要有这个门禁：LibreOffice 无头导出时不会展开 Word 的 TOC 域（目录只剩一行提示），
第一遍导出的页码是按「目录占 1 行」量出来的；换成静态目录（33 条、占满一页）后正文整体后移，
页码就整体差 1 页——文本层仍然「有页码」，人眼才看得出来。构建脚本已改成迭代到页码稳定，
本脚本是最后一道独立复核：解析 PDF 目录页上的点线与页码，逐条与书签实际页码比对，
有任何一条对不上就以非 0 退出。

用法：
  python3 scripts/check_official_toc.py <官方PDF>
"""

import argparse
import re
import sys

import fitz

TOC_TITLE_PATTERN = re.compile(r"目\s*录")
LEADER_PATTERN = re.compile(r"^(?P<title>.*?)\.{3,}\s*(?P<page>\d+)\s*$")
CONTINUATION_PATTERN = re.compile(r"^(?P<title>.*?)\.{3,}\s*$")


def collect_toc_entries(document):
    """从目录页里取出 (标题, 打印页码) 列表；标题过长换行时接续下一行的页码。"""
    entries = []
    for page_index in range(document.page_count):
        text = document[page_index].get_text()
        if not TOC_TITLE_PATTERN.search(text):
            continue
        pending = None
        for line in text.splitlines():
            line = line.strip()
            if not line or TOC_TITLE_PATTERN.search(line):
                continue
            match = LEADER_PATTERN.match(line)
            if match:
                entries.append((match.group("title").strip(), int(match.group("page"))))
                pending = None
                continue
            match = CONTINUATION_PATTERN.match(line)
            if match:
                pending = match.group("title").strip()
                continue
            if pending is not None and line.isdigit():
                entries.append((pending, int(line)))
                pending = None
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf_path")
    arguments = parser.parse_args()

    document = fitz.open(arguments.pdf_path)
    printed = collect_toc_entries(document)
    bookmarks = [(title.strip(), page) for _, title, page in document.get_toc()]

    if not printed:
        print("没有解析到目录条目，无法核对。")
        return 1

    bookmark_by_title = {}
    for title, page in bookmarks:
        bookmark_by_title.setdefault(title, page)

    problems = []
    unmatched = []
    for title, page in printed:
        actual = bookmark_by_title.get(title)
        if actual is None:
            unmatched.append(title)
            continue
        if actual != page:
            problems.append((title, page, actual))

    print("文件：%s" % arguments.pdf_path)
    print("页数：%d；目录条目 %d 条；书签 %d 条" % (document.page_count, len(printed), len(bookmarks)))
    if len(printed) != len(bookmarks):
        problems.append(("（条目数不符）", len(printed), len(bookmarks)))
    if problems:
        print("目录页码与实际页码不一致 %d 条：" % len(problems))
        for title, printed_page, actual_page in problems:
            print("  - %s：目录写 %d，实际 %d" % (title, printed_page, actual_page))
    if unmatched:
        print("目录条目未在书签中找到对应标题 %d 条：%s" % (len(unmatched), unmatched[:5]))
    if len(printed) != len(bookmarks):
        print("目录条目数 %d 与书签数 %d 不符（有条目没被解析出来）" % (len(printed), len(bookmarks)))
    if problems or unmatched:
        return 1
    print("通过：目录打印页码与标题实际页码逐条一致。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
