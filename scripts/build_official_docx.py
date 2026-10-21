#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成官方《作品设计报告》DOCX：官方模板封面 + M1–M5 平台主体正文。

输入（只读）：
  templates/official-report-template.docx
        官方模板（提交 5e00512 时的原字节）：封面、目录、官方样式与封面图。
  deliverables/research/multi-leakage-platform-20261016/report.md
        P2 收尾版平台报告正文（支撑材料卷），是本 DOCX 正文的技术论断唯一来源。
输出：
  CACR2026EA16XZ-作品设计报告.docx

合流口径：
  * 模板封面、目录骨架、官方样式与封面图全部保留，只替换目录之后的正文区。
  * 早期 v1–v4 归入第 0 节「前期自研探索与频率门诊断基线」，只作前期探索与对照基线登记，
    不改写其历史结论，也不把它当成本轮平台结果。
  * M1–M5 多泄漏检测平台是主体工程实现与实验结果，按模板既有章节骨架组织：
    1 作品功能与性能说明 / 2 设计与实现方案 / 3 系统测试与结果 /
    4 应用前景 / 5 结论 / 6 来源与复现材料。
  * 平台报告的实测数字、表格与结论段落逐字取自 report.md；本脚本只做章节归位与
    段落级重排，不新增、不改写任何技术论断。
  * 平台报告全文（P2 收尾版）另以 PDF 形式作为支撑材料卷随附，本 DOCX 是主报告载体。

排版口径（与模板既有正文一致）：
  * 一级标题：模板 Heading 1（STKaiti，小四加粗 15pt，段前段后 240，行距 360 auto）。
  * 二级标题：模板 Heading 2（Times New Roman + SimHei，14pt）。
  * 正文：Normal + 直接格式（楷体_GB2312 / Times New Roman，14pt，行距 480 exact）。
  * 表格：模板表格样式「网格型1」，字号 10.5pt。
