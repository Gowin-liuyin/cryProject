#!/usr/bin/env python3
"""从已提交的 run 原件生成 X.1–X.7 的实测图。不读取确认 p 值来改预算。"""

import csv
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
EVIDENCE = ROOT / "docs/evidence/seven-capabilities-20261011"
OUT = Path(__file__).resolve().parent


def read_fields(path):
    fields = {}
    for line in path.read_text().splitlines():
        if "=" not in line or line.startswith("session_effect "):
            continue
        key, value = line.split("=", 1)
        fields[key] = value
    return fields


def session_effects(path):
    effects = []
    for line in path.read_text().splitlines():
        if not line.startswith("session_effect "):
            continue
        parts = {}
        for token in line.split()[1:]:
            key, value = token.split("=", 1)
            parts[key] = value
        effects.append((parts["session_id"], float(parts["difference"])))
    return effects


def csv_means(path, categories):
    sums = {name: 0 for name in categories}
    counts = {name: 0 for name in categories}
    with path.open() as handle:
        for row in csv.DictReader(handle):
            name = row["category"]
            if name not in sums:
                continue
            sums[name] += int(row["elapsed_clock_counts"])
            counts[name] += 1
    return {name: sums[name] / counts[name] for name in categories}


def rtt_mean(path):
    values = []
    with path.open() as handle:
        for row in csv.DictReader(handle):
            values.append(float(row["elapsed_clock_counts"]))
    return len(values), statistics.fmean(values)


