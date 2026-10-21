#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 docs/R05-全流程排查表.md §5 的 mermaid 流程图渲染成等价的静态图（SVG + PNG）。

XeLaTeX 不能直接渲染 mermaid：报告 PDF 用这里产出的 PNG，离线 HTML 另外原样保留
mermaid 源码文本并用同一份 SVG 内联展示。两种渲染共用同一套布局函数，因此几何与
换行位置一致；节点文字逐字取自该表 §5 的三条主链（含 <br/> 处的换行）。

本模块只画图，不解释结果，也不改变该表的任何字节。
"""
from pathlib import Path

CANVAS_WIDTH = 2200
MARGIN = 40
COLUMN_GAP = 30
FIX_STRIP = 44
NODE_FONT = 36
ADDR_FONT = 29
ID_FONT = 24
TITLE_FONT = 46
SUBTITLE_FONT = 29
LEGEND_FONT = 30
LINE_FACTOR = 1.34
NODE_PAD = 15
CHAIN_GAP = 26
HEADER_FONT = 33
HEADER_PAD = 18

FONT_REGULAR_PATH = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_BOLD_PATH = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_REGULAR_INDEX = 0
FONT_BOLD_INDEX = 2

CLASS_STYLE = {
    "pub": {"fill": "#e8f4ff", "stroke": "#2b6cb0", "width": 2, "dash": None},
    "leak": {"fill": "#ffe0e0", "stroke": "#c53030", "width": 4, "dash": None},
    "fix": {"fill": "#e6ffed", "stroke": "#2f855a", "width": 4, "dash": None},
    "art": {"fill": "#fff8e1", "stroke": "#b7791f", "width": 3, "dash": "10,7"},
}
INK = "#193248"
MUTED = "#536475"
FIX_EDGE_COLOR = "#2f855a"

FLOW = {
    "title": "ML-KEM 解封装全流程：泄漏点与修复点（R05 排查表 §5 流程图的等价静态渲染）",
    "subtitle": "三实现泳道；红色=本轮判定「存在」，绿色=修复后的同一位置，黄色虚框=人工构造校准或未检查项，蓝色=无该类来源。",
    "input_lines": ["输入: 密文 ct 1088B, 解封装私钥 sk"],
    "output_lines": ["共享秘密 ss 32B 返回", "三实现正常路径返回码均为 0"],
    "columns": [
        {
            "id": "M1",
            "title": "M1 liboqs 0.10.0 historical-clangover（未修 / 982c762）",
            "nodes": [
                {"id": "M1A", "class": "pub", "text": "解密: indcpa_dec → poly_tomsg", "addr": "kem.c:151 / indcpa.c:313-331"},
                {"id": "M1B", "class": "pub", "text": "哈希 G/H/J: hash_g sha3-512, hash_h sha3-256, rkprf shake256", "addr": "kem.c:155,163"},
                {"id": "M1C1", "class": "pub", "text": "重加密: indcpa_enc", "addr": "kem.c:158"},
                {"id": "M1C2", "class": "leak", "text": "poly_frommsg: bt / jae", "addr": "16e bt %ecx,%r8d → 172 jae 179", "fix_to": "M1C3"},
                {"id": "M1C3", "class": "fix", "text": "poly_frommsg（982c762）: setb + cmov_int16", "addr": "189 bt → 18d setb → 198 call cmov_int16"},
                {"id": "M1D", "class": "pub", "text": "密文比较: verify", "addr": "verify.c:16-25, len=1088 定长"},
                {"id": "M1E1", "class": "pub", "text": "隐式拒绝: rkprf(ss, z, ct)", "addr": "kem.c:163"},
                # 2026-10-16 补测后改回 :::pub（产物上未观测到分支，屏障缺失只作可移植性
                # 隐患登记）——此前这里仍画成「leak」，图与 R05 §5 的 mermaid 源**说反了**。
                {"id": "M1E2", "class": "pub", "text": "cmov: 无 __asm__ 值屏障（可移植性隐患）", "addr": "产物上掩码走 sete + neg/and/xor，未编成分支（2026-10-16 补测）", "fix_to": "M1E3"},
                {"id": "M1E3", "class": "pub", "text": "cmov(ss, kr, 32, !fail) → return 0", "addr": "kem.c:166-168"},
            ],
        },
        {
            "id": "M2",
            "title": "M2 pq-crystals kyber768 a621b8d（未修 / 272125f）",
            "nodes": [
                {"id": "M2A1", "class": "pub", "text": "解密: indcpa_dec → poly_tomsg", "addr": "kem.c:106 / indcpa.c:328"},
                {"id": "M2A2", "class": "leak", "text": "poly_tomsg: 秘密被除数 ÷ 3329", "addr": "36a5 movswl → 36bf div %r9d (r9d=0xd01)", "fix_to": "M2A3"},
                {"id": "M2A3", "class": "fix", "text": "poly_tomsg（272125f）: imul 0x275f6 + add + shr 0x1c", "addr": "div 计数 0"},
                {"id": "M2B", "class": "pub", "text": "哈希 G/H/J: sha3-512, sha3-256, shake256", "addr": "kem.c:111,119,125"},
                {"id": "M2C1", "class": "pub", "text": "重加密: indcpa_enc", "addr": "kem.c:114"},
                {"id": "M2C2", "class": "leak", "text": "poly_compress / polyvec_compress: 秘密被除数 ÷ 3329", "addr": "3523 div %r8d / 38c7 div %r8d", "fix_to": "M2C3"},
                {"id": "M2C3", "class": "fix", "text": "272125f: 乘加移位替代除法", "addr": "division-counts 三热点 0"},
                # 2026-10-16 补测后由反汇编判定为「存在」，R05 §5 改用 :::leak；
                # 「:::art」（未检查）这一类在 2026-10-16 起已不再使用——此前这里仍画成
                # 「未检查」，图与源**说反了**。
                {"id": "M2C4", "class": "leak", "text": "poly_frommsg: bt / jae 数据相关分支", "addr": "未修 3668 bt → 366c jae / 已修 366e bt → 3672 jae；两侧指令字节相同，272125f 未修此处（2026-10-16 补测）"},
                {"id": "M2D", "class": "pub", "text": "密文比较: verify", "addr": "2ee0 mov 0x440,edx → 2eeb call verify"},
                {"id": "M2E1", "class": "pub", "text": "隐式拒绝: hash_h(kr+32, ct, 1088)", "addr": "kem.c:119"},
                {"id": "M2E2", "class": "pub", "text": "cmov(kr, z, 32, fail) 带值屏障", "addr": "verify.c:44-52 → kdf shake256"},
            ],
        },
        {
            "id": "M5",
            "title": "M5 mlkem-native b3ba7b3 参考路径",
            "nodes": [
                {"id": "M5S", "class": "leak", "text": "mlk_kem_check_sk: sk 公开部分哈希检查失败", "addr": "a40c test eax,eax → a40e jne ad87"},
                {"id": "M5A", "class": "pub", "text": "解密: mlk_indcpa_dec → mlk_poly_tomsg", "addr": "kem.c:429 / indcpa.c:598"},
                {"id": "M5B", "class": "pub", "text": "哈希 G/H/J: mlk_hash_g, mlk_hash_h, mlk_hash_j", "addr": "kem.c:436,452,457"},
                {"id": "M5C", "class": "pub", "text": "重加密: mlk_indcpa_enc → mlk_poly_frommsg", "addr": "kem.c:441 / compress.c:697, 无数据相关分支；唯一跳转 26e2 jne 由 cmp 0x20,rax 判定"},
                {"id": "M5D", "class": "pub", "text": "密文比较: mlk_ct_memcmp 内联", "addr": "ct 1088B 定长, neg/shr/xor 无分支出 0/1"},
                {"id": "M5E", "class": "pub", "text": "隐式拒绝: mlk_hash_j(z‖ct) + mlk_ct_cmov_zero", "addr": "kem.c:455-459, 掩码选择无分支"},
            ],
        },
    ],
    "legend": [
        ("pub", "无该类来源的步骤（mermaid :::pub）"),
        ("leak", "本轮判定「存在」的泄漏点（:::leak）"),
        ("fix", "修复后的同一位置（:::fix）"),
        ("art", "人工构造校准 / 未检查项（:::art，虚线框）"),
        ("edge", "虚线箭头＝官方修复映射（提交号见绿色节点文本）"),
    ],
    "footer": ["虚线箭头＝修复映射（mermaid 边标签原样）：982c762 修复（M1C2→M1C3）；982c762 verify.c 值屏障（M1E2→M1E3）；dda29cc → 272125f 修复（M2A2→M2A3）；272125f 修复（M2C2→M2C3）。",
               "本图是 docs/R05-全流程排查表.md §5 mermaid 流程图的等价静态渲染；mermaid 源码原样保留在该文件与报告离线 HTML 中。"],
}


def _font(size, bold=False):
    from PIL import ImageFont

    path = FONT_BOLD_PATH if bold else FONT_REGULAR_PATH
    index = FONT_BOLD_INDEX if bold else FONT_REGULAR_INDEX
    return ImageFont.truetype(path, size, index=index)


_FONT_CACHE = {}


def measure(text, size, bold=False):
    key = (size, bold)
    if key not in _FONT_CACHE:
        try:
            _FONT_CACHE[key] = _font(size, bold)
        except OSError:
            _FONT_CACHE[key] = None
    font = _FONT_CACHE[key]
    if font is not None:
        return float(font.getlength(text))
    return sum(size if ord(character) > 0x2E7F else size * 0.55 for character in text)


def wrap(text, capacity, size, bold=False):
    """按像素宽度贪心换行；CJK 逐字断行，西文按空格与标点断词。"""
    tokens = []
    for chunk in text.split(" "):
        if tokens:
            tokens.append(" ")
        if chunk:
            tokens.append(chunk)
    lines = []
    current = ""
    for token in tokens:
        candidate = current + token
        if current and measure(candidate.rstrip(), size, bold) > capacity:
            lines.append(current.rstrip())
            current = "" if token == " " else token
            continue
        current = candidate
        while measure(current, size, bold) > capacity and len(current) > 1:
            cut = len(current) - 1
            while cut > 1 and measure(current[:cut], size, bold) > capacity:
                cut -= 1
            lines.append(current[:cut])
            current = current[cut:]
    if current.strip():
        lines.append(current.rstrip())
    return lines or [""]


def layout(flow=None, width=CANVAS_WIDTH):
    flow = flow or FLOW
    column_count = len(flow["columns"])
    column_width = (width - 2 * MARGIN - (column_count - 1) * COLUMN_GAP) // column_count
    box_width = column_width - FIX_STRIP
    text_capacity = box_width - 2 * NODE_PAD
    columns = []
    header_lines = []
    for column in flow["columns"]:
        header_lines.append(wrap(column["title"], column_width - 24, HEADER_FONT, True))
    header_height = 2 * HEADER_PAD + max(len(lines) for lines in header_lines) * HEADER_FONT * 1.3
    header_height = round(header_height)
    for index, column in enumerate(flow["columns"]):
        x = MARGIN + index * (column_width + COLUMN_GAP)
        nodes = []
        y = 0
        for node in column["nodes"]:
            body_lines = wrap(node["text"], text_capacity, NODE_FONT)
            address_lines = wrap(node["addr"], text_capacity, ADDR_FONT)
            height = NODE_PAD * 2 + len(body_lines) * NODE_FONT * LINE_FACTOR + len(address_lines) * ADDR_FONT * LINE_FACTOR
            nodes.append({"id": node["id"], "class": node["class"], "fix_to": node.get("fix_to"), "x": x, "y": y, "width": box_width, "height": round(height), "body": body_lines, "address": address_lines})
            y += round(height) + CHAIN_GAP
        columns.append({"id": column["id"], "title": column["title"], "title_lines": header_lines[index], "x": x, "width": column_width, "nodes": nodes, "chain_height": y - CHAIN_GAP})
    flow_top = 174
    input_height = NODE_PAD * 2 + len(flow["input_lines"]) * NODE_FONT * LINE_FACTOR
    input_box = {"x": width / 2 - 320, "y": flow_top, "width": 640, "height": round(input_height), "lines": flow["input_lines"]}
    columns_top = input_box["y"] + input_box["height"] + 74
    tallest = max(column["chain_height"] for column in columns)
    bus_top = columns_top + header_height + tallest + 48
    output_top = bus_top + 46
    output_height = NODE_PAD * 2 + len(flow["output_lines"]) * NODE_FONT * LINE_FACTOR
    output_box = {"x": width / 2 - 340, "y": output_top, "width": 680, "height": round(output_height), "lines": flow["output_lines"]}
    legend_top = output_box["y"] + output_box["height"] + 58
    legend_height = 44 + len(flow["legend"]) * 46
    footer_lines = []
    for footer_line in flow["footer"]:
        footer_lines.extend(wrap(footer_line, width - 2 * MARGIN, SUBTITLE_FONT))
    height = legend_top + legend_height + 40 + len(footer_lines) * SUBTITLE_FONT * LINE_FACTOR + 40
    return {"width": width, "height": round(height), "columns": columns, "input": input_box, "output": output_box, "columns_top": columns_top, "header_height": header_height, "bus_top": bus_top, "legend_top": legend_top, "legend_height": legend_height, "footer_lines": footer_lines, "flow": flow}


def _tspans(lines, x, y, size, color, bold=False):
    step = size * LINE_FACTOR
    weight = ' font-weight="600"' if bold else ""
    return ["<text x=\"" + str(round(x)) + "\" y=\"" + str(round(y + index * step)) + "\" font-size=\"" + str(size) + "\" fill=\"" + color + "\"" + weight + ">" + _escape(line) + "</text>" for index, line in enumerate(lines)]


def _escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def render_svg(plan=None):
    plan = plan or layout()
    flow = plan["flow"]
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="' + str(plan["width"]) + '" height="' + str(plan["height"]) + '" viewBox="0 0 ' + str(plan["width"]) + " " + str(plan["height"]) + '"><rect width="100%" height="100%" fill="white"/><g font-family="Hiragino Sans GB, PingFang SC, Arial, sans-serif" fill="' + INK + '">']
    parts.append('<defs><marker id="r05-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="' + INK + '"/></marker><marker id="r05-fixarrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="' + FIX_EDGE_COLOR + '"/></marker></defs>')
    parts.extend(_tspans([flow["title"]], MARGIN, 58, TITLE_FONT, INK, True))
    parts.extend(_tspans([flow["subtitle"]], MARGIN, 90, SUBTITLE_FONT, MUTED))
    parts.append(_svg_box(plan["input"], "#eef2f5", "#6b7280", 2, None, plan["input"]["lines"], NODE_FONT))
    arrow_start_y = plan["input"]["y"] + plan["input"]["height"]
    for column in plan["columns"]:
        center = column["x"] + column["width"] / 2
        parts.append('<path d="M ' + str(round(plan["input"]["x"] + plan["input"]["width"] / 2)) + " " + str(round(arrow_start_y)) + " L " + str(round(plan["input"]["x"] + plan["input"]["width"] / 2)) + " " + str(round(arrow_start_y + 22)) + " L " + str(round(center)) + " " + str(round(arrow_start_y + 22)) + " L " + str(round(center)) + " " + str(round(plan["columns_top"] - 6)) + '" fill="none" stroke="' + INK + '" stroke-width="2" marker-end="url(#r05-arrow)"/>')
    for column in plan["columns"]:
        header_y = plan["columns_top"]
        parts.append('<rect x="' + str(round(column["x"])) + '" y="' + str(round(header_y)) + '" width="' + str(round(column["width"])) + '" height="' + str(plan["header_height"]) + '" rx="6" fill="#dfe7ec"/>')
        parts.extend(_tspans(column["title_lines"], column["x"] + 12, header_y + HEADER_PAD + HEADER_FONT, HEADER_FONT, INK, True))
        nodes = column["nodes"]
        for index, node in enumerate(nodes):
            style = CLASS_STYLE[node["class"]]
            absolute_y = header_y + plan["header_height"] + node["y"]
            parts.append(_svg_box({"x": node["x"], "y": absolute_y, "width": node["width"], "height": node["height"]}, style["fill"], style["stroke"], style["width"], style["dash"], node["body"], NODE_FONT, node["address"], node["id"]))
            if index + 1 < len(nodes):
                next_node = nodes[index + 1]
                next_y = header_y + plan["header_height"] + next_node["y"]
                center = node["x"] + node["width"] / 2
                parts.append('<line x1="' + str(round(center)) + '" y1="' + str(round(absolute_y + node["height"])) + '" x2="' + str(round(center)) + '" y2="' + str(round(next_y - 6)) + '" stroke="' + INK + '" stroke-width="2" marker-end="url(#r05-arrow)"/>')
        for node in nodes:
            if not node["fix_to"]:
                continue
            target = next(item for item in nodes if item["id"] == node["fix_to"])
            source_y = header_y + plan["header_height"] + node["y"] + node["height"] / 2
            target_y = header_y + plan["header_height"] + target["y"] + target["height"] / 2
            corridor = node["x"] + node["width"] + FIX_STRIP / 2
            parts.append('<path d="M ' + str(round(node["x"] + node["width"])) + " " + str(round(source_y)) + " L " + str(round(corridor)) + " " + str(round(source_y)) + " L " + str(round(corridor)) + " " + str(round(target_y)) + " L " + str(round(target["x"] + target["width"] + 8)) + " " + str(round(target_y)) + '" fill="none" stroke="' + FIX_EDGE_COLOR + '" stroke-width="3" stroke-dasharray="10,7" marker-end="url(#r05-fixarrow)"/>')
        bottom_y = header_y + plan["header_height"] + column["chain_height"]
        center = column["x"] + column["width"] / 2
        output_center = plan["output"]["x"] + plan["output"]["width"] / 2
        parts.append('<path d="M ' + str(round(center)) + " " + str(round(bottom_y)) + " L " + str(round(center)) + " " + str(round(plan["bus_top"])) + " L " + str(round(output_center)) + " " + str(round(plan["bus_top"])) + " L " + str(round(output_center)) + " " + str(round(plan["output"]["y"] - 6)) + '" fill="none" stroke="' + INK + '" stroke-width="2" marker-end="url(#r05-arrow)"/>')
    parts.append(_svg_box(plan["output"], "#eef2f5", "#6b7280", 2, None, plan["output"]["lines"], NODE_FONT))
    legend_y = plan["legend_top"]
    parts.extend(_tspans(["图例"], MARGIN, legend_y, LEGEND_FONT + 4, INK, True))
    for index, (kind, label) in enumerate(flow["legend"]):
        y = legend_y + 22 + index * 46
        if kind == "edge":
            parts.append('<line x1="' + str(MARGIN) + '" y1="' + str(round(y - 10)) + '" x2="' + str(MARGIN + 96) + '" y2="' + str(round(y - 10)) + '" stroke="' + FIX_EDGE_COLOR + '" stroke-width="3" stroke-dasharray="10,7" marker-end="url(#r05-fixarrow)"/>')
        else:
            style = CLASS_STYLE[kind]
            dash = ' stroke-dasharray="' + style["dash"] + '"' if style["dash"] else ""
            parts.append('<rect x="' + str(MARGIN) + '" y="' + str(round(y - 30)) + '" width="96" height="30" rx="5" fill="' + style["fill"] + '" stroke="' + style["stroke"] + '" stroke-width="' + str(style["width"]) + '"' + dash + "/>")
        parts.extend(_tspans([label], MARGIN + 116, y - 8, LEGEND_FONT, INK))
    parts.extend(_tspans(plan["footer_lines"], MARGIN, legend_y + plan["legend_height"] + 20, SUBTITLE_FONT, MUTED))
    parts.append("</g></svg>")
    return "".join(parts)


def _svg_box(box, fill, stroke, width, dash, lines, font, address_lines=None, node_id=None):
    dash = ' stroke-dasharray="' + dash + '"' if dash else ""
    parts = ['<rect x="' + str(round(box["x"])) + '" y="' + str(round(box["y"])) + '" width="' + str(round(box["width"])) + '" height="' + str(round(box["height"])) + '" rx="6" fill="' + fill + '" stroke="' + stroke + '" stroke-width="' + str(width) + '"' + dash + "/>"]
    text_y = box["y"] + NODE_PAD + font
    parts.extend(_tspans(lines, box["x"] + NODE_PAD, text_y, font, INK))
    if address_lines:
        address_y = text_y + len(lines) * font * LINE_FACTOR + 4
        parts.extend(_tspans(address_lines, box["x"] + NODE_PAD, address_y, ADDR_FONT, MUTED))
    if node_id:
        parts.extend(_tspans([node_id], box["x"] + box["width"] - 12 - measure(node_id, ID_FONT), box["y"] + 27, ID_FONT, MUTED))
    return "".join(parts)


def render_png(path, plan=None):
    from PIL import Image, ImageDraw

    plan = plan or layout()
    flow = plan["flow"]
    image = Image.new("RGB", (plan["width"], plan["height"]), "white")
    draw = ImageDraw.Draw(image)
    fonts = {}

    def font(size, bold=False):
        key = (size, bold)
        if key not in fonts:
            fonts[key] = _font(size, bold)
        return fonts[key]

    def text_at(lines, x, y, size, color, bold=False):
        for index, line in enumerate(lines):
            draw.text((x, y + index * size * LINE_FACTOR - size * 0.82), line, font=font(size, bold), fill=color)

    def box(box_plan, fill, stroke, width, dash, lines, size, address_lines=None, node_id=None):
        draw.rounded_rectangle([box_plan["x"], box_plan["y"], box_plan["x"] + box_plan["width"], box_plan["y"] + box_plan["height"]], radius=8, fill=fill, outline=stroke, width=width)
        if dash:
            _dash_rect(draw, box_plan, stroke, width, dash)
        text_at(lines, box_plan["x"] + NODE_PAD, box_plan["y"] + NODE_PAD + size, size, INK)
        if address_lines:
            address_y = box_plan["y"] + NODE_PAD + size + len(lines) * size * LINE_FACTOR + 4
            text_at(address_lines, box_plan["x"] + NODE_PAD, address_y, ADDR_FONT, MUTED)
        if node_id:
            text_at([node_id], box_plan["x"] + box_plan["width"] - 12 - measure(node_id, ID_FONT), box_plan["y"] + 27, ID_FONT, MUTED)

    def arrow(x1, y1, x2, y2, color, dash=None, head=16):
        if dash:
            _dash_line(draw, x1, y1, x2, y2, color, 3, dash)
        else:
            draw.line([x1, y1, x2, y2], fill=color, width=2)
        if y1 == y2:
            direction = 1 if x2 > x1 else -1
            draw.polygon([(x2, y2), (x2 - direction * head, y2 - head * 0.55), (x2 - direction * head, y2 + head * 0.55)], fill=color)
        else:
            direction = 1 if y2 > y1 else -1
            draw.polygon([(x2, y2), (x2 - head * 0.55, y2 - direction * head), (x2 + head * 0.55, y2 - direction * head)], fill=color)

    text_at([flow["title"]], MARGIN, 58, TITLE_FONT, INK, True)
    text_at([flow["subtitle"]], MARGIN, 90, SUBTITLE_FONT, MUTED)
    box(plan["input"], "#eef2f5", "#6b7280", 2, None, plan["input"]["lines"], NODE_FONT)
    arrow_start_y = plan["input"]["y"] + plan["input"]["height"]
    input_center = plan["input"]["x"] + plan["input"]["width"] / 2
    for column in plan["columns"]:
        center = column["x"] + column["width"] / 2
        draw.line([input_center, arrow_start_y, input_center, arrow_start_y + 22], fill=INK, width=2)
        draw.line([input_center, arrow_start_y + 22, center, arrow_start_y + 22], fill=INK, width=2)
        arrow(center, arrow_start_y + 22, center, plan["columns_top"] - 4, INK)
    for column in plan["columns"]:
        header_y = plan["columns_top"]
        draw.rounded_rectangle([column["x"], header_y, column["x"] + column["width"], header_y + plan["header_height"]], radius=8, fill="#dfe7ec")
        text_at(column["title_lines"], column["x"] + 12, header_y + HEADER_PAD + HEADER_FONT, HEADER_FONT, INK, True)
        nodes = column["nodes"]
        for index, node in enumerate(nodes):
            style = CLASS_STYLE[node["class"]]
            absolute_y = header_y + plan["header_height"] + node["y"]
            box({"x": node["x"], "y": absolute_y, "width": node["width"], "height": node["height"]}, style["fill"], style["stroke"], style["width"], style["dash"], node["body"], NODE_FONT, node["address"], node["id"])
            if index + 1 < len(nodes):
                next_node = nodes[index + 1]
                next_y = header_y + plan["header_height"] + next_node["y"]
                center = node["x"] + node["width"] / 2
                arrow(center, absolute_y + node["height"], center, next_y - 4, INK)
        for node in nodes:
            if not node["fix_to"]:
                continue
            target = next(item for item in nodes if item["id"] == node["fix_to"])
            source_y = header_y + plan["header_height"] + node["y"] + node["height"] / 2
            target_y = header_y + plan["header_height"] + target["y"] + target["height"] / 2
            corridor = node["x"] + node["width"] + FIX_STRIP / 2
            arrow(node["x"] + node["width"], source_y, corridor, source_y, FIX_EDGE_COLOR)
            arrow(corridor, source_y, corridor, target_y, FIX_EDGE_COLOR, dash=(10, 7))
            arrow(corridor, target_y, target["x"] + target["width"] + 6, target_y, FIX_EDGE_COLOR, dash=(10, 7))
        bottom_y = header_y + plan["header_height"] + column["chain_height"]
        center = column["x"] + column["width"] / 2
        output_center = plan["output"]["x"] + plan["output"]["width"] / 2
        draw.line([center, bottom_y, center, plan["bus_top"]], fill=INK, width=2)
        draw.line([center, plan["bus_top"], output_center, plan["bus_top"]], fill=INK, width=2)
        arrow(output_center, plan["bus_top"], output_center, plan["output"]["y"] - 4, INK)
    box(plan["output"], "#eef2f5", "#6b7280", 2, None, plan["output"]["lines"], NODE_FONT)
    legend_y = plan["legend_top"]
    text_at(["图例"], MARGIN, legend_y, LEGEND_FONT + 4, INK, True)
    for index, (kind, label) in enumerate(flow["legend"]):
        y = legend_y + 22 + index * 46
        if kind == "edge":
            arrow(MARGIN, y - 10, MARGIN + 96, y - 10, FIX_EDGE_COLOR, dash=(10, 7))
        else:
            style = CLASS_STYLE[kind]
            box({"x": MARGIN, "y": y - 30, "width": 96, "height": 30}, style["fill"], style["stroke"], style["width"], style["dash"], [], 0)
        text_at([label], MARGIN + 116, y - 8, LEGEND_FONT, INK)
    text_at(plan["footer_lines"], MARGIN, legend_y + plan["legend_height"] + 20, SUBTITLE_FONT, MUTED)
    image.save(path)
    return plan


def _dash_line(draw, x1, y1, x2, y2, color, width, dash):
    import math
    import re

    parts = [float(item) for item in re.split(r"[,\s]+", dash)] if isinstance(dash, str) else [float(item) for item in dash]
    parts = [item for item in parts if item == item]
    on = parts[0]
    off = parts[1] if len(parts) > 1 else parts[0]
    total = math.hypot(x2 - x1, y2 - y1)
    if total == 0:
        return
    step_x = (x2 - x1) / total
    step_y = (y2 - y1) / total
    position = 0.0
    while position < total:
        end = min(position + on, total)
        draw.line([x1 + step_x * position, y1 + step_y * position, x1 + step_x * end, y1 + step_y * end], fill=color, width=width)
        position = end + off


def _dash_rect(draw, box_plan, stroke, width, dash):
    left, top = box_plan["x"], box_plan["y"]
    right, bottom = left + box_plan["width"], top + box_plan["height"]
    for x1, y1, x2, y2 in [(left, top, right, top), (right, top, right, bottom), (right, bottom, left, bottom), (left, bottom, left, top)]:
        draw.line([x1, y1, x2, y2], fill="white", width=width)
        _dash_line(draw, x1, y1, x2, y2, stroke, width, dash)


def main():
    directory = Path(__file__).resolve().parent
    plan = layout()
    (directory / "r05-flowchart.svg").write_text(render_svg(plan), encoding="utf-8")
    render_png(directory / "r05-flowchart.png", plan)
    print(str(directory / "r05-flowchart.svg") + " " + str(plan["width"]) + "x" + str(plan["height"]))


if __name__ == "__main__":
    main()
