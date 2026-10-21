#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成附件三「审批及签字页」的待签字版本（DOCX + PDF）。

输入（只读）：
  deliverables/report/待编号-2026密码竞赛审批及签字页.docx
        官方附件三模板的工作副本（版式、承诺语与签字栏原样保留）。
输出：
  CACR2026EA16XZ-审批及签字页.docx
  CACR2026EA16XZ-审批及签字页.pdf

填写口径：
  * 只填**系统可确定**的字段：作品编号（系统自动分配号）与作品题目。
  * 队伍成员姓名、院系/部门、专业、任务分工、签字，指导教师意见与院系盖章
    一律留空——这些必须由**本人手写**或**实物盖章**，脚本不得代填。
  * 版式、字号、表格结构与承诺语不改动，只替换两处字段文本。
"""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from docx import Document

REPOSITORY = Path(__file__).resolve().parents[1]
TEMPLATE = REPOSITORY / "deliverables/report/待编号-2026密码竞赛审批及签字页.docx"
OUTPUT_DOCX = REPOSITORY / "CACR2026EA16XZ-审批及签字页.docx"
OUTPUT_PDF = REPOSITORY / "CACR2026EA16XZ-审批及签字页.pdf"
SOFFICE = Path("/Applications/LibreOffice.app/Contents/MacOS/soffice")
FONTCONFIG_FILE = REPOSITORY / "scripts/libreoffice-fonts.conf"

SYSTEM_NUMBER = "CACR2026EA16XZ"
WORK_TITLE = (
    "ML-KEM 解封装实现的时间侧信道检测与常数时间防护"
    "——多泄漏检测平台与五模块时间侧信道证据闭环"
)


def replace_in_paragraph(paragraph, old_text, new_text):
    """把段落里的 old_text 换成 new_text，保留首个命中的 run 的版式。"""
    if old_text not in paragraph.text:
        return False
    remaining = new_text
    for run in paragraph.runs:
        if old_text in run.text:
            run.text = run.text.replace(old_text, remaining)
            remaining = ""
            break
    if remaining:
        paragraph.runs[0].text = paragraph.runs[0].text + remaining
    return True


def sanitize_metadata(docx_path):
    """清理附件三 DOCX 的包级元数据。

    2026-10-21 复查发现：官方模板带来的 `docProps/custom.xml` 里有 WPS 的
    `KSOTemplateDocerSaveRecord`（base64 内含 `hdid` 与 `userId` 设备标识），
    `docProps/app.xml` 还留着 `Company=微软中国` 与 `Application=WPS Office…`。
    这些是**模板自带的**、不是队伍身份，但签字页是要交出去的件，不该留着：
    这里清空 custom.xml 的全部属性，并把 app.xml 的公司与程序名置空。
    模板的正文、表格与版式**一个字节都不动**。
    """
    import tempfile
    import zipfile

    with tempfile.TemporaryDirectory(dir=str(REPOSITORY / "build")) as temporary_directory:
        temporary_path = Path(temporary_directory) / "sanitized.docx"
        with zipfile.ZipFile(docx_path) as source:
            with zipfile.ZipFile(temporary_path, "w", zipfile.ZIP_DEFLATED) as target:
                for item in source.infolist():
                    content = source.read(item.filename)
                    if item.filename == "docProps/custom.xml":
                        content = (b'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                                   b'<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"'
                                   b' xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"/>')
                    elif item.filename == "docProps/app.xml":
                        import re as regular_expression
                        text = content.decode("utf-8")
                        for tag in ("Company", "Application", "Manager", "Template"):
                            text = regular_expression.sub(
                                r"<" + tag + r"(\s[^>]*)?>.*?</" + tag + r">",
                                "<" + tag + "></" + tag + ">", text, count=1, flags=regular_expression.S)
                        content = text.encode("utf-8")
                    target.writestr(item, content)
        shutil.copyfile(temporary_path, docx_path)


def keep_last_row_whole(document):
    """让「所在单位或部门意见 + 盖章 + 日期」那一行**不跨页**。

    背景（2026-10-21 复查）：题名较长，模板原本两页的排版被推成「第一页塞满、
    第二页只剩一行『年 月 日』」——签字人要在第二页单独写日期。
    这里**不动模板的任何间距与字号**，只禁止最后一行被拆开：
    该行要么整行留在第一页，要么整行落到第二页（盖章区自成一块，反而便于盖章）。
    """
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn

    for table in document.tables:
        if not table.rows:
            continue
        row = table.rows[-1]
        properties = row._tr.get_or_add_trPr()
        if properties.find(qn("w:cantSplit")) is None:
            properties.append(OxmlElement("w:cantSplit"))


def enlarge_member_rows(document, minimum_cm=1.4):
    """把「队伍成员」表的行高提到 ≥14 mm。

    2026-10-21 第 4 轮复核实测：队员行只有 11.2 mm，「姓名 / 院系 / 专业 /
    任务分工 / 队员签字」五项挤一行——签字本身够写，「任务分工」只能写短语。
    这里只加行高（`w:trHeight` 的 atLeast），不改模板的间距、字号与内容。
    """
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn

    twips = int(round(minimum_cm * 567))
    for table in document.tables:
        if not table.rows:
            continue
        header = "".join(cell.text for cell in table.rows[0].cells)
        if "姓名" not in header or "任务分工" not in header:
            continue
        for row in table.rows:
            properties = row._tr.get_or_add_trPr()
            height = properties.find(qn("w:trHeight"))
            if height is None:
                height = OxmlElement("w:trHeight")
                properties.append(height)
            height.set(qn("w:val"), str(twips))
            height.set(qn("w:hRule"), "atLeast")
        return True
    return False


def enlarge_seal_area(document, minimum_cm=5.0):
    """把「所在单位或部门意见 / 盖章 / 年 月 日」那一行的行高放大到**够盖公章**。

    2026-10-21 的可读性复查实测：那一行只有约 2.9 cm 高，而单位公章直径通常
    4.0–4.2 cm——照现状印出来，公章会盖到框外。这里只加行高（`w:trHeight` 的
    atLeast，不改模板的间距、字号与内容），让盖章区成块。
    """
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn

    twips = int(round(minimum_cm * 567))
    for table in document.tables:
        if not table.rows:
            continue
        row = table.rows[-1]
        if "盖章" not in "".join(cell.text for cell in row.cells):
            continue
        properties = row._tr.get_or_add_trPr()
        height = properties.find(qn("w:trHeight"))
        if height is None:
            height = OxmlElement("w:trHeight")
            properties.append(height)
        height.set(qn("w:val"), str(twips))
        height.set(qn("w:hRule"), "atLeast")
        return True
    return False


def main():
    if not TEMPLATE.is_file():
        raise SystemExit("缺少模板：" + str(TEMPLATE))
    document = Document(str(TEMPLATE))

    number_done = False
    title_done = False
    for table in document.tables:
        for row in table.rows:
            for cell in row.cells:
                for paragraph in cell.paragraphs:
                    if "作品编号" in paragraph.text and not number_done:
                        number_done = replace_in_paragraph(
                            paragraph, "作品编号：[系统编号待填写]", "作品编号：" + SYSTEM_NUMBER)
                    if "作品题目" in paragraph.text and not title_done:
                        title_done = replace_in_paragraph(
                            paragraph,
                            "作品题目：ML-KEM 解封装实现的时间侧信道检测与常数时间防护（暂定题名）",
                            "作品题目：" + WORK_TITLE)
    for paragraph in document.paragraphs:
        if "作品编号" in paragraph.text and not number_done:
            number_done = replace_in_paragraph(
                paragraph, "作品编号：[系统编号待填写]", "作品编号：" + SYSTEM_NUMBER)
        if "作品题目" in paragraph.text and not title_done:
            title_done = replace_in_paragraph(
                paragraph,
                "作品题目：ML-KEM 解封装实现的时间侧信道检测与常数时间防护（暂定题名）",
                "作品题目：" + WORK_TITLE)
    if not number_done or not title_done:
        raise SystemExit("未在模板里找到作品编号或作品题目字段")

    keep_last_row_whole(document)
    enlarge_member_rows(document)
    enlarge_seal_area(document)
    document.save(str(OUTPUT_DOCX))

    sanitize_metadata(OUTPUT_DOCX)

    if SOFFICE.is_file():
        # 导出 PDF 前显式给出系统字体目录：本机 LibreOffice 默认找不到中文系统字体，
        # 导出的 PDF 会整段丢字（文本层仍在，纯文本检查抓不到）。
        environment = dict(os.environ)
        environment["FONTCONFIG_FILE"] = str(FONTCONFIG_FILE)
        (REPOSITORY / "build/fonts-cache").mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=str(REPOSITORY / "build")) as temporary_directory:
            subprocess.run([
                str(SOFFICE), "--headless", "--norestore",
                "--convert-to", "pdf:writer_pdf_Export",
                "--outdir", temporary_directory, str(OUTPUT_DOCX),
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=environment)
            produced = Path(temporary_directory) / (OUTPUT_DOCX.stem + ".pdf")
            if not produced.is_file():
                raise SystemExit("PDF 导出失败")
            shutil.copyfile(produced, OUTPUT_PDF)
        subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_pdf_render.py"),
                        str(OUTPUT_PDF)], check=True)
    else:
        print("提示：未找到 LibreOffice，未导出 PDF。", file=sys.stderr)

    print("已生成：" + OUTPUT_DOCX.name + (" 与 " + OUTPUT_PDF.name if OUTPUT_PDF.is_file() else ""))
    print("提示：队伍成员信息、指导教师意见与院系盖章须由本人手写与实物盖章后使用。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
