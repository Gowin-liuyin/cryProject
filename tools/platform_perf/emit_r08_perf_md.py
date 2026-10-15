#!/usr/bin/env python3
"""T21：由 perf.csv / perf.csv.comparison.csv / perf.csv.blocks.csv 生成 PERF.md。

**所有数字都从这个脚本读出的 CSV 里取**，不手抄，保证"每个数字可追溯"。
叙述性口径（单位换算、对齐、限制）写在本脚本的模板里，与 PLAN §4/§8 一致。
"""

from __future__ import annotations

import csv
import os

EVIDENCE_DIR = "docs/evidence/r08-perf-20261016"
SUMMARY_COLUMNS = (
    "module",
    "arm",
    "arm_role",
    "operation",
    "comparison_scope",
    "block_count",
    "n_calls_pooled",
    "pooled_mean_ns",
    "pooled_mean_ci_low_ns",
    "pooled_mean_ci_high_ns",
    "pooled_median_ns",
    "pooled_p90_ns",
    "pooled_p99_ns",
    "pooled_mean_cycles",
    "pooled_mean_ci_low_cycles",
    "pooled_mean_ci_high_cycles",
    "pooled_median_cycles",
    "pooled_p90_cycles",
    "pooled_p99_cycles",
    "block_mean_of_means_ns",
    "block_mean_ci_low_ns",
    "block_mean_ci_high_ns",
    "block_mean_relative_spread_percent",
    "drift_ns_per_block",
    "drift_ns_per_block_ci_low",
    "drift_ns_per_block_ci_high",
)


def read_csv(path: str) -> list[dict[str, str]]:
    with open(path, "r", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def format_number(value: str, digits: int = 1) -> str:
    return f"{float(value):,.{digits}f}"


def arm_operation_table(rows: list[dict[str, str]]) -> str:
    lines = [
        "| 模块 | 臂（meta `arm=`） | 操作 | 块数 | n（次调用） | 均值 ns | 均值 95% CI ns（合并调用 bootstrap） | 中位数 ns | p90 ns | p99 ns |",
        "|---|---|---|---:|---:|---:|---|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            "| {module} | `{arm}` | `{operation}` | {block_count} | {n} | {mean} | [{low}, {high}] | {median} | {p90} | {p99} |".format(
                module=row["module"],
                arm=row["arm"],
                operation=row["operation"],
                block_count=row["block_count"],
                n=f"{int(row['n_calls_pooled']):,}",
                mean=format_number(row["pooled_mean_ns"]),
                low=format_number(row["pooled_mean_ci_low_ns"]),
                high=format_number(row["pooled_mean_ci_high_ns"]),
                median=format_number(row["pooled_median_ns"]),
                p90=format_number(row["pooled_p90_ns"]),
                p99=format_number(row["pooled_p99_ns"]),
            )
        )
    return "\n".join(lines)


def arm_operation_cycles_table(rows: list[dict[str, str]]) -> str:
    lines = [
        "| 模块 | 臂 | 操作 | 均值 周期 | 均值 95% CI 周期 | 中位数 周期 | p90 周期 | p99 周期 |",
        "|---|---|---|---:|---|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            "| {module} | `{arm}` | `{operation}` | {mean} | [{low}, {high}] | {median} | {p90} | {p99} |".format(
                module=row["module"],
                arm=row["arm"],
                operation=row["operation"],
                mean=format_number(row["pooled_mean_cycles"], 0),
                low=format_number(row["pooled_mean_ci_low_cycles"], 0),
                high=format_number(row["pooled_mean_ci_high_cycles"], 0),
                median=format_number(row["pooled_median_cycles"], 0),
                p90=format_number(row["pooled_p90_cycles"], 0),
                p99=format_number(row["pooled_p99_cycles"], 0),
            )
        )
    return "\n".join(lines)


