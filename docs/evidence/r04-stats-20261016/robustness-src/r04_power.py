"""T26 功效分析 / MDE：只读已有证据 CSV，输出 `docs/evidence/r04-stats-20261016/POWER.md`。

运行（在仓库根目录）：
    python3 docs/evidence/r04-stats-20261016/robustness-src/r04_power.py

不重新采集、不修改任何已有证据文件、不做密钥恢复。
"""

from __future__ import annotations

import csv
import gzip
import json
from pathlib import Path

import numpy as np

import r04_common as rc


# ---------------------------------------------------------------- 交叉核对

def load_members_table() -> dict[str, dict[str, str]]:
    path = rc.PLATFORM_DIR / "stats" / "members" / "members.csv.gz"
    with gzip.open(path, "rt", newline="") as handle:
        rows = list(csv.DictReader(handle))
    return {row["member_id"]: row for row in rows}


MEMBER_ID_BY_KEY = {}
for _seed_tag, _index in (("s1", 1), ("s2", 2), ("s3", 3)):
    MEMBER_ID_BY_KEY[f"M2-unfixed-{_seed_tag}"] = f"m2-r0{_index}-unfixed"
    MEMBER_ID_BY_KEY[f"M2-fixed-{_seed_tag}"] = f"m2-r0{_index}-fixed"
    MEMBER_ID_BY_KEY[f"M3-on-{_seed_tag}"] = f"m3-r0{_index}-on"
    MEMBER_ID_BY_KEY[f"M3-off-{_seed_tag}"] = f"m3-r0{_index}-off"
    MEMBER_ID_BY_KEY[f"M4-vuln-{_seed_tag}"] = f"m4-r0{_index}-vulnerable"
    MEMBER_ID_BY_KEY[f"M4-ct-{_seed_tag}"] = f"m4-r0{_index}-ct"
    MEMBER_ID_BY_KEY[f"M5-reference-{_seed_tag}"] = f"m5-r0{_index}-reference"


def cross_check(stats_list: list[rc.PairStats]) -> dict[str, object]:
    """把本脚本重算的量与已提交证据逐项比对，返回核对报告。"""
    members = load_members_table()
    report: dict[str, object] = {
        "members_checked": 0,
        "members_ok": 0,
        "members_mismatch": [],
        "ci_checked": 0,
        "ci_ok": 0,
        "ci_mismatch": [],
        "m1_derived_checked": 0,
        "m1_derived_ok": 0,
        "m1_derived_mismatch": [],
        "m1_documented": [],
    }

    tolerance = 1e-6
    for item in stats_list:
        member_id = MEMBER_ID_BY_KEY.get(item.pair.key)
        if member_id is not None:
            row = members[member_id]
            problems = []
            for field_name, mine, theirs in (
                ("mean0_ns", item.mean0_ns, float(row["mean0_ns"])),
                ("mean1_ns", item.mean1_ns, float(row["mean1_ns"])),
                ("sd0_ns", item.sd0_ns, float(row["sd0_ns"])),
                ("sd1_ns", item.sd1_ns, float(row["sd1_ns"])),
            ):
                if abs(mine - theirs) > tolerance * max(1.0, abs(theirs)):
                    problems.append(f"{field_name}: 本脚本 {mine!r} vs 证据 {theirs!r}")
            if int(row["n0"]) != item.n0 or int(row["n1"]) != item.n1:
                problems.append(f"n: {item.n0}/{item.n1} vs {row['n0']}/{row['n1']}")
            report["members_checked"] += 1
            if problems:
                report["members_mismatch"].append((member_id, problems))
            else:
                report["members_ok"] += 1

        ci_path = rc.ci_json_path(item.pair)
        if ci_path.is_file():
            payload = json.loads(ci_path.read_text())
            problems = []
            if abs(payload["mean_difference_class0_minus_class1_ns"] - item.delta_ns) > 1e-6:
                problems.append(
                    "Δ: 本脚本 %r vs ci_welch %r"
                    % (item.delta_ns, payload["mean_difference_class0_minus_class1_ns"])
                )
            if abs(payload["standard_error_ns"] - item.se_ns) > 1e-6:
                problems.append(
                    "se: 本脚本 %r vs ci_welch %r" % (item.se_ns, payload["standard_error_ns"])
                )
            if payload["class0_count"] != item.n0 or payload["class1_count"] != item.n1:
                problems.append("n 不一致")
            report["ci_checked"] += 1
            if problems:
                report["ci_mismatch"].append((str(ci_path.relative_to(rc.REPO_ROOT)), problems))
            else:
                report["ci_ok"] += 1

        if item.pair.derived_csv:
            derived = rc.REPO_ROOT / item.pair.derived_csv
            with open(derived, "r", newline="") as handle:
                reader = csv.DictReader(handle)
                col0 = [int(row["message-zero"]) for row in reader]
            with open(derived, "r", newline="") as handle:
                reader = csv.DictReader(handle)
                col1 = [int(row["message-ones"]) for row in reader]
            values0, values1 = rc.load_pair(item.pair)
            same = bool(
                np.array_equal(np.sort(np.asarray(col0)), np.sort(values0))
                and np.array_equal(np.sort(np.asarray(col1)), np.sort(values1))
            )
            report["m1_derived_checked"] += 1
            if same:
                report["m1_derived_ok"] += 1
            else:
                report["m1_derived_mismatch"].append(item.pair.key)
    return report


