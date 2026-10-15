#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T09 稳健性敏感性分析：对仓库中**已有**的原始计时 CSV 复算四种位置/均值方法。

设计原则
--------
1. 不采集新数据：只读 `docs/evidence/` 下已封存的原始 CSV / CSV.GZ。
2. 不修改任何已有证据文件：本脚本只写 `docs/evidence/r02-env-20261016/` 下的产物。
3. 主分析不做任何截尾：第 1 种方法（全样本 Welch 大样本正态近似）与已冻结统计
   家族逐位对齐，作为对照基线；第 2—4 种方法**只用于族外敏感性分析**，
   不改变任何 Holm 判定（见 OUTLIER_RULES.md）。
4. 每个数字都能从原始 CSV 复算：脚本 + 确切命令行写入 ROBUSTNESS.md。

四种方法（Δ 一律定义为 mean/median/位置(class0) − 对应量(class1)）
------------------------------------------------------------------
M1 `full_welch`  ：全样本均值差，SE=sqrt(s0^2/n0+s1^2/n1)，CI=Δ±1.96·SE（冻结口径）
M2 `trim_p999`   ：两侧各截 0.1%（p99.9 截尾）后的截尾均值差；CI 用 bootstrap 百分位
M3 `median`      ：中位数差；CI 用 bootstrap 百分位
M4 `hodges_lehmann`：Hodges–Lehmann 位置差（全部 n0·n1 个成对差的中位数）；CI 用 bootstrap 百分位

