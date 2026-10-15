#!/usr/bin/env python3
"""T21：R08 性能开销表的本地计算工具（只读已采集数据，不联网、不改远端）。

输入：docs/evidence/r08-perf-20261016/remote/R08/<run-name>/*.csv.gz 与同名 .meta
输出：docs/evidence/r08-perf-20261016/perf.csv（汇总+对照）
      docs/evidence/r08-perf-20261016/perf.csv.blocks.csv（块级明细）
      docs/evidence/r08-perf-20261016/perf.csv.samples.csv（逐样本分位数口径）
      docs/evidence/r08-perf-20261016/PERF.md 由本工具打印到标准输出，由作者落盘

口径要点（与 PLAN §8 一致，且把 PLAN 没写死的地方写明）：
  * 单位换算：cycles = ns x BASE_FREQUENCY_KHZ / 1e6。基频取控制器锁定的名义频率
    4300000 kHz（TARGET_KHZ）。本轮 R08 归档里**没有** during.json/entry-probes.json，
    因此无法给逐运行 cur_khz 核对口径——这一点在 PERF.md 里如实写。
  * 「每次调用」是计时观测单位，不是独立重复单位：同一次运行内的 25000 次调用共享
    同一段频率/温度状态。因此均值的 95% CI 给两套：
      - 运行内（把块内调用当 i.i.d.）——下界，偏窄；
      - 块级（对 6 个块均值做 bootstrap 10000）——主口径，含块间漂移。
  * 开销% 用同一父模块的成对块（ABBA）做块级 bootstrap；另给独立合并口径作对照。
"""

from __future__ import annotations

import argparse
import csv
import glob
import gzip
import itertools
import os
import sys
from dataclasses import dataclass, field

import numpy as np

BASE_FREQUENCY_KHZ = 4300000
BOOTSTRAP_RESAMPLES = 10000
BOOTSTRAP_SEED = 20261016
NS_PER_CYCLE = 1e6 / BASE_FREQUENCY_KHZ  # 4300000 kHz -> 0.232558... ns/cycle

META_TO_CSV_ROOT = "docs/evidence/r08-perf-20261016/remote/R08"

# 臂 -> 模块、角色、对照臂。M5 是单臂，没有同模块对照（写 not_applicable）。
ARM_MODULE = {
    "m1unfixed": "M1",
    "m1fixed": "M1",
    "m2unfixed": "M2",
    "m2fixed": "M2",
    "m3on": "M3",
    "m3off": "M3",
    "m4vul": "M4",
    "m4ct": "M4",
    "m5ref": "M5",
}
ARM_ROLE = {
    "m1unfixed": "baseline_unfixed",
    "m1fixed": "treatment_fixed",
    "m2unfixed": "baseline_unfixed",
    "m2fixed": "treatment_fixed",
    "m3on": "baseline_variant_on",
    "m3off": "treatment_variant_off",
    "m4vul": "baseline_vulnerable",
    "m4ct": "treatment_constant_time",
    "m5ref": "reference_only",
}
ARM_TREATMENT = {
    "M1": "m1fixed",
    "M2": "m2fixed",
    "M3": "m3off",
    "M4": "m4ct",
}
ARM_BASELINE = {
    "M1": "m1unfixed",
    "M2": "m2unfixed",
    "M3": "m3on",
    "M4": "m4vul",
}
# M4 的窗口只包比较步，不与完整 decaps 混比；它的两个 input_category 是夹具用例。
M4_OPERATIONS = ("mismatch-first", "mismatch-last")
FULL_OPERATIONS = ("decaps", "keygen", "encaps")


@dataclass
class RunData:
    run_name: str
    arm: str
    implementation: str
    block_label: str
    block_index_meta: str
    block_count_meta: str
    executable_sha256: str
    csv_relative_path: str
    samples: dict[str, np.ndarray] = field(default_factory=dict)
    run_status: str = ""
    zero_elapsed_count: str = ""
    operation_order: str = ""
    timed_window_start_ns: int = 0
    time_unit: str = ""