# ---------------------------------------------------------------- 文档渲染

def arm_rollup(stats_list: list[rc.PairStats]) -> list[dict[str, object]]:
    rows = []
    for (module, arm), items in rc.iter_grouped(stats_list):
        worst = max(items, key=lambda s: s.mde_holm_ns)
        row = {
            "module": module,
            "arm": arm,
            "arm_cn": items[0].pair.arm_cn,
            "runs": len(items),
            "family": items[0].pair.family,
            "family_m": items[0].pair.family_m,
            "alpha_eff": items[0].alpha_eff,
            "n_each": items[0].n0,
            "sd0_min": min(s.sd0_ns for s in items),
            "sd0_max": max(s.sd0_ns for s in items),
            "sd1_min": min(s.sd1_ns for s in items),
            "sd1_max": max(s.sd1_ns for s in items),
            "mde_alpha_min": min(s.mde_alpha_ns for s in items),
            "mde_alpha_max": max(s.mde_alpha_ns for s in items),
            "mde_holm_min": min(s.mde_holm_ns for s in items),
            "mde_holm_max": max(s.mde_holm_ns for s in items),
            "mde_holm_worst": worst.mde_holm_ns,
            "delta_min": min(s.delta_ns for s in items),
            "delta_max": max(s.delta_ns for s in items),
            "exceed_alpha": sum(1 for s in items if abs(s.delta_ns) > s.mde_alpha_ns),
            "exceed_holm": sum(1 for s in items if abs(s.delta_ns) > s.mde_holm_ns),
            "mean_of_means": sum(0.5 * (s.mean0_ns + s.mean1_ns) for s in items) / len(items),
        }
        rows.append(row)
    return rows