Hodges–Lehmann 与 p99.9 截尾都是**族外**敏感性方法，不参与 Holm，也不进 `holm.csv`。
"""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import math
import os
import sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

# ---------------------------------------------------------------- 规则常量（写进 OUTLIER_RULES.md）
# 冻结口径来自 scripts/platform_stats/stats_csv.c:207-208：
#   lower = mean_diff - 1.959963984540054 * se
#   upper = mean_diff + 1.959963984540054 * se
# 方差除数 n-1 来自 src/timing_statistics.c:116-118（series_moments）。
Z95 = 1.959963984540054         # 97.5% 标准正态分位，与冻结的 platform_stats 逐位一致
TRIM_FRACTION = 0.001           # p99.9：两侧各截 0.1%
BOOTSTRAP_REPLICATES = 2000     # 每种 bootstrap 区间的重复次数
BOOTSTRAP_SEED_BASE = 20261016  # 固定种子；每对再按序号派生，保证可复算
MIN_N_FOR_TRIMMED = 1000        # 截尾方法样本量下限（两侧截尾后仍须 >= 该值）
MIN_N_FOR_BOOTSTRAP = 100       # bootstrap 类方法样本量下限


# ---------------------------------------------------------------- 类对清单
def build_pairs():
    """返回 (pair_id, module, role, family_id, member_id, csv_path, class0, class1, note) 列表。"""
    pairs = []

    # ---- M2：未修/已修两臂，各 3 次运行（r01=s1 seed31337/CPU2, r02=s2 seed424242/CPU2, r03=s3 seed31337/CPU6）
    for seed_index in (1, 2, 3):
        for arm in ("unfixed", "fixed"):
            member = "m2-r0%d-%s" % (seed_index, arm)
            pairs.append(dict(
                pair_id="%s:main" % member, module="M2", role="main",
                family_id="m2_end_to_end_full_decaps_v1", member_id=member,
                csv_path="docs/evidence/platform-collection-20261016/M2/m2-s%d-%s/%s-main.csv.gz" % (seed_index, arm, arm),
                class0="message-zero", class1="message-ones",
                note="主类对；成员与 stats/members/members.csv.gz 对齐"))
            pairs.append(dict(
                pair_id="%s:control" % member, module="M2", role="control",
                family_id="m2_end_to_end_full_decaps_v1", member_id="",
                csv_path="docs/evidence/platform-collection-20261016/M2/m2-s%d-%s-ctl/%s-control.csv.gz" % (seed_index, arm, arm),
                class0="malformed-zero-tail", class1="malformed-ff-tail",
                note="族外对照类对；不进 Holm"))

    # ---- M3：on/off 两臂 × 3 次运行；同一份 CSV 同时给出主类对与对照类对
    for seed_index in (1, 2, 3):
        for arm in ("on", "off"):
            member = "m3-r0%d-%s" % (seed_index, arm)
            csv_path = "docs/evidence/platform-collection-20261016/M3/m3-s%d-%s/%s-samples.csv.gz" % (seed_index, arm, arm)
            pairs.append(dict(
                pair_id="%s:main" % member, module="M3", role="main",
                family_id="m3_lut_arm_end_to_end_v1", member_id=member,
                csv_path=csv_path, class0="message-zero", class1="message-ones",
                note="主类对；人工构造的 LUT 开关臂（人工构造校准）"))
            pairs.append(dict(
                pair_id="%s:control" % member, module="M3", role="control",
                family_id="m3_lut_arm_end_to_end_v1", member_id="",
                csv_path=csv_path, class0="bit-flipped", class1="random",
                note="族外对照类对；不进 Holm"))

    # ---- M4：vuln/ct 两臂 × 3 次运行；主路径与截断对照各自独立 CSV
    for seed_index in (1, 2, 3):
        for arm, suffix in (("vuln", "vulnerable"), ("ct", "ct")):
            member = "m4-r0%d-%s" % (seed_index, suffix)
            csv_path = "docs/evidence/platform-collection-20261016/M4/m4-s%d-%s/%s-samples.csv.gz" % (seed_index, arm, arm)
            pairs.append(dict(
                pair_id="%s:main" % member, module="M4", role="main",
                family_id="m4_compare_arm_session_v1", member_id=member,
                csv_path=csv_path, class0="mismatch-first", class1="mismatch-last",
                note="主类对；人工构造的提前退出夹具（人工构造校准）"))
            pairs.append(dict(
                pair_id="%s:control" % member, module="M4", role="control",
                family_id="m4_compare_arm_session_v1", member_id="",
                csv_path="docs/evidence/platform-collection-20261016/M4/m4-c%d-%s/%strunc-samples.csv.gz" % (seed_index, arm, arm),
                class0="mismatch-first", class1="mismatch-last",
                note="族外截断对照（比较窗口外的区别字节）；不进 Holm"))

    # ---- M5：只有参考臂，3 次运行；同一份 CSV 给出主类对与对照类对
    for seed_index in (1, 2, 3):
        member = "m5-r0%d-reference" % seed_index
        csv_path = "docs/evidence/platform-collection-20261016/M5/m5-s%d-meas/m5-samples.csv.gz" % seed_index
        pairs.append(dict(
            pair_id="%s:main" % member, module="M5", role="main",
            family_id="m5_reference_end_to_end_v1", member_id=member,
            csv_path=csv_path, class0="message-zero", class1="message-ones",
            note="主类对；纯参考实现"))
        pairs.append(dict(
            pair_id="%s:control" % member, module="M5", role="control",
            family_id="m5_reference_end_to_end_v1", member_id="",
            csv_path=csv_path, class0="bit-flipped", class1="random",
            note="族外对照类对；不进 Holm"))

    # ---- M1：liboqs 0.10.0 历史锁频复测（未修/已修），主类对 + 族外对照
    for arm in ("vulnerable", "fixed"):
        pairs.append(dict(
            pair_id="m1-liboqs010-%s:main" % arm, module="M1", role="main",
            family_id="m1_liboqs010_locked_v1", member_id="m1-liboqs010-%s" % arm,
            csv_path="docs/evidence/liboqs010-locked-20261015/runs/%s/samples.csv" % arm,
            class0="message-zero", class1="message-ones",
            note="M1 主类对；族外（该数据无预注册 Holm 家族）"))
        pairs.append(dict(
            pair_id="m1-liboqs010-%s:control" % arm, module="M1", role="control",
            family_id="m1_liboqs010_locked_v1", member_id="",
            csv_path="docs/evidence/liboqs010-locked-20261015/runs/%s/samples.csv" % arm,
            class0="bit-flipped", class1="random",
            note="族外对照类对；不进 Holm"))

    # ---- R03：3 臂 × 3 种子，两个族外对照（valid−malformed / valid−truncated）
    for arm in ("m1unfixed", "m1fixed", "m5ref"):
        for seed_name in ("s1", "s2", "s3"):
            run = "r03-%s-%s" % (arm, seed_name)
            csv_path = "docs/evidence/r03-malformed-20261016/R03/%s/%s.csv.gz" % (run, run)
            for c1name, short in (("malformed", "malformed"), ("truncated", "truncated")):
                pairs.append(dict(
                    pair_id="%s:valid-%s" % (run, short), module="R03", role="control",
                    family_id="", member_id="",
                    csv_path=csv_path, class0="valid", class1=c1name,
                    note="R03 族外对照（%s）；不进 Holm" % ("隐式拒绝" if short == "malformed" else "长度截断")))

    return pairs


# ---------------------------------------------------------------- 读 CSV
def _open_text(path):
    if path.endswith(".gz"):
        return gzip.open(path, "rt", newline="")
    return open(path, "r", newline="")


def load_classes(rel_path, class0, class1):
    """返回 (arr0, arr1, missing0, missing1, zero0, zero1, row_count)。缺失值剔除并计数。"""
    path = os.path.join(REPO_ROOT, rel_path)
    buckets = {class0: [], class1: []}
    missing = {class0: 0, class1: 0}
    zeros = {class0: 0, class1: 0}
    row_count = 0
    with _open_text(path) as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            category = row["input_category"]
            if category not in buckets:
                continue
            row_count += 1
            raw = (row.get("elapsed_nanoseconds") or "").strip()
            if raw == "":
                missing[category] += 1
                continue
            try:
                value = float(raw)
            except ValueError:
                missing[category] += 1
                continue
            if value == 0.0:
                zeros[category] += 1
            buckets[category].append(value)
    return (np.asarray(buckets[class0], dtype=np.float64),
            np.asarray(buckets[class1], dtype=np.float64),
            missing[class0], missing[class1], zeros[class0], zeros[class1], row_count)


# ---------------------------------------------------------------- 统计核
def welch_normal(x, y):
    """冻结口径：大样本正态近似，z=1.959963984540054，方差除数 n-1。"""
    n0, n1 = x.size, y.size
    delta = float(x.mean() - y.mean())
    se = math.sqrt(x.var(ddof=1) / n0 + y.var(ddof=1) / n1)
    return delta, se, delta - Z95 * se, delta + Z95 * se


def two_sided_normal_p(delta, se):
    if se <= 0.0:
        return 0.0 if delta != 0.0 else 1.0
    return math.erfc(abs(delta) / se / math.sqrt(2.0))


def trimmed_values(values, k):
    ordered = np.sort(values)
    if k == 0:
        return ordered
    return ordered[k:ordered.size - k]


def hodges_lehmann(sorted_x, sorted_y):
    """全部 n0*n1 个成对差 (x_i - y_j) 的中位数；整数格点二分，精确。"""
    n0, n1 = sorted_x.size, sorted_y.size
    total = n0 * n1
    lower = int(sorted_x[0] - sorted_y[-1])
    upper = int(sorted_x[-1] - sorted_y[0])

    def count_le(d):
        # x_i - y_j <= d  <=>  y_j >= x_i - d
        idx = np.searchsorted(sorted_y, sorted_x - d, side="left")
        return int(np.sum(sorted_y.size - idx))

    def kth(k):
        lo, hi = lower, upper
        while lo < hi:
            mid = lo + (hi - lo) // 2
            if count_le(mid) >= k:
                hi = mid
            else:
                lo = mid + 1
        return lo

    if total % 2 == 1:
        return float(kth(total // 2 + 1))
    return (kth(total // 2) + kth(total // 2 + 1)) / 2.0


def percentile_ci(samples):
    low, high = np.percentile(samples, [2.5, 97.5])
    return float(low), float(high)


def analyse_one(task):
    pair, trim_fraction, replicates, seed = task
    x, y, miss0, miss1, zero0, zero1, row_count = load_classes(pair["csv_path"], pair["class0"], pair["class1"])
    n0, n1 = x.size, y.size

    result = dict(pair)
    result.update(dict(row_count=row_count, n0=int(n0), n1=int(n1),
                       missing0=miss0, missing1=miss1, zero0=zero0, zero1=zero1,
                       bootstrap_replicates=replicates, bootstrap_seed=seed,
                       trim_fraction=trim_fraction))

    if n0 < MIN_N_FOR_BOOTSTRAP or n1 < MIN_N_FOR_BOOTSTRAP:
        result["status"] = "insufficient_samples"
        return result

    k0 = int(math.floor(trim_fraction * n0))
    k1 = int(math.floor(trim_fraction * n1))
    result.update(trim_k0=k0, trim_k1=k1, trim_n0=int(n0 - 2 * k0), trim_n1=int(n1 - 2 * k1))

    # M1 全样本 Welch（对照基线，冻结口径）
    delta, se, ci_low, ci_high = welch_normal(x, y)
    result.update(full_delta_ns=delta, full_se_ns=se,
                  full_ci_low_ns=ci_low, full_ci_high_ns=ci_high,
                  full_p_two_sided=two_sided_normal_p(delta, se),
                  full_ci_excludes_zero=bool(ci_low > 0.0 or ci_high < 0.0))

    # M2 截尾均值差（p99.9）
    trimmed_x = trimmed_values(x, k0)
    trimmed_y = trimmed_values(y, k1)
    result["trim_delta_ns"] = float(trimmed_x.mean() - trimmed_y.mean())
    result["trim_ok"] = bool(result["trim_n0"] >= MIN_N_FOR_TRIMMED and result["trim_n1"] >= MIN_N_FOR_TRIMMED)

    # M3 中位数差
    result["median_delta_ns"] = float(np.median(x) - np.median(y))

    # M4 Hodges–Lehmann 位置差
    result["hl_delta_ns"] = float(hodges_lehmann(np.sort(x), np.sort(y)))

    # bootstrap（分组内独立重采样，同一批重采样同时给出三种方法的区间）
    rng = np.random.default_rng(seed)
    boot_trim = np.empty(replicates, dtype=np.float64)
    boot_median = np.empty(replicates, dtype=np.float64)
    boot_hl = np.empty(replicates, dtype=np.float64)
    for index in range(replicates):
        sx = np.sort(x[rng.integers(0, n0, n0)])
        sy = np.sort(y[rng.integers(0, n1, n1)])
        if result["trim_ok"]:
            boot_trim[index] = sx[k0:sx.size - k0].mean() - sy[k1:sy.size - k1].mean()
        else:
            boot_trim[index] = math.nan
        boot_median[index] = np.median(sx) - np.median(sy)
        boot_hl[index] = hodges_lehmann(sx, sy)

    result["trim_bootstrap_failures"] = int(np.count_nonzero(~np.isfinite(boot_trim)))
    if result["trim_ok"]:
        low, high = percentile_ci(boot_trim)
        result.update(trim_ci_low_ns=low, trim_ci_high_ns=high,
                      trim_ci_excludes_zero=bool(low > 0.0 or high < 0.0))
    else:
        result.update(trim_ci_low_ns=math.nan, trim_ci_high_ns=math.nan, trim_ci_excludes_zero=None)

    low, high = percentile_ci(boot_median)
    result.update(median_ci_low_ns=low, median_ci_high_ns=high,
                  median_ci_excludes_zero=bool(low > 0.0 or high < 0.0))

    low, high = percentile_ci(boot_hl)
    result.update(hl_ci_low_ns=low, hl_ci_high_ns=high,
                  hl_ci_excludes_zero=bool(low > 0.0 or high < 0.0))

    # 翻转判定：稳健方法的「CI 是否含 0」与全样本是否一致
    full_excl = result["full_ci_excludes_zero"]
    result["trim_flip"] = None if result["trim_ci_excludes_zero"] is None else bool(result["trim_ci_excludes_zero"] != full_excl)
    result["median_flip"] = bool(result["median_ci_excludes_zero"] != full_excl)
    result["hl_flip"] = bool(result["hl_ci_excludes_zero"] != full_excl)
    result["flip_methods"] = ",".join(
        name for name, flag in (("trim_p999", result["trim_flip"]),
                                ("median", result["median_flip"]),
                                ("hodges_lehmann", result["hl_flip"])) if flag)
    result["any_flip"] = bool(result["flip_methods"])
    result["status"] = "ok"
    return result


# ---------------------------------------------------------------- 复算对齐校验
def reproduction_check(results):
    """把本脚本的全样本 Welch 与已冻结的 members.csv / holm.csv 逐行比对。"""
    checks = []
    members_path = os.path.join(REPO_ROOT, "docs/evidence/platform-collection-20261016/stats/members/members.csv.gz")
    holm_path = os.path.join(REPO_ROOT, "docs/evidence/platform-collection-20261016/stats/holm/holm.csv.gz")

    by_member = {r["member_id"]: r for r in results if r.get("member_id") and r.get("status") == "ok"}

    with gzip.open(members_path, "rt", newline="") as handle:
        for row in csv.DictReader(handle):
            member = row["member_id"]
            mine = by_member.get(member)
            if mine is None:
                checks.append(dict(member_id=member, status="missing_in_robustness"))
                continue
            frozen_delta = float(row["mean0_ns"]) - float(row["mean1_ns"])
            frozen_low = float(row["ci95_low_ns"])
            frozen_high = float(row["ci95_high_ns"])
            checks.append(dict(
                member_id=member, family_id=row["family_id"], source="members.csv",
                frozen_delta_ns=frozen_delta, recomputed_delta_ns=mine["full_delta_ns"],
                delta_abs_diff=max(abs(frozen_delta - mine["full_delta_ns"]), 0.0),
                frozen_ci_low_ns=frozen_low, recomputed_ci_low_ns=mine["full_ci_low_ns"],
                frozen_ci_high_ns=frozen_high, recomputed_ci_high_ns=mine["full_ci_high_ns"],
                max_ci_abs_diff=max(abs(frozen_low - mine["full_ci_low_ns"]),
                                    abs(frozen_high - mine["full_ci_high_ns"])),
                frozen_n0=int(row["n0"]), frozen_n1=int(row["n1"]),
                recomputed_n0=mine["n0"], recomputed_n1=mine["n1"],
            ))

    holm_index = {}
    with gzip.open(holm_path, "rt", newline="") as handle:
        for row in csv.DictReader(handle):
            holm_index[row["member_id"]] = row
    for check in checks:
        holm_row = holm_index.get(check["member_id"])
        mine = by_member.get(check["member_id"])
        if holm_row is not None and mine is not None:
            check["frozen_holm_raw_p"] = float(holm_row["raw_p"])
            check["frozen_holm_reject"] = int(holm_row["reject"])
            check["recomputed_p_two_sided"] = mine["full_p_two_sided"]
            check["p_abs_diff"] = abs(float(holm_row["raw_p"]) - mine["full_p_two_sided"])
    return checks


# ---------------------------------------------------------------- CSV 输出
CSV_COLUMNS = [
    "pair_id", "module", "role", "family_id", "member_id", "class0", "class1", "csv_path",
    "n0", "n1", "missing0", "missing1", "zero0", "zero1",
    "trim_k0", "trim_k1", "trim_n0", "trim_n1", "bootstrap_replicates", "bootstrap_seed", "trim_fraction",
    "full_delta_ns", "full_se_ns", "full_ci_low_ns", "full_ci_high_ns", "full_p_two_sided", "full_ci_excludes_zero",
    "trim_delta_ns", "trim_ci_low_ns", "trim_ci_high_ns", "trim_ci_excludes_zero", "trim_flip",
    "median_delta_ns", "median_ci_low_ns", "median_ci_high_ns", "median_ci_excludes_zero", "median_flip",
    "hl_delta_ns", "hl_ci_low_ns", "hl_ci_high_ns", "hl_ci_excludes_zero", "hl_flip",
    "flip_methods", "any_flip", "note",
]


def write_csv(path, results):
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writeheader()
        for row in results:
            out = dict(row)
            for key in ("full_delta_ns", "full_se_ns", "full_ci_low_ns", "full_ci_high_ns", "full_p_two_sided",
                        "trim_delta_ns", "trim_ci_low_ns", "trim_ci_high_ns",
                        "median_delta_ns", "median_ci_low_ns", "median_ci_high_ns",
                        "hl_delta_ns", "hl_ci_low_ns", "hl_ci_high_ns"):
                if key in out and isinstance(out[key], float):
                    out[key] = "%.4f" % out[key]
            writer.writerow(out)


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description="T09 稳健性敏感性分析（只读既有 CSV）")
    parser.add_argument("--output-dir", default=os.path.join(REPO_ROOT, "docs/evidence/r02-env-20261016"))
    parser.add_argument("--replicates", type=int, default=BOOTSTRAP_REPLICATES)
    parser.add_argument("--trim-fraction", type=float, default=TRIM_FRACTION)
    parser.add_argument("--workers", type=int, default=min(8, os.cpu_count() or 1))
    parser.add_argument("--seed-base", type=int, default=BOOTSTRAP_SEED_BASE,
                        help="bootstrap 种子基数；换值可做「翻转集合对种子是否稳定」的自检")
    parser.add_argument("--suffix", default="", help="输出文件名后缀，用于并列保留自检产物")
    args = parser.parse_args()

    pairs = build_pairs()
    tasks = [(pair, args.trim_fraction, args.replicates, args.seed_base + index)
             for index, pair in enumerate(pairs)]

    results = []
    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(analyse_one, tasks):
            results.append(result)
            print("[%2d/%2d] %-34s d_full=%8.4f  d_trim=%8.4f  d_med=%8.4f  d_hl=%8.4f  flip=%s" % (
                len(results), len(tasks), result["pair_id"],
                result.get("full_delta_ns", float("nan")), result.get("trim_delta_ns", float("nan")),
                result.get("median_delta_ns", float("nan")), result.get("hl_delta_ns", float("nan")),
                result.get("flip_methods", "-")), flush=True)

    checks = reproduction_check(results)

    os.makedirs(args.output_dir, exist_ok=True)
    csv_path = os.path.join(args.output_dir, "robustness%s.csv" % args.suffix)
    write_csv(csv_path, results)

    payload = dict(
        script=os.path.relpath(os.path.abspath(__file__), REPO_ROOT),
        script_sha256=sha256_of(os.path.abspath(__file__)),
        z95=Z95, trim_fraction=args.trim_fraction, bootstrap_replicates=args.replicates,
        bootstrap_seed_base=args.seed_base, min_n_for_trimmed=MIN_N_FOR_TRIMMED,
        min_n_for_bootstrap=MIN_N_FOR_BOOTSTRAP,
        pair_count=len(results),
        flip_pair_count=sum(1 for r in results if r.get("any_flip")),
        flipped=[dict(pair_id=r["pair_id"], methods=r["flip_methods"],
                      full_ci=[r["full_ci_low_ns"], r["full_ci_high_ns"]],
                      trim_ci=[r.get("trim_ci_low_ns"), r.get("trim_ci_high_ns")],
                      median_ci=[r["median_ci_low_ns"], r["median_ci_high_ns"]],
                      hl_ci=[r["hl_ci_low_ns"], r["hl_ci_high_ns"]]) for r in results if r.get("any_flip")],
        results=results,
        reproduction_check=checks,
    )
    json_path = os.path.join(args.output_dir, "robustness%s.json" % args.suffix)
    with open(json_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")

    worst = max((c.get("max_ci_abs_diff", 0.0) for c in checks if "max_ci_abs_diff" in c), default=0.0)
    worst_delta = max((c.get("delta_abs_diff", 0.0) for c in checks if "delta_abs_diff" in c), default=0.0)
    print("\n复算对齐：%d 个成员；最大 |Δ 差| = %.9g ns；最大 |CI 端点差| = %.9g ns" % (len(checks), worst_delta, worst))
    print("翻转类对：%d / %d" % (payload["flip_pair_count"], payload["pair_count"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
