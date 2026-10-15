"""T27 图：ECDF 对比图 + 修复前后箱线图，输出 PDF 到 `docs/evidence/r04-stats-20261016/figures/`。

运行（在仓库根目录）：
    python3 docs/evidence/r04-stats-20261016/robustness-src/r04_figures.py

约定：
- 图内文字全部 ASCII，避免 PDF 字体缺字（本仓库报告在别处排版）。
- 每张图都印标题、带单位 ns 的轴标签、图例，以及数据来源 CSV 路径 + run 名 + 种子/绑核。
- 只读已有证据 CSV；不重新采集、不改动已有证据文件。
"""

from __future__ import annotations

import textwrap

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch

import r04_common as rc

COLOR0 = "#1f77b4"
COLOR1 = "#d62728"
GRID_KW = {"color": "0.85", "linewidth": 0.6, "linestyle": "-"}

ARM_LABELS = {
    "unfixed": "unfixed",
    "fixed": "fixed",
    "on": "on",
    "off": "off",
    "vuln": "vulnerable",
    "ct": "ct",
    "reference": "reference",
}

R03_ARM_ASCII = {
    "m1unfixed": "M1 unfixed",
    "m1fixed": "M1 fixed (982c762)",
    "m5ref": "M5 reference",
}
R03_PAIR_ASCII = {
    "valid-malformed": "control A: valid vs malformed",
    "valid-truncated": "control B: valid vs truncated",
}

MODULE_STATS: dict[str, list[rc.PairStats]] = {}


def arm_ascii(pair: rc.ClassPair) -> str:
    """图内使用的纯 ASCII 臂名（PDF 不保证含中文字形）。"""
    if pair.module == "R03":
        arm_base, pair_key = pair.arm.split("/")
        return f"{R03_ARM_ASCII[arm_base]} / {R03_PAIR_ASCII[pair_key]}"
    if pair.arm == "fixed" and pair.module in ("M1", "M2"):
        return "fixed (982c762)"
    if pair.arm == "unfixed" and pair.module in ("M1", "M2"):
        return "unfixed (pre-fix)"
    if pair.arm == "on":
        return "LUT on"
    if pair.arm == "off":
        return "LUT off"
    return ARM_LABELS.get(pair.arm, pair.arm)


# ---------------------------------------------------------------- 公共工具

def provenance_lines(pair: rc.ClassPair, extra: str = "") -> str:
    """图脚注：数据来源 CSV 路径 + run 名 + 种子与绑核。"""
    lines = []
    if extra:
        lines.append(extra)
    lines.append(f"Source CSV: {pair.source_csv}")
    lines.append(
        f"run: {pair.run_label}   |   seed {pair.seed}   |   taskset {pair.cpu}   |   "
        f"n = 10000 per class   |   unit: ns"
    )
    return "\n".join(textwrap.fill(line, 205) for line in lines)


def add_footer(fig, pair: rc.ClassPair, extra: str = "", y: float = 0.012) -> None:
    fig.text(
        0.008,
        y,
        provenance_lines(pair, extra),
        ha="left",
        va="bottom",
        fontsize=5.2,
        color="0.28",
    )


