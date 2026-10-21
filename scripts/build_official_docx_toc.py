#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从已排版的 PDF 目录（书签）提取每个标题的实测页码，供静态目录使用。

输入：--pdf  第一遍导出的 PDF（其书签由 Heading 1 / Heading 2 生成）
      --outline-json  可选：标题序列 JSON（由 build_official_docx.py --print-outline 给出）
输出：--out  JSON 数组 [[层级, 标题, 页码], ...]

页码口径：PDF 书签页码是 1 起的物理页序，与目录条目右侧打印的页码一致。
若书签缺失或与标题序列对不上，脚本以退出码 1 失败，不静默产出残缺目录。
"""

import argparse
import json
import sys
from pathlib import Path

import fitz


def main():
    parser = argparse.ArgumentParser(description="从 PDF 书签提取标题页码")
    parser.add_argument("--pdf", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--outline-json")
    arguments = parser.parse_args()

    document = fitz.open(arguments.pdf)
    bookmarks = document.get_toc()
    if not bookmarks:
        raise SystemExit("PDF 没有目录书签，无法提取页码：" + arguments.pdf)
    entries = [(int(level), str(title).strip(), int(page)) for level, title, page in bookmarks]

    if arguments.outline_json:
        outline = json.loads(Path(arguments.outline_json).read_text(encoding="utf-8"))
        expected = [(int(level), str(title).strip()) for level, title in outline]
        actual = [(level, title) for level, title, _ in entries]
        if expected != actual:
            raise SystemExit(
                "PDF 书签与标题序列不一致：\n期望 %d 条，实际 %d 条\n首个差异：%s"
                % (len(expected), len(actual), next(
                    (f"期望 {e} 实际 {a}" for e, a in zip(expected, actual) if e != a),
                    "长度不同",
                ))
            )

    Path(arguments.out).write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("toc entries:", len(entries))


if __name__ == "__main__":
    sys.exit(main())