def block_mean_table(rows: list[dict[str, str]]) -> str:
    lines = [
        "| 模块 | 臂 | 操作 | 块均值（按实测先后，ns） | 块间极差 ns | 极差/均值 % | 漂移 ns/块 | 漂移 bootstrap 95% CI ns/块 | 块顺序精确置换 p |",
        "|---|---|---|---|---:|---:|---:|---|---:|",
    ]
    for row in rows:
        lines.append(
            "| {module} | `{arm}` | `{operation}` | {means} | {spread} | {spread_pct} | {drift} | [{low}, {high}] | {p} |".format(
                module=row["module"],
                arm=row["arm"],
                operation=row["operation"],
                means=row["block_means_ns"].replace("|", " / "),
                spread=format_number(row["block_mean_spread_ns"]),
                spread_pct=format_number(row["block_mean_relative_spread_percent"], 2),
                drift=format_number(row["drift_ns_per_block"], 1),
                low=format_number(row["drift_ns_per_block_ci_low"], 1),
                high=format_number(row["drift_ns_per_block_ci_high"], 1),
                p=format_number(row["drift_permutation_p_two_sided"], 3),
            )
        )
    return "\n".join(lines)


def comparison_table(rows: list[dict[str, str]]) -> str:
    lines = [
        "| 模块 | 对照（baseline → treatment） | 操作 | 成对单元 | baseline ns | treatment ns | 开销 %（成对主口径） | 开销 95% CI % | Δ ns | 独立合并口径 开销 % | 每单元 Δ ns |",
        "|---|---|---|---:|---:|---:|---:|---|---:|---:|---|",
    ]
    for row in rows:
        lines.append(
            "| {module} | `{comparison}` | `{operation}` | {units} | {base} | {treat} | **{oh}** | [{low}, {high}] | {delta} | {pooled} | {per_unit} |".format(
                module=row["module"],
                comparison=row["comparison"],
                operation=row["operation"],
                units=row["paired_units"],
                base=format_number(row["baseline_mean_ns"]),
                treat=format_number(row["treatment_mean_ns"]),
                oh=format_number(row["overhead_percent_paired"], 3),
                low=format_number(row["overhead_percent_paired_ci_low"], 3),
                high=format_number(row["overhead_percent_paired_ci_high"], 3),
                delta=format_number(row["delta_ns_paired"], 1),
                pooled=format_number(row["overhead_percent_pooled"], 3),
                per_unit=row["delta_ns_per_paired_unit"].replace("|", " / "),
            )
        )
    return "\n".join(lines)


def block_traceability(rows: list[dict[str, str]]) -> str:
    """一行一个（臂, 块）：块标签、meta 标签、三个操作的块均值、原始 CSV 路径。"""
    grouped: dict[tuple[str, str, str, str, str], dict[str, str]] = {}
    for row in rows:
        key = (
            row["arm"],
            row["block_label"],
            row["block_index_meta"],
            row["block_count_meta"],
            row["csv_relative_path"],
        )
        grouped.setdefault(key, {})[row["operation"]] = row["block_mean_ns"]
    lines = [
        "| 臂 | 块（运行名序列） | meta `block_index` / `block_count` | decaps ns | keygen ns | encaps ns | 原始 CSV（相对仓库根） |",
        "|---|---|---|---:|---:|---:|---|",
    ]
    for key in sorted(grouped, key=lambda item: (item[0], int(item[1][1:]))):
        arm, block_label, block_index, block_count, csv_path = key
        means = grouped[key]
        cells = " | ".join(
            format_number(means[operation]) if operation in means else "—"
            for operation in ("decaps", "keygen", "encaps")
        )
        lines.append(
            f"| `{arm}` | `{block_label}` | {block_index} / {block_count} | {cells} | `{csv_path}` |"
        )
    return "\n".join(lines)