def ecdf(values: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    ordered = np.sort(values)
    cdf = np.arange(1, ordered.size + 1, dtype=np.float64) / ordered.size
    return ordered, cdf


def describe(values: np.ndarray) -> str:
    return "n=%d  mean=%.1f ns  median=%.0f ns  SD=%.1f ns" % (
        values.size,
        float(np.mean(values)),
        float(np.median(values)),
        float(np.std(values, ddof=1)),
    )


def needs_log_axis(values0: np.ndarray, values1: np.ndarray) -> bool:
    """两类中位数相差 100 倍以上时改用对数横轴。"""
    median0 = float(np.median(values0))
    median1 = float(np.median(values1))
    if median0 <= 0.0 or median1 <= 0.0:
        return False
    return max(median0, median1) / min(median0, median1) > 100.0


def add_legend(ax, location: str = "lower right", fontsize: float = 7.4) -> None:
    ax.legend(loc=location, fontsize=fontsize, framealpha=0.92)


# ---------------------------------------------------------------- ECDF 单图

def figure_ecdf(pair: rc.ClassPair, stats: rc.PairStats) -> str:
    values0, values1 = rc.load_pair(pair)
    log_axis = needs_log_axis(values0, values1)

    fig, ax = plt.subplots(figsize=(7.6, 4.9))
    for values, label, color in (
        (values0, pair.class0, COLOR0),
        (values1, pair.class1, COLOR1),
    ):
        ordered, cdf = ecdf(values)
        ax.step(ordered, cdf, where="post", color=color, linewidth=1.2, label=f"{label}: {describe(values)}")

    ax.set_xlabel("elapsed time of one measured call (ns)" + ("   [log scale]" if log_axis else ""))
    ax.set_ylabel("empirical CDF (fraction of samples)")
    ax.set_ylim(-0.02, 1.02)
    # 横轴截到两类各自的 p99.5：M3/M5 这类臂存在单个 97000 ns 级的长尾点，
    # 不截会让主体分布被压成一条竖线。截断在图上显式标注，不隐藏长尾。
    upper = float(max(np.quantile(values0, 0.995), np.quantile(values1, 0.995)))
    lower = float(min(values0.min(), values1.min()))
    clipped = bool(values0.max() > upper or values1.max() > upper)
    if log_axis:
        ax.set_xscale("log")
        # 对数轴上不能出现 <= 0 的边界，用乘法留白。
        ax.set_xlim(max(lower, 1.0) / 1.30, upper * 1.30)
    else:
        ax.set_xlim(lower - 0.01 * (upper - lower), upper + 0.01 * (upper - lower))
    ax.grid(True, **GRID_KW)
    ax.legend(loc="lower right", fontsize=7.0, framealpha=0.92)

    delta = stats.delta_ns
    mde = stats.mde_alpha_ns
    verdict = "delta EXCEEDS MDE" if abs(delta) > mde else "delta is inside MDE (not distinguishable at this budget)"
    fig.text(
        0.5,
        0.968,
        f"ECDF — {pair.module} {arm_ascii(pair)} / run {pair.run_label}",
        ha="center",
        va="top",
        fontsize=10.5,
    )
    fig.text(
        0.5,
        0.925,
        f"{pair.class0} (class0) vs {pair.class1} (class1)   |   n = {stats.n0} / {stats.n1}",
        ha="center",
        va="top",
        fontsize=7.6,
        color="0.15",
    )
    fig.text(
        0.5,
        0.882,
        f"mean delta = {delta:+.3f} ns   |   MDE(alpha=0.05, power=0.80) = {mde:.3f} ns   |   {verdict}",
        ha="center",
        va="top",
        fontsize=7.2,
        color="0.35",
    )
    if log_axis:
        fig.text(
            0.5,
            0.845,
            "x-axis is logarithmic because the two medians differ by more than 100x",
            ha="center",
            va="top",
            fontsize=7.0,
            color="0.45",
        )
    if clipped:
        ax.text(
            0.012,
            0.975,
            "x-axis clipped at the p99.5 of the two classes (full maxima: %.0f / %.0f ns);\n"
            "the upper tail is not removed from any statistic" % (values0.max(), values1.max()),
            transform=ax.transAxes,
            ha="left",
            va="top",
            fontsize=6.2,
            color="0.35",
            bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.82},
        )
    fig.subplots_adjust(left=0.105, right=0.98, top=0.815, bottom=0.185)
    add_footer(fig, pair)
    target = rc.FIG_DIR / f"ecdf-{pair.key}.pdf"
    fig.savefig(target, format="pdf")
    plt.close(fig)
    return target.name


# ---------------------------------------------------------------- 箱线图

