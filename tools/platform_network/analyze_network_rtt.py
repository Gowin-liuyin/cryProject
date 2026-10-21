#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""复算 T25 网络场景的客户端 RTT 统计与检测预算。

输入（只读）：
  <runs_root>/net-<arm>-<run>/<scenario>-rtt.csv   客户端 RTT 原始值
  <runs_root>/net-<arm>-<run>/<scenario>-server.txt 服务端摘要
  <runs_root>/net-<arm>-<run>/scenarios.txt      每档的执行结果
  <runs_root>/arms/arms.json                     三套臂的产物身份
输出：
  <runs_root>/rtt-summary.csv                    逐（臂, 运行, 档）的 RTT 分布
  <runs_root>/class-comparison.csv               逐（臂, 运行, 档）的五类输入对比
  <runs_root>/analysis.json                     机器可读汇总

口径（与 PLAN.md 一致）：
  * 客户端 RTT 是网络结论的唯一依据；服务端诊断不参与主分析。
  * 五个输入类别按 request_index % 5 轮转（valid / bit-flipped / random /
    message-zero / message-ones），每次 80 请求即每类 16 次。
  * 主类对是 message-zero vs message-ones（同为接受路径、仅消息位不同），
    用 Welch 检验 + 正态近似 95% CI；**族外，不做 Holm**。
  * 「本地基线」用 direct 档的同类对比：若本地都分不出，网络档更不可能分出。
  * 超时/丢失单列为删失；本轮六次运行均无丢失（acks 字节数与服务端完成数核对）。
  * 结论上限：只写「本预算下未检出」或「可分辨」，不写「没有远程泄露」。
