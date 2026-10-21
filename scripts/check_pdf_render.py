#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查导出的 PDF 是否真的能显示中文，而不是只在文本层里“看得见”。

背景（2026-10-20 实测）：本机 LibreOffice 26.8.1.1 因为找不到中文系统字体，
导出的官方作品设计报告 PDF 里汉字整段不显示，但 `pdftotext` 仍能抽出中文，
只查文本层会漏判。本检查按两条独立判据把关：

  1. 页面里至少嵌入一款覆盖中文的字体（按字体名判定，覆盖 Songti/Heiti/
     Kaiti/PingFang/Hiragino/Arial Unicode/FZXiaoBiaoSong/FangSong 等）；
  2. 前若干页渲染后的非白像素比例达到下限——整页无字形的 PDF 渲染出来几乎全白。

用法：
  python3 scripts/check_pdf_render.py <PDF> [--pages 3] [--min-ink 0.01]
退出码 0 表示通过，非 0 表示不通过（可直接用于构建流水线）。
"""

import argparse
import sys
from pathlib import Path

import fitz

CJK_FONT_MARKERS = (
    "Songti", "STSong", "Heiti", "STHeiti", "Kaiti", "STKaiti", "PingFang",
    "Hiragino", "HiraMaru", "Arial Unicode", "FZXiaoBiaoSong", "FangSong",
    "Noto Sans CJK", "Noto Serif CJK", "Source Han", "SimSun", "SimHei", "Hei",
    "Fandol",
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf_path")
    parser.add_argument("--pages", type=int, default=3)
    parser.add_argument("--min-ink", type=float, default=0.01)
    parser.add_argument("--max-overlaps", type=int, default=-1,
                        help="文字物理重叠的上限（-1 表示不检查；标点相邻不算）")
    parser.add_argument("--max-fragments", type=int, default=20000,
                        help="窄列逐字断行的文本碎片上限（宽<45pt 且 2–4 字符）")
    arguments = parser.parse_args()

    pdf_path = Path(arguments.pdf_path)
    if not pdf_path.is_file():
        print("缺少 PDF：" + str(pdf_path))
        return 1

    document = fitz.open(str(pdf_path))
    fonts = set()
    for page_index in range(document.page_count):
        for entry in document[page_index].get_fonts(full=True):
            fonts.add(entry[3] or "")
    cjk_fonts = sorted(name for name in fonts
                       if any(marker.lower() in name.lower() for marker in CJK_FONT_MARKERS))

    checked_pages = min(arguments.pages, document.page_count)
    ink_ratios = []
    for page_index in range(checked_pages):
        pixmap = document[page_index].get_pixmap(dpi=72)
        image = pixmap.pil_image().convert("L")
        histogram = image.histogram()
        total = image.width * image.height
        non_white = sum(histogram[:250])
        ink_ratios.append(non_white / total if total else 0.0)

    # 窄列逐字断行：统计「宽 < 45pt 且 2–4 字符」的文本碎片。
    # 表格列宽按内容分配 + 多列表用 9pt 之后，这个数应当显著下降；
    # 超过阈值说明又有表被压回等宽窄列（2026-10-21 可读性复查的实测问题）。
    fragments = 0
    for page_index in range(document.page_count):
        for block in document[page_index].get_text("dict")["blocks"]:
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    content = span["text"].strip()
                    if not content:
                        continue
                    if (span["bbox"][2] - span["bbox"][0]) < 45 and 2 <= len(content) <= 4:
                        fragments += 1

    print("文件：" + str(pdf_path))
    print("页数：%d" % document.page_count)
    print("嵌入字体（%d 款）：%s" % (len(fonts), "、".join(sorted(fonts)) or "无"))
    print("覆盖中文的字体：%s" % ("、".join(cjk_fonts) or "无"))
    print("前 %d 页非白像素比例：%s" % (checked_pages,
                                       "、".join("%.4f" % ratio for ratio in ink_ratios)))
    print("窄小文本片段（宽<45pt 且 2–4 字符，参考值）：%d 处（上限 %d）"
          % (fragments, arguments.max_fragments))


    # 文字**物理重叠**（两段文字的包围盒相交）检查：可选门禁。
    # 只统计**都不是纯标点**的重叠——CJK 标点与数学符号的排版间距会让相邻 span
    # 的包围盒轻微相交（xeCJK 的中西文间距调整、组合符号的上划线），那是排版常态，
    # 不是缺陷。真正要拦的是「组合符号 / 长片段顶到邻列」这类真重叠
    # （2026-10-21 的 Δ̄ 就是这么发现的：在官方报告里与后一个文字横叠 9pt）。
    overlaps = 0
    if arguments.max_overlaps >= 0:
        punctuation = set("（）【】《》「」、。，；：？！…—·%")
        for page_index in range(document.page_count):
            spans = []
            for block in document[page_index].get_text("dict")["blocks"]:
                for line in block.get("lines", []):
                    for span in line.get("spans", []):
                        content = span["text"].strip()
                        if content:
                            spans.append((span["bbox"], content))
            for first in range(len(spans)):
                for second in range(first + 1, len(spans)):
                    box_a, text_a = spans[first]
                    box_b, text_b = spans[second]
                    if all(character in punctuation for character in text_a):
                        continue
                    if all(character in punctuation for character in text_b):
                        continue
                    horizontal = min(box_a[2], box_b[2]) - max(box_a[0], box_b[0])
                    vertical = min(box_a[3], box_b[3]) - max(box_a[1], box_b[1])
                    if horizontal > 3.0 and vertical > 2.0:
                        overlaps += 1

    if arguments.max_overlaps >= 0:
        print("文字物理重叠（不含标点相邻）：%d 处（上限 %d）" % (overlaps, arguments.max_overlaps))

    failures = []
    if not cjk_fonts:
        failures.append("没有任何覆盖中文的嵌入字体：中文多半无法显示")
    if checked_pages and max(ink_ratios) < arguments.min_ink:
        failures.append("前几页渲染几乎全白：字形很可能没有真正画出来")
    # 这个指标**只是参考**：PDF 里逐字换行的正文（标点与数字造成的短行）也会被算进去，
    # 所以它不能单独当「表格被压窄」的判据。真正的门禁在
    # `scripts/check_table_column_widths.py`（按**生成的列宽**判，不靠渲染猜测）。
    # 这里只留一个宽松的上限，拦「排版彻底失控」这种极端情况。
    if 0 <= arguments.max_overlaps < overlaps:
        failures.append("文字物理重叠 %d 处（上限 %d）：有组合符号或长片段顶到了邻列"
                        % (overlaps, arguments.max_overlaps))
    if fragments > arguments.max_fragments:
        failures.append("窄小文本片段 %d 处（上限 %d）：排版可能整体失控，请同时跑 "
                        "scripts/check_table_column_widths.py" % (fragments, arguments.max_fragments))
    if failures:
        print("不通过：")
        for item in failures:
            print("  - " + item)
        return 1
    print("通过：PDF 内嵌了中文字体且页面有实际字形。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