def svg_table(title, headers, rows, source):
    width = 920
    row_height = 28
    height = 64 + row_height * (len(rows) + 1) + 28
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<text x="16" y="28" font-family="sans-serif" font-size="16" fill="#111111">{title}</text>',
        f'<text x="16" y="48" font-family="sans-serif" font-size="11" fill="#444444">{source}</text>',
    ]
    columns = len(headers)
    col_width = (width - 32) / columns
    top = 64
    for index, header in enumerate(headers):
        x = 16 + index * col_width
        lines.append(
            f'<text x="{x:.1f}" y="{top + 18}" font-family="sans-serif" font-size="12" font-weight="700" fill="#111111">{header}</text>'
        )
    for row_index, row in enumerate(rows):
        y = top + row_height * (row_index + 1)
        lines.append(f'<line x1="16" y1="{y}" x2="{width - 16}" y2="{y}" stroke="#dddddd"/>')
        for index, cell in enumerate(row):
            x = 16 + index * col_width
            lines.append(
                f'<text x="{x:.1f}" y="{y + 18}" font-family="sans-serif" font-size="12" fill="#111111">{cell}</text>'
            )
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def build():
    vulnerable = read_fields(EVIDENCE / "ryzen-positive/vulnerable-decision.txt")
    vulnerable_meta = read_fields(EVIDENCE / "ryzen-positive/vulnerable-s1.meta")
    apple = read_fields(EVIDENCE / "apple-silicon/vulnerable-decision.txt")
    apple_meta = read_fields(EVIDENCE / "apple-silicon/v-1.meta")
    v2 = read_fields(EVIDENCE / "ryzen-confirm-v2/vulnerable-decision.txt")
    v2_meta = read_fields(EVIDENCE / "ryzen-confirm-v2/vulnerable-s1.meta")
    v3 = read_fields(EVIDENCE / "ryzen-confirm-v3/vulnerable-decision.txt")
    v3_meta = read_fields(EVIDENCE / "ryzen-confirm-v3/vulnerable-s01.meta")
    v3_hardened = read_fields(EVIDENCE / "ryzen-confirm-v3/hardened-decision.txt")
    v3_rollback = read_fields(EVIDENCE / "ryzen-confirm-v3/rollback-decision.txt")
    v3_retry = read_fields(EVIDENCE / "rollback-retry-31415926/rollback-decision.txt")
    hardened = read_fields(EVIDENCE / "ryzen-positive/hardened-decision.txt")
    rollback = read_fields(EVIDENCE / "ryzen-positive/rollback-decision.txt")
    rank = read_fields(EVIDENCE / "ryzen-positive/vulnerable-rank.txt")
    effects = session_effects(EVIDENCE / "ryzen-positive/vulnerable-decision.txt")
    all_plain = []
    with (EVIDENCE / "trace-overhead/plain.csv").open() as handle:
        for row in csv.DictReader(handle):
            all_plain.append(int(row["elapsed_clock_counts"]))
    plain_mean = statistics.fmean(all_plain)
    account = read_fields(EVIDENCE / "trace-overhead/account-summary.txt")
    timing = read_fields(EVIDENCE / "trace-overhead/timing-summary.txt")
    window_meta = read_fields(EVIDENCE / "ryzen-dev-window-90210/message/session.meta")
    window_means = csv_means(
        EVIDENCE / "ryzen-dev-window-90210/message/session.csv",
        ["message-zero", "message-ones"],
    )
    direct_n, direct_mean = rtt_mean(EVIDENCE / "mac-ryzen-rtt-20261011/rtt-80.csv")
    low_n, low_mean = rtt_mean(EVIDENCE / "ryzen-network/low-rtt.csv")
    mid_n, mid_mean = rtt_mean(EVIDENCE / "ryzen-network/mid-rtt.csv")
    high_n, high_mean = rtt_mean(EVIDENCE / "ryzen-network/high-rtt.csv")
    matrix = csv_means(
        EVIDENCE / "ryzen-matrix/reference-gcc-O2.csv",
        ["valid", "message-zero", "message-ones"],
    )
    figures = {
        "x1-measurement.svg": svg_table(
            "X.1 测量质量与主效应，Holm 均未拒绝",
            ["run_id", "resolution", "empty_max", "primary_mean", "p", "Holm"],
            [
                [
                    "ryzen-vulnerable",
                    vulnerable_meta["resolution_counts"],
                    vulnerable_meta["empty_window_max_counts"],
                    f"{float(vulnerable['primary_mean_difference_counts']):.2f}",
                    f"{float(vulnerable['primary_p_value']):.3f}",
                    vulnerable["holm_rejected_primary"],
                ],
                [
                    "apple-v",
                    apple_meta["resolution_counts"],
                    apple_meta["empty_window_max_counts"],
                    f"{float(apple['primary_mean_difference_counts']):.2f}",
                    f"{float(apple['primary_p_value']):.3f}",
                    apple["holm_rejected_primary"],
                ],
                [
                    "v2-vulnerable",
                    v2_meta["resolution_counts"],
                    v2_meta["empty_window_max_counts"],
                    f"{float(v2['primary_mean_difference_counts']):.2f}",
                    f"{float(v2['primary_p_value']):.3f}",
                    v2["holm_rejected_primary"],
                ],
                [
                    "v3-vulnerable",
                    v3_meta["resolution_counts"],
                    v3_meta["empty_window_max_counts"],
                    f"{float(v3['primary_mean_difference_counts']):.2f}",
                    f"{float(v3['primary_p_value']):.3f}",
                    v3["holm_rejected_primary"],
                ],
            ],
            "ryzen-positive、apple-silicon、ryzen-confirm-v2、ryzen-confirm-v3 的决策文件和 s1 元数据",
        ),
        "x2-overhead.svg": svg_table(
            "X.2 插桩开销与开发种子窗口，未减钩子常数",
            ["record", "quantity", "counts"],
            [
                ["overhead-plain", "all-call mean", f"{plain_mean:.0f}"],
                ["account valid", "outer mean", f"{float(account['outer_mean_counts_valid']):.0f}"],
                ["timing valid", "outer mean", f"{float(timing['outer_mean_counts_valid']):.0f}"],
                ["dev-window-90210-message", "message-zero minus message-ones", f"{window_means['message-zero'] - window_means['message-ones']:.3f}"],
                ["dev-window-90210-message", "empty_window_max", window_meta["empty_window_max_counts"]],
            ],
            "trace-overhead/plain.csv, account-summary.txt, timing-summary.txt；ryzen-dev-window-90210/message/session.csv + session.meta",
        ),
        "x3-sessions.svg": svg_table(
            "X.3 ryzen-vulnerable 六个会话效应，单位为时钟计数",
            ["session", "difference"],
            [[name, f"{value:.2f}"] for name, value in effects],
            "ryzen-positive/vulnerable-decision.txt session_effect；holm_rejected_primary=no",
        ),
        "x4-protection.svg": svg_table(
            "X.4 掩码后不再拒绝，两次回滚都未恢复",
            ["run_id", "primary_mean", "p", "Holm", "rank"],
            [
                [
                    "ryzen-vulnerable",
                    f"{float(vulnerable['primary_mean_difference_counts']):.2f}",
                    f"{float(vulnerable['primary_p_value']):.3f}",
                    vulnerable["holm_rejected_primary"],
                    rank["single_root_cause"],
                ],
                [
                    "ryzen-hardened",
                    f"{float(hardened['primary_mean_difference_counts']):.2f}",
                    f"{float(hardened['primary_p_value']):.3f}",
                    hardened["holm_rejected_primary"],
                    "not_established",
                ],
                [
                    "ryzen-rollback",
                    f"{float(rollback['primary_mean_difference_counts']):.2f}",
                    f"{float(rollback['primary_p_value']):.3f}",
                    rollback["holm_rejected_primary"],
                    "not_established",
                ],
                [
                    "v3-vulnerable",
                    f"{float(v3['primary_mean_difference_counts']):.2f}",
                    f"{float(v3['primary_p_value']):.3f}",
                    v3["holm_rejected_primary"],
                    "top3 20/20",
                ],
                [
                    "v3-hardened",
                    f"{float(v3_hardened['primary_mean_difference_counts']):.2f}",
                    f"{float(v3_hardened['primary_p_value']):.3f}",
                    v3_hardened["holm_rejected_primary"],
                    "shrink_gate",
                ],
                [
                    "v3-rollback",
                    f"{float(v3_rollback['primary_mean_difference_counts']):.2f}",
                    f"{float(v3_rollback['primary_p_value']):.3f}",
                    v3_rollback["holm_rejected_primary"],
                    "restore_not_established",
                ],
                [
                    "v3-rollback-retry",
                    f"{float(v3_retry['primary_mean_difference_counts']):.3f}",
                    f"{float(v3_retry['primary_p_value']):.4f}",
                    v3_retry["holm_rejected_primary"],
                    "restore_not_established",
                ],
            ],
            "trace20-31415926 重加密与 message 包装均为 20/20。旧 v3-rollback 与 v3-rollback-retry 的 Holm 都是 no",
        ),
        "x5-rtt.svg": svg_table(
            "X.5 veth 计数和 Mac 到 Ryzen 的直接 RTT",
            ["run_id", "n", "mean_elapsed_clock_counts"],
            [
                ["network-jitter-low", str(low_n), f"{low_mean:.4f}"],
                ["network-jitter-mid", str(mid_n), f"{mid_mean:.4f}"],
                ["network-jitter-high", str(high_n), f"{high_mean:.4f}"],
                ["mac-ryzen-18080", str(direct_n), f"{direct_mean:.1f}"],
                ["mac-to-ryzen-18012", "0", "absent"],
            ],
            "ryzen-network 三档 CSV。mac-ryzen-rtt-20261011/rtt-80.csv 是直接 TCP，单位为客户端单调钟纳秒计数",
        ),
        "x6-matrix.svg": svg_table(
            "X.6 matrix-reference-gcc-O2 每类 20 次均值",
            ["category", "n", "mean_elapsed_clock_counts"],
            [
                ["valid", "20", f"{matrix['valid']:.1f}"],
                ["message-zero", "20", f"{matrix['message-zero']:.1f}"],
                ["message-ones", "20", f"{matrix['message-ones']:.2f}"],
            ],
            "ryzen-matrix/reference-gcc-O2.csv；24 格资格见同目录 manifest，本图不是确认检验",
        ),
        "x7-platforms.svg": svg_table(
            "X.7 两台机器分开比较，样本未合并，Holm 均未拒绝",
            ["platform", "run_id", "resolution", "empty_max", "primary_mean", "p", "Holm"],
            [
                [
                    "Ryzen 9 9950X",
                    "ryzen-vulnerable",
                    vulnerable_meta["resolution_counts"],
                    vulnerable_meta["empty_window_max_counts"],
                    f"{float(vulnerable['primary_mean_difference_counts']):.2f}",
                    f"{float(vulnerable['primary_p_value']):.3f}",
                    vulnerable["holm_rejected_primary"],
                ],
                [
                    "Apple Silicon",
                    "apple-v",
                    apple_meta["resolution_counts"],
                    apple_meta["empty_window_max_counts"],
                    f"{float(apple['primary_mean_difference_counts']):.2f}",
                    f"{float(apple['primary_p_value']):.3f}",
                    apple["holm_rejected_primary"],
                ],
            ],
            "同一 v1 种子 20261111；ryzen-positive 与 apple-silicon 的决策文件和 s1 元数据",
        ),
    }
    for name, content in figures.items():
        (OUT / name).write_text(content)
    print(f"wrote {len(figures)} figures to {OUT}")
    print(f"plain_mean={plain_mean:.1f} window_diff={window_means['message-zero'] - window_means['message-ones']:.3f}")
    print(f"rtt={low_mean:.4f},{mid_mean:.4f},{high_mean:.4f}")
    print(f"matrix_ones={matrix['message-ones']:.2f} holm={vulnerable['holm_rejected_primary']}")


if __name__ == "__main__":
    build()