def box_panel(ax, pair: rc.ClassPair, values0: np.ndarray, values1: np.ndarray, panel_title: str) -> None:
    result = ax.boxplot(
        [values0, values1],
        showfliers=False,
        patch_artist=True,
        widths=0.55,
        medianprops={"color": "black", "linewidth": 1.8},
    )
    for patch, color in zip(result["boxes"], (COLOR0, COLOR1)):
        patch.set_facecolor(color)
        patch.set_alpha(0.45)
    whisker_ends = np.concatenate([item.get_ydata() for item in result["whiskers"]])
    low = float(np.min(whisker_ends))
    high = float(np.max(whisker_ends))
    # 退化臂（IQR = 0，例如 M4 ct 臂 83% 的样本落在同一个 10 ns 格点）要撑开一个最小可视跨度，
    # 否则箱线被压成一条线，看不出它是真的常数还是坐标轴缩放造成的假象。
    minimum_span = 0.06 * float(np.median(np.concatenate([values0, values1])))
    if high - low < minimum_span:
        centre = 0.5 * (high + low)
        low = centre - 0.5 * minimum_span
        high = centre + 0.5 * minimum_span
    pad = 0.08 * (high - low)
    ax.set_ylim(low - pad, high + pad)

    ax.set_xticks([1, 2])
    ax.set_xticklabels([pair.class0, pair.class1], fontsize=7.6)
    ax.set_title(panel_title, fontsize=8.8)
    ax.set_xlabel("input class")
    ax.set_ylabel("elapsed time (ns)")
    ax.grid(True, axis="y", **GRID_KW)

    def modal_share(values: np.ndarray) -> tuple[int, float]:
        counts = np.bincount(values.astype(np.int64))
        mode = int(np.argmax(counts))
        return mode, 100.0 * float(counts[mode]) / values.size

    mode0, share0 = modal_share(values0)
    mode1, share1 = modal_share(values1)
    iqr0 = float(np.quantile(values0, 0.75) - np.quantile(values0, 0.25))
    iqr1 = float(np.quantile(values1, 0.75) - np.quantile(values1, 0.25))
    distinct = len(np.unique(np.concatenate([values0, values1])))
    notes = [
        f"distinct values: {distinct}   fliers omitted; whiskers = 1.5 IQR",
        f"medians: {np.median(values0):.0f} / {np.median(values1):.0f} ns    "
        f"IQR: {iqr0:.0f} / {iqr1:.0f} ns",
        f"modal value: {mode0} ns ({share0:.1f}% of class0) / {mode1} ns ({share1:.1f}% of class1)",
    ]
    if iqr0 == 0.0 or iqr1 == 0.0:
        notes.append("IQR = 0 on at least one class: the timing values sit on a coarse grid")
    ax.text(
        0.02,
        0.975,
        "\n".join(notes),
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=6.0,
        color="0.3",
    )
    ax.legend(
        handles=[
            Patch(facecolor=COLOR0, alpha=0.45, label=f"{pair.class0} (class0)"),
            Patch(facecolor=COLOR1, alpha=0.45, label=f"{pair.class1} (class1)"),
        ],
        loc="lower right",
        fontsize=6.8,
        framealpha=0.92,
    )


def delta_panel(ax, items: list[rc.PairStats], title: str) -> None:
    """每臂每次 run 的 Δ 与 95% CI，叠加 ±MDE(α=0.05) 与 ±MDE(Holm) 带。"""
    positions = [float(index + 1) for index in range(len(items))]
    labels = [f"{ARM_LABELS.get(item.pair.arm, item.pair.arm)}\nrun {item.pair.run_index}" for item in items]
    worst_mde_alpha = max(item.mde_alpha_ns for item in items)
    worst_mde_holm = max(item.mde_holm_ns for item in items)
    ax.axhspan(-worst_mde_holm, worst_mde_holm, color="0.72", alpha=0.40, zorder=0)
    ax.axhspan(-worst_mde_alpha, worst_mde_alpha, color="0.45", alpha=0.30, zorder=0)
    ax.axhline(0.0, color="black", linewidth=0.9, zorder=1)
    for position, item in zip(positions, items):
        color = COLOR0 if item.pair.arm in ("unfixed", "on", "vuln", "reference") else COLOR1
        ax.errorbar(
            position,
            item.delta_ns,
            yerr=[[item.delta_ns - item.ci_low_ns], [item.ci_high_ns - item.delta_ns]],
            fmt="o",
            color=color,
            markersize=5.5,
            capsize=4,
            linewidth=1.3,
            zorder=3,
        )
    ax.set_xticks(positions)
    ax.set_xticklabels(labels, fontsize=6.6)
    ax.set_xlabel("arm / run")
    ax.set_ylabel("delta = mean(class0) - mean(class1) (ns)")
    ax.grid(True, axis="y", **GRID_KW)
    span = max(
        [abs(item.delta_ns) for item in items]
        + [abs(item.ci_low_ns) for item in items]
        + [abs(item.ci_high_ns) for item in items]
        + [worst_mde_holm]
    )
    ax.set_ylim(-1.35 * span, 1.35 * span)
    ax.set_title(title, fontsize=8.4)
    ax.legend(
        handles=[
            Patch(facecolor="0.45", alpha=0.30, label=f"+/-MDE(alpha=0.05), worst {worst_mde_alpha:.2f} ns"),
            Patch(facecolor="0.72", alpha=0.40, label=f"+/-MDE(Holm), worst {worst_mde_holm:.2f} ns"),
            plt.Line2D([], [], color="black", marker="o", linestyle="none", markersize=5, label="delta with 95% CI"),
        ],
        loc="lower right",
        fontsize=6.4,
        framealpha=0.92,
    )