def read_meta(meta_path: str) -> dict[str, str]:
    meta: dict[str, str] = {}
    with open(meta_path, "r", encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line or "=" not in line:
                continue
            key, value = line.split("=", 1)
            meta.setdefault(key, value)
    return meta


def read_csv_samples(csv_path: str) -> tuple[dict[str, list[int]], dict[str, int]]:
    """读 gzip CSV，按 input_category 分组返回原始纳秒值。"""
    grouped: dict[str, list[int]] = {}
    header: dict[str, int] = {}
    with gzip.open(csv_path, "rt", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        for column_index, column_name in enumerate(next(reader)):
            header[column_name] = column_index
        category_column = header["input_category"]
        elapsed_column = header["elapsed_nanoseconds"]
        for row in reader:
            grouped.setdefault(row[category_column], []).append(int(row[elapsed_column]))
    return grouped, header


def block_label_from_run_name(run_name: str) -> str:
    """按运行名序列数块：r08-perf-<arm>-b<N> -> b<N>（N 是该配对 12 次运行里的序号）。"""
    tail = run_name.rsplit("-", 1)[-1]
    return tail


def load_runs(root: str) -> list[RunData]:
    runs: list[RunData] = []
    for run_dir in sorted(glob.glob(os.path.join(root, "r08-perf-*"))):
        run_name = os.path.basename(run_dir)
        meta_candidates = sorted(glob.glob(os.path.join(run_dir, "*.meta")))
        csv_candidates = sorted(glob.glob(os.path.join(run_dir, "*.csv.gz")))
        if len(meta_candidates) != 1 or len(csv_candidates) != 1:
            raise SystemExit(
                f"{run_name}: 期望 1 个 .meta 与 1 个 .csv.gz，实际 "
                f"{len(meta_candidates)} / {len(csv_candidates)}"
            )
        meta = read_meta(meta_candidates[0])
        if "module" in meta and meta.get("module") == "M4":
            arm = "m4vul" if meta.get("variant") == "vulnerable" else "m4ct"
            implementation = meta.get("variant", "")
        else:
            arm = meta["arm"]
            implementation = meta["implementation"]
        grouped, _ = read_csv_samples(csv_candidates[0])
        samples = {category: np.asarray(values, dtype=np.int64) for category, values in grouped.items()}
        runs.append(
            RunData(
                run_name=run_name,
                arm=arm,
                implementation=implementation,
                block_label=block_label_from_run_name(run_name),
                block_index_meta=meta.get("block_index", ""),
                block_count_meta=meta.get("block_count", ""),
                executable_sha256=meta.get("executable_sha256", meta.get("executable_digest", "")),
                csv_relative_path=os.path.relpath(csv_candidates[0], os.getcwd()),
                samples=samples,
                run_status=meta.get("run_status", meta.get("collection_status", "")),
                zero_elapsed_count=meta.get("zero_elapsed_count", ""),
                operation_order=meta.get("operation_order", ""),
                timed_window_start_ns=int(meta.get("timed_window_start_ns", 0)),
                time_unit=meta.get("time_unit", meta.get("unit", "")),
            )
        )
    return runs


def bootstrap_mean_ci(values: np.ndarray, rng: np.random.Generator, resamples: int) -> tuple[float, float]:
    if values.size == 0:
        return (float("nan"), float("nan"))
    draws = rng.integers(0, values.size, size=(resamples, values.size))
    means = values[draws].mean(axis=1)
    return (float(np.percentile(means, 2.5)), float(np.percentile(means, 97.5)))


BOOTSTRAP_CHUNK = 250
ORDER_STATISTIC_RESAMPLES = 2000


def cycles(nanoseconds: float) -> float:
    return nanoseconds / NS_PER_CYCLE


def summarize(values: np.ndarray, rng: np.random.Generator) -> dict[str, float]:
    """一次 bootstrap 复采样同时给出均值/中位数/p90/p99 的 95% CI。

    均值 CI 用全部 BOOTSTRAP_RESAMPLES 次复采样；三个分位数是描述量，
    用同一批复采样里的前 ORDER_STATISTIC_RESAMPLES 次，避免重复抽 5 遍大矩阵。
    """
    sample_count = int(values.size)
    mean_ns = float(values.mean())
    median_ns = float(np.median(values))
    p90_ns = float(np.percentile(values, 90))
    p99_ns = float(np.percentile(values, 99))

    bootstrap_means = np.empty(BOOTSTRAP_RESAMPLES, dtype=float)
    bootstrap_medians: list[float] = []
    bootstrap_p90: list[float] = []
    bootstrap_p99: list[float] = []
    remaining = BOOTSTRAP_RESAMPLES
    while remaining > 0:
        chunk = min(BOOTSTRAP_CHUNK, remaining)
        draws = rng.integers(0, sample_count, size=(chunk, sample_count))
        resampled = values[draws]
        bootstrap_means[BOOTSTRAP_RESAMPLES - remaining : BOOTSTRAP_RESAMPLES - remaining + chunk] = (
            resampled.mean(axis=1)
        )
        if len(bootstrap_medians) < ORDER_STATISTIC_RESAMPLES:
            bootstrap_medians.extend(np.median(resampled, axis=1).tolist())
            bootstrap_p90.extend(np.percentile(resampled, 90, axis=1).tolist())
            bootstrap_p99.extend(np.percentile(resampled, 99, axis=1).tolist())
        remaining -= chunk
        del resampled, draws

    mean_lo = float(np.percentile(bootstrap_means, 2.5))
    mean_hi = float(np.percentile(bootstrap_means, 97.5))
    median_lo = float(np.percentile(bootstrap_medians, 2.5))
    median_hi = float(np.percentile(bootstrap_medians, 97.5))
    p90_lo = float(np.percentile(bootstrap_p90, 2.5))
    p90_hi = float(np.percentile(bootstrap_p90, 97.5))
    p99_lo = float(np.percentile(bootstrap_p99, 2.5))
    p99_hi = float(np.percentile(bootstrap_p99, 97.5))
    return {
        "sample_count": sample_count,
        "mean_ns": mean_ns,
        "mean_ci_low_ns": mean_lo,
        "mean_ci_high_ns": mean_hi,
        "median_ns": median_ns,
        "median_ci_low_ns": median_lo,
        "median_ci_high_ns": median_hi,
        "p90_ns": p90_ns,
        "p90_ci_low_ns": p90_lo,
        "p90_ci_high_ns": p90_hi,
        "p99_ns": p99_ns,
        "p99_ci_low_ns": p99_lo,
        "p99_ci_high_ns": p99_hi,
        "mean_cycles": cycles(mean_ns),
        "mean_ci_low_cycles": cycles(mean_lo),
        "mean_ci_high_cycles": cycles(mean_hi),
        "median_cycles": cycles(median_ns),
        "p90_cycles": cycles(p90_ns),
        "p99_cycles": cycles(p99_ns),
    }


def run_execution_order(run: RunData) -> tuple[int, float, int]:
    """运行先后：优先用 meta 的 CLOCK_MONOTONIC 窗口起点，缺失时退回运行名的块号。

    M4 夹具的 meta 用的是 CLOCK_MONOTONIC_RAW，没有 timed_window_start_ns，
    因此退回块号——这两臂的先后只能按块号排，文档里写明。
    """
    has_monotonic = run.timed_window_start_ns > 0
    return (0 if has_monotonic else 1, float(run.timed_window_start_ns), int(run.block_label[1:]))


def ordered_pairing(runs: list[RunData], module: str) -> list[list[RunData]]:
    """按实测先后把同模块两个臂排成 ABBA 配对单元（每单元 2 次运行，一臂一次）。

    配对依据是**运行先后**（窗口起点），不是 meta 的 block_index，也不是
    两臂块号相同——M1/M2/M3 每臂的 6 次运行块号互不相同（合计 12 个序号）。
    """
    participants = [run for run in runs if ARM_MODULE[run.arm] == module]
    participants.sort(key=run_execution_order)
    pairs: list[list[RunData]] = []
    for index in range(0, len(participants) - 1, 2):
        pairs.append([participants[index], participants[index + 1]])
    return pairs


def block_level_ci(block_means: list[float], rng: np.random.Generator) -> tuple[float, float, float]:
    array = np.asarray(block_means, dtype=float)
    mean = float(array.mean())
    low, high = bootstrap_mean_ci(array, rng, BOOTSTRAP_RESAMPLES)
    return mean, low, high


def main() -> int:
    parser = argparse.ArgumentParser(description="R08 性能表计算（T21）")
    parser.add_argument("--root", default=META_TO_CSV_ROOT, help="R08 采集目录")
    parser.add_argument("--out-csv", default="docs/evidence/r08-perf-20261016/perf.csv")
    parser.add_argument(
        "--emit-md",
        action="store_true",
        help="写完后调用 emit_r08_perf_md.py 由 CSV 重新生成 PERF.md",
    )
    arguments = parser.parse_args()

    rng = np.random.default_rng(BOOTSTRAP_SEED)
    runs = load_runs(arguments.root)
    print(f"# loaded {len(runs)} runs", file=sys.stderr)

    # 1) 逐（臂, 操作）汇总
    arms = sorted({run.arm for run in runs}, key=lambda name: (ARM_MODULE[name], name))
    summary_rows: list[dict[str, object]] = []
    block_rows: list[dict[str, object]] = []
    sample_rows: list[dict[str, object]] = []

    per_arm_operation: dict[tuple[str, str], dict[str, object]] = {}
    for arm in arms:
        arm_runs = sorted((run for run in runs if run.arm == arm), key=run_execution_order)
        operations = sorted({category for run in arm_runs for category in run.samples})
        for operation in operations:
            pooled = np.concatenate([run.samples[operation] for run in arm_runs if operation in run.samples])
            print(f"# summarize {arm} / {operation} (n={pooled.size})", file=sys.stderr, flush=True)
            stats = summarize(pooled, rng)
            block_means: list[float] = []
            block_labels: list[str] = []
            block_run_names: list[str] = []
            for run in arm_runs:
                if operation not in run.samples:
                    continue
                values = run.samples[operation]
                block_mean = float(values.mean())
                block_means.append(block_mean)
                block_labels.append(run.block_label)
                block_run_names.append(run.run_name)
                block_rows.append(
                    {
                        "module": ARM_MODULE[arm],
                        "arm": arm,
                        "operation": operation,
                        "block_label": run.block_label,
                        "block_index_meta": run.block_index_meta,
                        "block_count_meta": run.block_count_meta,
                        "run_name": run.run_name,
                        "sample_count": int(values.size),
                        "block_mean_ns": block_mean,
                        "block_median_ns": float(np.median(values)),
                        "block_p90_ns": float(np.percentile(values, 90)),
                        "block_p99_ns": float(np.percentile(values, 99)),
                        "block_mean_cycles": cycles(block_mean),
                        "csv_relative_path": run.csv_relative_path,
                    }
                )
            block_mean, block_low, block_high = block_level_ci(block_means, rng)
            block_array = np.asarray(block_means, dtype=float)
            drift_slope, drift_low, drift_high, drift_p = drift_slope_and_permutation(block_array, rng)
            summary_rows.append(
                {
                    "module": ARM_MODULE[arm],
                    "arm": arm,
                    "arm_role": ARM_ROLE[arm],
                    "operation": operation,
                    "comparison_scope": "M4_compare_step_only" if arm.startswith("m4") else "full_kem_call",
                    "block_count": len(block_means),
                    "n_calls_pooled": stats["sample_count"],
                    "pooled_mean_ns": stats["mean_ns"],
                    "pooled_mean_ci_low_ns": stats["mean_ci_low_ns"],
                    "pooled_mean_ci_high_ns": stats["mean_ci_high_ns"],
                    "pooled_median_ns": stats["median_ns"],
                    "pooled_median_ci_low_ns": stats["median_ci_low_ns"],
                    "pooled_median_ci_high_ns": stats["median_ci_high_ns"],
                    "pooled_p90_ns": stats["p90_ns"],
                    "pooled_p90_ci_low_ns": stats["p90_ci_low_ns"],
                    "pooled_p90_ci_high_ns": stats["p90_ci_high_ns"],
                    "pooled_p99_ns": stats["p99_ns"],
                    "pooled_p99_ci_low_ns": stats["p99_ci_low_ns"],
                    "pooled_p99_ci_high_ns": stats["p99_ci_high_ns"],
                    "block_mean_of_means_ns": block_mean,
                    "block_mean_ci_low_ns": block_low,
                    "block_mean_ci_high_ns": block_high,
                    "block_mean_spread_ns": float(block_array.max() - block_array.min()),
                    "block_mean_iqr_ns": float(np.percentile(block_array, 75) - np.percentile(block_array, 25)),
                    "pooled_mean_cycles": stats["mean_cycles"],
                    "pooled_mean_ci_low_cycles": stats["mean_ci_low_cycles"],
                    "pooled_mean_ci_high_cycles": stats["mean_ci_high_cycles"],
                    "pooled_median_cycles": stats["median_cycles"],
                    "pooled_p90_cycles": stats["p90_cycles"],
                    "pooled_p99_cycles": stats["p99_cycles"],
                    "base_frequency_khz": BASE_FREQUENCY_KHZ,
                    "block_labels_in_execution_order": "|".join(block_labels),
                    "block_run_names_in_execution_order": "|".join(block_run_names),
                    "block_means_ns": "|".join(f"{value:.1f}" for value in block_means),
                    "block_mean_relative_spread_percent": (
                        100.0 * float(block_array.max() - block_array.min()) / float(block_array.mean())
                    ),
                    "drift_ns_per_block": drift_slope,
                    "drift_ns_per_block_ci_low": drift_low,
                    "drift_ns_per_block_ci_high": drift_high,
                    "drift_relative_percent_per_block": 100.0 * drift_slope / float(block_array.mean()),
                    "drift_permutation_p_two_sided": drift_p,
                    "csv_relative_paths": "|".join(run.csv_relative_path for run in arm_runs),
                }
            )
            per_arm_operation[(arm, operation)] = {
                "pooled": pooled,
                "block_means": block_means,
                "summary": summary_rows[-1],
            }
            for label, mean_ns, median_ns, p90_ns, p99_ns in (
                (
                    "pooled_n_calls",
                    stats["mean_ns"],
                    stats["median_ns"],
                    stats["p90_ns"],
                    stats["p99_ns"],
                ),
                (
                    "block_mean_of_means",
                    block_mean,
                    float(np.median(block_means)),
                    float(np.percentile(block_means, 90)),
                    float(np.percentile(block_means, 99)),
                ),
            ):
                sample_rows.append(
                    {
                        "module": ARM_MODULE[arm],
                        "arm": arm,
                        "operation": operation,
                        "scope": label,
                        "unit": "ns",
                        "mean": mean_ns,
                        "median": median_ns,
                        "p90": p90_ns,
                        "p99": p99_ns,
                        "mean_cycles": cycles(mean_ns),
                        "median_cycles": cycles(median_ns),
                        "p90_cycles": cycles(p90_ns),
                        "p99_cycles": cycles(p99_ns),
                    }
                )

    # 2) 成对开销（同模块 baseline -> treatment）
    comparison_rows: list[dict[str, object]] = []
    for module, treatment in sorted(ARM_TREATMENT.items()):
        baseline = ARM_BASELINE[module]
        print(f"# compare {module}: {baseline} -> {treatment}", file=sys.stderr, flush=True)
        operations = sorted(
            {operation for (arm, operation) in per_arm_operation if arm in (baseline, treatment)}
        )
        pairs = ordered_pairing(runs, module)
        for operation in operations:
            ratios: list[float] = []
            differences: list[float] = []
            pair_descriptions: list[str] = []
            for pair in pairs:
                baseline_run = next((run for run in pair if run.arm == baseline), None)
                treatment_run = next((run for run in pair if run.arm == treatment), None)
                if baseline_run is None or treatment_run is None:
                    continue
                if operation not in baseline_run.samples or operation not in treatment_run.samples:
                    continue
                baseline_mean = float(baseline_run.samples[operation].mean())
                treatment_mean = float(treatment_run.samples[operation].mean())
                ratios.append((treatment_mean - baseline_mean) / baseline_mean)
                differences.append(treatment_mean - baseline_mean)
                pair_descriptions.append(f"{baseline_run.run_name}+{treatment_run.run_name}")
            ratio_array = np.asarray(ratios, dtype=float)
            difference_array = np.asarray(differences, dtype=float)
            rng_pair = np.random.default_rng(BOOTSTRAP_SEED + 1)
            picks = rng_pair.integers(0, ratio_array.size, size=(BOOTSTRAP_RESAMPLES, ratio_array.size))
            ratio_draws = ratio_array[picks].mean(axis=1)
            difference_draws = difference_array[picks].mean(axis=1)
            pooled_baseline = per_arm_operation[(baseline, operation)]["pooled"]
            pooled_treatment = per_arm_operation[(treatment, operation)]["pooled"]
            pooled_ratio = (
                (float(pooled_treatment.mean()) - float(pooled_baseline.mean())) / float(pooled_baseline.mean())
            )
            rng_independent = np.random.default_rng(BOOTSTRAP_SEED + 2)
            independent_draws = np.empty(BOOTSTRAP_RESAMPLES, dtype=float)
            baseline_draws = rng_independent.integers(
                0, pooled_baseline.size, size=(BOOTSTRAP_RESAMPLES, pooled_baseline.size)
            ).mean(axis=1)
            treatment_draws = rng_independent.integers(
                0, pooled_treatment.size, size=(BOOTSTRAP_RESAMPLES, pooled_treatment.size)
            ).mean(axis=1)
            independent_draws[:] = (treatment_draws - baseline_draws) / baseline_draws
            comparison_rows.append(
                {
                    "module": module,
                    "comparison": f"{baseline} -> {treatment}",
                    "baseline_arm": baseline,
                    "treatment_arm": treatment,
                    "operation": operation,
                    "comparison_scope": "M4_compare_step_only" if module == "M4" else "full_kem_call",
                    "paired_units": len(ratios),
                    "paired_units_detail": "|".join(pair_descriptions),
                    "baseline_mean_ns": float(pooled_baseline.mean()),
                    "treatment_mean_ns": float(pooled_treatment.mean()),
                    "overhead_percent_paired": float(ratio_array.mean() * 100.0),
                    "overhead_percent_paired_ci_low": float(np.percentile(ratio_draws, 2.5) * 100.0),
                    "overhead_percent_paired_ci_high": float(np.percentile(ratio_draws, 97.5) * 100.0),
                    "delta_ns_paired": float(difference_array.mean()),
                    "delta_ns_paired_ci_low": float(np.percentile(difference_draws, 2.5)),
                    "delta_ns_paired_ci_high": float(np.percentile(difference_draws, 97.5)),
                    "overhead_percent_pooled": pooled_ratio * 100.0,
                    "overhead_percent_pooled_ci_low": float(np.percentile(independent_draws, 2.5) * 100.0),
                    "overhead_percent_pooled_ci_high": float(np.percentile(independent_draws, 97.5) * 100.0),
                    "delta_ns_pooled": float(pooled_treatment.mean()) - float(pooled_baseline.mean()),
                    "baseline_run_level_mean_ns": per_arm_operation[(baseline, operation)]["summary"][
                        "block_mean_of_means_ns"
                    ],
                    "treatment_run_level_mean_ns": per_arm_operation[(treatment, operation)]["summary"][
                        "block_mean_of_means_ns"
                    ],
                    "delta_ns_per_paired_unit": "|".join(f"{value:.1f}" for value in difference_array),
                    "overhead_percent_per_paired_unit": "|".join(
                        f"{value * 100.0:.4f}" for value in ratio_array
                    ),
                }
            )

    os.makedirs(os.path.dirname(arguments.out_csv), exist_ok=True)
    write_csv(arguments.out_csv, summary_rows)
    write_csv(arguments.out_csv + ".comparison.csv", comparison_rows)
    write_csv(arguments.out_csv + ".blocks.csv", block_rows)
    write_csv(arguments.out_csv + ".samples.csv", sample_rows)
    print(
        f"# wrote {arguments.out_csv}: {len(summary_rows)} summary rows, "
        f"{len(comparison_rows)} comparison rows, {len(block_rows)} block rows",
        file=sys.stderr,
    )
    if arguments.emit_md:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import emit_r08_perf_md

        emit_r08_perf_md.main()
    return 0


def drift_slope_and_permutation(
    block_means: np.ndarray,
    rng: np.random.Generator,
) -> tuple[float, float, float, float]:
    """块均值对执行顺序的斜率，加**精确置换检验**与 **bootstrap 斜率 CI**。

    置换的对象是"块均值 ↔ 时间位置"的对应关系（固定 6 个时间位置，重排 6 个观测值），
    穷举 6! = 720 种；左侧统计量用与斜率等价的中心化内积
    `sum((y-ȳ)·(t-t̄))`（分母是常数，不影响比较）。p = |统计量| 不小于观测值的比例。
    斜率本身的 95% CI 用 bootstrap 重采样 6 个块（描述量，不做多重比较校正）。
    返回 (slope, bootstrap 2.5 分位, bootstrap 97.5 分位, 精确置换双侧 p)。
    """
    positions = np.arange(block_means.size, dtype=float)
    slope = float(np.polyfit(positions, block_means, 1)[0])
    centered_values = block_means - block_means.mean()
    centered_positions = positions - positions.mean()
    denominator = float((centered_positions**2).sum())
    observed = float((centered_values * centered_positions).sum())
    permutations = list(itertools.permutations(range(block_means.size)))
    permuted = np.asarray(
        [
            float((centered_values[list(order)] * centered_positions).sum())
            for order in permutations
        ]
    )
    p_value = float((np.abs(permuted) >= abs(observed) - 1e-9).mean())

    draws = rng.integers(0, block_means.size, size=(BOOTSTRAP_RESAMPLES, block_means.size))
    slopes = np.asarray(
        [
            float(np.polyfit(positions, block_means[draw], 1)[0])
            if np.unique(draw).size >= 2
            else slope
            for draw in draws
        ]
    )
    return (
        slope,
        float(np.percentile(slopes, 2.5)),
        float(np.percentile(slopes, 97.5)),
        p_value,
    )


def write_csv(path: str, rows: list[dict[str, object]]) -> None:
    if not rows:
        print(f"# {path}: no rows", file=sys.stderr)
        return
    field_names: list[str] = []
    for row in rows:
        for key in row:
            if key not in field_names:
                field_names.append(key)
    with open(path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=field_names)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: format_value(row.get(key, "")) for key in field_names})


def format_value(value: object) -> object:
    if isinstance(value, float):
        return f"{value:.6f}"
    return value


if __name__ == "__main__":
    raise SystemExit(main())
