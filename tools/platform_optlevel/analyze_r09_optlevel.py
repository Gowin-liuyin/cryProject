#!/usr/bin/env python3
"""T24：R09 优化级别统计（只读已采集 CSV + T22 判定表，本地计算）。

输入：
  docs/evidence/r09-optlevel-20261016/remote/R09/<run-name>/<run-name>.csv.gz + .meta
  docs/evidence/r09-optlevel-20261016/disasm/CELLS.tsv（T22 判定，24 列机器可读版）
  docs/evidence/r09-optlevel-20261016/memcheck/SUMMARY.tsv（T22 Memcheck 计数）
输出：
  docs/evidence/r09-optlevel-20261016/result.csv（每格每种子 + 每格汇总，族外）
  供 RESULT.md 引用的汇总数字打印到标准输出。

统计口径（PLAN §5.3）：
  * 主类对 message-zero - message-ones，Δ>0 表示 zero 比 ones 慢。
  * 每次运行给: Δ、Welch 原始 p、95% 大样本正态近似 CI（PLAN 口径）。
  * 每格跨 3 个种子：Δ 用块级 bootstrap（重采样 3 个种子的 Δ）给 95% CI（本工具补充口径）。
  * 不做 Holm、不做任何多重比较校正（族外描述）。
"""

from __future__ import annotations

import argparse
import csv
import glob
import gzip
import math
import os
import re
import sys
from dataclasses import dataclass

import numpy as np

BOOTSTRAP_RESAMPLES = 10000
BOOTSTRAP_SEED = 20261016
PRIMARY_PAIR = ("message-zero", "message-ones")
CELL_PATTERN = re.compile(r"^r09-(o0|o2|o3|os)-(m1unfixed|m1fixed|m5ref)-s([123])(r\d+)?$")
LEVEL_ORDER = ("-O0", "-O2", "-O3", "-Os")
ARM_ORDER = ("m1unfixed", "m1fixed", "m5ref")


@dataclass
class RunRecord:
    run_name: str
    cell: str
    arm: str
    level: str
    seed_index: int
    cpu_policy_hint: str
    samples: dict[str, np.ndarray]
    executable_digest: str
    csv_relative_path: str


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