def figure_boxplot(module: str, arm0: str, arm1: str, filename: str, title: str, note: str) -> str:
    items = list(MODULE_STATS[module])
    items0 = [item for item in items if item.pair.arm == arm0]
    items1 = [item for item in items if item.pair.arm == arm1]
    pair0 = items0[0].pair
    pair1 = items1[0].pair
    values0 = rc.load_pair(pair0)
    values1 = rc.load_pair(pair1)

    fig, axes = plt.subplots(1, 3, figsize=(13.0, 4.9))
    box_panel(axes[0], pair0, values0[0], values0[1], f"(a) arm {arm_ascii(pair0)}, run {pair0.run_label}")
    box_panel(axes[1], pair1, values1[0], values1[1], f"(b) arm {arm_ascii(pair1)}, run {pair1.run_label}")
    delta_panel(
        axes[2],
        items0 + items1,
        "(c) delta per run with 95% CI, against the MDE bands",
    )

    fig.suptitle(title, fontsize=11.0, y=0.982)
    fig.text(0.5, 0.912, textwrap.fill(note, 168), ha="center", va="top", fontsize=7.0, color="0.2")
    fig.text(
        0.5,
        0.856,
        "panels (a) and (b) use INDEPENDENT y-scales: the arm-to-arm level offset is a build difference, not the "
        "tested effect. The tested effect is the within-arm class0 - class1 difference, shown in panel (c).",
        ha="center",
        va="top",
        fontsize=6.7,
        color="0.35",
    )
    fig.subplots_adjust(left=0.058, right=0.988, top=0.79, bottom=0.215, wspace=0.30)
    extra = "Source CSVs: " + "; ".join(sorted({item.pair.source_csv for item in items0 + items1}))
    add_footer(fig, pair0, extra=extra, y=0.008)
    target = rc.FIG_DIR / filename
    fig.savefig(target, format="pdf")
    plt.close(fig)
    return target.name


# ---------------------------------------------------------------- M2 定位层说明图

M2_LOCALIZATION_NOTE = (
    "LOCALIZATION LAYER (separate evidence, NOT a wall-clock measurement): the unfixed chain has 1 `div` in each of "
    "3 hotspots and the fixed chain has 0; KyberSlash varlat reports 1280 errors / 3 contexts (unfixed) and 0 / 0 "
    "(fixed). See m2-kem-20261016/RESULT.md. THIS FIGURE SHOWS NO END-TO-END DIFFERENCE."
)


