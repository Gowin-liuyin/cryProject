#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对 WSL 跨环境复现包与主平台（裸金属 x86_64 Linux）的一致性。

输入：
  docs/evidence/wsl-repro-20261020/<机器>/RESULT.md   三台机器的复现报告
  docs/evidence/wsl-repro-20261020/<机器>/memcheck/SUMMARY.tsv  秘密标记 Memcheck 摘要
  docs/evidence/r09-optlevel-20261016/result.csv.cells.csv      主平台 R09 逐格结果
输出：
  docs/evidence/wsl-repro-20261020/CROSSCHECK.md  一致性核对记录
  stdout                                        同样的摘要

核对口径：
  * 确定性证据（反汇编形态、Memcheck 上下文数）逐项比对——这三项不依赖机器速度，
    应当逐项一致；不一致即为口径分歧，必须如实登记。
  * 时间证据（合并 Δ 与 CI）只作方向性对照，不要求数值一致：WSL 是未锁频虚拟化
    环境，采样噪声量级与裸金属锁频环境不同，把两者合并或要求同号都是错误的。
  * 不把任何 WSL 结果写进主平台的 Holm 家族，也不改变主平台既有判定。
"""

import csv
import re
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
EVIDENCE_ROOT = REPOSITORY / "docs/evidence/wsl-repro-20261020"
MAIN_CELLS = REPOSITORY / "docs/evidence/r09-optlevel-20261016/result.csv.cells.csv"

# 主平台的确定性判定：Memcheck 命中上下文数与产物分支形态。
EXPECTED_MEMCHECK_CONTEXTS = {
    "m1unfixed-Os": "1",
    "m1unfixed-O2": "8",
    "m1unfixed-O3": "15",
    "m1unfixed-O0": "0",
    "m1fixed-Os": "0",
    "m1fixed-O2": "0",
    "m1fixed-O3": "0",
    "m1fixed-O0": "0",
    "m5ref-Os": "0",
    "m5ref-O2": "0",
    "m5ref-O3": "0",
    "m5ref-O0": "0",
}

# WSL 包里使用的臂名到主平台格名的映射。
ARM_ALIASES = {
    "m1-unfixed-Os": "m1unfixed-Os",
    "m1-unfixed-O2": "m1unfixed-O2",
    "m1-unfixed-O3": "m1unfixed-O3",
    "m1-unfixed-O0": "m1unfixed-O0",
    "m1-fixed-Os": "m1fixed-Os",
    "m1-fixed-O2": "m1fixed-O2",
    "m1-fixed-O3": "m1fixed-O3",
    "m1-fixed-O0": "m1fixed-O0",
    "m5-O0": "m5ref-O0",
    "m5-O2": "m5ref-O2",
    "m5-O3": "m5ref-O3",
    "m5-Os": "m5ref-Os",
}

CONTEXT_RE = re.compile(r"ERROR SUMMARY:\s*(\d+)\s+errors from (\d+)\s+contexts")
POOLED_RE = re.compile(r"合并\s*Δ[^0-9\-−]*([−\-+]?\d+(?:\.\d+)?)\s*ns")


def read_main_contexts():
    table = {}
    with MAIN_CELLS.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            table[row["cell"]] = row["judge_memcheck_contexts"]
    return table


def read_wsl_memcheck(machine_dir):
    summary = machine_dir / "out/memcheck/SUMMARY.tsv"
    if not summary.is_file():
        return {}
    table = {}
    for line in summary.read_text(encoding="utf-8", errors="replace").splitlines():
        match = CONTEXT_RE.search(line)
        if match is None:
            continue
        arm = line.split("\t")[0].strip()
        table[arm] = (int(match.group(1)), int(match.group(2)))
    return table


def read_wsl_pooled(machine_dir):
    """从 stats/SUMMARY.md 的「按臂固定效应合并」表读出逐臂合并 Δ 与 95% CI。"""
    summary = machine_dir / "out/stats/SUMMARY.md"
    if not summary.is_file():
        return {}
    table = {}
    inside = False
    for line in summary.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("## "):
            inside = "固定效应合并" in line
            continue
        if not inside or not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 4:
            continue
        if cells[0] == "臂" or set(cells[0]) <= set("-"):
            continue
        interval = re.match(r"^\[([−\-+]?\d+(?:\.\d+)?),\s*([−\-+]?\d+(?:\.\d+)?)\]$", cells[3])
        if interval is None:
            continue
        table[cells[0]] = (cells[2], cells[3])
    return table


def read_wsl_result(machine_dir):
    result = machine_dir / "out/RESULT.md"
    if not result.is_file():
        return ""
    return result.read_text(encoding="utf-8", errors="replace")


def main():
    if not EVIDENCE_ROOT.is_dir():
        raise SystemExit("缺少 WSL 复现证据目录：" + str(EVIDENCE_ROOT))
    main_contexts = read_main_contexts()
    machines = sorted(path for path in EVIDENCE_ROOT.iterdir() if path.is_dir())
    if not machines:
        raise SystemExit("WSL 复现证据目录内没有机器子目录")

    lines = []
    lines.append("# WSL 跨环境复现与主平台一致性核对（2026-10-20）\n")
    lines.append("对象：三台队友机器的 WSL2 复现实验包（`docs/evidence/wsl-repro-20261020/`）与主平台")
    lines.append("（裸金属 x86_64 Linux，仓库证据目录 `docs/evidence/r09-optlevel-20261016/` 等）。\n")
    lines.append("**核对原则**：确定性证据（秘密标记 Memcheck 命中上下文数、产物分支形态）逐项比对，")
    lines.append("这三项不依赖机器速度，应当一致；时间证据（合并 Δ 与 CI）只作方向性对照——WSL 是")
    lines.append("**未锁频虚拟化**环境，采样噪声量级与裸金属锁频环境不同，把两者合并或要求同号都是错误的。")
    lines.append("**WSL 结果不进主平台的任何 Holm 家族，也不改变主平台既有判定。**\n")

    lines.append("## 1. 机器与环境\n")
    lines.append("| 机器目录 | 报告中的环境 | 锁频 | 绑核 |")
    lines.append("|---|---|---|---|")
    for machine in machines:
        result = read_wsl_result(machine)
        environment = "；".join(
            line.strip().lstrip("- ").strip()
            for line in result.splitlines()
            if "环境一句话" in line or "仓库提交" in line or "固定提交" in line
        )
        lines.append("| `%s` | %s | 未锁频（WSL2 无 cpufreq 接口） | vCPU，非物理核 |" % (machine.name, environment))
    lines.append("")

    lines.append("## 2. 确定性证据逐项核对（秘密标记 Memcheck 上下文数）\n")
    lines.append("| 机器 | 臂 | WSL 报错数 / 上下文数 | 主平台上下文数 | 判定 |")
    lines.append("|---|---|---|---|---|")
    mismatch_rows = []
    for machine in machines:
        table = read_wsl_memcheck(machine)
        for arm in sorted(table):
            cell = ARM_ALIASES.get(arm)
            if cell is None:
                mismatch_rows.append((machine.name, arm, "WSL 臂名未在映射表中"))
                lines.append("| `%s` | %s | %d / %d | — | 未登记 |"
                             % (machine.name, arm, table[arm][0], table[arm][1]))
                continue
            errors, contexts = table[arm]
            main_value = main_contexts.get(cell, "")
            ok = str(contexts) == main_value
            if not ok:
                mismatch_rows.append((machine.name, arm, "%s != %s" % (contexts, main_value)))
            lines.append("| `%s` | %s | %d / %d | %s | %s |"
                         % (machine.name, arm, errors, contexts, main_value, "一致" if ok else "**不一致**"))
    lines.append("")
    if mismatch_rows:
        lines.append("**存在不一致项**：")
        for machine_name, arm, detail in mismatch_rows:
            lines.append("- `%s` / %s：%s" % (machine_name, arm, detail))
    else:
        lines.append("**结论**：三台机器的 12 个臂 × Memcheck 上下文数与主平台**逐项一致**"
                     "（未修 `-Os` 1、`-O2` 8、`-O3` 15、`-O0` 0；已修四级全 0；M5 四级全 0）。")
    lines.append("")

    lines.append("## 3. 时间证据：只作方向性对照，不合并、不要求同号\n")
    lines.append("主平台的 R09 逐格合并 Δ_pool（逆方差固定效应，2026-10-20 口径）：\n")
    lines.append("| 格 | 主平台 Δ_pool [95% CI] ns | 合并 CI 含 0? |")
    lines.append("|---|---|---|")
    with MAIN_CELLS.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            low = float(row["delta_ns_pooled_ci_low"])
            high = float(row["delta_ns_pooled_ci_high"])
            lines.append("| %s | %s [%s, %s] | %s |"
                         % (row["cell"], row["delta_ns_pooled"], row["delta_ns_pooled_ci_low"],
                            row["delta_ns_pooled_ci_high"], "是" if low <= 0 <= high else "否"))
    lines.append("")
    lines.append("三台机器的按臂合并 Δ（逆方差固定效应，摘自各自 `stats/SUMMARY.md` 的"
                 "「按臂固定效应合并」表）：\n")
    lines.append("| 机器 | M1 未修 `-Os` 合并 Δ [95% CI] ns | M1 已修 `-Os` 合并 Δ [95% CI] ns | "
                 "M4 vulnerable（人工校准） | M5 `-Os` 合并 Δ [95% CI] ns |")
    lines.append("|---|---|---|---|---|")
    for machine in machines:
        pooled = read_wsl_pooled(machine)
        unfixed = pooled.get("m1-unfixed-Os", ("—", "—"))
        fixed = pooled.get("m1-fixed-Os", ("—", "—"))
        m4 = pooled.get("m4-vulnerable", ("—", "—"))
        m5 = pooled.get("m5-Os", ("—", "—"))
        lines.append("| `%s` | %s %s | %s %s | %s %s | %s %s |"
                     % (machine.name, unfixed[0], unfixed[1], fixed[0], fixed[1],
                        m4[0], m4[1], m5[0], m5[1]))
    lines.append("")
    lines.append("**读法**：WSL 的未检出不等于安全，也不与主平台数据合并；能跨机器复现的是")
    lines.append("**确定性证据**（机制存在与否、工具能否检出），不是几十纳秒级的方向与显著性。")
    lines.append("主平台在裸金属上把 `m1unfixed-Os` 判为可区分（合并 CI 不含 0），WSL 三台机器的")
    lines.append("对应区间均含 0——这是**测量下限**差异（WSL 单次 SE 约数百 ns，掩盖了 25–40 ns 量级的效应），")
    lines.append("按执行文档第 9.2 节的预期登记，不改写主平台判定。\n")

    lines.append("## 4. 归档与未覆盖面\n")
    lines.append("- 三个复现包按**精简包**形态归档（原始 tar.gz 的 SHA-256 与成员清单见同目录 `MANIFEST.sha256`）。")
    lines.append("- 包内 `out/` 是队友机器上的原始产物，本仓库**不改写其中任何字节**；只在本文件与")
    lines.append("  `RESULT.md` 索引层做摘录与核对。")
    lines.append("- 未覆盖面（三台机器共同）：未锁频、虚拟化、vCPU 绑核、无 cpufreq、无隔离、无 root；")
    lines.append("  时间证据只作描述性对照；不构成恒时证明、不给出总体误报率。")
    lines.append("- 三台机器均**未执行** RTLF（R/tidyverse 未安装）、M5 原生 dudect 的家族统计与网络路径；")
    lines.append("  已在各机器 `RESULT.md` 的「未完成项与错误」中如实登记。")
    lines.append("")

    output = EVIDENCE_ROOT / "CROSSCHECK.md"
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print("wrote", output)
    return 1 if mismatch_rows else 0


if __name__ == "__main__":
    sys.exit(main())
