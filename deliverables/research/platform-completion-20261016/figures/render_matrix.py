"""从 EVIDENCE_MATRIX.csv 重建平台矩阵 SVG 结果图（原生矢量，无 foreignObject）。

图是按行分组的 5 列结果矩阵：真实历史案例 / 人工构造校准 / 阴性对照候选。
状态词直接写在格内，颜色只是辅助；未运行格显式写“未运行”，不写成阴性。
"""
import csv
from html import escape
from pathlib import Path

figure_directory = Path(__file__).resolve().parent
csv_path = figure_directory.parent / "EVIDENCE_MATRIX.csv"
with csv_path.open() as source:
    evidence_rows = list(csv.DictReader(source))

assert [row["module"] for row in evidence_rows] == ["M1", "M2", "M3", "M4", "M5"], "module order changed"
assert all(row["audit_commit"] == "ac46e62" for row in evidence_rows), "audit identity changed"
assert len({row["category"] for row in evidence_rows}) == 3, "expected three case categories"

category_bands = [
    ("historical_real", "真实历史案例（固定上游提交，非本轮新造漏洞）"),
    ("artificial_calibration", "人工构造校准（明确标注，不计为新的真实 CVE）"),
    ("negative_control", "阴性对照候选（固定参考实现；有限输入内观察）"),
]
category_order = [key for key, _ in category_bands]

module_labels = {
    "M1": ["M1 编译器消息位分支"],
    "M2": ["M2 秘密操作数除法", "KyberSlash 历史路径"],
    "M3": ["M3 秘密下标访存", "人工 LUT 挂载"],
    "M4": ["M4 提前退出比较", "人工 checked compare"],
    "M5": ["M5 mlkem-native", "固定参考实现"],
}
columns = [
    ("模块 / 机制", "module", 250),
    ("软件资格与产物", "software_state", 300),
    ("定位（工具与结论）", "localization_state", 340),
    ("时间统计与复测", "statistics_state", 260),
    ("形式化 / 边界", "formal_state", 250),
]

width_pixels = 22 * 2 + sum(width for _, _, width in columns) + 12 * (len(columns) - 1)
left_pixels = 22
top_pixels = 178
band_height_pixels = 40
row_gap_pixels = 10
band_gap_pixels = 8
line_height_pixels = 21
row_padding_pixels = 14
svg_fragments = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{width_pixels}" height="{{height}}" '
    f'viewBox="0 0 {width_pixels} {{height}}">',
    '<rect width="100%" height="100%" fill="#ffffff"/>',
    '<g font-family="Arial, PingFang SC, sans-serif" fill="#17212b">',
    '<text x="22" y="38" font-size="25" font-weight="600">多泄漏模块平台：结果矩阵（真实案例 / 人工校准 / 阴性对照 / 各层状态）</text>',
    '<text x="22" y="68" font-size="16">结果图，不是计划图；审计时点 2026-10-16 · 数据源 EVIDENCE_MATRIX.csv · 证据路径见图注 CAPTION.md</text>',
    '<text x="22" y="94" font-size="16">“未运行”与“已执行且未检出”分列；«待主控数据» 表示锁频采数尚未回填，不是阴性结果。</text>',
]


def display_units(text):
    return sum(2 if ord(character) > 0x2E7F else 1 for character in text)


def tokenize(text):
    """切成 ASCII 词（含数字/路径）与单个中日韩字符，避免在词或数字中间断行。"""
    tokens = []
    current = ""
    for character in text:
        if ord(character) > 0x2E7F:
            if current:
                tokens.append(current)
                current = ""
            tokens.append(character)
        elif character == " ":
            if current:
                tokens.append(current)
                current = ""
            tokens.append(" ")
        else:
            current += character
    if current:
        tokens.append(current)
    return tokens


def wrap_text(text, capacity_units):
    lines = []
    current = ""
    for token in tokenize(text):
        if display_units(current) + display_units(token) <= capacity_units or not current.strip():
            if display_units(current) + display_units(token) > capacity_units and not current.strip():
                for character in token:
                    if display_units(current) + display_units(character) > capacity_units and current:
                        lines.append(current)
                        current = character
                    else:
                        current += character
                continue
            current += token
            continue
        lines.append(current.rstrip())
        current = "" if token == " " else token
    lines.append(current.rstrip())
    return [line for line in lines if line] or [""]