"""

import argparse
import csv
import gzip
import json
import math
import os
import statistics
import sys
from pathlib import Path


def open_text(path):
    """归档里的逐样本文件可能是 .csv 或 .csv.gz，两种都要能读。"""
    if str(path).endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8", newline="")
    return open(path, "r", encoding="utf-8", newline="")

CATEGORY_NAMES = ("valid", "bit_flipped", "random", "message_zero", "message_ones")
SCENARIO_ORDER = ("direct", "loopback", "low", "mid", "high")
SCENARIO_LABELS = {
    "direct": "本地直调（基线）",
    "loopback": "回环 TCP（协议开销基线）",
    "low": "veth+netem 100us/20us",
    "mid": "veth+netem 1ms/200us",
    "high": "veth+netem 10ms/2ms",
}


def read_rtt(path):
    rows = []
    with open_text(path) as handle:
        for record in csv.DictReader(handle):
            rows.append({
                "request_index": int(record["request_index"]),
                "elapsed": int(record["elapsed_clock_counts"]),
                "clock_path": record["clock_path"],
            })
    return rows


def classify(request_index):
    return CATEGORY_NAMES[request_index % 5]


def welch_test(sample_a, sample_b):
    """Welch t 检验的原始 p（正态近似 erfc）与均值差、正态近似 95% CI。"""
    if len(sample_a) < 2 or len(sample_b) < 2:
        return None
    mean_a = statistics.fmean(sample_a)
    mean_b = statistics.fmean(sample_b)
    variance_a = statistics.variance(sample_a)
    variance_b = statistics.variance(sample_b)
    standard_error = math.sqrt(variance_a / len(sample_a) + variance_b / len(sample_b))
    difference = mean_a - mean_b
    if standard_error == 0.0:
        p_value = 0.0 if difference != 0.0 else 1.0
        return {
            "mean_a": mean_a, "mean_b": mean_b, "difference": difference,
            "standard_error": standard_error, "p_value": p_value,
            "ci_low": difference, "ci_high": difference,
            "pooled_sd": math.sqrt((variance_a + variance_b) / 2.0),
        }
    statistic = difference / standard_error
    p_value = math.erfc(abs(statistic) / math.sqrt(2.0))
    half_width = 1.959963984540054 * standard_error
    return {
        "mean_a": mean_a, "mean_b": mean_b, "difference": difference,
        "standard_error": standard_error, "p_value": p_value,
        "ci_low": difference - half_width, "ci_high": difference + half_width,
        "pooled_sd": math.sqrt((variance_a + variance_b) / 2.0),
    }


def percentile(sorted_values, fraction):
    """零基下标 floor(p*(n-1)+0.5) 的分位数（与仓库既有口径一致）。"""
    if not sorted_values:
        return None
    index = int(math.floor(fraction * (len(sorted_values) - 1) + 0.5))
    index = max(0, min(index, len(sorted_values) - 1))
    return sorted_values[index]


def read_local_direct(run_directory):
    """读本地直调档（measure 的 CSV），返回摘要与对比行。

    measure 自身按 sample_index % 5 轮转五类输入，**一次运行就产出全部五类**；
    因此这里按 CSV 自带的 `input_category` 列分组，而不是按文件名分组
    （采集脚本按类别各起一次运行是为了对齐口径，但分组必须以列为准）。
    """
    values_by_category = {name: [] for name in CATEGORY_NAMES}
    seen_files = 0
    for path in sorted(run_directory.glob("direct*.csv*")):
        if path.name.endswith(".cost") or path.name.endswith(".cost.gz"):
            continue
        seen_files += 1
        with open_text(path) as handle:
            for record in csv.DictReader(handle):
                category = record["input_category"].strip().replace("-", "_")
                if category not in values_by_category:
                    continue
                values_by_category[category].append(int(record["elapsed_nanoseconds"]))
    if not values_by_category["message_zero"] or not values_by_category["message_ones"]:
        return None
    # 五类都被覆盖才算一次完整的本地直调。
    if any(not values for values in values_by_category.values()):
        return None
    by_category = {name: sorted(values) for name, values in values_by_category.items()}
    all_values = sorted(value for values in by_category.values() for value in values)
    summary = {
        "run": run_directory.name,
        "arm": run_directory.name[len("net-"):].rsplit("-", 1)[0],
        "scenario": "direct",
        "label": SCENARIO_LABELS["direct"],
        "requests": len(all_values),
        "server_completed_decapsulations": len(all_values),
        "acknowledgement_bytes": 0,
        "censored_or_incomplete": False,
        "min_ns": all_values[0],
        "p10_ns": percentile(all_values, 0.10),
        "p50_ns": percentile(all_values, 0.50),
        "p90_ns": percentile(all_values, 0.90),
        "p99_ns": percentile(all_values, 0.99),
        "max_ns": all_values[-1],
        "mean_ns": statistics.fmean(all_values),
        "stdev_ns": statistics.stdev(all_values) if len(all_values) > 1 else None,
    }
    test = welch_test(by_category["message_zero"], by_category["message_ones"])
    comparison = {
        "run": run_directory.name,
        "arm": summary["arm"],
        "scenario": "direct",
        "label": SCENARIO_LABELS["direct"],
        "n_message_zero": len(by_category["message_zero"]),
        "n_message_ones": len(by_category["message_ones"]),
        "mean_message_zero_ns": test["mean_a"],
        "mean_message_ones_ns": test["mean_b"],
        "difference_ns": test["difference"],
        "standard_error_ns": test["standard_error"],
        "ci_low_ns": test["ci_low"],
        "ci_high_ns": test["ci_high"],
        "p_value": test["p_value"],
        "pooled_sd_ns": test["pooled_sd"],
        "mde_ns": 1.959963984540054 * test["standard_error"],
        "distinguishable": test["ci_low"] > 0.0 or test["ci_high"] < 0.0,
    }
    return {"summary": summary, "comparison": comparison}


def main():
    parser = argparse.ArgumentParser(description="复算 T25 网络场景 RTT 统计")
    parser.add_argument("--runs-root", required=True)
    arguments = parser.parse_args()
    runs_root = Path(arguments.runs_root)
    if not runs_root.is_dir():
        raise SystemExit("missing runs root: %s" % runs_root)

    arms_path = runs_root / "arms" / "arms.json"
    if not arms_path.is_file():
        arms_path = runs_root / "arms.json"
    if not arms_path.is_file():
        raise SystemExit("missing arms.json under %s" % runs_root)
    arms = json.loads(arms_path.read_text(encoding="utf-8"))["arms"]
    run_directories = sorted(
        path for path in runs_root.glob("net-*") if path.is_dir()
    )
    if not run_directories:
        raise SystemExit("no run directories under %s" % runs_root)

    summary_rows = []
    comparison_rows = []
    analysis = {"runs_root": str(runs_root), "runs": [], "arms": arms}

    for run_directory in run_directories:
        name = run_directory.name
        arm = name[len("net-"):].rsplit("-", 1)[0]
        run_label = name.rsplit("-", 1)[1]
        run_record = {"run": name, "arm": arm, "run_label": run_label, "scenarios": {}}
        for scenario in SCENARIO_ORDER:
            if scenario == "direct":
                # 本地直调档：来自 measure 的逐类 CSV（不走 socket），不是客户端 RTT。
                direct = read_local_direct(run_directory)
                if direct is not None:
                    summary_rows.append(direct["summary"])
                    comparison_rows.append(direct["comparison"])
                    run_record["scenarios"][scenario] = direct["summary"]
                continue
            rtt_path = run_directory / ("%s-rtt.csv" % scenario)
            if not rtt_path.is_file():
                rtt_path = run_directory / ("%s-rtt.csv.gz" % scenario)
            server_path = run_directory / ("%s-server.txt" % scenario)
            if not rtt_path.is_file():
                continue
            rows = read_rtt(rtt_path)
            acknowledgement_path = run_directory / ("%s-rtt.csv.acks" % scenario)
            acknowledgement_bytes = (
                acknowledgement_path.stat().st_size if acknowledgement_path.is_file() else 0
            )
            server_text = server_path.read_text(encoding="utf-8", errors="replace") if server_path.is_file() else ""
            completed = 0
            for line in server_text.splitlines():
                if line.startswith("completed_decapsulations="):
                    completed = int(line.split("=", 1)[1])
            values = sorted(row["elapsed"] for row in rows)
            by_category = {name: [] for name in CATEGORY_NAMES}
            for row in rows:
                by_category[classify(row["request_index"])].append(row["elapsed"])
            censored = len(rows) != completed
            summary = {
                "run": name, "arm": arm, "scenario": scenario,
                "label": SCENARIO_LABELS[scenario],
                "requests": len(rows),
                "server_completed_decapsulations": completed,
                "acknowledgement_bytes": acknowledgement_bytes,
                "censored_or_incomplete": censored,
                "min_ns": values[0] if values else None,
                "p10_ns": percentile(values, 0.10),
                "p50_ns": percentile(values, 0.50),
                "p90_ns": percentile(values, 0.90),
                "p99_ns": percentile(values, 0.99),
                "max_ns": values[-1] if values else None,
                "mean_ns": statistics.fmean(values) if values else None,
                "stdev_ns": statistics.stdev(values) if len(values) > 1 else None,
            }
            summary_rows.append(summary)
            run_record["scenarios"][scenario] = summary

            test = welch_test(by_category["message_zero"], by_category["message_ones"])
            if test is not None:
                comparison_rows.append({
                    "run": name, "arm": arm, "scenario": scenario,
                    "label": SCENARIO_LABELS[scenario],
                    "n_message_zero": len(by_category["message_zero"]),
                    "n_message_ones": len(by_category["message_ones"]),
                    "mean_message_zero_ns": test["mean_a"],
                    "mean_message_ones_ns": test["mean_b"],
                    "difference_ns": test["difference"],
                    "standard_error_ns": test["standard_error"],
                    "ci_low_ns": test["ci_low"],
                    "ci_high_ns": test["ci_high"],
                    "p_value": test["p_value"],
                    "pooled_sd_ns": test["pooled_sd"],
                    "mde_ns": 1.959963984540054 * test["standard_error"],
                    "distinguishable": test["ci_low"] > 0.0 or test["ci_high"] < 0.0,
                })
        analysis["runs"].append(run_record)

    summary_path = runs_root / "rtt-summary.csv"
    if summary_rows:
        field_names = list(summary_rows[0].keys())
        with open(summary_path, "w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=field_names)
            writer.writeheader()
            for row in summary_rows:
                writer.writerow(row)
    # —— 检测预算：把「本地可分辨的效应」放到各网络档的噪声里看 ——
    # 参照效应取 m1unfixed 的本地直调档差异（该机制在本地直调下已实测可分辨），
    # 是「本地差异有多大」的量，不是网络侧的假设。
    reference_effects = [
        row["difference_ns"] for row in comparison_rows
        if row["arm"] == "m1unfixed" and row["scenario"] == "direct"
    ]
    reference_effect_ns = statistics.fmean(reference_effects) if reference_effects else None
    budget_rows = []
    for row in comparison_rows:
        target = reference_effect_ns
        required_n = None
        if target is not None and abs(target) > 0.0 and row.get("pooled_sd_ns"):
            # 与 MDE 同口径：Welch 的 SE = SD·sqrt(2/n)，故 n = 2·(z·SD/|效应|)²。
            required_n = int(math.ceil(
                2.0 * (1.959963984540054 * row["pooled_sd_ns"] / abs(target)) ** 2))
        budget_rows.append({
            "arm": row["arm"],
            "run": row["run"],
            "scenario": row["scenario"],
            "n_per_class": row["n_message_zero"],
            "pooled_sd_ns": row.get("pooled_sd_ns"),
            "standard_error_ns": row["standard_error_ns"],
            "mde_ns": row.get("mde_ns"),
            "reference_local_effect_ns": target,
            "required_n_per_class_for_reference_effect": required_n,
            "achieved_budget_ratio": (
                (row["n_message_zero"] / required_n) if required_n else None),
        })
    if budget_rows:
        budget_path = runs_root / "detection-budget.csv"
        with open(budget_path, "w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(budget_rows[0].keys()))
            writer.writeheader()
            for row in budget_rows:
                writer.writerow(row)
        analysis["reference_local_effect_ns"] = reference_effect_ns
    analysis["reference_effect_note"] = (
        "参照效应 = m1unfixed 本地直调档各次运行差异的算术平均；"
        "该平均由一次可分辨、一次未检出的两次运行合并而来，本身 CI 含 0，只作量级参照。")
    analysis["required_n_convention"] = (
        "required_n = 2·(1.96·SD_pooled/|参照效应|)²，与 MDE 列同口径（Welch SE = SD·sqrt(2/n)）")

    comparison_path = runs_root / "class-comparison.csv"
    if comparison_rows:
        field_names = list(comparison_rows[0].keys())
        with open(comparison_path, "w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=field_names)
            writer.writeheader()
            for row in comparison_rows:
                writer.writerow(row)
    (runs_root / "analysis.json").write_text(
        json.dumps(analysis, ensure_ascii=False, indent=2, default=str) + "\n", encoding="utf-8")

    print("runs: %d, summary rows: %d, comparison rows: %d"
          % (len(run_directories), len(summary_rows), len(comparison_rows)))
    for row in comparison_rows:
        kind = "本地直调" if row["scenario"] == "direct" else "网络RTT"
        print("  %-22s %-9s %-6s diff=%9.1f CI=[%9.1f,%9.1f] p=%.4g %s"
              % (row["run"], row["scenario"], kind, row["difference_ns"], row["ci_low_ns"],
                 row["ci_high_ns"], row["p_value"],
                 "可分辨" if row["distinguishable"] else "未检出"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
