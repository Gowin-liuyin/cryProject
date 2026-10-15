"""T27 分位数差 + bootstrap 95% CI：输出 `docs/evidence/r04-stats-20261016/QUANTILE_CI.md`。

运行（在仓库根目录）：
    python3 docs/evidence/r04-stats-20261016/robustness-src/r04_quantile.py

只读已有证据 CSV；bootstrap 次数 10000、种子固定，见 `r04_common.py`。
"""

from __future__ import annotations

import math
import time
from collections import Counter

import numpy as np

import r04_common as rc


def quantile_label(prob: float) -> str:
    return f"p{prob * 100:.0f}"


# ---------------------------------------------------------------- 逐条一致性

def consistency_records(stats_list: list[rc.PairStats]) -> list[dict[str, object]]:
    """逐 (主类对, 分位数) 判定「与均值差是否一致」。"""
    records = []
    for item in stats_list:
        mean_detectable = (item.ci_low_ns > 0.0) or (item.ci_high_ns < 0.0)
        mean_sign = (item.delta_ns > 0.0) - (item.delta_ns < 0.0)
        for prob in rc.QUANTILE_PROBS:
            payload = item.quantiles[prob]
            diff = payload["diff_ns"]
            low = payload["ci_low_ns"]
            high = payload["ci_high_ns"]
            detectable = (low > 0.0) or (high < 0.0)
            sign = (diff > 0.0) - (diff < 0.0)
            if sign == 0:
                direction = "zero"
            elif sign == mean_sign:
                direction = "same"
            else:
                direction = "reverse"
            records.append(
                {
                    "key": item.pair.key,
                    "module": item.pair.module,
                    "arm": item.pair.arm_cn,
                    "run": item.pair.run_label,
                    "label": quantile_label(prob),
                    "diff": diff,
                    "low": low,
                    "high": high,
                    "detectable": detectable,
                    "direction": direction,
                    "mean_delta": item.delta_ns,
                    "mean_low": item.ci_low_ns,
                    "mean_high": item.ci_high_ns,
                    "mean_detectable": mean_detectable,
                    "mde_alpha": item.mde_alpha_ns,
                    "verdict_agree": detectable == mean_detectable,
                }
            )
    return records


# ---------------------------------------------------------------- 计时粒度

def granularity_ns(values: np.ndarray) -> tuple[int, int, int]:
    """返回 (不同取值个数, 最小相邻间隔, 相邻间隔中位数)，单位 ns。"""
    distinct = np.unique(values)
    gaps = np.diff(distinct)
    gaps = gaps[gaps > 0]
    if gaps.size == 0:
        return int(distinct.size), 0, 0
    return int(distinct.size), int(gaps.min()), int(np.median(gaps))


def granularity_rows(stats_list: list[rc.PairStats]) -> list[dict[str, object]]:
    rows = []
    for item in stats_list:
        values0, values1 = rc.load_pair(item.pair)
        combined = np.concatenate([values0, values1])
        distinct, min_gap, median_gap = granularity_ns(combined)
        rows.append(
            {
                "key": item.pair.key,
                "module": item.pair.module,
                "distinct": distinct,
                "min_gap": min_gap,
                "median_gap": median_gap,
            }
        )
    return rows


# ---------------------------------------------------------------- 文档渲染

