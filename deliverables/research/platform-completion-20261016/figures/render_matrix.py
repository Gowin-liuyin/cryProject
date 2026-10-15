from pathlib import Path
import csv
from html import escape


figure_directory = Path(__file__).resolve().parent
with (figure_directory.parent / "EVIDENCE_MATRIX.csv").open() as source:
    evidence_rows = list(csv.DictReader(source))
assert [row["module"] for row in evidence_rows] == ["M1", "M2", "M3", "M4", "M5"]
assert all(row["audit_commit"] == "ac46e62" for row in evidence_rows)

module_labels = {
    "M1": ["M1 编译器分支"],
    "M2": ["M2 秘密除法"],
    "M3": ["M3 秘密访存"],
    "M4": ["M4 提前比较"],
    "M5": ["M5 阴性候选"],
}
case_labels = {
    "historical_real": ["真实历史"],
    "historical_real_hotspots": ["真实历史热点"],
    "artificial_calibration": ["人工构造校准"],
    "negative_candidate": ["固定 mlkem-native"],
}
location_labels = {
    "frozen_reference": ["原封存闭环"],
    "varlat_1280_3_vs_0_0": ["varlat", "1280/3 对 0/0"],
    "memcheck_32_1_vs_0_0": ["Memcheck", "32/1 对 0/0"],
    "not_run": ["工具未运行"],
}
statistics_labels = {"frozen_reference": ["原证据引用"], "not_run": ["未运行"]}
gap_labels = {
    "M1": ["保护旧原件"],
    "M2": ["完整 KEM / 锁频", "Mona 对照"],
    "M3": ["KEM 挂载 / 统计"],
    "M4": ["Binsec / 统计"],
    "M5": ["原生定位 / 阴性统计"],
}

width_pixels = 1460
height_pixels = 810
column_width_pixels = 274
column_gap_pixels = 12
row_height_pixels = 102
row_gap_pixels = 12
left_pixels = 22
top_pixels = 180
fragments = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{width_pixels}" '
    f'height="{height_pixels}" viewBox="0 0 {width_pixels} {height_pixels}">',
    '<rect width="100%" height="100%" fill="#ffffff"/>',
    '<g font-family="Arial, PingFang SC, sans-serif" fill="#17212b">',
    '<text x="22" y="38" font-size="25" font-weight="600">多泄漏模块平台：证据状态与剩余交付</text>',
    '<text x="22" y="68" font-size="16">审计基线 ac46e62 · 2026-10-16；定位、统计与验收分别记录</text>',
]


def add_cell(column_index, top, height, lines, fill, stroke, text_color, is_bold=False):
    left = left_pixels + column_index * (column_width_pixels + column_gap_pixels)
    center = left + column_width_pixels / 2
    fragments.append(
        f'<rect x="{left}" y="{top}" width="{column_width_pixels}" '
        f'height="{height}" fill="{fill}" stroke="{stroke}" stroke-width="1.2"/>'
    )
    first_baseline = top + height / 2 - (len(lines) - 1) * 14 + 6
    weight = "600" if is_bold else "400"
    for line_index, label in enumerate(lines):
        fragments.append(
            f'<text x="{center}" y="{first_baseline + line_index * 28}" '
            f'text-anchor="middle" fill="{text_color}" font-size="19" '
            f'font-weight="{weight}">{escape(label)}</text>'
        )


for column_index, label in enumerate(
    ["模块 / 机制", "案例类型", "已核对定位", "新模块统计", "完整目标缺口"]
):
    add_cell(column_index, 103, 62, [label], "#243746", "#243746", "#ffffff", True)

for row_index, row in enumerate(evidence_rows):
    top = top_pixels + row_index * (row_height_pixels + row_gap_pixels)
    columns = [
        module_labels[row["module"]],
        case_labels[row["case_type"]],
        location_labels[row["localization_state"]],
        statistics_labels[row["formal_statistics_state"]],
        gap_labels[row["module"]],
    ]
    for column_index, labels in enumerate(columns):
        fill, stroke, color = "#ffffff", "#d4dce2", "#17212b"
        if row_index == 0:
            fill, stroke, color = "#edf1f4", "#9eacb7", "#243746"
        elif column_index in [3, 4] or (column_index == 2 and row["localization_state"] == "not_run"):
            fill, stroke, color = "#fff3dd", "#c9a365", "#5b4219"
        elif column_index == 2:
            fill, stroke, color = "#e8f1f7", "#779bb2", "#17384d"
        add_cell(column_index, top, row_height_pixels, labels, fill, stroke, color)

fragments.extend(
    [
        '<text x="22" y="773" font-size="15">工具数字是错误次数 / 上下文数；不是时间样本量、效应量或攻击成功率。</text>',
        '<text x="22" y="798" font-size="15">缺口列为摘要，完整条件见 COMPLETION_REQUIREMENTS；未运行不等于未检出。</text>',
        '</g></svg>',
    ]
)
(figure_directory / "platform-evidence-matrix.svg").write_text("\n".join(fragments) + "\n")