def read_csv_samples(csv_path: str) -> dict[str, list[int]]:
    grouped: dict[str, list[int]] = {}
    with gzip.open(csv_path, "rt", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        header = {name: index for index, name in enumerate(next(reader))}
        category_column = header["input_category"]
        elapsed_column = header["elapsed_nanoseconds"]
        for row in reader:
            grouped.setdefault(row[category_column], []).append(int(row[elapsed_column]))
    return grouped


def load_runs(root: str) -> list[RunRecord]:
    records: list[RunRecord] = []
    for run_dir in sorted(glob.glob(os.path.join(root, "r09-*"))):
        run_name = os.path.basename(run_dir)
        match = CELL_PATTERN.match(run_name)
        if match is None:
            raise SystemExit(f"{run_name}: 运行名不符合 r09-<level>-<arm>-s<n> 约定")
        level_token, arm, seed_digit, _retry = match.groups()
        meta = read_meta(glob.glob(os.path.join(run_dir, "*.meta"))[0])
        grouped = read_csv_samples(glob.glob(os.path.join(run_dir, "*.csv.gz"))[0])
        records.append(
            RunRecord(
                run_name=run_name,
                cell=meta.get("cell", f"{arm}-{level_token.upper()}"),
                arm=arm,
                level=meta.get("optimization_level", "-" + level_token.upper()),
                seed_index=int(seed_digit),
                cpu_policy_hint="cpu2" if int(seed_digit) in (1, 2) else "cpu6",
                samples={name: np.asarray(values, dtype=np.int64) for name, values in grouped.items()},
                executable_digest=meta.get("executable_digest", ""),
                csv_relative_path=os.path.relpath(
                    glob.glob(os.path.join(run_dir, "*.csv.gz"))[0], os.getcwd()
                ),
            )
        )
    return records


def welch_p_value(reference: np.ndarray, other: np.ndarray) -> float:
    """双侧 Welch t 检验的原始 p（正态近似；只作族外描述，不做校正）。"""
    count_a = reference.size
    count_b = other.size
    mean_a = float(reference.mean())
    mean_b = float(other.mean())
    variance_a = float(reference.var(ddof=1))
    variance_b = float(other.var(ddof=1))
    standard_error = math.sqrt(variance_a / count_a + variance_b / count_b)
    if standard_error == 0.0:
        return 0.0 if mean_a != mean_b else 1.0
    statistic = (mean_a - mean_b) / standard_error
    # 双侧 p = 2 * (1 - Phi(|t|))，用 erfc 提高尾部精度。
    return math.erfc(abs(statistic) / math.sqrt(2.0))


def delta_ci_normal(reference: np.ndarray, other: np.ndarray) -> tuple[float, float]:
    """PLAN §5.3 的 95% 大样本正态近似 CI（对 Δ = mean(reference) - mean(other)）。"""
    count_a = reference.size
    count_b = other.size
    standard_error = math.sqrt(
        float(reference.var(ddof=1)) / count_a + float(other.var(ddof=1)) / count_b
    )
    delta = float(reference.mean()) - float(other.mean())
    return (delta - 1.959963984540054 * standard_error, delta + 1.959963984540054 * standard_error)


def read_cells_tsv(disasm_dir: str) -> dict[str, dict[str, str]]:
    table: dict[str, dict[str, str]] = {}
    with open(os.path.join(disasm_dir, "CELLS.tsv"), "r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            table[row["cell"]] = row
    return table


def read_elf_digests(disasm_dir: str) -> dict[str, str]:
    """disasm/CELLS.sha256 里每格 measure= 的摘要（T22 判定的那个产物）。"""
    table: dict[str, str] = {}
    with open(os.path.join(disasm_dir, "CELLS.sha256"), "r", encoding="utf-8") as handle:
        for line in handle:
            parts = line.split()
            if len(parts) < 2:
                continue
            cell = parts[0]
            for token in parts[1:]:
                if token.startswith("measure="):
                    table[cell] = token.split("=", 1)[1]
    return table


def verify_timed_against_judged(runs: list[RunRecord], elf_digests: dict[str, str]) -> None:
    """两项可查的产物一致性：

    1. 同一格内 3 个种子的 measure 二进制摘要必须相同（否则三种子不可合并）；
    2. T22 判定产物的 sha256 与 T23 meta 的 executable_digest **算法不同**
       （T22 用 sha256，meta 自报 SHA3-256），因此只能并列记录，不能断言相等。
    """
    by_cell: dict[str, set[str]] = {}
    for run in runs:
        by_cell.setdefault(run.cell, set()).add(run.executable_digest)
    unstable = {cell: sorted(values) for cell, values in by_cell.items() if len(values) > 1}
    if unstable:
        raise SystemExit(f"同一格内 measure 摘要不一致，三种子不可合并：{unstable}")
    missing = [cell for cell in by_cell if cell not in elf_digests]
    print(
        f"# measure digest: {len(by_cell)} cells x 3 seeds, single digest per cell (stable); "
        f"judged sha256 recorded for {len(elf_digests)} cells; missing judged digest: {missing or 'none'}",
        file=sys.stderr,
    )
    print(
        "# NOTE: T22 judged artifact digest is sha256, T23 meta executable_digest declares SHA3-256; "
        "the two are recorded side by side and are NOT asserted equal.",
        file=sys.stderr,
    )


def read_memcheck_summary(memcheck_dir: str) -> dict[str, dict[str, str]]:
    table: dict[str, dict[str, str]] = {}
    with open(os.path.join(memcheck_dir, "SUMMARY.tsv"), "r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            key = row.get("cell") or row.get("cell_name") or ""
            table[key] = row
    return table


def main() -> int:
    parser = argparse.ArgumentParser(description="R09 优化级别统计（T24）")
    parser.add_argument("--root", default="docs/evidence/r09-optlevel-20261016/remote/R09")
    parser.add_argument("--disasm-dir", default="docs/evidence/r09-optlevel-20261016/disasm")
    parser.add_argument("--memcheck-dir", default="docs/evidence/r09-optlevel-20261016/memcheck")
    parser.add_argument("--out-csv", default="docs/evidence/r09-optlevel-20261016/result.csv")
    arguments = parser.parse_args()

    runs = load_runs(arguments.root)
    print(f"# loaded {len(runs)} runs", file=sys.stderr)
    cells = read_cells_tsv(arguments.disasm_dir)
    memcheck = read_memcheck_summary(arguments.memcheck_dir)
    elf_digests = read_elf_digests(arguments.disasm_dir)
    verify_timed_against_judged(runs, elf_digests)

    rng = np.random.default_rng(BOOTSTRAP_SEED)
    per_run_rows: list[dict[str, object]] = []
    per_cell_deltas: dict[str, list[float]] = {}
    per_cell_rows: list[dict[str, object]] = []

    for run in sorted(runs, key=lambda item: (ARM_ORDER.index(item.arm), LEVEL_ORDER.index(item.level), item.seed_index)):
        reference = run.samples[PRIMARY_PAIR[0]]
        other = run.samples[PRIMARY_PAIR[1]]
        delta = float(reference.mean()) - float(other.mean())
        low, high = delta_ci_normal(reference, other)
        p_value = welch_p_value(reference, other)
        per_cell_deltas.setdefault(run.cell, []).append(delta)
        per_run_rows.append(
            {
                "cell": run.cell,
                "arm": run.arm,
                "optimization_level": run.level,
                "seed_index": run.seed_index,
                "cpu_policy_hint": run.cpu_policy_hint,
                "run_name": run.run_name,
                "n_per_class": int(reference.size),
                "mean_message_zero_ns": float(reference.mean()),
                "mean_message_ones_ns": float(other.mean()),
                "delta_ns": delta,
                "delta_ci_low_ns": low,
                "delta_ci_high_ns": high,
                "welch_two_sided_p": p_value,
                "delta_percent_of_mean": 100.0 * delta / float(other.mean()),
                "executable_digest": run.executable_digest,
                "csv_relative_path": run.csv_relative_path,
            }
        )

    for arm in ARM_ORDER:
        for level in LEVEL_ORDER:
            cell = f"{arm}-{level.lstrip('-')}"
            deltas = per_cell_deltas.get(cell)
            if not deltas:
                per_cell_rows.append(
                    {
                        "cell": cell,
                        "arm": arm,
                        "optimization_level": level,
                        "seeds": 0,
                        "note": "未执行/无数据",
                    }
                )
                continue
            delta_array = np.asarray(deltas, dtype=float)
            draws = rng.integers(0, delta_array.size, size=(BOOTSTRAP_RESAMPLES, delta_array.size))
            bootstrap_means = delta_array[draws].mean(axis=1)
            # 逆方差固定效应合并（与 M1–M5 主家族方法统一）：
            # 从每次运行的 95% CI 推导 SE_i = (high - low) / (2 * z)，
            # 权重 w_i = 1 / SE_i^2，合并 Δ = Σ(w_i·Δ_i) / Σ(w_i)，
            # 合并 SE = sqrt(1 / Σ(w_i))，95% CI = Δ ± 1.96·SE。
            per_run_ci_ranges = np.asarray(
                [row["delta_ci_high_ns"] - row["delta_ci_low_ns"] for row in per_run_rows
                 if row["cell"] == cell], dtype=float)
            per_run_ses = per_run_ci_ranges / (2.0 * 1.959963984540054)
            if np.any(per_run_ses == 0):
                pooled_delta = float(delta_array.mean())
                pooled_ci_low = float(np.percentile(bootstrap_means, 2.5))
                pooled_ci_high = float(np.percentile(bootstrap_means, 97.5))
            else:
                weights = 1.0 / (per_run_ses ** 2)
                pooled_delta = float(np.sum(weights * delta_array) / np.sum(weights))
                pooled_se = float(np.sqrt(1.0 / np.sum(weights)))
                pooled_ci_low = pooled_delta - 1.959963984540054 * pooled_se
                pooled_ci_high = pooled_delta + 1.959963984540054 * pooled_se
            judgment = cells.get(cell, {})
            mem = memcheck.get(cell, {})
            per_cell_rows.append(
                {
                    "cell": cell,
                    "arm": arm,
                    "optimization_level": level,
                    "seeds": int(delta_array.size),
                    "delta_ns_run_mean": float(delta_array.mean()),
                    "delta_ns_run_ci_low": float(np.percentile(bootstrap_means, 2.5)),
                    "delta_ns_run_ci_high": float(np.percentile(bootstrap_means, 97.5)),
                    "delta_ns_run_min": float(delta_array.min()),
                    "delta_ns_run_max": float(delta_array.max()),
                    "delta_ns_per_seed": "|".join(f"{value:.3f}" for value in deltas),
                    "delta_ns_pooled": pooled_delta,
                    "delta_ns_pooled_ci_low": pooled_ci_low,
                    "delta_ns_pooled_ci_high": pooled_ci_high,
                    "disasm_symbol": judgment.get("symbol", ""),
                    "disasm_instructions": judgment.get("instructions", ""),
                    "disasm_bt": judgment.get("bt", ""),
                    "disasm_bt_jae": judgment.get("bt_jae", ""),
                    "disasm_per_bit_test_jcc": judgment.get("per_bit_test_jcc", ""),
                    "disasm_division": judgment.get("division", ""),
                    "disasm_setcc": judgment.get("setcc", ""),
                    "disasm_cmov": judgment.get("cmov", ""),
                    "disasm_conditional_jumps": judgment.get("conditional_jumps", ""),
                    "disasm_mask_neg_and": judgment.get("mask_neg_and", ""),
                    "helper_cmov": judgment.get("helper_cmov", ""),
                    "helper_setcc": judgment.get("helper_setcc", ""),
                    "helper_bt_jae": judgment.get("helper_bt_jae", ""),
                    "judge_memcheck_contexts": judgment.get("memcheck_contexts", ""),
                    "judge_memcheck_errors": judgment.get("memcheck_errors", ""),
                    "memcheck_probe": mem.get("probe", ""),
                    "memcheck_contexts": mem.get("memcheck_contexts", judgment.get("memcheck_contexts", "")),
                    "memcheck_errors": mem.get("memcheck_errors", judgment.get("memcheck_errors", "")),
                    "judged_artifact_sha256": elf_digests.get(cell, ""),
                    "timed_artifact_sha3_256": sorted(
                        {run.executable_digest for run in runs if run.cell == cell}
                    )[0]
                    if any(run.cell == cell for run in runs)
                    else "",
                }
            )

    write_csv(arguments.out_csv, per_run_rows)
    write_csv(arguments.out_csv + ".cells.csv", per_cell_rows)

    print("\n=== per-cell summary (family-external, no Holm) ===")
    header = f"{'cell':18s} {'seeds':>5s} {'delta_ns':>10s} {'ci_low':>10s} {'ci_high':>10s} {'bt_jae':>7s} {'perbit':>7s} {'div':>5s} {'mem_ctx':>8s}"
    print(header)
    for row in per_cell_rows:
        print(
            f"{row['cell']:18s} {row.get('seeds', 0):5d} {row.get('delta_ns_run_mean', float('nan')):10.2f} "
            f"{row.get('delta_ns_run_ci_low', float('nan')):10.2f} "
            f"{row.get('delta_ns_run_ci_high', float('nan')):10.2f} "
            f"{str(row.get('disasm_bt_jae', '')):>7s} {str(row.get('disasm_per_bit_test_jcc', '')):>7s} "
            f"{str(row.get('disasm_division', '')):>5s} {str(row.get('memcheck_contexts', '')):>8s}"
        )

    print("\n=== per-run ===")
    for row in per_run_rows:
        print(
            f"{row['run_name']:26s} n={row['n_per_class']:5d} zero={row['mean_message_zero_ns']:9.2f} "
            f"ones={row['mean_message_ones_ns']:9.2f} delta={row['delta_ns']:8.3f} "
            f"[{row['delta_ci_low_ns']:8.3f},{row['delta_ci_high_ns']:8.3f}] p={row['welch_two_sided_p']:.3g} "
            f"({row['cpu_policy_hint']})"
        )
    return 0


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
    print(f"# wrote {path} ({len(rows)} rows)", file=sys.stderr)


def format_value(value: object) -> object:
    if isinstance(value, float):
        return f"{value:.6f}"
    return value


if __name__ == "__main__":
    raise SystemExit(main())