def figure_m2_note() -> str:
    items = list(MODULE_STATS["M2"])
    pair_unfixed = next(item.pair for item in items if item.pair.key == "M2-unfixed-s1")
    pair_fixed = next(item.pair for item in items if item.pair.key == "M2-fixed-s1")

    fig, axes = plt.subplots(1, 3, figsize=(13.2, 5.0))

    for ax, pair, panel_title in (
        (axes[0], pair_unfixed, f"(a) M2 unfixed arm, run {pair_unfixed.run_label}"),
        (axes[1], pair_fixed, f"(b) M2 fixed arm, run {pair_fixed.run_label}"),
    ):
        values0, values1 = rc.load_pair(pair)
        for data, label, color in ((values0, pair.class0, COLOR0), (values1, pair.class1, COLOR1)):
            ordered, cdf = ecdf(data)
            ax.step(ordered, cdf, where="post", color=color, linewidth=1.2, label=f"{label}: {describe(data)}")
        low = float(min(values0.min(), values1.min()))
        high = float(
            max(np.quantile(values0, 0.995), np.quantile(values1, 0.995))
        )
        ax.set_xlim(low - 0.01 * (high - low), high + 0.01 * (high - low))
        ax.set_ylim(-0.02, 1.02)
        ax.set_xlabel("elapsed time of one complete decapsulation (ns)")
        ax.set_ylabel("empirical CDF (fraction of samples)")
        ax.grid(True, **GRID_KW)
        ax.set_title(panel_title, fontsize=8.8)
        ax.legend(loc="upper left", fontsize=6.3, framealpha=0.92)
        ax.text(
            0.98,
            0.04,
            "the two ECDFs are visually coincident\n(x-axis clipped at the p99.5 of the two classes)",
            transform=ax.transAxes,
            ha="right",
            va="bottom",
            fontsize=6.2,
            color="0.35",
        )

    delta_panel(
        axes[2],
        items,
        "(c) delta per run with 95% CI, against the MDE bands",
    )

    fig.suptitle(
        "M2 end-to-end class pair (message-zero vs message-ones): NOT distinguishable at this budget "
        "— localization-layer note",
        fontsize=10.2,
        y=0.982,
    )
    fig.text(
        0.5,
        0.912,
        textwrap.fill(M2_LOCALIZATION_NOTE, 168),
        ha="center",
        va="top",
        fontsize=6.9,
        color="0.2",
    )
    fig.text(
        0.5,
        0.858,
        textwrap.fill(
            "The unfixed and fixed arms are two DIFFERENT BUILDS with different absolute levels (about 56.8 us vs "
            "about 60.8 us). That offset is a build difference, not the tested effect, so the two arms are never "
            "placed on a common axis here. This figure must NOT be read as 'the fix changed the timing'.",
            168,
        ),
        ha="center",
        va="top",
        fontsize=6.3,
        color="0.35",
    )
    fig.subplots_adjust(left=0.056, right=0.988, top=0.748, bottom=0.205, wspace=0.28)
    extra = "Source CSVs: " + "; ".join(sorted({item.pair.source_csv for item in items}))
    add_footer(fig, pair_unfixed, extra=extra, y=0.008)
    target = rc.FIG_DIR / "m2-endtoend-localization-note.pdf"
    fig.savefig(target, format="pdf")
    plt.close(fig)
    return target.name


# ---------------------------------------------------------------- 主流程

def main() -> None:
    rc.FIG_DIR.mkdir(parents=True, exist_ok=True)
    stats_list = [rc.compute_pair_stats(pair, index) for index, pair in enumerate(rc.CLASS_PAIRS)]
    MODULE_STATS.clear()
    for item in stats_list:
        MODULE_STATS.setdefault(item.pair.module, []).append(item)

    written: list[str] = [figure_ecdf(item.pair, item) for item in stats_list]

    written.append(
        figure_boxplot(
            "M1",
            "unfixed",
            "fixed",
            "boxplot-M1-unfixed-vs-fixed.pdf",
            "M1 (liboqs 0.10.0 historical Kyber768): message-zero vs message-ones, before/after the official 982c762 fix",
            "The two arms are separate builds (historical-clangover vs historical-fixed-982c762). M1 has no "
            "pre-registered Holm family (outside-family), so the MDE uses alpha = 0.05 without correction.",
        )
    )
    written.append(
        figure_boxplot(
            "M3",
            "on",
            "off",
            "boxplot-M3-on-vs-off.pdf",
            "M3 (ARTIFICIAL LUT calibration, not an upstream CVE): message-zero vs message-ones, LUT mechanism on vs off",
            "The two arms are separate builds (platform-m3-lut-on vs platform-m3-lut-off). M3 is a constructed "
            "calibration. Family m3_lut_arm_end_to_end_v1, m = 6, alpha_eff = 0.05/6.",
        )
    )
    written.append(
        figure_boxplot(
            "M4",
            "vuln",
            "ct",
            "boxplot-M4-vulnerable-vs-ct.pdf",
            "M4 (ARTIFICIAL early-exit compare fixture, not an upstream CVE): mismatch-first vs mismatch-last, vulnerable vs ct",
            "The two arms are separate builds (m4-vulnerable vs m4-ct). Family m4_compare_arm_session_v1, m = 6, "
            "alpha_eff = 0.05/6. Note the very coarse value grid of the vulnerable arm; see QUANTILE_CI.md section 4.4.",
        )
    )
    written.append(figure_m2_note())

    print(f"[T27] 写出 {len(written)} 张 PDF 到 {rc.relpath(rc.FIG_DIR)}/")
    for name in written:
        print("       ", name)


if __name__ == "__main__":
    main()