def cell_lines(values, capacity_units):
    lines = []
    for value in values:
        lines.extend(wrap_text(value, capacity_units))
    return lines


def x_offset(column_index):
    return left_pixels + sum(width for _, _, width in columns[:column_index]) + 12 * column_index


def add_cell(column_index, top, height, lines, fill, stroke, text_color, is_bold=False):
    width = columns[column_index][2]
    left = x_offset(column_index)
    center = left + width / 2
    svg_fragments.append(
        f'<rect x="{left}" y="{top}" width="{width}" height="{height}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="1.2"/>'
    )
    first_baseline = top + height / 2 - (len(lines) - 1) * line_height_pixels / 2 + 6
    weight = "600" if is_bold else "400"
    for line_index, label in enumerate(lines):
        svg_fragments.append(
            f'<text x="{center}" y="{first_baseline + line_index * line_height_pixels}" '
            f'text-anchor="middle" fill="{text_color}" font-size="16" '
            f'font-weight="{weight}">{escape(label)}</text>'
        )


def cell_style(value):
    if value.startswith("未运行"):
        return "#fff3dd", "#c9a365", "#5b4219"
    if "封存" in value:
        return "#edf1f4", "#9eacb7", "#243746"
    if "不适用" in value or "未主张" in value:
        return "#ffffff", "#d4dce2", "#17212b"
    return "#e8f1f7", "#779bb2", "#17384d"


# 表头
header_left = left_pixels
for column_index, (label, _, width) in enumerate(columns):
    svg_fragments.append(
        f'<rect x="{x_offset(column_index)}" y="112" width="{width}" height="46" fill="#243746"/>'
    )
    svg_fragments.append(
        f'<text x="{x_offset(column_index) + width / 2}" y="140" text-anchor="middle" '
        f'fill="#ffffff" font-size="17" font-weight="600">{escape(label)}</text>'
    )

current_top = top_pixels
for category_key, band_label in category_bands:
    band_rows = [row for row in evidence_rows if row["category"] == category_key]
    svg_fragments.append(
        f'<rect x="{left_pixels}" y="{current_top}" width="{width_pixels - 2 * left_pixels}" '
        f'height="{band_height_pixels}" fill="#dfe7ec" stroke="#a9b8c2" stroke-width="1.2"/>'
    )
    svg_fragments.append(
        f'<text x="{left_pixels + 12}" y="{current_top + 26}" font-size="17" font-weight="600" '
        f'fill="#243746">{escape(band_label)}</text>'
    )
    current_top += band_height_pixels + band_gap_pixels
    for row in band_rows:
        row_lines = []
        for column_index, (_, key, width) in enumerate(columns):
            capacity = (width - 24) / 8
            values = module_labels[row["module"]] if key == "module" else [row[key]]
            row_lines.append(cell_lines(values, capacity))
        row_height = max(len(lines) for lines in row_lines) * line_height_pixels + row_padding_pixels
        for column_index, lines in enumerate(row_lines):
            value = row[columns[column_index][1]]
            fill, stroke, color = cell_style(value)
            add_cell(column_index, current_top, row_height, lines, fill, stroke, color)
        current_top += row_height + row_gap_pixels

footer_top = current_top + 12
svg_fragments.extend(
    [
        f'<text x="22" y="{footer_top}" font-size="15.5">图注：格内数字是工具错误次数 / 报警上下文数或统计结论词，不是时间样本量、效应量或攻击成功率。</text>',
        f'<text x="22" y="{footer_top + 26}" font-size="15.5">M1 为已封存真实案例的引用；M2 为真实历史路径但时间统计 «待主控数据»；M3/M4 是人工构造校准；M5 是阴性对照候选。</text>',
        f'<text x="22" y="{footer_top + 52}" font-size="15.5">定位阳性、工具无报警、预算内未检出都不等于恒时证明或总体误报率为零；完整条件见 COMPLETION_REQUIREMENTS.md。</text>',
        "</g></svg>",
    ]
)
height_pixels = int(footer_top + 80)
svg_document = "\n".join(svg_fragments).replace("{height}", str(height_pixels))
(figure_directory / "platform-evidence-matrix.svg").write_text(svg_document + "\n")
print(f"svg={width_pixels}x{height_pixels} rows={len(evidence_rows)}")