def render_power_md(stats_list: list[rc.PairStats], report: dict[str, object]) -> str:
    z_alpha = rc.z_for_two_sided_alpha(rc.ALPHA_FAMILY)
    z_power = rc.z_for_power(rc.TARGET_POWER)
    out: list[str] = []
    add = out.append

    add("# T26 功效分析 / MDE（r04-stats-20261016）")
    add("")
    add("本页是**只读复算**：输入全部是已提交的锁频采集 CSV，不重新采集、不改动任何已有证据文件、")
    add("不做密钥恢复。每个数字都可以由 `robustness-src/r04_power.py` 从原始 CSV 重算；")
    add("输入文件摘要见[附录 A](#附录-a输入文件摘要)，与既有证据的逐项交叉核对见[附录 B](#附录-b与既有证据的交叉核对)。")
    add("")
    add("## 1. 方法")
    add("")
    add("### 1.1 数据粒度")
    add("")
    add("一行 = 一个**主类对实例** = 一次 run × 一个臂 × 两类样本（class0 − class1）。")
    add("这个粒度与预注册 Holm 家族的成员表 `stats/members/members.csv.gz` 完全同构，")
    add("所以家族 m 可以直接套用（M2 = 3 run × 2 臂 = 6，M3 = 6，M4 = 6，M5 = 3）。")
    add("")
    add("- **主类对**：M1 未修/已修、M2 未修/已修、M3 on/off、M4 vulnerable/ct、M5 reference。")
    add("- **R03 两个族外对照**：对照 A `valid vs malformed`、对照 B `valid vs truncated`，各 3 臂 × 3 种子。")
    add("- 平台侧各模块的**对照类对**（M2 malformed-zero-tail/ff-tail、M3/M5 bit-flipped/random、")
    add("  M4 截断对照）不在本页范围内：它们不是主类对，也不是 R03 的两个对照。")
    add("")
    add("### 1.2 每类 SD 与 n")
    add("")
    add("SD 一律取**样本标准差**（`numpy.std(..., ddof=1)`）。")
    add("口径由既有证据锁定：`stats/members/members.csv.gz` 的 `sd0_ns`/`sd1_ns` 与各")
    add("`stats/<dataset>/ci_welch.json` 的 `standard_error_ns` 都能被 ddof=1 逐位复现，ddof=0 不能。")
    add("本批全部 41 个主类对都是 `n0 = n1 = 10000`（预热 100 次在计时窗口外，不计入）。")
    add("")
    add("### 1.3 MDE 公式与实现")
    add("")
    add("两样本、双侧 α、目标功效 1−β、等 n 的最小可检测效应：")
    add("")
    add("```")
    add("MDE = (z_{1-α/2} + z_{1-β}) * sqrt( sd0^2 / n0 + sd1^2 / n1 )")
    add("```")
    add("")
    add(f"本页取 α = {rc.ALPHA_FAMILY}、1−β = {rc.TARGET_POWER:.2f}，于是")
    add(f"z_{{1-α/2}} = {z_alpha:.9f}、z_{{1-β}} = {z_power:.9f}，两者之和 = {z_alpha + z_power:.9f}。")
    add("等 n 时它退化为教科书的 `2.8016 * sd * sqrt(2/n)`；实现保留不等 n 的一般形式。")
    add("")
    add("实现：`robustness-src/r04_common.py::mde_ns`，正态分位用标准库 `statistics.NormalDist().inv_cdf`，")
    add("不引入近似表。MDE 是**统计可检测性**（在给定 n 与实测离散度下，80% 功效能分辨的最小均值差），")
    add("不是物理泄漏阈值、不是密钥恢复门槛。")
    add("")
    add("### 1.4 Holm 校正后的有效 α")
    add("")
    add("Holm 逐步法的最小阈值是 `α/m`（最显著那一项）。要在**整族**上保证设计期功效，")
    add("就要按最严阈值反推可检测效应，因此本页取")
    add("")
    add("```")
    add("α_eff = α / m        （族外不校正：α_eff = α）")
    add("```")
    add("")
    add("家族与 m 直接取自已提交的预注册成员表：M2 = 6、M5 = 3、M3 = 6、M4 = 6。")
    add("M1 主类对与 R03 两个对照都**没有**预注册家族（M1 规程写明「没有 Holm」，")
    add("R03 PLAN 写明「不做 Holm、不做任何多重比较校正」），故 α_eff = 0.05。")
    add("")
    add("| 家族 | m | α_eff = 0.05/m | z_{1-α_eff/2} |")
    add("| --- | ---: | ---: | ---: |")
    for family, m in (
        ("m2_end_to_end_full_decaps_v1", 6),
        ("m3_lut_arm_end_to_end_v1", 6),
        ("m4_compare_arm_session_v1", 6),
        ("m5_reference_end_to_end_v1", 3),
    ):
        alpha_eff = rc.holm_effective_alpha(m)
        add(
            f"| `{family}` | {m} | {alpha_eff:.9f} | "
            f"{rc.z_for_two_sided_alpha(alpha_eff):.9f} |"
        )
    add("| （族外：M1 主类对、R03 两个对照） | — | 0.050000000 | 1.959963985 |")
    add("")

    # ---- 一句话结论
    add("## 2. 一句话结论（可直接引用）")
    add("")
    add("> **M2/M3/M5「端到端未检出」的确切含义是：在本机、本编译产物、本类对与本次样本预算下，")
    add("> 观测到的类间均值差小于本设计的最小可检测效应 MDE（M2 约 25–67 ns、M3 约 18–34 ns、")
    add("> M5 约 14–28 ns），所以这套预算**分辨不出**任何小于该量级的效应；")
    add("> 「未检出」= 观测效应 < MDE，**不等于零效应**，也不构成恒时证明或物理泄漏界。**")
    add("")
    add("可检测性上界不是一个「泄漏界」：MDE 说的是「用这套 n 与实测 SD，80% 功效能分辨多大的均值差」，")
    add("不是「机制最多只能泄漏多少纳秒」。")
    add("")

    # ---- 主表
    add("## 3. 主表：一行一个主类对")
    add("")
    add("单位 ns。「观测 Δ」= class0 均值 − class1 均值，与既有证据同向。")
    add("95% CI 是既有口径的正态近似区间（z = 1.96，方差除数 n−1），仅作参照，不参与 MDE 判定。")
    add("")
    header = (
        "| # | 模块 | 臂 | run | 家族(m) | α_eff | n0/n1 | SD0 | SD1 | "
        "MDE(α=0.05) | MDE(Holm α_eff) | MDE%(α) | MDE%(Holm) | 观测 Δ | 95% CI | "
        "\\|Δ\\|>MDE(α) | \\|Δ\\|>MDE(Holm) |"
    )
    add(header)
    add("| ---: | --- | --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |")
    for position, item in enumerate(stats_list, start=1):
        pair = item.pair
        family = pair.family if pair.family_m else "族外"
        exceed_alpha = "**是**" if abs(item.delta_ns) > item.mde_alpha_ns else "否"
        exceed_holm = "**是**" if abs(item.delta_ns) > item.mde_holm_ns else "否"
        add(
            f"| {position} | {pair.module} | {pair.arm_cn} | `{pair.run_label}` | "
            f"{family}"
            + (f"({pair.family_m})" if pair.family_m else "")
            + f" | {item.alpha_eff:.9f} | {item.n0}/{item.n1} | "
            f"{item.sd0_ns:.3f} | {item.sd1_ns:.3f} | "
            f"{item.mde_alpha_ns:.4f} | {item.mde_holm_ns:.4f} | "
            f"{item.rel_mde_alpha_percent:.4f}% | {item.rel_mde_holm_percent:.4f}% | "
            f"{item.delta_ns:+.4f} | [{item.ci_low_ns:+.3f}, {item.ci_high_ns:+.3f}] | "
            f"{exceed_alpha} | {exceed_holm} |"
        )
    add("")

    # ---- 臂级汇总
    add("## 4. 臂级汇总（每个主类对一行：跨 run 的 SD 与 MDE 范围）")
    add("")
    add("「MDE(Holm) 最坏」= 该臂 3 次 run 中最大的 Holm 有效 α 下 MDE，是引用单个数时该用的保守值。")
    add("")
    add("| 模块 | 臂 | run 数 | 家族(m) | n/类 | SD0 范围 | SD1 范围 | MDE(α) 范围 | MDE(Holm) 范围 | MDE(Holm) 最坏 | 观测 Δ 范围 | 超 MDE(α) | 超 MDE(Holm) |")
    add("| --- | --- | ---: | --- | ---: | --- | --- | --- | --- | ---: | --- | ---: | ---: |")
    for row in arm_rollup(stats_list):
        family = row["family"] if row["family_m"] else "族外"
        add(
            f"| {row['module']} | {row['arm_cn']} | {row['runs']} | {family}"
            + (f"({row['family_m']})" if row["family_m"] else "")
            + f" | {row['n_each']} | "
            f"{row['sd0_min']:.1f}–{row['sd0_max']:.1f} | "
            f"{row['sd1_min']:.1f}–{row['sd1_max']:.1f} | "
            f"{row['mde_alpha_min']:.4f}–{row['mde_alpha_max']:.4f} | "
            f"{row['mde_holm_min']:.4f}–{row['mde_holm_max']:.4f} | "
            f"{row['mde_holm_worst']:.4f} | "
            f"{row['delta_min']:+.3f} … {row['delta_max']:+.3f} | "
            f"{row['exceed_alpha']}/{row['runs']} | {row['exceed_holm']}/{row['runs']} |"
        )
    add("")

    # ---- 分模块解读
    add("## 5. 用 MDE 读「未检出」")
    add("")
    add("### 5.1 数值读法")
    add("")
    add("- **M2**（家族 m = 6，α_eff = 0.008333）：主类对 6 项的 |Δ| 全部小于 Holm 有效 α 下的 MDE")
    add("  （MDE(α) 19.9–54.0 ns，MDE(Holm) 24.7–67.1 ns），所以预注册家族 Holm 全部不拒绝。")
    add("  这套预算对**小于几十纳秒**的端到端均值差没有分辨力。M2 的**定位层**阳性的内容是")
    add("  「未修链三个热点各含 1 个 `div`、已修链 0 个」，那是**指令与数据流层面**的结论，")
    add("  不是本机测到的物理时差；两层互不冒充（见 `m2-kem-20261016/RESULT.md`）。")
    add("- **M3**（m = 6，MDE(α) 14.2–27.1 ns，MDE(Holm) 17.7–33.7 ns）：on / off 两臂的 |Δ| 都小于 MDE，")
    add("  属于「观测效应被预算盖住」。M3 是**人工构造校准**，本页只记录可检测性，不据此作泄漏结论。")
    add("- **M4**（m = 6）：vulnerable 臂的 |Δ| **远大于** MDE（3/3 run 超过，最坏情况下 MDE(Holm) 也只有 1.47 ns，")
    add("  而 |Δ| ≈ 3.5–4.4 ns）；ct 臂的 |Δ| 小于 MDE（0/3 超过）。")
    add("  这正是「该臂的效应大到这套预算足以分辨」与「该臂分辨不了」的分界。")
    add("  注意 M4 是**人工构造校准**（人工提前退出比较夹具），不是上游 CVE。")
    add("- **M5**（m = 3，MDE(α) 11.7–24.5 ns，MDE(Holm) 13.5–28.3 ns）：|Δ| 小于 MDE，未检出。")
    m1_unfixed = next(s for s in stats_list if s.pair.key == "M1-unfixed-s1")
    m1_fixed = next(s for s in stats_list if s.pair.key == "M1-fixed-s1")
    add("- **M1 未修**：Δ = %+.3f ns，|Δ| **超过** α = 0.05 下的 MDE %.3f ns。" % (m1_unfixed.delta_ns, m1_unfixed.mde_alpha_ns))
    add("- **M1 已修**：Δ = %+.3f ns，|Δ| **小于** MDE %.3f ns。" % (m1_fixed.delta_ns, m1_fixed.mde_alpha_ns))
    add("  但 M1 主类对**没有预注册 Holm 家族**（`tooling-strengthen-20261015/PROTOCOL.md` 写明「没有 Holm」），")
    add("  这两个数是单次运行、族外、不校正的结果，不构成 Holm 确认。同一批数据的族外 online dudect")
    add("  方向相同（未修臂三次越过上游 `t > 10` 阈值、已修臂三次都在 2.05 以下），同样不进 Holm。")
    add("- **R03 对照 A**（valid vs malformed）：9 个「臂 × 种子」组合的 |Δ| 都小于 MDE（0/9 超过），")
    add("  即隐式拒绝路径与接受路径在本预算下不可区分；**对照 B**（valid vs truncated）的 |Δ| ≈ 29–55 µs，")
    add("  比该对比的 MDE（约 7–21 ns）大 3–4 个数量级，说明这是封装层长度检查的接口语义差，")
    add("  不是秘密相关泄漏。两者都**族外**（R03 PLAN：不做 Holm、不做任何多重比较校正）。")
    add("")
    add("### 5.2 「未检出」的正确措辞")
    add("")
    add("未检出 = 「观测效应 < MDE」。它**不**推出下列任何一条：")
    add("")
    add("1. 效应恰好为零；")
    add("2. 机制在物理上恒时；")
    add("3. 攻击者不可利用；")
    add("4. 换机器、换编译产物、换类对、换样本预算后仍然未检出。")
    add("")
    add("它**确实**推出：在这套 n 与实测 SD 下，凡是小于表中 MDE 的均值差都照不出来；")
    add("要缩小 MDE，只能按 `MDE ∝ 1/sqrt(n)` 加样本，或降低测量噪声（锁频、绑核、缩短窗口）。")
    add("")

    # ---- 边界
    add("## 6. 边界")
    add("")
    add("- MDE 是**统计可检测性**，不是物理泄漏阈值，也不是恒时证明；本页不给出物理误差界。")
    add("- 本页**不做密钥恢复**，不运行 exploit demo，不给出真实总体检出率/误报率。")
    add("- MDE 用的是**本次实测 SD**，属于事后（post hoc）功效描述：它说明「这套数据能看见多大」，")
    add("  不是事先的样本量规划，也不改变任何已提交的 Holm 判定。")
    add("- M3/M4 是**人工构造校准**（M3 为 LUT 机制校准、M4 为人工提前退出比较夹具），不是上游 CVE。")
    add("- R03 与 dudect/RTLF 一律**族外**；dudect 的最大 t 不转伪 p，本页不引用它做任何 MDE 计算。")
    add("- M1 的实测样本取自 `liboqs010-locked-20261015/runs/{vulnerable,fixed}/samples.csv`")
    add("  （锁频采集，单次、seed 31337、CPU2），与平台四模块的控制器采集不是同一条流水线；")
    add("  `tooling-strengthen-20261015/csv/*-message-zero-ones.csv` 是同一批样本的派生两列文件，")
    add("  只用于逐值一致性旁证（附录 B）。两边的 `.meta` 都有")
    add("  `cpu_affinity=not_pinned` 与 `frequency_control=not_configured` 的固定字符串，")
    add("  真正的绑核与频率门在各自 README / `logs/status.log` / 控制器落盘件里。")
    add("- 本页只读已有证据，没有新增任何采集，没有改任何已有证据文件。")
    add("")

    # ---- 附录 A
    add("## 附录 A：输入文件摘要")
    add("")
    add("每个主类对的原始 CSV（仓库相对路径）、解压后内容 SHA-256 与容器文件 SHA-256。")
    add("解压后摘要的口径与各目录既有的 `input.sha256` / `.meta` 一致。")
    add("M1 两臂的源文件是未压缩 `.csv`，故两列摘要相同。")
    add("R03 的同一份 run CSV 同时提供两个对照类对，故第 24–41 行有 9 组重复文件——这是同一原件的两次使用，")
    add("不是两份数据。")
    add("")
    add("| # | 主类对 | 原始 CSV | 解压内容 sha256 | 容器 sha256 |")
    add("| ---: | --- | --- | --- | --- |")
    for position, item in enumerate(stats_list, start=1):
        path = rc.REPO_ROOT / item.pair.source_csv
        add(
            f"| {position} | {item.pair.key} | `{item.pair.source_csv}` | "
            f"`{rc.sha256_uncompressed(path)}` | `{rc.sha256_file(path)}` |"
        )
    add("")

    # ---- 附录 B
    add("## 附录 B：与既有证据的交叉核对")
    add("")
    add(f"- 与 `stats/members/members.csv.gz` 的 `mean0/mean1/sd0/sd1/n0/n1` 逐项比对：")
    add(f"  **{report['members_ok']}/{report['members_checked']} 一致**。")
    add(f"- 与各 `stats/<dataset>/ci_welch.json` 的 `mean_difference_class0_minus_class1_ns`")
    add(f"  与 `standard_error_ns` 逐项比对：**{report['ci_ok']}/{report['ci_checked']} 一致**。")
    add(f"- M1 两臂与派生文件 `tooling-strengthen-20261015/csv/*-message-zero-ones.csv` 的")
    add(f"  逐值（排序后）比对：**{report['m1_derived_ok']}/{report['m1_derived_checked']} 一致**。")
    if report["members_mismatch"]:
        add("")
        add("**不一致项（需人工复核）**：")
        add("")
        for member_id, problems in report["members_mismatch"]:
            add(f"- `{member_id}`：{'；'.join(problems)}")
    if report["ci_mismatch"]:
        add("")
        add("**ci_welch 不一致项**：")
        add("")
        for path, problems in report["ci_mismatch"]:
            add(f"- `{path}`：{'；'.join(problems)}")
    add("")
    add("## 附录 C：复现命令")
    add("")
    add("```bash")
    add("cd <repo-root>")
    add("python3 docs/evidence/r04-stats-20261016/robustness-src/r04_power.py")
    add("# 一次跑完 T26 + T27（含图）：")
    add("python3 docs/evidence/r04-stats-20261016/robustness-src/r04_run_all.py")
    add("```")
    add("")
    add("依赖：Python 3.9+ 标准库 + numpy（本机为 Python 3.9.6 / numpy 2.0.2）。")
    add("脚本只读仓库内已有 CSV，不联网、不采集、不写已有证据文件。")
    add("")
    return "\n".join(out) + "\n"


def main() -> None:
    stats_list = [rc.compute_pair_stats(pair, index) for index, pair in enumerate(rc.CLASS_PAIRS)]
    report = cross_check(stats_list)
    markdown = render_power_md(stats_list, report)
    target = rc.OUT_DIR / "POWER.md"
    target.write_text(markdown, encoding="utf-8")
    print(f"[T26] 写出 {rc.relpath(target)}（{len(stats_list)} 个主类对）")
    print(
        "[T26] 交叉核对：members %s/%s，ci_welch %s/%s，M1 派生文件 %s/%s"
        % (
            report["members_ok"],
            report["members_checked"],
            report["ci_ok"],
            report["ci_checked"],
            report["m1_derived_ok"],
            report["m1_derived_checked"],
        )
    )
    if report["members_mismatch"] or report["ci_mismatch"] or report["m1_derived_mismatch"]:
        raise SystemExit("[T26] 交叉核对存在不一致，见 POWER.md 附录 B")


if __name__ == "__main__":
    main()