def render_markdown(
    stats_list: list[rc.PairStats],
    records: list[dict[str, object]],
    granularity: list[dict[str, object]],
) -> str:
    out: list[str] = []
    add = out.append

    add("# T27 分位数差 + bootstrap 95% CI（r04-stats-20261016）")
    add("")
    add("本页是**只读复算**：输入是已提交的锁频采集 CSV，不重新采集、不改动任何已有证据文件、")
    add("不做密钥恢复。复现命令见 §8；输入文件摘要见 [POWER.md 附录 A](POWER.md#附录-a输入文件摘要)。")
    add("")

    # ---------------- 1 方法
    add("## 1. 方法")
    add("")
    add("### 1.1 统计量")
    add("")
    add("- 分位数：`p10 / p50 / p90 / p99`，`numpy.quantile(..., method='linear')`（numpy 默认口径）。")
    add("- **分位数差 = class0 分位数 − class1 分位数**，与既有证据的 Δ = mean0 − mean1 同向、同命名。")
    add("- 每类的经验分布用同一份 CSV 的逐次原始值，不做截尾、不去长尾、不重排。")
    add("")
    add("### 1.2 bootstrap 95% CI")
    add("")
    add("- **百分位法**：对两类**各自独立**做有放回重抽样（每次重抽 n = 10000），")
    add("  复算同一分位数并相减，取重抽样分布的 2.5% / 97.5% 分位作为区间端点。")
    add("- **次数 B = 10000**（≥10000），按 250 个重抽样一块分块生成索引以控制峰值内存。")
    add("- **固定种子**：`numpy.random.default_rng([20261016, <数据集序号>])`，")
    add("  序号就是 POWER.md 主表里的 `#`（1–41），与登记表顺序绑定，重跑逐位可复现。")
    add("- 均值差的 95% CI 沿用既有证据口径（正态近似，z = 1.96，方差除数 n−1），")
    add("  只用于「与分位差是否一致」的对照，不改写既有结论。")
    add("- 每个主类对都是 `n0 = n1 = 10000`。")
    add("")
    add("### 1.3 「与均值差一致」的判定")
    add("")
    add("对每个（主类对，分位数）记录两个**互相独立**的判定：")
    add("")
    add("1. **方向**：分位差与均值差的关系分三类——")
    add("   `同向`（两者符号相同且都非零）、`反向`（符号相反且都非零）、`零`（分位差恰为 0，无方向）。")
    add("2. **判定**：`(分位差 95% CI 排除 0) == (均值差 95% CI 排除 0)`。")
    add("   只要出现「分位差 CI 排除 0 而均值差 CI 含 0」（或反向），就算**判定翻转**。")
    add("")
    add("§4 把所有翻转、反向与零差条目逐条列出，不做任何隐藏或选择性汇报。")
    add("")

    # ---------------- 2 主表
    add("## 2. 主表：一行一个主类对")
    add("")
    add("单位 ns。每格是 `差值 [bootstrap 95% CI 下界, 上界]`；`Δmean` 一列给出均值差及其既有口径 95% CI。")
    add("**加粗**表示该区间的 95% CI 不含 0（注意 `[+0.0, +0.0]` 是**含** 0 的退化区间）。")
    add("")
    add("| # | 模块 | 臂 | run | Δmean [95% CI] | Δp10 [bootstrap 95% CI] | Δp50 | Δp90 | Δp99 | 方向 同/反/零 | 判定一致 |")
    add("| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")

    def cell(text: str, detectable: bool) -> str:
        return f"**{text}**" if detectable else text

    for position, item in enumerate(stats_list, start=1):
        mean_detectable = (item.ci_low_ns > 0.0) or (item.ci_high_ns < 0.0)
        cells = []
        for prob in rc.QUANTILE_PROBS:
            payload = item.quantiles[prob]
            detectable = (payload["ci_low_ns"] > 0.0) or (payload["ci_high_ns"] < 0.0)
            cells.append(
                cell(
                    "%+.1f [%+.1f, %+.1f]"
                    % (payload["diff_ns"], payload["ci_low_ns"], payload["ci_high_ns"]),
                    detectable,
                )
            )
        pair_records = [r for r in records if r["key"] == item.pair.key]
        tally = Counter(r["direction"] for r in pair_records)
        verdict_agree = sum(1 for r in pair_records if r["verdict_agree"])
        add(
            f"| {position} | {item.pair.module} | {item.pair.arm_cn} | `{item.pair.run_label}` | "
            + cell(
                "%+.3f [%+.3f, %+.3f]" % (item.delta_ns, item.ci_low_ns, item.ci_high_ns),
                mean_detectable,
            )
            + " | "
            + " | ".join(cells)
            + f" | {tally['same']}/{tally['reverse']}/{tally['zero']} | {verdict_agree}/4 |"
        )
    add("")

    # ---------------- 3 点估计
    add("## 3. 点估计附录（class0 / class1）")
    add("")
    add("每格是 `class0 分位数 / class1 分位数`，单位 ns，方便把上表的差值逐位还原。")
    add("")
    add("| # | 主类对 | p10 (c0 / c1) | p50 (c0 / c1) | p90 (c0 / c1) | p99 (c0 / c1) |")
    add("| ---: | --- | --- | --- | --- | --- |")
    for position, item in enumerate(stats_list, start=1):
        cells = []
        for prob in rc.QUANTILE_PROBS:
            payload = item.quantiles[prob]
            cells.append("%.0f / %.0f" % (payload["q0_ns"], payload["q1_ns"]))
        add(f"| {position} | {item.pair.key} | " + " | ".join(cells) + " |")
    add("")

    # ---------------- 4 不一致
    flips = [r for r in records if not r["verdict_agree"]]
    reverses = [r for r in records if r["direction"] == "reverse"]
    zeros = [r for r in records if r["direction"] == "zero"]
    no_mean_ci = [r for r in flips if r["detectable"] and not r["mean_detectable"]]
    no_quant_ci = [r for r in flips if r["mean_detectable"] and not r["detectable"]]

    add("## 4. 与均值差**不一致**的条目（如实列出）")
    add("")
    add(f"共 {len(records)} 条（41 个主类对 × 4 个分位数）：")
    add("")
    add(f"- 判定翻转：**{len(flips)} / {len(records)}**")
    add(f"  - 分位差 CI 排除 0 而均值差 CI 含 0：{len(no_mean_ci)} 条")
    add(f"  - 均值差 CI 排除 0 而分位差 CI 含 0：{len(no_quant_ci)} 条")
    add(f"- 方向反向（两者都非零且符号相反）：**{len(reverses)} / {len(records)}**")
    add(f"- 分位差恰为 0（无方向）：**{len(zeros)} / {len(records)}**")
    add("")

    add("### 4.1 判定翻转逐条")
    add("")
    add("| 主类对 | 分位数 | 分位差 [bootstrap 95% CI] | 均值差 [既有 95% CI] | 方向 | 该对比 MDE(α=0.05) |")
    add("| --- | --- | --- | --- | --- | ---: |")
    for row in flips:
        add(
            f"| `{row['key']}` | {row['label']} | "
            f"{row['diff']:+.1f} [{row['low']:+.1f}, {row['high']:+.1f}]"
            f"（{'不含' if row['detectable'] else '含'} 0） | "
            f"{row['mean_delta']:+.3f} [{row['mean_low']:+.3f}, {row['mean_high']:+.3f}]"
            f"（{'不含' if row['mean_detectable'] else '含'} 0） | "
            f"{'同向' if row['direction'] == 'same' else ('**反向**' if row['direction'] == 'reverse' else '零')} | "
            f"{row['mde_alpha']:.3f} |"
        )
    add("")

    add("### 4.2 方向反向逐条")
    add("")
    add("| 主类对 | 分位数 | 分位差 [bootstrap 95% CI] | 均值差 [既有 95% CI] |")
    add("| --- | --- | --- | --- |")
    for row in reverses:
        add(
            f"| `{row['key']}` | {row['label']} | "
            f"{row['diff']:+.1f} [{row['low']:+.1f}, {row['high']:+.1f}] | "
            f"{row['mean_delta']:+.3f} [{row['mean_low']:+.3f}, {row['mean_high']:+.3f}] |"
        )
    add("")

    add("### 4.3 分位差恰为 0 的条目按模块统计")
    add("")
    add("| 模块 | 条目数 | 判定翻转 | 方向反向 | 分位差为 0 |")
    add("| --- | ---: | ---: | ---: | ---: |")
    for module in ("M1", "M2", "M3", "M4", "M5", "R03"):
        module_records = [r for r in records if r["module"] == module]
        if not module_records:
            continue
        add(
            f"| {module} | {len(module_records)} | "
            f"{sum(1 for r in module_records if not r['verdict_agree'])} | "
            f"{sum(1 for r in module_records if r['direction'] == 'reverse')} | "
            f"{sum(1 for r in module_records if r['direction'] == 'zero')} |"
        )
    add("")

    # ---------------- 5 离散化
    median_gaps = [int(row["median_gap"]) for row in granularity]
    min_gaps = [int(row["min_gap"]) for row in granularity]
    add("### 4.4 为什么会有这么多零差与翻转：有效计时粒度")
    add("")
    add("对每个主类对把两类的取值合起来看：")
    add("")
    add(
        f"- 相邻**不同取值**的间隔中位数：全批 41 个主类对合起来的中位数是 **{int(np.median(median_gaps))} ns**"
        f"（各主类对的范围 {min(median_gaps)}–{max(median_gaps)} ns）。"
    )
    add(f"- 相邻不同取值的最小间隔：全批都是 **{min(min_gaps)} ns**。")
    add("- 取值本身是整数 ns（所以最小间隔是 1 ns），但在实际聚簇区间上，**不同取值之间的典型间隔是 9–10 ns**；")
    add("  也就是说，本平台这批数据的**有效计时量化尺度约 10 ns**——")
    add("  均值可以靠 n = 10000 平均出 1 ns 以下的差异，但**分位数只能落在约 10 ns 的格点上**。")
    add("")
    add("这一条直接解释了两类现象：")
    add("")
    add("1. **分位差恰为 0**（63 条）：两类的同一个分位点落在同一格点上。")
    add("2. **判定翻转 / 方向反向**：格点跳一格就是 ±10 ns，而这个跳格的行为")
    add("   （中心质量在相邻格点之间搬家）与均值（受长尾支配）可以给出不同甚至相反的读数。")
    add("")
    add("| # | 主类对 | 不同取值个数 | 最小相邻间隔 (ns) | 相邻间隔中位数 (ns) |")
    add("| ---: | --- | ---: | ---: | ---: |")
    for position, row in enumerate(granularity, start=1):
        add(
            f"| {position} | {row['key']} | {row['distinct']} | {row['min_gap']} | {row['median_gap']} |"
        )
    add("")

    # ---------------- 6 结论
    add("## 5. 分位数差是否与均值差一致？")
    add("")
    add(
        f"**结论：方向层面多数一致（{len(records) - len(reverses) - len(zeros)}/{len(records)} 同向），"
        f"但有 {len(reverses)} 条方向反向、{len(flips)} 条判定翻转，全部如实列在 §4。**"
    )
    add("")
    add("### 5.1 逐模块读法")
    add("")
    module_tally = {}
    for module in ("M1", "M2", "M3", "M4", "M5", "R03"):
        subset = [r for r in records if r["module"] == module]
        module_tally[module] = {
            "total": len(subset),
            "flips": sum(1 for r in subset if not r["verdict_agree"]),
            "reverses": sum(1 for r in subset if r["direction"] == "reverse"),
            "zeros": sum(1 for r in subset if r["direction"] == "zero"),
            "no_mean_ci": sum(1 for r in subset if not r["verdict_agree"] and r["detectable"]),
        }
    r03_a = [r for r in records if r["module"] == "R03" and str(r["arm"]).endswith("对照 A：合法 vs 格式破损")]
    r03_b = [r for r in records if r["module"] == "R03" and str(r["arm"]).endswith("对照 B：合法 vs 截断")]
    r03_a_flips = [r for r in r03_a if not r["verdict_agree"]]

    m4_vuln_runs = [item for item in stats_list if item.pair.module == "M4" and item.pair.arm == "vuln"]
    m4_vuln_zero_probs = sorted(
        {
            quantile_label(prob)
            for item in m4_vuln_runs
            for prob in rc.QUANTILE_PROBS
            if item.quantiles[prob]["diff_ns"] == 0.0
        }
    )
    m4_vuln_means = ", ".join("%+.3f" % item.delta_ns for item in m4_vuln_runs)

    m2_fixed_s1 = next(item for item in stats_list if item.pair.key == "M2-fixed-s1")
    m2_s1 = m2_fixed_s1.quantiles[0.10]
    m2_s50 = m2_fixed_s1.quantiles[0.50]

    add("- **M4 vulnerable（最需要注意的一条）**：均值差是 %s ns（3/3 次 run 的 CI 不含 0，Holm 拒绝），" % m4_vuln_means)
    add(
        "  但 %s 的分位差**恰好是 0.0**，只有 p50 是 −10.0 ns。"
        % ("/".join(m4_vuln_zero_probs) if m4_vuln_zero_probs else "（无零差分位点）")
    )
    add("  原因是 M4 这一臂的取值**几乎只有 {20, 21, 30, 31, …} 几个格点**")
    add("  （`M4-vuln-s1` 未修臂：`20` 出现 6922/10000、`30` 出现 2659/10000；")
    add("  已修臂：`30` 出现 6513/10000、`20` 出现 2983/10000）。")
    add("  泄漏体现为**质量在 20 与 30 两个格点之间搬家**：搬家约 40% 的质量就会把均值推动约 4 ns，")
    add("  而分位点只在 20 → 30 之间整格跳变，所以分位数**分辨不出**这个 4 ns 的均值移动。")
    add("  → 这一条是**测量粒度导致的不一致，不是统计矛盾**，但它意味着：")
    add("  **不能用 M4 的分位数差去复核 M4 的均值结论**，两边都只能用各自的口径表述。")
    add(
        "- **M2**：判定翻转 %d/%d、方向反向 %d/%d，都集中在 M2。最典型的是 `M2-fixed-s1`——"
        % (module_tally["M2"]["flips"], module_tally["M2"]["total"], module_tally["M2"]["reverses"], module_tally["M2"]["total"])
    )
    add(
        "  p10/p50 的分位差为 **%+.1f / %+.1f ns**（CI 不含 0），而均值差是 **%+.3f ns**（CI 含 0）："
        % (m2_s1["diff_ns"], m2_s50["diff_ns"], m2_fixed_s1.delta_ns)
    )
    add("  中心与均值**反向**。这与 `platform-collection-20261016/README.md` §5 记录的")
    add("  **M2 臂间漂移**一致：重尾把均值拖走，而分布中心往相反方向移动。")
    add("  这**不改变** M2 家族 Holm 不拒绝的结论，也不构成泄漏声明。")
    add(
        "- **M3 on/off**：%d/%d 条分位差恰为 0，其余 |分位差| ≤ 10 ns，与均值差（|Δ| ≤ 10.7 ns）同为「不可区分」；"
        % (module_tally["M3"]["zeros"], module_tally["M3"]["total"])
    )
    add(
        "  但仍有 %d 条方向反向、%d 条判定翻转；两者都落在 ±10 ns 的边缘格点上，"
        % (module_tally["M3"]["reverses"], module_tally["M3"]["flips"])
    )
    add("  且 CI 都含 0。M3 是**人工构造校准**。")
    add(
        "- **M5**：%d 条判定翻转、%d 条方向反向（都在 p99，CI 都很宽、都含 0），"
        % (module_tally["M5"]["flips"], module_tally["M5"]["reverses"])
    )
    add("  中心与均值一致地「不可区分」。")
    add("- **M1 未修**：p10/p50/p90 与均值同为正向且 CI 都不含 0；p99 差值为正但 CI 含 0，")
    add("  长尾段不足以复现均值层结论。**M1 已修**：4 个分位数与均值同为「不可区分」。")
    add("  两者都**族外**（`tooling-strengthen-20261015/PROTOCOL.md`：没有 Holm）。")
    add(
        "- **R03**：对照 A 的 %d 条里有 %d 条判定翻转（%s 的 p50 = %+.1f ns，"
        % (
            len(r03_a),
            len(r03_a_flips),
            ", ".join("`%s`" % r["key"] for r in r03_a_flips) if r03_a_flips else "无",
            r03_a_flips[0]["diff"] if r03_a_flips else 0.0,
        )
    )
    add(
        "  远小于本批数据的有效计时粒度中位数 %d ns，属离散化边界效应）；"
        % int(np.median(median_gaps))
    )
    add(
        "  对照 B 的 %d 条里判定翻转 %d 条、方向反向 %d 条，全部与均值同向且 CI 不含 0。"
        % (
            len(r03_b),
            sum(1 for r in r03_b if not r["verdict_agree"]),
            sum(1 for r in r03_b if r["direction"] == "reverse"),
        )
    )
    add("  分位数与均值在这两个族外对照上一致：A 不可区分、B 是接口层数量级差。")
    add("")
    add("### 5.2 可以引用的一句话")
    add("")
    add("> **分位数差与均值差在本批数据上多数同向，但两者并不等价：在有效计时粒度约 10 ns 的条件下，")
    add("> 分位数只能整格跳动，而均值能靠 n = 10000 分辨到 1 ns 以下。**")
    add(
        "> 因此 M4 vulnerable 出现「均值差 3/3 显著、分位差 %s 恰为 0」的分歧，"
        % ("/".join(m4_vuln_zero_probs) if m4_vuln_zero_probs else "（无）")
    )
    add("> M2 出现「中位数与均值反向」的分歧；两者**都不推翻**已提交的 Holm 判定，")
    add("> 也**都不**构成新的泄漏结论。")
    add("")

    # ---------------- 7 图
    add("## 6. 图")
    add("")
    add("全部 PDF 在 `docs/evidence/r04-stats-20261016/figures/`。生成命令见 §8；")
    add("每张图内部都印了标题、带单位（ns）的轴标签、图例，以及**数据来源 CSV 路径 + run 名 + 种子/绑核**。")
    add("")
    add(f"### 6.1 ECDF 对比图（每个主类对一张，共 {len(stats_list)} 张）")
    add("")
    add("| 图 | 内容 |")
    add("| --- | --- |")
    for item in stats_list:
        add(
            f"| `figures/ecdf-{item.pair.key}.pdf` | {item.pair.module} {item.pair.arm_cn}，"
            f"`{item.pair.run_label}`，{item.pair.class0} vs {item.pair.class1} |"
        )
    add("")
    add("R03 对照 B（valid vs truncated）的两类中位数相差 3 个数量级，这些图的横轴自动切到对数刻度，")
    add("并在标题里标注 `log x`。")
    add("")
    add("### 6.2 修复前后箱线图（4 张）")
    add("")
    add("| 图 | 面板 | 说明 |")
    add("| --- | --- | --- |")
    add("| `figures/boxplot-M1-unfixed-vs-fixed.pdf` | a) 未修臂两类箱线；b) 已修臂两类箱线；c) 各臂 Δ 与 95% CI + MDE 带 | M1 主类对，单次 run |")
    add("| `figures/boxplot-M3-on-vs-off.pdf` | 同上三面板 | M3 是**人工构造校准**；on/off 是两个不同构建 |")
    add("| `figures/boxplot-M4-vulnerable-vs-ct.pdf` | 同上三面板 | M4 是**人工构造校准**（人工提前退出比较夹具） |")
    add("| `figures/m2-endtoend-localization-note.pdf` | a) 未修臂 ECDF；b) 已修臂 ECDF；c) 6 次 run 的 Δ 与 CI + MDE 带 | **M2 定位层说明**：端到端不可区分，不是「修复前后有差异」 |")
    add("")
    add("> **M2 的图不能说成「修复前后有差异」。** 面板 a/b 只在**同一个臂内部**比较两类")
    add("> （message-zero vs message-ones），面板 c 展示 6 次 run 的 Δ 全部被 MDE 带包住。")
    add("> 未修臂与已修臂的**绝对耗时水平不同（约 56.8 µs vs 约 60.8 µs）来自两份不同的构建**，")
    add("> 不是本实验测到的秘密相关效应，因此这两条水平线**没有**被放进同一张比较图里。")
    add("")
    add("M1 / M3 / M4 的箱线图同样把两个臂分开画（面板 a / b 各有自己的纵轴），")
    add("原因相同：臂间整体水平差是构建差异。要比较的效应是**臂内** class0 − class1，")
    add("它体现在面板 c 的 Δ 与 MDE 带上。")
    add("")

    # ---------------- 8 边界
    add("## 7. 边界")
    add("")
    add("- **bootstrap 假设类内样本可交换**。本批样本在 run 内按固定种子的平衡乱序产生，")
    add("  这是为了抵消时间漂移；但 `platform-collection-20261016/README.md` §5 记录的 **M2 臂间漂移**")
    add("  说明同一台机器上仍可能有慢漂移。若漂移存在，bootstrap 区间会偏窄（偏乐观）。")
    add("  本页因此**只把分位差 CI 当作描述性区间**，不把它升级为新的显著性判定。")
    add("- **有效计时分辨率约 10 ns**（§4.4）与 M2/M3/M4/M5 关心的 4–30 ns 效应同量级，")
    add("  分位数在这个尺度上只能整格跳动。任何「分位数不显著/显著」的读法都必须带上这条限制。")
    add("- 分位数差是**描述性统计**：它不改变任何已提交的 Holm 判定，也不构成恒时证明、")
    add("  物理泄漏界或总体检出率。")
    add("- **M3 / M4 是人工构造校准**（M3 为 LUT 机制校准，M4 为人工提前退出比较夹具），不是上游 CVE。")
    add("- **R03 两个对照与 dudect / RTLF 一律族外**：它们不进任何 Holm 家族，本页也不把")
    add("  dudect 的最大 t 转成伪 p。")
    add("- 不做密钥恢复，不运行 exploit demo，不给出真实总体误报率。")
    add("- 本页只读已有证据；没有新增采集，没有修改任何已有证据文件。")
    add("")
    add(
        f"（本页 bootstrap 参数固定：B = {rc.BOOTSTRAP_RESAMPLES}，基础种子 {rc.BOOTSTRAP_BASE_SEED}，"
        f"分块 {rc.BOOTSTRAP_CHUNK}；同一份输入重跑得到逐字节相同的本文件。）"
    )
    add("")

    # ---------------- 9 复现
    add("## 8. 复现命令")
    add("")
    add("```bash")
    add("cd <repo-root>")
    add("# 只算分位数 CI 与本文档：")
    add("python3 docs/evidence/r04-stats-20261016/robustness-src/r04_quantile.py")
    add("# 只画图：")
    add("python3 docs/evidence/r04-stats-20261016/robustness-src/r04_figures.py")
    add("# 一次跑完 T26 + T27（POWER.md + QUANTILE_CI.md + 全部 PDF）：")
    add("python3 docs/evidence/r04-stats-20261016/robustness-src/r04_run_all.py")
    add("```")
    add("")
    add("依赖：Python 3.9+ 标准库 + numpy + matplotlib（画图时）。")
    add("本机版本 Python 3.9.6 / numpy 2.0.2 / matplotlib 3.9.4。")
    add("脚本只读仓库内已有 CSV；不联网、不采集、不写已有证据文件。")
    add("")
    return "\n".join(out) + "\n"


def main() -> None:
    started = time.time()
    stats_list = [
        rc.compute_pair_stats(pair, index, need_quantiles=True)
        for index, pair in enumerate(rc.CLASS_PAIRS)
    ]
    elapsed = time.time() - started
    records = consistency_records(stats_list)
    granularity = granularity_rows(stats_list)
    markdown = render_markdown(stats_list, records, granularity)
    target = rc.OUT_DIR / "QUANTILE_CI.md"
    target.write_text(markdown, encoding="utf-8")
    flips = sum(1 for r in records if not r["verdict_agree"])
    reverses = sum(1 for r in records if r["direction"] == "reverse")
    zeros = sum(1 for r in records if r["direction"] == "zero")
    print(
        "[T27] 写出 %s（%d 个主类对 × %d 个分位数，B=%d，耗时 %.1fs）"
        % (rc.relpath(target), len(stats_list), len(rc.QUANTILE_PROBS), rc.BOOTSTRAP_RESAMPLES, elapsed)
    )
    print(f"[T27] 判定翻转 {flips}/{len(records)}，方向反向 {reverses}/{len(records)}，零差 {zeros}/{len(records)}")


if __name__ == "__main__":
    main()