"""

import html
import re
import sys
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

REPOSITORY = Path(__file__).resolve().parents[1]
TEMPLATE = REPOSITORY / "templates/official-report-template.docx"
SOURCE_MARKDOWN = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report.md"
OUTPUT_DOCX = REPOSITORY / "CACR2026EA16XZ-作品设计报告.docx"

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
TABLE_SEPARATOR_RE = re.compile(r"^\|[\s\-:|]+\|$")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")
CODE_FENCE_RE = re.compile(r"^```")
# R05 排查表 §5 流程图的静态渲染（与平台报告 PDF 用的是同一张 PNG）
R05_FLOWCHART_PNG = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/r05-flowchart.png"
TABLE_TITLE_RE = re.compile(r"^\*\*(表\s*T\d+[　\s]*[^*]+)\*\*$")
# Markdown 行内链接：保留可见标签，把目标路径并入文本，避免 PDF 里出现原始标记。
MARKDOWN_LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]*)\)")
# Markdown 图片：只保留说明文字（图片本体在 Word 版中另以图题登记）。
MARKDOWN_IMAGE_RE = re.compile(r"!\[([^\]]*)\]\(([^)]*)\)")
# 证据来源编号（E01…E60）：路径已在「来源与复现材料」章逐条列出，正文只留编号。
SOURCE_ID_RE = re.compile(r"^E\d{2}$")

# 模板正文的起始下标：0 起为封面与目录，51 起为「1 作品功能与性能说明」。
BODY_START_INDEX = 51
# 模板静态目录条目的下标区间：28 起为第一条目录项，50 为最后一条。
TOC_START_INDEX = 28
TOC_END_INDEX = 51

# 平台报告章节 → 主报告章节的归位表（键为平台报告二级标题前缀）。
SECTION_PLAN = [
    ("1 研究对象与证据口径", "1", "作品功能与性能说明"),
    ("2 平台架构与机制矩阵", "1", "作品功能与性能说明"),
    ("3 统一测量与统计方法", "1", "作品功能与性能说明"),
    ("19 M1 既有真实案例与 Mona 对照", "1", "作品功能与性能说明"),
    ("20 M2 KyberSlash：真实历史案例", "1", "作品功能与性能说明"),
    ("21 M3 与 M4：人工机制校准", "1", "作品功能与性能说明"),
    ("22 M5：参考实现阴性对照候选", "1", "作品功能与性能说明"),
    ("10 题面第 5 条对照：六类泄漏来源 × 解封装步骤", "2", "设计与实现方案"),
    ("11 题面第 5 条补充：R05 全流程六类来源排查表（90 格）", "2", "设计与实现方案"),
    ("12 题面第 6 条：修复手段映射与泄露渠道审计", "2", "设计与实现方案"),
    ("4 题面第 1 条：向量来源与修复语义等价", "3", "系统测试与结果"),
    ("5 题面第 2 条：测量环境、异常样本规则与稳健性", "3", "系统测试与结果"),
    ("6 检测—定位—修复—复测：四段链状态", "3", "系统测试与结果"),
    ("7 题面第 3 条对照：输入分类与测试", "3", "系统测试与结果"),
    ("8 题面第 4 条对照：侧信道统计检测", "3", "系统测试与结果"),
    ("9 题面第 4 条补充：功效 / MDE、分位数差与分布图", "3", "系统测试与结果"),
    ("13 题面第 3 条补充：R03 格式破损 / 截断族的族外对照", "3", "系统测试与结果"),
    ("14 题面第 8 条：性能开销表", "3", "系统测试与结果"),
    ("15 题面第 9 条：优化级别对照与跨环境范围", "3", "系统测试与结果"),
    ("17 题面第 11 条：一键复现与复现参数总表", "3", "系统测试与结果"),
    ("18 威胁模型（题面第 10 条）", "3", "系统测试与结果"),
    ("16 题面第 12 条：创新对照（锁频 vs 不锁频、多工具矩阵）", "4", "应用前景"),
    ("23 实测数值、证据对照与复算入口", "5", "结论"),
    ("24 当前局限、占位符与后续验收", "5", "结论"),
    ("25 附录 A：题面 12 条对照矩阵", "6", "来源与复现材料"),
    ("证据来源索引", "6", "来源与复现材料"),
]

PREAMBLE = [
    "本报告为 2026 年第十一届全国密码技术竞赛工程实践类作品的正式提交载体。正文以 2026 年 10 月"
    "完成的「多泄漏模块检测平台」为主体工程实现与实验结果（平台主体于 10 月 16 日完成，"
    "10 月 20 日做 P2 级收尾补强：M2 候选解释按观测自查修正、一键取件、题面 12 条由 11+1 改为 12 条逐条对照；"
    "10 月 21 日做 P2 级收尾复核：修官方报告目录页码、报告内 R05 计数与官方补丁描述的错位，并回填 T25 网络场景 / 第二架构 aarch64 / M5 重加密 Binsec / 计时精度四项实测）；"
    "此前的 v1–v4 版本作为前期自研探索与频率门诊断基线单独登记在第 0 节，"
    "只保留其历史结论与对照作用，不改写、不冒充本轮平台结果。",
    "平台报告的完整技术卷（P2 收尾版，含 25 章正文与全部实测表格）另以 PDF 形式随支撑材料提交，"
    "本报告的每个实测数字都可回到该技术卷与仓库内对应证据文件逐字核对。",
]

BASELINE_PARAGRAPHS = [
    "前期 v1–v4 的具体内容不在本报告正文重复：v1–v3 是同一把密钥下两种固定封装硬币的单密文对差"
    "（效应对象是密文个体差异，不能推广到类别差异），v4 改为 16 把密钥的输入组并引入完整解封装测量、"
    "阶段候选诊断与确认停止协议，但只完成首会话确认，primary_token 未成立。历史记录、原判定与"
    "未闭合项原样保留在仓库证据目录中，本报告引用其结论时逐条标注为封存引用。",
    "这条基线在本轮平台中的作用有两条：其一，它确定了测量必须落在完整解封装调用窗口内、"
    "必须把输入类别与密文个体效应分开、以及必须先冻结协议再采集，这三条约束直接进入了平台"
    "的实现；其二，它给出的「首会话不足以支撑类别效应结论」的判断，是平台坚持三次独立运行、"
    "预注册检验族与分状态记录的直接理由。基线不构成新漏洞、不计为检出，也不进入本报告任何统计判定。",
]


def strip_inline_markup(text):
    """去掉 Markdown 行内标记，只保留文字内容。

    * 图片转成图题文字；
    * 证据来源编号链接（E01…）只保留编号——路径已在「来源与复现材料」章逐条列出；
    * 其余链接转成「标签（路径）」，路径是证据可核性的关键信息，不能丢；
    * 粗体与反引号只去掉标记本身。
    """
    text = MARKDOWN_IMAGE_RE.sub(r"\1", text)
    text = MARKDOWN_LINK_RE.sub(_expand_link, text)
    text = BOLD_RE.sub(r"\1", text)
    # report.md 里的 &lt; &gt; &quot; &amp; 等是 HTML 转义（Markdown 渲染需要），
    # 直接搬进 DOCX 会把实体字面量印出来（2026-10-21 复查实测 42 处），故在此解码。
    text = html.unescape(text)
    return text.replace("`", "").strip()


def _expand_link(match):
    label = match.group(1).strip()
    target = match.group(2).strip()
    if SOURCE_ID_RE.match(label):
        return label
    if not target or target.startswith("#"):
        return label
    return label + "（" + target + "）"


def split_table_row(line):
    """按**未转义**的竖线切分表格行，并把转义的竖线还原成 `|`。

    报告里的表格单元格可能含竖线（例如 C 代码 `difference_bits |= a[i]^b[i]`），
    markdown 里写成转义竖线。直接 split("|") 会把一格切成两格——2026-10-21 复查实测
    官方报告表 T18 的 M4-b 行因此错位（方法分类列被写成代码片段、证据路径列丢失）。
    """
    import re as regular_expression

    cells = regular_expression.split(r"(?<!\\)\|", line.strip().strip("|"))
    return [strip_inline_markup(cell.replace(r"\|", "|")) for cell in cells]


SVG_RASTER_CACHE = REPOSITORY / "build/official-report/figures"


def rasterize_svg(svg_path):
    """把 SVG 渲染成 PNG（本机 Chrome 无头），供 Word 插图。

    官方报告的 DOCX 走 Word 路线，**插不进 SVG**；平台报告里的「平台证据矩阵」
    原本就是 SVG，直接丢掉会只剩一行图题（2026-10-21 复查发现）。这里把它
    渲染成 PNG 真正插进 DOCX。渲染结果缓存在 build/ 下，源 SVG 不改。
    """
    import subprocess

    svg_path = Path(svg_path)
    SVG_RASTER_CACHE.mkdir(parents=True, exist_ok=True)
    png_path = SVG_RASTER_CACHE / (svg_path.stem + ".png")
    if png_path.is_file() and png_path.stat().st_mtime >= svg_path.stat().st_mtime:
        return png_path
    chrome = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
    if not chrome.is_file():
        raise SystemExit("未找到本机 Chrome，无法把 SVG 渲染成 PNG：" + str(svg_path))
    subprocess.run([
        str(chrome), "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
        "--force-device-scale-factor=2", "--window-size=1500,1200",
        "--screenshot=" + str(png_path), "--default-background-color=ffffff",
        svg_path.resolve().as_uri(),
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not png_path.is_file():
        raise SystemExit("SVG 渲染失败：" + str(svg_path))
    # 裁掉渲染结果下方的空白（SVG 视口比内容高），否则 DOCX 里图与图题之间会留一大片空。
    try:
        from PIL import Image, ImageChops

        with Image.open(png_path) as image:
            background = Image.new(image.mode, image.size, (255, 255, 255))
            difference = ImageChops.difference(image.convert("RGB"), background.convert("RGB"))
            box = difference.getbbox()
            if box is not None:
                cropped = image.crop((0, 0, image.size[0], box[3]))
                cropped.save(png_path)
    except Exception:
        pass
    return png_path


def add_figure(document, image_path, caption):
    """插图 + 图题（图在上、题在下，与官方模板的图题惯例一致）。"""
    paragraph = document.add_paragraph()
    properties = paragraph._p.get_or_add_pPr()
    justification = OxmlElement("w:jc")
    justification.set(qn("w:val"), "center")
    properties.append(justification)
    run = paragraph.add_run()
    run.add_picture(str(image_path), width=Inches(6.2))
    add_caption_paragraph(document, caption)
    return paragraph


def collect_blocks(markdown_text):
    """把 Markdown 拆成有序块；表格标题（**表 T..**）单独成块以便加题注。"""
    blocks = []
    lines = markdown_text.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if not stripped:
            index += 1
            continue
        if CODE_FENCE_RE.match(stripped):
            fence_language = stripped.strip("`").strip().lower()
            index += 1
            code_lines = []
            while index < len(lines) and not CODE_FENCE_RE.match(lines[index].strip()):
                code_lines.append(lines[index])
                index += 1
            index += 1
            code_text = "\n".join(code_lines)
            if fence_language == "mermaid":
                # mermaid 源码块：DOCX 里**不再当正文印源码**（那是 3 页图描述语言，
                # 2026-10-21 复查发现），改插平台报告同源的等价静态图，源码留档路径写进图题。
                blocks.append(("figure", R05_FLOWCHART_PNG,
                               "图 2：R05 全流程排查表 §5 mermaid 流程图的等价静态渲染"
                               "（同一份节点文字、三条主链、同一套颜色语义；虚线箭头是修复映射）。"
                               "mermaid 源码原样保留在 docs/R05-全流程排查表.md §5 与本报告的离线 HTML 中；"
                               "本 PDF 只承载静态图，不改变任何一格结论。"))
            else:
                blocks.append(("code", code_text))
            continue
        heading = HEADING_RE.match(line)
        if heading:
            blocks.append(("heading", len(heading.group(1)), heading.group(2).strip()))
            index += 1
            continue
        table_title = TABLE_TITLE_RE.match(stripped)
        if table_title:
            blocks.append(("table_title", table_title.group(1).strip()))
            index += 1
            continue
        if stripped.startswith("|") and index + 1 < len(lines) and TABLE_SEPARATOR_RE.match(
            lines[index + 1].strip()
        ):
            rows = [split_table_row(line)]
            index += 2
            while index < len(lines) and lines[index].lstrip().startswith("|"):
                rows.append(split_table_row(lines[index]))
                index += 1
            blocks.append(("table", rows))
            continue
        if stripped.startswith("!["):
            # Markdown 图片：**真的插图**（原来是只留一行图题，图是空的）。
            image_match = MARKDOWN_IMAGE_RE.match(stripped)
            if image_match is not None and image_match.group(2).endswith(".svg"):
                blocks.append(("figure", rasterize_svg(REPOSITORY / "deliverables/research/multi-leakage-platform-20261016" / image_match.group(2)),
                               "图 1：" + image_match.group(1)))
            else:
                blocks.append(("caption", strip_inline_markup(stripped)))
            index += 1
            continue
        paragraph_lines = [line]
        index += 1
        while index < len(lines) and lines[index].strip() and not HEADING_RE.match(lines[index]) \
                and not lines[index].lstrip().startswith("|") and not CODE_FENCE_RE.match(
                    lines[index].strip()
                ) and not TABLE_TITLE_RE.match(lines[index].strip()):
            paragraph_lines.append(lines[index])
            index += 1
        blocks.append(("paragraph", " ".join(part.strip() for part in paragraph_lines)))
    return blocks


def set_run_font(run, east_asia, ascii_font, size_half_points):
    """按模板正文的直接格式设置字体与字号。"""
    properties = run._r.get_or_add_rPr()
    fonts = properties.find(qn("w:rFonts"))
    if fonts is None:
        fonts = OxmlElement("w:rFonts")
        properties.insert(0, fonts)
    fonts.set(qn("w:ascii"), ascii_font)
    fonts.set(qn("w:eastAsia"), east_asia)
    fonts.set(qn("w:hAnsi"), ascii_font)
    fonts.set(qn("w:hint"), "eastAsia")
    for tag in ("w:sz", "w:szCs"):
        element = properties.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            properties.append(element)
        element.set(qn("w:val"), str(size_half_points))


def add_body_paragraph(document, text, first=False):
    """正文段落：Normal + 模板正文的直接格式（楷体_GB2312 14pt，行距 480 exact）。"""
    paragraph = document.add_paragraph()
    properties = paragraph._p.get_or_add_pPr()
    for tag, attributes in (
        ("w:widowControl", {}),
        ("w:adjustRightInd", {"w:val": "0"}),
        ("w:snapToGrid", {"w:val": "0"}),
        ("w:spacing", {"w:line": "480", "w:lineRule": "exact"}),
    ):
        element = OxmlElement(tag)
        for key, value in attributes.items():
            element.set(qn(key), value)
        properties.append(element)
    if first:
        indent = OxmlElement("w:ind")
        indent.set(qn("w:firstLine"), "560")
        properties.append(indent)
    run = paragraph.add_run(text)
    set_run_font(run, "楷体_GB2312", "Times New Roman", 28)
    return paragraph


def add_caption_paragraph(document, text):
    """表题/图题：楷体_GB2312 12pt，居中。"""
    paragraph = document.add_paragraph()
    properties = paragraph._p.get_or_add_pPr()
    justification = OxmlElement("w:jc")
    justification.set(qn("w:val"), "center")
    properties.append(justification)
    spacing = OxmlElement("w:spacing")
    spacing.set(qn("w:before"), "60")
    spacing.set(qn("w:after"), "60")
    spacing.set(qn("w:line"), "240")
    spacing.set(qn("w:lineRule"), "auto")
    properties.append(spacing)
    run = paragraph.add_run(text)
    set_run_font(run, "楷体_GB2312", "Times New Roman", 24)
    return paragraph


def add_code_paragraph(document, text):
    paragraph = document.add_paragraph()
    properties = paragraph._p.get_or_add_pPr()
    spacing = OxmlElement("w:spacing")
    spacing.set(qn("w:line"), "240")
    spacing.set(qn("w:lineRule"), "auto")
    properties.append(spacing)
    run = paragraph.add_run(text)
    set_run_font(run, "Consolas", "Consolas", 20)
    return paragraph


def column_widths(rows, column_count, total_twips=9636, minimum_twips=520):
    """按每列的实际文字量分配列宽（不是等宽）。

    2026-10-21 的可读性复查发现：等宽硬编码的 `w:gridCol` 把「证据路径」这类
    必然很长的列压到 3–4 个字符宽，35 页表格被逐字断行。这里按各列内容的
    最大字符数（表头与正文取大）按比例分配，并给每列一个下限，避免某列被压成一条。
    """
    weights = []
    for column_index in range(column_count):
        longest = 1
        for row in rows:
            value = row[column_index] if column_index < len(row) else ""
            # 中文按 2 个字符宽计，ASCII 按 1 计
            length = sum(2 if ord(character) > 0x2E80 else 1 for character in str(value))
            longest = max(longest, length)
        weights.append(min(longest, 90))
    total = sum(weights) or column_count
    widths = [max(minimum_twips, int(total_twips * weight / total)) for weight in weights]
    # 归一化到总宽，避免超出页面
    while sum(widths) > total_twips:
        widest = widths.index(max(widths))
        widths[widest] -= 10
    return widths


def set_table_grid(table, widths):
    """把计算出的列宽写进 `w:tblGrid`（Word 依据它排版）。"""
    properties = table._tbl.tblPr
    existing = properties.find(qn("w:tblW"))
    if existing is None:
        existing = OxmlElement("w:tblW")
        properties.append(existing)
    existing.set(qn("w:type"), "dxa")
    existing.set(qn("w:w"), str(sum(widths)))
    layout = properties.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        properties.append(layout)
    layout.set(qn("w:type"), "fixed")
    grid = table._tbl.find(qn("w:tblGrid"))
    if grid is not None:
        table._tbl.remove(grid)
    grid = OxmlElement("w:tblGrid")
    for width in widths:
        column = OxmlElement("w:gridCol")
        column.set(qn("w:w"), str(width))
        grid.append(column)
    table._tbl.insert(list(table._tbl).index(properties) + 1, grid)


def append_table(document, rows):
    if not rows:
        return
    column_count = max(len(row) for row in rows)
    table = document.add_table(rows=len(rows), cols=column_count)
    try:
        table.style = "网格型1"
    except KeyError:
        table.style = "Table Grid"
    table.autofit = False
    set_table_grid(table, column_widths(rows, column_count))
    # 列多的表（≥6 列）正文用 9pt：6.7 英寸宽的版面里，10.5pt 的长路径列仍会被逐字断行
    # （2026-10-21 可读性复查的实测问题），9pt 能让证据引用多出一行字数。
    body_size = 18 if column_count >= 6 else 21
    for row_index, row in enumerate(rows):
        for column_index in range(column_count):
            value = row[column_index] if column_index < len(row) else ""
            cell = table.cell(row_index, column_index)
            cell.text = ""
            paragraph = cell.paragraphs[0]
            run = paragraph.add_run(value)
            set_run_font(run, "宋体", "Times New Roman", body_size)
            if row_index == 0:
                properties = run._r.get_or_add_rPr()
                properties.append(OxmlElement("w:b"))


COVER_TITLE = (
    "ML-KEM 解封装实现的时间侧信道检测与常数时间防护"
    "——多泄漏检测平台与五模块时间侧信道证据闭环"
)

COVER_ABSTRACT = (
    "本作品面向固定 ML-KEM-768 便携 C 实现，建成一个多泄漏模块检测平台："
    "以统一输入生成、完整解封装调用窗口、逐次原始值落盘与预注册检验族，"
    "对五类泄漏来源做「检测—定位—修复—复测」四段链闭环。"
    "M1（liboqs 0.10.0 未修 vs 官方修复 982c762）与 M2（pq-crystals KyberSlash，"
    "dda29cc 与 272125f）是真实历史案例；M3（秘密下标访存）与 M4（提前退出比较）"
    "是人工构造校准，只用于检验工具链能否识别目标机制；M5（mlkem-native 参考路径）"
    "是阴性对照候选。修复手段覆盖题面第 6 条的七个分类：常量时间比较、掩码选择（cmov）、"
    "固定循环上界、统一错误处理（隐式拒绝）、消除数据相关分支、消除数据相关除法、"
    "消除数据相关访存。R05 排查表把 3 实现 × 5 步骤 × 6 类来源展开为 90 格逐格给出结论；"
    "R06 泄露渠道专项审计给出秘密内容泄露 0 条（原低危发现 F1 已于 2026-10-20 闭合，"
    "计时模式 stderr 恒空、退出码与内部比较结果无关）；R08 性能开销给出 25 行汇总与 11 行成对开销；"
    "R09 优化级别对照 12 格按逆方差固定效应合并 CI 判定；R12 以 9 工具 × 5 模块的 45 格交叉矩阵"
    "回答单工具会漏掉什么。"
    "全部统计在真实 x86_64 Linux 上以锁频、绑核、预热在窗口外的口径采集，"
    "原始值全量落盘、不删普通长尾；平台报告全文（P2 收尾版，25 章正文与全部实测表格）"
    "另以 PDF 形式作为支撑材料卷随附。题面 12 条要求逐条对照：**10 条满足 + 2 条部分**"
    "（第 6 条「自研防护闭环未落在真实 ML-KEM 上、泄露渠道审计不含 vendor 树」、"
    "第 7 条「本轮自研防护只在人工构造校准链上、真实实现的前后对比引用上游补丁」——"
    "两处的缺口、原因与影响都写在附录 A 对应行与正文 §24，不按「12/12 全满足」计），"
    "判据是仓库内可打开的证据文件（**支撑材料卷内每个 `docs/…` 路径都在 "
    "`evidence/files/<同一路径>` 下有匿名副本，E01–E70 的可点索引在卷内 `index.html`**）。"
    "已执行且未检出的项目按预算给出 MDE，"
    "「未检出 = 观测效应 < MDE」；本作品不做密钥恢复、不交付 exploit、"
    "不把历史 Kyber 等同最终标准 ML-KEM、不把人工夹具算作新漏洞，"
    "现有证据也不构成物理精度、逐调用恒频或完整竞赛签收。"
)

COVER_KEYWORDS = "关键词（五个）：ML-KEM；时间侧信道；多泄漏检测平台；常数时间防护；可复现性"


def update_cover_page(document):
    """把封面日期、题目与基本信息表更新为本轮合流口径。

    只改封面字段，不动封面版式、编号、类别勾选与主办信息。
    """
    paragraphs = document.paragraphs
    for index in (14, 21):
        if index >= len(paragraphs):
            continue
        paragraph = paragraphs[index]
        if index == 14 and "作品题目" in paragraph.text:
            for run in paragraph.runs:
                if "作品题目" in run.text:
                    run.text = "作品题目：" + COVER_TITLE
        if index == 21 and "年" in paragraph.text and "月" in paragraph.text:
            for run in paragraph.runs:
                if "年" in run.text and "月" in run.text:
                    run.text = "2026 年 10 月 21 日"

    cover_table = document.tables[0]
    replacements = {
        "作品题目": "作品题目：" + COVER_TITLE,
        "作品内容摘要": "作品内容摘要：\n" + COVER_ABSTRACT,
        "关键词": COVER_KEYWORDS,
    }
    for row in cover_table.rows:
        for cell in row.cells:
            text = cell.text.strip()
            for prefix, value in replacements.items():
                if not text.startswith(prefix):
                    continue
                # 单元格首段承载标签，其余段落承载正文：逐段替换，保留版式。
                paragraphs_in_cell = cell.paragraphs
                if not paragraphs_in_cell:
                    continue
                first = paragraphs_in_cell[0]
                for run in first.runs:
                    run.text = ""
                first.runs[0].text = value if len(paragraphs_in_cell) == 1 else value.split("\n")[0]
                for extra_index, extra_paragraph in enumerate(paragraphs_in_cell[1:], start=1):
                    extra_text = value.split("\n")[extra_index] if extra_index < len(
                        value.split("\n")) else ""
                    for run in extra_paragraph.runs:
                        run.text = ""
                    if extra_paragraph.runs:
                        extra_paragraph.runs[0].text = extra_text


def remove_body_from(document, start_index):
    """删除模板正文区，保留封面与目录。"""
    children = list(document.element.body)
    for child in children[start_index:]:
        if child.tag == qn("w:sectPr"):
            continue
        document.element.body.remove(child)


def replace_static_toc_with_field(document, toc_start_index, toc_end_index):
    """把模板的静态目录改成 Word 目录域，页码由排版引擎计算。

    模板目录是「标题 + 点线 + 手工页码」的静态文本；合流后章节结构完全改变，
    静态页码必然失真。这里改为 TOC 域（TOC \\o "1-2" \\h \\z \\u），
    Word / LibreOffice 打开或导出时会按实际标题重算页码。
    """
    body = document.element.body
    children = list(body)
    toc_entries = []
    for child in children[toc_start_index:toc_end_index]:
        if child.tag != qn("w:p"):
            continue
        text = "".join(node.text or "" for node in child.iter(qn("w:t")))
        if not text.strip():
            continue
        # 静态条目形如「1 作品功能与性能说明4」：末位数字是页码，正文是标题。
        title = re.sub(r"\d+$", "", text).strip()
        if not title:
            continue
        toc_entries.append((title, child))
    if not toc_entries:
        raise SystemExit("模板静态目录未解析到条目")

    # 取第一条目的段落属性作为目录条目样式基准（点线制表位 + 行距）。
    template_paragraph = toc_entries[0][1]
    template_properties = template_paragraph.find(qn("w:pPr"))
    template_run_properties = None
    for run in template_paragraph.findall(qn("w:r")):
        template_run_properties = run.find(qn("w:rPr"))
        if template_run_properties is not None:
            break

    for _, paragraph in toc_entries:
        body.remove(paragraph)

    field_paragraph = OxmlElement("w:p")
    if template_properties is not None:
        field_paragraph.append(_copy_element(template_properties))
    run_begin = OxmlElement("w:r")
    if template_run_properties is not None:
        run_begin.append(_copy_element(template_run_properties))
    field_begin = OxmlElement("w:fldChar")
    field_begin.set(qn("w:fldCharType"), "begin")
    run_begin.append(field_begin)
    field_paragraph.append(run_begin)

    run_instruction = OxmlElement("w:r")
    if template_run_properties is not None:
        run_instruction.append(_copy_element(template_run_properties))
    instruction = OxmlElement("w:instrText")
    instruction.set(qn("xml:space"), "preserve")
    instruction.text = ' TOC \\o "1-2" \\h \\z \\u '
    run_instruction.append(instruction)
    field_paragraph.append(run_instruction)

    run_separate = OxmlElement("w:r")
    if template_run_properties is not None:
        run_separate.append(_copy_element(template_run_properties))
    field_separate = OxmlElement("w:fldChar")
    field_separate.set(qn("w:fldCharType"), "separate")
    run_separate.append(field_separate)
    field_paragraph.append(run_separate)

    run_placeholder = OxmlElement("w:r")
    if template_run_properties is not None:
        run_placeholder.append(_copy_element(template_run_properties))
    placeholder_text = OxmlElement("w:t")
    placeholder_text.text = "（目录在打开文档时自动更新）"
    run_placeholder.append(placeholder_text)
    field_paragraph.append(run_placeholder)

    run_end = OxmlElement("w:r")
    if template_run_properties is not None:
        run_end.append(_copy_element(template_run_properties))
    field_end = OxmlElement("w:fldChar")
    field_end.set(qn("w:fldCharType"), "end")
    run_end.append(field_end)
    field_paragraph.append(run_end)

    body.insert(toc_start_index, field_paragraph)


def write_static_toc(document, toc_start_index, entries, toc_end_index=None):
    """用已算好的页码写静态目录。

    entries 是 (层级, 标题, 页码) 列表，层级 1 表示章、2 表示节。
    静态目录的好处是任何阅读器打开都直接显示页码，不需要先更新域。
    """
    if toc_end_index is None:
        toc_end_index = toc_start_index
    body = document.element.body
    children = list(body)
    # 先取出模板目录条目的段落属性基准，再删除这些段落。
    old_paragraphs = []
    template_properties = None
    template_run_properties = None
    for child in children[toc_start_index:toc_end_index]:
        if child.tag != qn("w:p"):
            continue
        text = "".join(node.text or "" for node in child.iter(qn("w:t")))
        if not text.strip():
            continue
        old_paragraphs.append(child)
        if template_properties is None:
            template_properties = child.find(qn("w:pPr"))
            for run in child.findall(qn("w:r")):
                candidate = run.find(qn("w:rPr"))
                if candidate is not None:
                    template_run_properties = candidate
                    break
    if not old_paragraphs:
        raise SystemExit("模板静态目录未解析到条目")
    for paragraph in old_paragraphs:
        body.remove(paragraph)

    # 目录页上写一句**编号口径说明**：二级章节沿用平台补充报告的章节号（1–25），
    # 目录里看起来「乱序」是刻意的同源编号，不是排版事故（2026-10-21 第 4 轮复核 T1）。
    note = OxmlElement("w:p")
    if template_properties is not None:
        note_properties = _copy_element(template_properties)
        note.append(note_properties)
    note_run = OxmlElement("w:r")
    if template_run_properties is not None:
        note_run.append(_copy_element(template_run_properties))
    note_text = OxmlElement("w:t")
    note_text.set(qn("xml:space"), "preserve")
    note_text.text = ("编号口径：二级章节沿用《多泄漏模块检测平台补充报告》的章节号（1–25），"
                      "因此目录里的二级条目不按顺序排；正文的「第 N 节」同样指平台补充报告的第 N 节。")
    note_run.append(note_text)
    note.append(note_run)
    body.insert(toc_start_index, note)

    for level, title, page in entries:
        paragraph = OxmlElement("w:p")
        if template_properties is not None:
            properties = _copy_element(template_properties)
            if level == 2:
                indent = OxmlElement("w:ind")
                indent.set(qn("w:left"), "255")
                properties.append(indent)
            paragraph.append(properties)
        run = OxmlElement("w:r")
        if template_run_properties is not None:
            run.append(_copy_element(template_run_properties))
        text = OxmlElement("w:t")
        text.set(qn("xml:space"), "preserve")
        text.text = title
        run.append(text)
        paragraph.append(run)
        tab_run = OxmlElement("w:r")
        if template_run_properties is not None:
            tab_run.append(_copy_element(template_run_properties))
        tab = OxmlElement("w:tab")
        tab_run.append(tab)
        paragraph.append(tab_run)
        page_run = OxmlElement("w:r")
        if template_run_properties is not None:
            page_run.append(_copy_element(template_run_properties))
        page_text = OxmlElement("w:t")
        page_text.text = str(page)
        page_run.append(page_text)
        paragraph.append(page_run)
        body.insert(toc_start_index, paragraph)
        toc_start_index += 1


def _copy_element(element):
    from copy import deepcopy

    return deepcopy(element)


def add_heading(document, text, level):
    """标题使用模板既有 Heading 1 / Heading 2 样式，并按模板补直接格式。"""
    paragraph = document.add_paragraph(text, style="Heading %d" % level)
    properties = paragraph._p.get_or_add_pPr()
    spacing = properties.find(qn("w:spacing"))
    if spacing is None:
        spacing = OxmlElement("w:spacing")
        properties.append(spacing)
    spacing.set(qn("w:before"), "240")
    spacing.set(qn("w:after"), "240")
    spacing.set(qn("w:line"), "360")
    spacing.set(qn("w:lineRule"), "auto")
    for run in paragraph.runs:
        if level == 1:
            set_run_font(run, "STKaiti", "STKaiti", 30)
        else:
            set_run_font(run, "SimHei", "Times New Roman", 28)
    return paragraph


def sanitize_package_metadata(docx_path):
    """清理并重写 DOCX 的包级元数据（保存后直接改 zip 里的部件）。

    2026-10-21 复查发现：官方模板带来的 `docProps/core.xml` 里 `lastModifiedBy` 是一个
    **用户名**（匿名评审不该出现），`subject` 写的是旧修订稿日期，`description` 指向
    早已不存在的章节；`docProps/app.xml` 的页数/字数是模板残留；`docProps/custom.xml`
    还带着模板作者的用户标识。这里统一清空并改写，**不动正文与版式**。
    """
    import shutil
    import tempfile
    import zipfile

    replacements = {
        "docProps/core.xml": [
            ("dc:subject", "CACR2026EA16XZ 作品设计报告（2026-10-21 修订）"),
            ("dc:description", ""),
            ("cp:lastModifiedBy", ""),
            ("cp:lastPrinted", ""),
            ("cp:revision", "1"),
            ("dc:creator", ""),
        ],
        "docProps/app.xml": [
            ("Pages", ""), ("Words", ""), ("Characters", ""), ("Application", ""),
            ("Company", ""), ("Manager", ""), ("TotalTime", ""),
        ],
    }
    with tempfile.TemporaryDirectory(dir=str(REPOSITORY / "build")) as temporary_directory:
        temporary_path = Path(temporary_directory) / "sanitized.docx"
        with zipfile.ZipFile(docx_path) as source:
            items = source.infolist()
            document_xml = source.read("word/document.xml").decode("utf-8")
            relationships_xml = source.read("word/_rels/document.xml.rels").decode("utf-8")
            # 模板带来的三张**孤儿图**（image2/3/4：一张流程图与两张曲线图，内容与本作品无关）：
            # 它们的 relationship 在 rels 里有、但 document.xml 里没有任何 r:embed 引用，
            # 既污染文件又与正文矛盾——一并清掉（封面徽标等**被引用**的图要留下）。
            used_relationship_ids = set(re.findall(r'r:(?:embed|id)="([^"]+)"', document_xml))
            orphan_media = []
            for relationship in re.finditer(r"<Relationship[^>]*/>", relationships_xml):
                element = relationship.group(0)
                target = re.search(r'Target="([^"]+)"', element)
                identifier = re.search(r'Id="([^"]+)"', element)
                if target is None or identifier is None:
                    continue
                if not target.group(1).startswith("media/"):
                    continue
                if identifier.group(1) in used_relationship_ids:
                    continue
                orphan_media.append("word/" + target.group(1))
            with zipfile.ZipFile(temporary_path, "w", zipfile.ZIP_DEFLATED) as target:
                for item in items:
                    content = source.read(item.filename)
                    if item.filename in orphan_media:
                        continue
                    if item.filename == "word/document.xml":
                        # 封面徽标的 alt 文本里留着**模板方机器**的绝对路径（D:\密码学会…jpg），
                        # 与提交者无关，但出现在交件里突兀——清空 descr，保留 name。
                        import re as regular_expression
                        text_document = content.decode("utf-8")
                        text_document = regular_expression.sub(r'\sdescr="[^"]*"', "", text_document)
                        content = text_document.encode("utf-8")
                    if item.filename == "word/_rels/document.xml.rels":
                        import re as regular_expression
                        text_rels = content.decode("utf-8")
                        for name in orphan_media:
                            text_rels = regular_expression.sub(
                                r'<Relationship[^>]*Target="media/' + name.split("/")[-1].replace(".", r"\.") + r'"[^>]*/>', "", text_rels)
                        content = text_rels.encode("utf-8")
                    if item.filename == "docProps/core.xml":
                        # 模板自带的创建/修改时间是 2019-09-14（官方模板的），落在提交件里
                        # 会让人以为文件来自别处；改成卷的实际生成日期。
                        import re as regular_expression
                        text_core = content.decode("utf-8")
                        for tag in ("dcterms:created", "dcterms:modified"):
                            text_core = regular_expression.sub(
                                r"<" + tag + r"([^>]*)>[^<]*</" + tag + ">",
                                "<" + tag + r"\1>2026-10-21T00:00:00Z</" + tag + ">",
                                text_core)
                        content = text_core.encode("utf-8")
                    if item.filename == "docProps/custom.xml":
                        content = (b'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                                   b'<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"'
                                   b' xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"/>')
                    elif item.filename in replacements:
                        text = content.decode("utf-8")
                        for tag, value in replacements[item.filename]:
                            pattern = re.compile(r"<" + tag + r"(\s[^>]*)?>.*?</" + tag + r">|<" + tag + r"(\s[^>]*)?/>",
                                                re.S)
                            replacement = "<%s>%s</%s>" % (tag, value, tag)
                            text, count = pattern.subn(replacement, text, count=1)
                            if count == 0:
                                print("提示：%s 里没找到 <%s>，未改写" % (item.filename, tag))
                        content = text.encode("utf-8")
                    target.writestr(item, content)
        shutil.copyfile(temporary_path, docx_path)


def add_numbering_note(document):
    """在正文开头写一句**编号口径说明**。

    2026-10-21 的可读性复查发现：官方报告的一级章节是官方六章（0–6），
    而二级章节沿用平台补充报告的章节号（1–25，目录里表现为 1、2、3、19、20…），
    正文里的「第 N 节」也一律指平台补充报告的第 N 节。两套编号混在一起时，
    评委按「第 11 节」在本报告目录里找不到对应章节。这里直接写明口径。
    """
    paragraph = document.add_paragraph()
    properties = paragraph._p.get_or_add_pPr()
    for tag, attributes in (
        ("w:widowControl", {}),
        ("w:adjustRightInd", {"w:val": "0"}),
        ("w:snapToGrid", {"w:val": "0"}),
        ("w:spacing", {"w:line": "300", "w:lineRule": "exact"}),
        ("w:ind", {"w:left": "0", "w:firstLine": "560"}),
    ):
        element = OxmlElement(tag)
        for key, value in attributes.items():
            element.set(qn(key), value)
        properties.append(element)
    run = paragraph.add_run(
        "编号口径说明：本报告的一级章节是官方模板要求的六章（0–6）；"
        "二级章节沿用《多泄漏模块检测平台补充报告》的章节号（1–25），"
        "正文里出现的「第 N 节」「见第 N 节」一律指平台补充报告的第 N 节"
        "（两份文档的表号、图号与证据来源索引 E01–E70 也完全同源，可互相查证）。"
        "两份文档的对应关系与逐条证据见本报告末尾的「证据来源索引」。")
    set_run_font(run, "楷体_GB2312", "Times New Roman", 24)
    run_properties = run._r.get_or_add_rPr()
    run_properties.append(OxmlElement("w:b"))
    return paragraph


def build(toc_pages=None):
    if not TEMPLATE.is_file():
        raise SystemExit("缺少官方模板：" + str(TEMPLATE))
    if not SOURCE_MARKDOWN.is_file():
        raise SystemExit("缺少平台报告：" + str(SOURCE_MARKDOWN))
    markdown_text = SOURCE_MARKDOWN.read_text(encoding="utf-8")
    blocks = collect_blocks(markdown_text)

    chapters = []
    current = None
    for block in blocks:
        if block[0] == "heading" and block[1] == 2:
            current = {"title": block[2], "blocks": []}
            chapters.append(current)
        elif current is not None:
            current["blocks"].append(block)
    if not chapters:
        raise SystemExit("平台报告未解析到二级章节")

    plan_index = {prefix: (number, title) for prefix, number, title in SECTION_PLAN}
    unmatched = [chapter["title"] for chapter in chapters
                 if not any(chapter["title"].startswith(prefix) for prefix in plan_index)]
    if unmatched:
        raise SystemExit("以下平台报告章节未归位，请更新 SECTION_PLAN：" + "；".join(unmatched))

    document = Document(str(TEMPLATE))
    # 先删正文区（其下标在模板里固定），再替换静态目录，避免下标因元素增删而漂移。
    remove_body_from(document, BODY_START_INDEX)
    if toc_pages:
        # 已有实测页码：写静态目录，任何阅读器打开即见页码。
        write_static_toc(document, TOC_START_INDEX, toc_pages, TOC_END_INDEX)
    else:
        replace_static_toc_with_field(document, TOC_START_INDEX, TOC_END_INDEX)
    update_cover_page(document)

    add_numbering_note(document)

    add_heading(document, "0 前期自研探索与频率门诊断基线", 1)
    for text in PREAMBLE:
        add_body_paragraph(document, text)
    for text in BASELINE_PARAGRAPHS:
        add_body_paragraph(document, text)

    # 按主报告章节号归组（1→6 固定顺序），组内按 SECTION_PLAN 的声明顺序排列。
    grouped = {}
    for chapter in chapters:
        matched = next(prefix for prefix in plan_index if chapter["title"].startswith(prefix))
        number, title = plan_index[matched]
        grouped.setdefault((number, title), []).append(chapter)
    section_order = []
    for _prefix, number, title in SECTION_PLAN:
        key = (number, title)
        if key in grouped and key not in section_order:
            section_order.append(key)
    if len(section_order) != 6:
        raise SystemExit("主报告章节不是 6 节：" + repr(section_order))
    for number, title in section_order:
        add_heading(document, number + " " + title, 1)
        for chapter in grouped[(number, title)]:
            add_heading(document, chapter["title"], 2)
            first_paragraph_pending = True
            for block in chapter["blocks"]:
                kind = block[0]
                if kind == "paragraph":
                    text = strip_inline_markup(block[1])
                    if not text:
                        continue
                    add_body_paragraph(document, text, first=first_paragraph_pending)
                    first_paragraph_pending = False
                elif kind == "table_title":
                    add_caption_paragraph(document, block[1])
                elif kind == "table":
                    append_table(document, block[1])
                elif kind == "code":
                    add_code_paragraph(document, block[1])
                elif kind == "figure":
                    add_figure(document, block[1], block[2])
                elif kind == "caption":
                    add_caption_paragraph(document, block[1])

    document.save(OUTPUT_DOCX)
    sanitize_package_metadata(OUTPUT_DOCX)
    print("wrote", OUTPUT_DOCX)


def heading_outline():
    """返回本脚本将要写入的标题序列 [(层级, 标题)]，供两遍构建比对页码。"""
    markdown_text = SOURCE_MARKDOWN.read_text(encoding="utf-8")
    blocks = collect_blocks(markdown_text)
    chapters = []
    current = None
    for block in blocks:
        if block[0] == "heading" and block[1] == 2:
            current = {"title": block[2], "blocks": []}
            chapters.append(current)
        elif current is not None:
            current["blocks"].append(block)
    plan_index = {prefix: (number, title) for prefix, number, title in SECTION_PLAN}
    grouped = {}
    for chapter in chapters:
        matched = next(prefix for prefix in plan_index if chapter["title"].startswith(prefix))
        number, title = plan_index[matched]
        grouped.setdefault((number, title), []).append(chapter)
    outline = [(1, "0 前期自研探索与频率门诊断基线")]
    emitted = set()
    for _prefix, number, title in SECTION_PLAN:
        key = (number, title)
        if key not in grouped or key in emitted:
            continue
        emitted.add(key)
        outline.append((1, number + " " + title))
        for chapter in grouped[key]:
            outline.append((2, chapter["title"]))
    return outline


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser(description="生成官方作品设计报告 DOCX")
    parser.add_argument(
        "--toc-pages",
        help="目录页码 JSON 文件；给出时写静态目录，不给时写 TOC 域（两遍构建用）",
    )
    parser.add_argument(
        "--print-outline",
        action="store_true",
        help="只打印标题序列（JSON），不生成文档",
    )
    arguments = parser.parse_args()
    if arguments.print_outline:
        print(json.dumps(heading_outline(), ensure_ascii=False))
        sys.exit(0)
    toc_pages = None
    if arguments.toc_pages:
        toc_pages = json.loads(Path(arguments.toc_pages).read_text(encoding="utf-8"))
        toc_pages = [(int(level), str(title), int(page)) for level, title, page in toc_pages]
    sys.exit(build(toc_pages))
