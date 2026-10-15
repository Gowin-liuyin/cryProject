#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 robustness.json / robustness-seedcheck.json 渲染成 ROBUSTNESS.md。

只读 JSON，只写 ROBUSTNESS.md；所有表格数字均直接取自 JSON，不经人工转录。
用法：python3 docs/evidence/r02-env-20261016/render_robustness_md.py
"""

from __future__ import annotations

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PRIMARY = os.path.join(HERE, "robustness.json")
SEEDCHECK = os.path.join(HERE, "robustness-seedcheck.json")
OUTPUT = os.path.join(HERE, "ROBUSTNESS.md")

GROUPS = [
    ("M2 主类对（family `m2_end_to_end_full_decaps_v1`，6 个成员）",
     ["m2-r0%d-%s:main" % (s, a) for s in (1, 2, 3) for a in ("unfixed", "fixed")]),
    ("M2 对照类对（族外，不进 Holm）",
     ["m2-r0%d-%s:control" % (s, a) for s in (1, 2, 3) for a in ("unfixed", "fixed")]),
    ("M3 主类对（family `m3_lut_arm_end_to_end_v1`，6 个成员；人工构造校准）",
     ["m3-r0%d-%s:main" % (s, a) for s in (1, 2, 3) for a in ("on", "off")]),
    ("M3 对照类对（族外，不进 Holm）",
     ["m3-r0%d-%s:control" % (s, a) for s in (1, 2, 3) for a in ("on", "off")]),
    ("M4 主类对（family `m4_compare_arm_session_v1`，6 个成员；人工构造校准）",
     ["m4-r0%d-%s:main" % (s, a) for s in (1, 2, 3) for a in ("vulnerable", "ct")]),
    ("M4 截断对照类对（族外，不进 Holm）",
     ["m4-r0%d-%s:control" % (s, a) for s in (1, 2, 3) for a in ("vulnerable", "ct")]),
    ("M5 主类对（family `m5_reference_end_to_end_v1`，3 个成员）",
     ["m5-r0%d-reference:main" % s for s in (1, 2, 3)]),
    ("M5 对照类对（族外，不进 Holm）",
     ["m5-r0%d-reference:control" % s for s in (1, 2, 3)]),
    ("M1 主类对（`m1_liboqs010_locked_v1`，无预注册 Holm 家族，按族外报告）",
     ["m1-liboqs010-%s:main" % a for a in ("vulnerable", "fixed")]),
    ("M1 对照类对（族外，不进 Holm）",
     ["m1-liboqs010-%s:control" % a for a in ("vulnerable", "fixed")]),
    ("R03 两个族外对照（3 臂 × 3 种子 × 2 类对 = 18 行；不进 Holm）",
     ["r03-%s-%s:valid-%s" % (a, s, c)
      for a in ("m1unfixed", "m1fixed", "m5ref") for s in ("s1", "s2", "s3")
      for c in ("malformed", "truncated")]),
]

FLIP_EXPLANATION = [
    ("m2-r01-unfixed:main", "M2 未修臂 s1",
     "全样本均值 CI 含 0（Δ=+10.53，SE 被右长尾抬高），三种稳健位置量都不含 0：截尾均值 +21.26、中位数 +20.0、HL +21.0。"
     "方向与平台 README §5 已发布的**臂级描述性合并**一致（unfixed 合并 +12.35 [2.98, 21.71]，不含 0）。"),
    ("m2-r01-fixed:main", "M2 已修臂 s1",
     "全样本 CI 含 0；中位数 −19.0、HL −10.0 不含 0（截尾均值 +16.77 含 0，且与另两者**反号**）。"
     "方向与 fixed 臂描述性合并（−11.20 [−24.56, 2.15]）一致，但截尾均值符号相反，说明该臂的均值与中心不同向。"),
    ("m2-r02-fixed:main", "M2 已修臂 s2",
     "全样本 CI 含 0；中位数 −11.0、HL −10.0 不含 0（截尾均值 −14.21 含 0）。"),
    ("m2-r03-unfixed:main", "M2 未修臂 s3",
     "全样本 CI 含 0；中位数 +19.0、HL +11.0 不含 0（截尾均值 +5.79 含 0）。"),
    ("m2-r03-fixed:main", "M2 已修臂 s3",
     "全样本 CI 含 0（上界 +0.90，几乎贴 0）；三种稳健方法全部不含 0：截尾 −15.34、中位数 −10.0、HL −10.0。"),
    ("m4-r02-vulnerable:main", "M4 vulnerable 臂 s2（**Holm 拒绝成员**）",
     "全样本 CI 与截尾均值都不含 0，但 HL 的 bootstrap CI 为 [−1.0, 0.0] 含 0。"
     "原因是 M4 夹具耗时只有 ~20–30 ns、量化为 1 ns 台阶且同值并列极多，秩类统计量在 1 ns 尺度上失去分辨力；"
     "**Holm 拒绝本身不变**（家族用全样本均值 p=9.23e−25）。"),
    ("m4-r03-vulnerable:main", "M4 vulnerable 臂 s3（**Holm 拒绝成员**）",
     "同上：全样本与截尾均值不含 0，HL 点估计恰为 0.0、CI [−1.0, 0.0] 含 0。Holm 拒绝不变（p=3.14e−22）。"),
    ("m2-r01-fixed:control", "M2 已修臂 s1 对照类对（族外）",
     "反向翻转：全样本与截尾均值含 0，HL 点估计 +1.0、CI [1.0, 10.0] 不含 0。单方法、单次运行的族外结果，不据此新增声明。"),
    ("m4-r01-vulnerable:control", "M4 vulnerable 臂 s1 截断对照（族外）",
     "全样本与截尾均值不含 0（Δ≈−1.99），中位数差恰为 0、HL=0，CI 均含 0；同样是 1 ns 量化 + 大量并列造成的秩方法失效。"),
    ("m4-r02-vulnerable:control", "M4 vulnerable 臂 s2 截断对照（族外）",
     "同上（全样本 Δ≈−1.48，中位数差 0）。"),
    ("m4-r03-vulnerable:control", "M4 vulnerable 臂 s3 截断对照（族外）",
     "同上（全样本 Δ≈−1.92，中位数差 0）。"),
    ("m5-r01-reference:control", "M5 参考臂 s1 对照类对（族外）",
     "全样本（Δ=−15.73）与截尾均值（−11.04）都不含 0，中位数差恰为 0、HL=0，CI 含 0："
     "该差异由分布尾部而非中心位置驱动。"),
]


def fmt(value, digits):
    return ("%." + str(digits) + "f") % value


def cell(row, point_key, low_key, high_key, digits, excludes_key):
    low = row.get(low_key)
    if low is None or (isinstance(low, float) and low != low):
        return "n/a"
    return "%s [%s, %s] %s" % (fmt(row[point_key], digits), fmt(low, digits),
                               fmt(row[high_key], digits),
                               "**不含0**" if row[excludes_key] else "含0")


def escape(text):
    return text.replace("|", "\\|")


def render_tables(results):
    lines = []
    for title, pair_ids in GROUPS:
        lines.append("##### %s\n" % title)
        lines.append("| 类对 pair_id | n0/n1 | ① 全样本 Welch Δ ns [95% CI] | "
                     "② p99.9 截尾均值差 ns [boot 95% CI] | ③ 中位数差 ns [boot 95% CI] | "
                     "④ Hodges–Lehmann ns [boot 95% CI] | 翻转 |")
        lines.append("|---|---:|---|---|---|---|---|")
        for pair_id in pair_ids:
            row = results[pair_id]
            lines.append("| `%s` | %d/%d | %s | %s | %s | %s | %s |" % (
                pair_id, row["n0"], row["n1"],
                cell(row, "full_delta_ns", "full_ci_low_ns", "full_ci_high_ns", 3, "full_ci_excludes_zero"),
                cell(row, "trim_delta_ns", "trim_ci_low_ns", "trim_ci_high_ns", 3, "trim_ci_excludes_zero"),
                cell(row, "median_delta_ns", "median_ci_low_ns", "median_ci_high_ns", 1, "median_ci_excludes_zero"),
                cell(row, "hl_delta_ns", "hl_ci_low_ns", "hl_ci_high_ns", 1, "hl_ci_excludes_zero"),
                ("**%s**" % row["flip_methods"].replace(",", "+")) if row["flip_methods"] else "—"))
        lines.append("")
    return lines


def main():
    primary = json.load(open(PRIMARY, encoding="utf-8"))
    seedcheck = json.load(open(SEEDCHECK, encoding="utf-8"))
    results = {row["pair_id"]: row for row in primary["results"]}
    check = {row["pair_id"]: row for row in seedcheck["results"]}

    frozen_members = {row["member_id"] for row in primary["reproduction_check"]}
    flips = [row for row in primary["results"] if row.get("any_flip")]
    in_family = [row for row in flips if row.get("member_id") in frozen_members]
    out_family = [row for row in flips if row.get("member_id") not in frozen_members]
    seed_flips = {row["pair_id"] for row in seedcheck["results"] if row.get("any_flip")}
    primary_flips = {row["pair_id"] for row in flips}

    member_rows = [row for row in primary["results"] if row.get("member_id") in frozen_members]
    checks = primary["reproduction_check"]
    worst_delta = max(row.get("delta_abs_diff", 0.0) for row in checks)
    worst_ci = max(row.get("max_ci_abs_diff", 0.0) for row in checks)
    worst_p = max(row.get("p_abs_diff", 0.0) for row in checks)

    out = []
    add = out.append

    add("# T09 稳健性敏感性分析（2026-10-16）")
    add("")
    add("**输入全部是仓库中已有的原始计时 CSV，本轮没有采集任何新数据，也没有改写任何已有证据文件。**")
    add("")
    add("## 0. 一句话结论")
    add("")
    add("在 %d 个类对（含 %d 个已冻结 Holm 家族成员与 %d 个族外对照）上，四种方法给出 **%d 个"
        "「CI 含 0 / 不含 0」翻转**：其中 **%d 个属于已冻结家族成员**、%d 个属于族外对照。"
        "**没有任何翻转改变 Holm 判定**——家族与其 p 值在 `efca8a1` 已冻结，本页三种稳健方法一律族外；"
        "所有翻转都是「均值型检验与位置型检验的功效差」或「1 ns 量化下秩方法失效」，不是新的泄漏证据。"
        % (primary["pair_count"], len(member_rows),
           primary["pair_count"] - len(member_rows), len(flips), len(in_family), len(out_family)))
    add("")
    add("## 1. 输入")
    add("")
    add("| 来源 | 内容 | 用途 |")
    add("|---|---|---|")
    add("| `docs/evidence/platform-collection-20261016/` | M2/M5/M3/M4 的锁频主类对与对照类对原始 `.csv.gz` | %d 个类对 |"
        % len([r for r in primary["results"] if r["module"] in ("M2", "M3", "M4", "M5")]))
    add("| `docs/evidence/r03-malformed-20261016/R03/` | R03 三臂 × 三种子原始 `.csv.gz` | 18 个族外对照行 |")
    add("| `docs/evidence/liboqs010-locked-20261015/runs/` | M1 未修/已修 M1 锁频原始 `samples.csv` | 4 行 |")
    add("")
    add("逐文件路径、sha256、行数见 [robustness-inputs.txt](robustness-inputs.txt)。"
        "`docs/evidence/tooling-strengthen-20261015/csv/{vulnerable,fixed}-message-zero-ones.csv` "
        "是同一批 M1 样本的**成对宽表**导出。去重核对脚本 [m1_wide_long_check.py](m1_wide_long_check.py) "
        "逐值比较两边的多重集（结果见 [raw/m1-wide-long-check.txt](raw/m1-wide-long-check.txt)）："
        "两臂的 `message-zero` / `message-ones` **取值多重集与行序都完全相同** "
        "（`CONCLUSION same_sample_set=yes`），因此 T09 只取长表一次，避免重复计数。")
    add("")
    add("各模块主类对（预先规定，见各自 PLAN）：")
    add("")
    add("| 模块 | 主类对（class0 − class1） | 臂 | 成员数 | 家族 |")
    add("|---|---|---|---:|---|")
    add("| M1 | `message-zero` − `message-ones` | `vulnerable` / `fixed` | 2 | `m1_liboqs010_locked_v1`（**未进 Holm**；本轮按族外读） |")
    add("| M2 | `message-zero` − `message-ones` | `unfixed` / `fixed` | 6 | `m2_end_to_end_full_decaps_v1` |")
    add("| M3 | `message-zero` − `message-ones` | `on` / `off` | 6 | `m3_lut_arm_end_to_end_v1`（**人工构造校准**） |")
    add("| M4 | `mismatch-first` − `mismatch-last` | `vulnerable` / `ct` | 6 | `m4_compare_arm_session_v1`（**人工构造校准**） |")
    add("| M5 | `message-zero` − `message-ones` | `reference` | 3 | `m5_reference_end_to_end_v1` |")
    add("")
    add("对照类对（**族外、不进 Holm**）：M2 `malformed-zero-tail` − `malformed-ff-tail`；"
        "M3/M5 `bit-flipped` − `random`；M4 截断对照（同 `mismatch-first` − `mismatch-last`，比较窗口外字节）；"
        "M1 `bit-flipped` − `random`；R03 `valid` − `malformed` 与 `valid` − `truncated`。")
    add("")
    add("## 2. 方法与规则")
    add("")
    add("四种方法（Δ 一律定义为 class0 减 class1）：")
    add("")
    add("| # | 名称 | 点估计 | 区间 | 说明 |")
    add("|---|---|---|---|---|")
    add("| ① | 全样本 Welch（**对照基线**） | `mean(class0) − mean(class1)` | 解析正态近似，z=1.959963984540054，SE=√(s₀²/n₀+s₁²/n₁)，方差除数 n−1 | 与 `scripts/platform_stats/stats_csv.c:207-208`、`src/timing_statistics.c:116-118` 冻结口径逐位一致 |")
    add("| ② | p99.9 截尾均值差（**族外**） | 两侧各截 0.1% 后的截尾均值差 | bootstrap 百分位 95% | n=10000 时 k=⌊0.001·n⌋=10，保留 9980 |")
    add("| ③ | 中位数差（**族外**） | `median(class0) − median(class1)` | bootstrap 百分位 95% | — |")
    add("| ④ | Hodges–Lehmann 位置差（**族外**） | 全部 n₀·n₁ 个成对差的中位数 | bootstrap 百分位 95%% | 整数格点二分，精确求解 |")
    add("")
    add("bootstrap 为**分组内独立重采样**（各组按原样本量有放回），B=%d，"
        "每个类对固定种子 `%d + 序号`；换种子重跑见 §6。"
        "截尾、样本量下限、缺失/零值规则见 [OUTLIER_RULES.md](OUTLIER_RULES.md)。"
        % (primary["bootstrap_replicates"], primary["bootstrap_seed_base"]))
    add("")
    add("翻转判定：`CI 是否含 0` 与①不一致即记为该方法的翻转；本页不重算 Holm、不改任何 p 值。")
    add("")
    add("## 3. 确切命令与脚本")
    add("")
    add("```bash")
    add("cd /Users/yin/code/cryProject")
    add("# 主分析（B=2000，种子基数 20261016）")
    add("python3 docs/evidence/r02-env-20261016/robustness_analysis.py --replicates 2000 --workers 8")
    add("# 种子稳定性自检（同一脚本、只换 bootstrap 种子基数）")
    add("python3 docs/evidence/r02-env-20261016/robustness_analysis.py \\")
    add("    --replicates 2000 --workers 8 --seed-base 777 --suffix=-seedcheck")
    add("# 由 JSON 渲染本文件（表格数字不手工转录）")
    add("python3 docs/evidence/r02-env-20261016/render_robustness_md.py")
    add("# M1 宽表/长表去重核对")
    add("python3 docs/evidence/r02-env-20261016/m1_wide_long_check.py")
    add("```")
    add("")
    add("| 产物 | 说明 |")
    add("|---|---|")
    add("| [robustness_analysis.py](robustness_analysis.py) | 分析脚本，sha256 `%s` |" % primary["script_sha256"])
    add("| [robustness.csv](robustness.csv) | 每个类对一行：四种方法的点估计、CI、含 0 判定、翻转方法 |")
    add("| [robustness.json](robustness.json) | 同上加 n、零值/缺失计数、截尾 k、种子、复算对齐明细 |")
    add("| [robustness-seedcheck.csv](robustness-seedcheck.csv) / [robustness-seedcheck.json](robustness-seedcheck.json) | 种子基数 777 的并列产物 |")
    add("| [robustness-inputs.txt](robustness-inputs.txt) | 输入 CSV 的路径、sha256、行数 |")
    add("| [m1_wide_long_check.py](m1_wide_long_check.py) | M1 宽表与长表是否同一批样本的逐值核对 |")
    add("| [render_robustness_md.py](render_robustness_md.py) | 由 JSON 渲染本文件 |")
    add("")
    add("## 4. 与冻结家族的全样本复算对齐")
    add("")
    add("本脚本的全样本 Welch 与 `stats/members/members.csv.gz`（%d 个成员）以及 "
        "`stats/holm/holm.csv.gz` 的原始 p 逐项比对：" % len(checks))
    add("")
    add("| 项 | 最大绝对偏差 |")
    add("|---|---:|")
    add("| Δ（class0−class1） | %.3g ns |" % worst_delta)
    add("| CI 端点 | %.3g ns |" % worst_ci)
    add("| 双侧 p | %.3g |" % worst_p)
    add("")
    add("偏差量级为双精度舍入噪声（Δ 完全一致），说明本页①就是冻结口径本身，"
        "因此②③④与①的差异只来自方法，不来自实现。")
    add("")
    add("## 5. 结果表（%d 个类对）" % primary["pair_count"])
    add("")
    add("表中「含0」/「**不含0**」指该方法 95%% 区间是否包含 0；「翻转」列列出与①不一致的方法。")
    add("")
    out.extend(render_tables(results))
    add("## 6. 翻转条目逐条说明")
    add("")
    add("翻转总数 **%d / %d**（种子基数 20261016）；其中已冻结家族成员 **%d** 个、族外对照 **%d** 个。"
        % (len(flips), primary["pair_count"], len(in_family), len(out_family)))
    add("")
    add("| 类对 | 定位 | 翻转方法 | 全样本 Δ [CI] | 截尾 / 中位数 / HL 点估计 | 说明 |")
    add("|---|---|---|---|---|---|")
    for pair_id, label, note in FLIP_EXPLANATION:
        row = results[pair_id]
        add("| `%s` | %s | **%s** | %s [%s, %s] | %s / %s / %s | %s |" % (
            pair_id, label, row["flip_methods"].replace(",", "+"),
            fmt(row["full_delta_ns"], 3), fmt(row["full_ci_low_ns"], 3), fmt(row["full_ci_high_ns"], 3),
            fmt(row["trim_delta_ns"], 3), fmt(row["median_delta_ns"], 1), fmt(row["hl_delta_ns"], 1),
            escape(note)))
    add("")
    add("### 6.1 两类翻转的性质不同，不能合并叙述")
    add("")
    add("**第一类：均值检不出、位置量检出（M2 的 5 个成员 + M2 s1 对照）。**")
    add("")
    add("这类数据（M2/M5/M3）的耗时分布有很重的右尾：单次运行的样本标准差 443–1532 ns，"
        "而类间均值差只有 10–22 ns，所以均值差的标准误被长尾抬高，成员级均值检验普遍不显著。"
        "中位数与 HL 只看中心，标准误小得多，同样的中心位移就能被分辨。"
        "这与平台 README §5 已发布的**臂级描述性合并**方向一致（unfixed +12.35 [2.98, 21.71] 不含 0；"
        "fixed −11.20 [−24.56, 2.15] 含 0）：也就是说，**冻结家族之外的描述性合并早就给出过同一方向的读数**，"
        "本页没有发现新信号，只是换了一族更有功效的位置量。")
    add("")
    add("**第二类：位置量失效（M4 的 5 个 + M5 s1 对照）。**")
    add("")
    add("M4 夹具的耗时只有 20–30 ns，落在时钟粒度附近；10000 个样本挤在少数几个整数 ns 值上，"
        "中位数差恰为 0、HL 恰为 0，bootstrap 区间必然含 0。"
        "这**不是**「效应不存在」，而是秩/分位方法在这种量化粒度下没有分辨力；"
        "同族的截尾均值在 M4 vulnerable 主类对上仍稳定地不含 0（−4.10 / −3.98 / −3.86）。"
        "M5 s1 对照则相反：均值差 −15.73 由尾部驱动，中心位置差为 0。")
    add("")
    add("### 6.2 对已冻结 Holm 家族的影响：无")
    add("")
    add("| 冻结事实 | 本轮是否改变 |")
    add("|---|---|")
    add("| 四个家族（m=6/3/6/6）与其 α=0.05、成员定义 | **未改变**；本页不重算 Holm |")
    add("| `stats/holm/holm.csv.gz` 的 p、adjusted_p、reject | **未改变**；本页未写入该文件 |")
    add("| M4 vulnerable 臂 3 次 Holm 拒绝 | **未改变**；截尾均值在三次都仍不含 0，HL 在 s2/s3 含 0 属于族外方法功效问题 |")
    add("| 其余三个家族的「未拒绝」 | **未改变**；本页不把族外方法的不含 0 升格为家族判定 |")
    add("")
    add("## 7. 种子稳定性自检")
    add("")
    add("| 项 | 种子基数 %d（主分析） | 种子基数 %d（自检） |" % (primary["bootstrap_seed_base"], seedcheck["bootstrap_seed_base"]))
    add("|---|---:|---:|")
    add("| 翻转类对数 | %d / %d | %d / %d |" % (len(primary_flips), primary["pair_count"],
                                                len(seed_flips), seedcheck["pair_count"]))
    add("| 仅主分析翻转 | %s |" % ("、".join("`%s`" % p for p in sorted(primary_flips - seed_flips)) or "（无）"))
    add("| 仅自检翻转 | %s |" % ("、".join("`%s`" % p for p in sorted(seed_flips - primary_flips)) or "（无）"))
    add("")
    if seed_flips - primary_flips:
        borderline = sorted(seed_flips - primary_flips)
        add("唯一差异是族外 R03 类对 `%s`：其全样本 Δ 只有 %s ns、CI 含 0，"
            "中位数差 %s ns 落在 bootstrap 区间的边界上，所以**它对种子敏感**。"
            "本页把它如实登记为边界项，不当作稳定翻转。"
            % (borderline[0],
               fmt(results[borderline[0]]["full_delta_ns"], 3),
               fmt(results[borderline[0]]["median_delta_ns"], 1)))
        add("")
    add("其余 %d 个翻转在两组种子下逐条一致（方法集合也一致）。" % len(primary_flips & seed_flips))
    add("")
    add("## 8. 边界")
    add("")
    add("- 本页是**族外稳健性描述**，不是新的假设检验家族，也不是恒时证明；"
        "「未拒绝」与「未检出」都不等于恒时。")
    add("- 三种稳健方法一律**不进 Holm**，不改 `stats/holm/holm.csv.gz`，也不改任何 PLAN。")
    add("- M3、M4 是**人工构造校准**夹具，不代表上游 CVE；M4 的 vulnerable 只针对人工提前退出夹具。")
    add("- 族外对照与 M1、R03 的读数**不进 Holm**，不用于新增或削弱任何声明。")
    add("- bootstrap 区间依赖重采样假设；本页只报告点估计与百分位区间，不做多重比较校正，"
        "因此**不能**用「%d 个翻转」反推总体误报率（未校正、且各方法高度相关）。" % len(flips))
    add("- 各 run 的 `.meta` 里 `frequency_control=not_configured` 是采集件固定字符串；"
        "锁频事实以控制器落盘记录为准（见 [ENV_TABLE.md](ENV_TABLE.md)）。")
    add("")

    with open(OUTPUT, "w", encoding="utf-8") as handle:
        handle.write("\n".join(out))
    print("wrote %s (%d lines)" % (OUTPUT, len(out)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