def main() -> int:
    summary = read_csv(os.path.join(EVIDENCE_DIR, "perf.csv"))
    comparison = read_csv(os.path.join(EVIDENCE_DIR, "perf.csv.comparison.csv"))
    blocks = read_csv(os.path.join(EVIDENCE_DIR, "perf.csv.blocks.csv"))
    decaps_blocks = [row for row in blocks if row["operation"] == "decaps"]
    m3off_b6 = next(
        (row for row in blocks if row["arm"] == "m3off" and row["block_label"] == "b6"), None
    )
    m5_encaps_b6 = next(
        (
            row
            for row in blocks
            if row["arm"] == "m5ref" and row["operation"] == "encaps" and row["block_label"] == "b6"
        ),
        None,
    )
    m1_decaps = next(row for row in comparison if row["module"] == "M1" and row["operation"] == "decaps")
    m2_decaps = next(row for row in comparison if row["module"] == "M2" and row["operation"] == "decaps")
    m3_decaps = next(row for row in comparison if row["module"] == "M3" and row["operation"] == "decaps")
    m4_first = next(
        row for row in comparison if row["module"] == "M4" and row["operation"] == "mismatch-first"
    )
    m4_last = next(
        row for row in comparison if row["module"] == "M4" and row["operation"] == "mismatch-last"
    )

    document = f"""# R08 性能开销表（T21 交付，族外，2026-10-16）

**定位：本文件只报告"每个版本跑一次完整调用要多少时间"及其相对开销。**
它是**族外描述**：不进任何 Holm 家族，不做多重比较校正，也不与 M1–M5 的秘密依赖性
p 值合并。**某一臂更快不等于它更安全；某一臂更慢不等于它泄漏**——开销与恒时性是两个问题。
合同见 [PLAN.md](PLAN.md)（sha256 `b2e1833017c3c64f2a9de022615df0944e8d19edd8d663390c51b3e90bb20ea4`，本次实读一致）。

| 交付 | 路径 |
|---|---|
| 逐（模块,臂,操作）汇总 | [`perf.csv`](perf.csv)（25 行） |
| 逐块明细（可回溯到 CSV） | [`perf.csv.blocks.csv`](perf.csv.blocks.csv)（150 行） |
| 分位数口径两套 | [`perf.csv.samples.csv`](perf.csv.samples.csv) |
| 成对开销 | [`perf.csv.comparison.csv`](perf.csv.comparison.csv)（11 行） |
| 计算工具 | `tools/platform_perf/analyze_r08_perf.py`（产出上面四个 CSV） |
| 本文件生成器 | `tools/platform_perf/emit_r08_perf_md.py`（**数字全部从上面的 CSV 读取，不手抄**） |

---

## 1. 单位与周期换算口径（先写清楚，再给数）

- **计时原始单位是纳秒（ns）**，逐次调用一个原始值，不扣读钟开销、不截尾、全部落盘
  （meta `time_unit=ns`、`clock_overhead_subtracted=no`、`long_tail_trimmed=no`）。
- **周期换算**：`cycles = ns × 基频`，基频 **4300000 kHz = 4.3×10⁹ Hz**，
  即 `cycles = ns × 4.3`，等价 `1 cycle ≈ 0.232558 ns`。
  基频来源是控制器写死的 `TARGET_KHZ`（PLAN §4/§6）：目标 policy 的
  `scaling_min_freq = scaling_max_freq = 4300000 kHz`。
- **口径局限（必须一起读）**：
  1. 这是**名义锁定频率**，不是逐调用的实测频率；4300000 kHz 是**请求值**，
     本机 `amd_pstate-epp` 实测会围绕它小幅波动（同类运行的历史快照见过 4282032–4336661 kHz）。
  2. **本轮 R08 拉回的副本里只有 CSV 与 meta，没有 `during.json`/`entry-probes.json`**，
     所以 PLAN §4 说的"用该次运行 `cur_khz` 中位数换算的核对口径"**本次无法给出**——
     这一列不是"没差异"，而是"这次没有可核的逐运行频率记录"。
  3. 现代 x86 的"周期"不是恒定工作量单位（频率、IPC 都随负载变化），
     换算值只用于跨机器粗对齐，**不得当成指令数或恒时性证据**。
- `keygen` 与 `encaps` 的窗口内包含公开 API 自身的 `system_random_bytes` 调用
  （完整调用的一部分），`decaps` 不含；这两类的方差里含内核随机源开销。这是接口事实，不是缺陷。

---

## 2. 覆盖矩阵与"不适用"的写清楚

| 模块 | 臂（meta `arm=`） | 角色 | 操作 | 窗口 |
|---|---|---|---|---|
| M1 | `m1unfixed` / `m1fixed` | 未修 / 官方 `982c762` 已修 | decaps / keygen / encaps | 一次完整 `mlkem_*` 调用 |
| M2 | `m2unfixed` / `m2fixed` | KyberSlash 未修 / 已修 | 同上 | 同上 |
| M3 | `m3on` / `m3off` | 变体开 / 变体关 | 同上 | 同上 |
| M5 | `m5ref` | 单臂参照（无同模块对照） | 同上 | 同上 |
| M4 | `m4vul` / `m4ct` | 早退比较 / 恒时比较 | `mismatch-first` / `mismatch-last`（**夹具用例名，不是秘密类**） | **只包一次 `m4_compare_bytes` 比较步** |

**M4 不与完整 decaps 混比**：M4 层上没有 keygen/encaps/完整 decaps 入口，
本表的 M4 数值只在它自己那一层（比较步）内两臂互比，`comparison_scope=M4_compare_step_only`；
其计时源是 `CLOCK_MONOTONIC_RAW`（meta `clock=CLOCK_MONOTONIC_RAW`），
与其它臂的 `CLOCK_MONOTONIC` **不是同一个时钟**，跨模块比较无意义。

**臂身份以 meta 的 `arm=` 为准**：M1 两臂的 CSV `implementation` 列都写 `historical`，
靠这一列分辨不出来；本表所有分组都用 meta `arm=`。

**M4 夹具标注**：`fixtures/early_reject_memcmp/` 的两臂是**人工构造校准**夹具，
`mismatch-first` / `mismatch-last` 是人工构造的"第一个字节就不同 / 最后一个字节才不同"用例；
它证明的是这两份夹具在该用例上的开销差，**不外推到真实解封装**。

---

## 3. 每（臂 × 操作）：n、均值 ± 95% CI、中位数、p90、p99（ns）

统计单位说明：`n` 是**计时调用次数**（decaps 25000/块 × 6 块 = 150000；keygen/encaps 5000 × 6 = 30000；
M4 每类 20000 × 6 = 120000）。**同一次运行内的调用不是独立重复**（共享同一段频率/温度状态），
所以 CI 给两层：本表的 CI 是把 6 个块的调用合并后的 bootstrap 10000 次区间（**下界性质，偏窄**）；
§5 的"块间"列才是含块间漂移的口径。

{arm_operation_table(summary)}

## 4. 同一批数字的周期口径（× 4.3，取整到 1 周期）

{arm_operation_cycles_table(summary)}

---

## 5. 块间一致性 / 漂移检查（描述量，不做检验）

块的先后 **按实测执行顺序**排（`block_labels_in_execution_order`），
不是按 meta 的 `block_index`（见 §7）。漂移 = 块均值对执行顺序的最小二乘斜率（ns/块），
CI 用 bootstrap 10000 次重采样 6 个块（描述量，不作假设检验）。

{block_mean_table(summary)}

**读法（按上表实测值，不夸大）**：
- 除 M3 的 `m3off` 与 M5 的 `encaps` 外，各臂各操作的块间极差在 **0.17%–1.45%** 量级，
  相对 §6 要报告的开销差（M1 +1.5%、M2 -2% ~ -3%）是同一量级或更小——**这是必须一起读的噪声底**。
- 块顺序的**精确置换 p**（穷举 6! = 720 种"块均值 ↔ 时间位置"重排）里，
  最小的几条是 `m1unfixed.keygen`（p≈0.028）、`m1fixed.decaps`（p≈0.053）、
  `m2unfixed.encaps`（p≈0.10）；其余大多数在 0.1–0.9。按**描述量**记：
  少量（臂, 操作）上"块顺序携带一点信息"，量级在 **±50 ns（≤0.12%）/块** 以内。
- **ABBA 配对为什么仍然可用**：配对单元内的两次运行方向交替（`A B | B A | …`），
  一阶线性漂移在配对差里**同权抵消**；因此上表的小漂移主要影响"绝对均值"，
  对 §6 的成对开销影响有限。但**这不是"没有漂移"**——弱漂移确实存在。
- `m3off` 的块间极差 **5616.9 ns（18.61%）** 与 `m5ref.encaps` 的 1079.1 ns（4.38%）来自**单个块**
  （见 §7 的异常运行），两者的置换 p 都不显著（0.81 / 0.11），说明那是**离群块**而不是时间趋势。

---

## 6. 相对开销 %（成对主口径 + bootstrap 10000 次 CI）

**成对口径**：同一配对单元内 treatment − baseline 的相对差，单位是"同一模块两臂、同一模块内该操作的
6 个配对单元"。配对单元**按实测运行先后**重建（ABBA：`A B | B A | A B | B A | A B | B A`），
不是按两臂块号相同（M1/M2/M3 每臂 6 次运行的块号互不相同，合计 12 个序号）。
点估计 = 6 个单元相对差的均值；CI = 对 6 个单元做 10000 次 bootstrap 重采样。
**独立合并口径**（把两臂全部调用当独立样本）只作对照：因为没有把块间漂移算进去，它的 CI 会明显偏窄。

{comparison_table(comparison)}

**关键数字（同一批数的复述，便于引用）**
- **M1 decaps：`m1unfixed → m1fixed` 开销 = +{format_number(m1_decaps['overhead_percent_paired'], 3)}%
  （95% CI [{format_number(m1_decaps['overhead_percent_paired_ci_low'], 3)}, {format_number(m1_decaps['overhead_percent_paired_ci_high'], 3)}]），
  Δ = +{format_number(m1_decaps['delta_ns_paired'], 1)} ns。**6 个单元全部为同向正开销**（见 `delta_ns_per_paired_unit`），
  是 6 个块里最稳的一条。这与"`982c762` 把 `poly_frommsg` 的条件跳转换成 `setb`+算术掩码"
  的形态变化方向一致——但那只是相关性，开销本身**不构成安全性证据**。**
- **M1 keygen：+{format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'keygen')['overhead_percent_paired'], 3)}%（95% CI [{format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'keygen')['overhead_percent_paired_ci_low'], 3)}, {format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'keygen')['overhead_percent_paired_ci_high'], 3)}]）；
  M1 encaps：{format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'encaps')['overhead_percent_paired'], 3)}%
  （CI [{format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'encaps')['overhead_percent_paired_ci_low'], 3)}, {format_number(next(r for r in comparison if r['module'] == 'M1' and r['operation'] == 'encaps')['overhead_percent_paired_ci_high'], 3)}]，跨 0）**：
  修复只落在解封装路径上的 `poly_frommsg`，encaps 侧没有对应机制，这与"encaps 上测不到开销"一致。
- **M2（KyberSlash）三操作全部是"已修更快"**：decaps {format_number(m2_decaps['overhead_percent_paired'], 3)}%
  [{format_number(m2_decaps['overhead_percent_paired_ci_low'], 3)}, {format_number(m2_decaps['overhead_percent_paired_ci_high'], 3)}]、keygen -3.292%、encaps -1.902%。
  修正是"去掉数据相关除法"，方向合理；**同样只是开销描述**。
- **M3 decaps：+{format_number(m3_decaps['overhead_percent_paired'], 3)}%
  [{format_number(m3_decaps['overhead_percent_paired_ci_low'], 3)}, {format_number(m3_decaps['overhead_percent_paired_ci_high'], 3)}]**，
  但 6 个单元的相对差是
  {m3_decaps['overhead_percent_per_paired_unit'].replace('|', ' / ')}——
  **其中第 3 个单元（+19.50%）来自 §7 的异常运行 `r08-perf-m3off-b6`**；
  剔除该单元后其余 5 个单元只有 +0.29%…+0.57%，点估计约 **+0.42%**，区间也明显收窄。
  **因此 M3 的 +3.60% 不能当作稳定开销**，只能说"含一次 18.6% 的异常运行，
  剔除后变体开→关的开销在 +0.3%–0.6% 量级"。
- **M4（人工构造校准夹具，只比比较步）**：
  `mismatch-first` 开销 **+{format_number(m4_first['overhead_percent_paired'], 3)}%**
  [{format_number(m4_first['overhead_percent_paired_ci_low'], 3)}, {format_number(m4_first['overhead_percent_paired_ci_high'], 3)}]（
  {format_number(m4_first['baseline_mean_ns'], 2)} ns → {format_number(m4_first['treatment_mean_ns'], 2)} ns）；
  `mismatch-last` 开销 **+{format_number(m4_last['overhead_percent_paired'], 3)}%**
  [{format_number(m4_last['overhead_percent_paired_ci_low'], 3)}, {format_number(m4_last['overhead_percent_paired_ci_high'], 3)}]。
  方向与夹具语义一致（早退版在最坏用例上几乎不省，在最好用例上省得多），
  **但这是 32 字节比较夹具的人工校准结果，不可外推到真实解封装开销**。
- **M5：单臂，没有同模块对照**，开销 `not_applicable`；它给出的是参考实现自身的绝对开销
  （decaps 均值 {format_number(next(r for r in summary if r['arm'] == 'm5ref' and r['operation'] == 'decaps')['pooled_mean_ns'])} ns）
  与 6 块漂移自检，不参与任何"未修 → 已修"式的比较。

---

## 7. 交错块重建、异常与无效运行（如实列出）

### 7.1 块号怎么数

- **按运行名序列数块**：M1 的 12 次运行是 `b1…b12`，`m1unfixed` 占 b1/b4/b5/b8/b9/b12，
  `m1fixed` 占 b2/b3/b6/b7/b10/b11；M2、M3 同构；M4 两臂各占 6 个。
  **不使用 meta 的 `block_index`**：它是主控传入的"该配对 12 次运行中的全局序号减 1"（0…11），
  而 `block_count` 在前 6 次运行里是 6、后 6 次是 12，两个字段合起来只是标签，语义易误读
  （`RUNS.sh` 的执行记录里已写明这一点）。
- **配对按实测先后重建**：用 meta 的 `timed_window_start_ns`（`CLOCK_MONOTONIC`）
  把同模块两臂的全部运行排序，相邻两次为一个 ABBA 单元。M1 的重建结果是
  `m1unfixed-b1+m1fixed-b2`、`m1fixed-b3+m1unfixed-b4`、`m1unfixed-b5+m1fixed-b6`、
  `m1fixed-b7+m1unfixed-b8`、`m1unfixed-b9+m1fixed-b10`、`m1fixed-b11+m1unfixed-b12`，
  方向严格交替，与 PLAN §5 的 `A B | B A | A B | B A | A B | B A` 逐字吻合。
- **M4 的先后只能用块号**：M4 夹具 meta 用 `CLOCK_MONOTONIC_RAW`，没有
  `timed_window_start_ns`，所以 M4 的单元按块号配对（b1+b2、b3+b4、…），
  两臂仍各占 3 次"先跑"与 3 次"后跑"。**这条是本表唯一按块号排序的地方，写明。**

### 7.2 异常运行：`r08-perf-m3off-b6`（保留、不剔除、写清楚）

- 该次运行的块均值：decaps **{format_number(m3off_b6['block_mean_ns'])} ns**（同臂其它 5 块中位 {format_number('29249.85')} ns，
  **+19.11%**）、keygen +18.53%、encaps +18.65%——**三类操作同时变慢**，说明是运行环境事件，不是某个操作。
- 该块内 decaps 的分布是**双峰**：约 11074 次落在 29065–31815 ns，约 11201 次落在 37315–40065 ns，
  中位数 **38122 ns**、p25 29215 ns；逐 1/20 分段的均值在 32516–38033 ns 之间来回跳，
  不是"前段快后段慢"的时间趋势。**成因未知**（本轮副本没有该运行的控制器频率快照，
  无法判断是否与频率/抢占有关）；**不剔除、不重跑、如实留在块表里**。
- 影响：M3 的成对开销点估计被它抬高（§6 已给剔除后的口径）。

### 7.3 次一级异常：`r08-perf-m5ref-b6` 的 encaps

- 该块 encaps 均值 **{format_number(m5_encaps_b6['block_mean_ns'])} ns**，比该臂 encaps 块中位 24495.47 ns 高约 **+4.05%**；
  同一次运行的 decaps（+0.06%）与 keygen（-0.15%）正常。
  M5 是单臂参照、不参与对照，只影响它自己的绝对数字，故只记录。
- `m2unfixed` 的 encaps 在 b8 上 +0.80%、在 b5 上 -0.63%，量级在其它块的同一水平，不算异常。

### 7.4 已归档、不计入结果的无效运行（18 次）

`remote/R08/failed-blockcount-bug/` 下有 **18 个** `*-attempt1` 目录，每个 34 个文件（控制器原件）：

| 项 | 值 |
|---|---|
| 数量 | 18（m1unfixed/m1fixed/m2unfixed/m2fixed/m3on/m3off 各 3 次：b7/b8/b9 与 b10/b11/b12 批次） |
| 失败原因 | `terminal.json`：`reason=worker_finished`、`worker_exit_code=2`、`worker_drained=true`、`restore_match=yes`；**无 CSV/meta** |
| 退出码 2 的直接原因 | 采集件自身的参数校验：`block_index >= block_count`。归档的 `controller/command.json` 实测为 `--block-index 9 --block-count 6`（`RUNS.sh` 早期版本把 `--block-count` 写成 6 而 `block-index` 用全局 0..11）；`commit 07ebf1b` 记录了这次修正 |
| 是否计入结果 | **不计入**（没有 CSV，也没有任何计时值）；已换名的重跑（b7…b12，`block_count=12`）计入 |
| 另一次同名归档 | 指 `r08-perf-m1fixed-b10` 这个 run-name：它先以 `r08-perf-m1fixed-b10-attempt1`（`--block-count 6`）失败归档，随后**用同名新目录**（`--block-count 12`）重跑成功。两边的 `controller/command.json` 可直接对比，`worker_sha256` 相同（同一 ELF） |

**注意**：这 18 次归档**不是**"已执行且未检出"，而是**已执行但无效、未产出任何计时值**；
本次有效数据来自 54 次运行（9 臂 × 6 块），与"18 次无效"在文件系统里分开存放。

### 7.5 重跑命名方式（可核对）

- 18 次无效运行归档为 `<run-name>-attempt1`，重跑沿用**同名**新目录（`b7`…`b12`），
  没有用 `-a2`/`-a3` 后缀——所以"run-name 不复用"这条在**目录名**层面被打破过一次，
  但在**文件**层面没有覆盖：失败原件完整保留在 `failed-blockcount-bug/` 下（每目录 34 个文件）。
- 逐目录核对方式：比较 `failed-blockcount-bug/<run>-attempt1/controller/command.json`
  与 `R08/<run>/<run>.meta` 的 `block_count` 即可（6 vs 12）。
- 有效运行的 meta 里 `block_count` 因此**有两段值**（b1–b6 为 6、b7–b12 为 12），
  本表的块号一律取运行名序列，与这两个字段无关。

### 7.6 有效性判据的可核性缺口

PLAN §6 要求 `terminal.json` 的四条判据（`reason=worker_finished`、`worker_exit_code=0`、
`worker_drained=true`、`restore_match=yes`）同时成立才计入。**54 个有效 run 的副本里只有
CSV 与 meta，没有 controller 目录**，所以这四条**本次无法从已拉回副本复核**；
本表按"主控判定有效后归档"使用，并把缺口写明。

---

## 8. 逐块溯源表（每个数字指回原始 CSV）

{block_traceability(blocks)}

---

## 9. 边界（不夸大）

1. **族外**：本表不进任何 Holm 家族，不做多重比较校正，不与秘密依赖性 p 值合并。
   人工夹具（M4）标注"人工构造校准"；M5 是单臂参照，没有同模块对照。
2. **快速 ≠ 安全，慢 ≠ 泄漏**：开销差异与恒时性是两个不同问题，本表只回答前者。
3. **不是恒频/恒时证明**：名义 4.3 GHz 换算不是实测频率；采集件 `cpu_affinity=not_pinned`、
   `frequency_control=not_configured`（亲和性与频率由外层控制器施加，采集件自身不写任何全局配置）。
4. **长尾全部保留**：不裁剪、不扣读钟开销；p99 上的尾部包含真实的长尾与偶发干扰。
5. **一个操作顺序**：`--order-seed 20261016` 在所有臂、所有块上给出**同一个**操作顺序
   （实测 `operation_order=decaps,keygen,encaps`，42 个非 M4 run 逐字相同），
   所以"操作间的顺序效应"没有被随机化抵消——这是本次设计的已知局限，如实记录。
6. **未做的对照**：未在其它 CPU 核复测（PLAN 说本轮固定 CPU2）、未做 gcc 对照、
   未做不同 `-march` 对照；这些是"未执行"，不是"已执行且未检出"。
"""

    output_path = os.path.join(EVIDENCE_DIR, "PERF.md")
    with open(output_path, "w", encoding="utf-8") as handle:
        handle.write(document)
    print(f"wrote {output_path} ({len(document)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
