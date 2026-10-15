"""T26/T27 复算公用层：只读已有证据 CSV，不重新采集。

本模块做三件事：
1. 用一份显式登记表把「主类对」映射到仓库内的原始 CSV（gzip 原件）；
2. 提供统一的读取器，把两类样本读成 numpy 数组；
3. 提供功效分析与 bootstrap 分位数统计函数。

约定：
- 每类 SD 一律用**样本标准差**（ddof=1）。理由：已提交证据 `stats/members/members.csv.gz`
  与各 `stats/<dataset>/ci_welch.json` 的 SE 都能被 ddof=1 逐位复现，ddof=0 不能。
- Δ 一律定义为 class0 均值 − class1 均值，与既有证据同一方向。
- 不写任何已有证据文件；本模块只读。
"""

from __future__ import annotations

import csv
import gzip
import hashlib
import math
import statistics
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Sequence

import numpy as np

# ---------------------------------------------------------------- 路径与常量

REPO_ROOT = Path(__file__).resolve().parents[4]

OUT_DIR = REPO_ROOT / "docs" / "evidence" / "r04-stats-20261016"
FIG_DIR = OUT_DIR / "figures"
SRC_DIR = OUT_DIR / "robustness-src"

PLATFORM_DIR = REPO_ROOT / "docs" / "evidence" / "platform-collection-20261016"
R03_DIR = REPO_ROOT / "docs" / "evidence" / "r03-malformed-20261016"
M1_LOCKED_DIR = REPO_ROOT / "docs" / "evidence" / "liboqs010-locked-20261015"
M1_TOOLING_DIR = REPO_ROOT / "docs" / "evidence" / "tooling-strengthen-20261015"

ALPHA_FAMILY = 0.05  # 每个 Holm 家族的全族 α
TARGET_POWER = 0.80  # 计划功效 1-β
BOOTSTRAP_RESAMPLES = 10000  # ≥10000，固定种子
BOOTSTRAP_BASE_SEED = 20261016
BOOTSTRAP_CHUNK = 250  # 逐块生成重抽样索引，控制峰值内存
QUANTILE_PROBS = (0.10, 0.50, 0.90, 0.99)

# 每个 run 的绑核（来自 platform-collection README §1 与 R03 PLAN §4）。
RUN_CPU = {"s1": "CPU2", "s2": "CPU2", "s3": "CPU6"}


# ---------------------------------------------------------------- 登记表

@dataclass(frozen=True)
class ClassPair:
    """一个「主类对」实例 = 一次 run、一个臂、两类样本。"""

    key: str  # 唯一短名，用于文件名
    module: str  # M1 / M2 / M3 / M4 / M5 / R03
    arm: str  # ascii 臂名（图内用）
    arm_cn: str  # 中文臂名（文档用）
    run_label: str  # run 名（文档与图内注记用）
    run_index: int  # 1..3
    seed: int
    cpu: str
    family: str  # Holm 家族 id；族外用 "none(outside-family)"
    family_m: int | None  # 家族 m；族外为 None
    source_csv: str  # 相对仓库根的原始 CSV 路径
    loader: str  # measure_gz / paired_csv
    class0: str
    class1: str
    c0_col: str = ""  # paired_csv 用的列名
    c1_col: str = ""
    derived_csv: str = ""  # 派生/第二来源，仅用于一致性核对
    note: str = ""


def _p(*parts: str) -> str:
    return str(Path(*parts))


def _platform(module: str, run_dir: str, csv_name: str) -> str:
    return _p("docs", "evidence", "platform-collection-20261016", module, run_dir, csv_name)


def _r03(arm: str, seed_tag: str) -> str:
    name = f"r03-{arm}-{seed_tag}"
    return _p("docs", "evidence", "r03-malformed-20261016", "R03", name, f"{name}.csv.gz")


def _platform_runs(module: str, arm_dir: str, csv_name: str, arms: Sequence[tuple[str, str, str]]):
    """生成 M2/M3/M4/M5 的 3 次 run × 各臂登记项。"""
    rows = []
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        seed = {"s1": 31337, "s2": 424242, "s3": 31337}[seed_tag]
        for arm_key, arm_cn, family in arms:
            run_dir = f"{module.lower()}-{seed_tag}-{arm_dir[arm_key]}"
            run_label = f"{module.lower()}-{seed_tag}-{arm_dir[arm_key]}"
            rows.append(
                ClassPair(
                    key=f"{module}-{arm_key}-{seed_tag}",
                    module=module,
                    arm=arm_key,
                    arm_cn=arm_cn,
                    run_label=run_label,
                    run_index=run_index,
                    seed=seed,
                    cpu=RUN_CPU[seed_tag],
                    family=family,
                    family_m=6 if family != "none" else None,
                    source_csv=_platform(module, run_dir, csv_name),
                    loader="measure_gz",
                    class0="message-zero",
                    class1="message-ones",
                )
            )
    return rows


def _build_registry() -> list[ClassPair]:
    rows: list[ClassPair] = []

    # --- M1：tooling-strengthen 的两列配对 CSV 派生自 liboqs010-locked 的原始长表。
    # 主来源取 liboqs010-locked 原始 measure 长表（含完整 meta 与频率记录），
    # tooling-strengthen 的两列 CSV 作为一致性旁证（statistics run 见 verify_*）。
    for arm_key, arm_dir, arm_cn, run_label in (
        ("unfixed", "vulnerable", "未修", "hist010-vulnerable"),
        ("fixed", "fixed", "已修", "hist010-fixed"),
    ):
        rows.append(
            ClassPair(
                key=f"M1-{arm_key}-s1",
                module="M1",
                arm=arm_key,
                arm_cn=arm_cn,
                run_label=run_label,
                run_index=1,
                seed=31337,
                cpu="CPU2",
                family="none(outside-family)",
                family_m=None,
                source_csv=_p(
                    "docs", "evidence", "liboqs010-locked-20261015", "runs", arm_dir, "samples.csv"
                ),
                loader="measure_plain",
                class0="message-zero",
                class1="message-ones",
                derived_csv=_p(
                    "docs",
                    "evidence",
                    "tooling-strengthen-20261015",
                    "csv",
                    f"{arm_dir}-message-zero-ones.csv",
                ),
                note="M1 主类对无预注册 Holm 家族（PROTOCOL.md：'没有 Holm'），族外不校正。",
            )
        )

    # --- M2：家族 m2_end_to_end_full_decaps_v1，m=6（3 run × 2 臂）。
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        for arm_key, arm_cn in (("unfixed", "未修"), ("fixed", "已修")):
            run_dir = f"m2-{seed_tag}-{arm_key}"
            rows.append(
                ClassPair(
                    key=f"M2-{arm_key}-{seed_tag}",
                    module="M2",
                    arm=arm_key,
                    arm_cn=arm_cn,
                    run_label=run_dir,
                    run_index=run_index,
                    seed={"s1": 31337, "s2": 424242, "s3": 31337}[seed_tag],
                    cpu=RUN_CPU[seed_tag],
                    family="m2_end_to_end_full_decaps_v1",
                    family_m=6,
                    source_csv=_platform("M2", run_dir, f"{arm_key}-main.csv.gz"),
                    loader="measure_gz",
                    class0="message-zero",
                    class1="message-ones",
                )
            )

    # --- M3：家族 m3_lut_arm_end_to_end_v1，m=6（3 run × on/off）。
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        for arm_key, arm_cn in (("on", "on"), ("off", "off")):
            run_dir = f"m3-{seed_tag}-{arm_key}"
            rows.append(
                ClassPair(
                    key=f"M3-{arm_key}-{seed_tag}",
                    module="M3",
                    arm=arm_key,
                    arm_cn=arm_cn,
                    run_label=run_dir,
                    run_index=run_index,
                    seed={"s1": 31337, "s2": 424242, "s3": 31337}[seed_tag],
                    cpu=RUN_CPU[seed_tag],
                    family="m3_lut_arm_end_to_end_v1",
                    family_m=6,
                    source_csv=_platform("M3", run_dir, f"{arm_key}-samples.csv.gz"),
                    loader="measure_gz",
                    class0="message-zero",
                    class1="message-ones",
                )
            )

    # --- M4：家族 m4_compare_arm_session_v1，m=6（3 run × vulnerable/ct）。
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        for arm_key, arm_cn, file_tag in (("vuln", "vulnerable", "vuln"), ("ct", "ct", "ct")):
            run_dir = f"m4-{seed_tag}-{arm_key}"
            rows.append(
                ClassPair(
                    key=f"M4-{arm_key}-{seed_tag}",
                    module="M4",
                    arm=arm_key,
                    arm_cn=arm_cn,
                    run_label=run_dir,
                    run_index=run_index,
                    seed={"s1": 31337, "s2": 424242, "s3": 31337}[seed_tag],
                    cpu=RUN_CPU[seed_tag],
                    family="m4_compare_arm_session_v1",
                    family_m=6,
                    source_csv=_platform("M4", run_dir, f"{file_tag}-samples.csv.gz"),
                    loader="measure_gz",
                    class0="mismatch-first",
                    class1="mismatch-last",
                )
            )

    # --- M5：家族 m5_reference_end_to_end_v1，m=3（3 run × 单臂）。
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        run_dir = f"m5-{seed_tag}-meas"
        rows.append(
            ClassPair(
                key=f"M5-reference-{seed_tag}",
                module="M5",
                arm="reference",
                arm_cn="reference",
                run_label=run_dir,
                run_index=run_index,
                seed={"s1": 31337, "s2": 424242, "s3": 31337}[seed_tag],
                cpu=RUN_CPU[seed_tag],
                family="m5_reference_end_to_end_v1",
                family_m=3,
                source_csv=_platform("M5", run_dir, "m5-samples.csv.gz"),
                loader="measure_gz",
                class0="message-zero",
                class1="message-ones",
            )
        )

    # --- R03：两个族外对照类对 × 3 臂 × 3 种子。
    for run_index, seed_tag in enumerate(("s1", "s2", "s3"), start=1):
        seed = {"s1": 31337, "s2": 424242, "s3": 7}[seed_tag]
        for arm_key, arm_cn in (("m1unfixed", "M1 未修"), ("m1fixed", "M1 已修"), ("m5ref", "M5")):
            for pair_key, pair_cn, c1 in (
                ("valid-malformed", "对照 A：合法 vs 格式破损", "malformed"),
                ("valid-truncated", "对照 B：合法 vs 截断", "truncated"),
            ):
                rows.append(
                    ClassPair(
                        key=f"R03-{pair_key}-{arm_key}-{seed_tag}",
                        module="R03",
                        arm=f"{arm_key}/{pair_key}",
                        arm_cn=f"{arm_cn} / {pair_cn}",
                        run_label=f"r03-{arm_key}-{seed_tag}",
                        run_index=run_index,
                        seed=seed,
                        cpu=RUN_CPU[seed_tag],
                        family="none(outside-family)",
                        family_m=None,
                        source_csv=_r03(arm_key, seed_tag),
                        loader="measure_gz",
                        class0="valid",
                        class1=c1,
                        note="R03 两个对照族外，不进 Holm，不做多重比较校正。",
                    )
                )
    return rows


CLASS_PAIRS: list[ClassPair] = _build_registry()


# ---------------------------------------------------------------- 读取器

def _read_measure_csv(path: Path) -> list[dict[str, str]]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", newline="") as handle:
        return list(csv.DictReader(handle))


def load_pair(pair: ClassPair) -> tuple[np.ndarray, np.ndarray]:
    """读回该主类对的两类耗时（ns），保持 CSV 原始出现顺序。"""
    path = REPO_ROOT / pair.source_csv
    if not path.exists():
        raise FileNotFoundError(f"缺少输入 CSV：{pair.source_csv}")

    if pair.loader in ("measure_gz", "measure_plain"):
        rows = _read_measure_csv(path)
        class0: list[int] = []
        class1: list[int] = []
        for row in rows:
            category = row["input_category"]
            if category == pair.class0:
                class0.append(int(row["elapsed_nanoseconds"]))
            elif category == pair.class1:
                class1.append(int(row["elapsed_nanoseconds"]))
        if not class0 or not class1:
            raise ValueError(
                f"{pair.source_csv} 缺少类 {pair.class0}/{pair.class1}；"
                f"实际类={sorted({r['input_category'] for r in rows})}"
            )
        return np.asarray(class0, dtype=np.int64), np.asarray(class1, dtype=np.int64)

    if pair.loader == "paired_csv":
        with open(path, "r", newline="") as handle:
            reader = csv.DictReader(handle)
            class0 = [int(row[pair.c0_col]) for row in reader]
        with open(path, "r", newline="") as handle:
            reader = csv.DictReader(handle)
            class1 = [int(row[pair.c1_col]) for row in reader]
        return np.asarray(class0, dtype=np.int64), np.asarray(class1, dtype=np.int64)

    raise ValueError(f"未知 loader：{pair.loader}")


def ci_json_path(pair: ClassPair) -> Path:
    """该主类对对应的既有统计电池出口 `ci_welch.json`（用于交叉核对）。"""
    if pair.module in ("M2", "M3", "M4"):
        dataset = f"{pair.module.lower()}-{pair.run_label}-main"
        return PLATFORM_DIR / "stats" / dataset / "ci_welch.json"
    if pair.module == "M5":
        dataset = f"m5-m5-s{pair.run_index}-main"
        return PLATFORM_DIR / "stats" / dataset / "ci_welch.json"
    if pair.module == "R03":
        arm_base, pair_key = pair.arm.split("/")
        dataset = f"r03-{arm_base}-s{pair.run_index}-{pair_key}"
        return R03_DIR / "stats" / dataset / "ci_welch.json"
    return Path()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def sha256_uncompressed(path: Path) -> str:
    """解压后内容的 SHA-256；与各 `input.sha256` 记录的口径一致。"""
    digest = hashlib.sha256()
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


# ---------------------------------------------------------------- 基础统计

def mean_ns(values: np.ndarray) -> float:
    return float(np.mean(values, dtype=np.float64))


def sd_ns_sample(values: np.ndarray) -> float:
    """样本标准差（ddof=1），与已提交证据的 SE 口径一致。"""
    return float(np.std(values, ddof=1, dtype=np.float64))


def se_diff_ns(values0: np.ndarray, values1: np.ndarray) -> float:
    n0 = values0.size
    n1 = values1.size
    return math.sqrt(sd_ns_sample(values0) ** 2 / n0 + sd_ns_sample(values1) ** 2 / n1)


def z_for_two_sided_alpha(alpha: float) -> float:
    return statistics.NormalDist().inv_cdf(1.0 - alpha / 2.0)


def z_for_power(power: float) -> float:
    return statistics.NormalDist().inv_cdf(power)


def mde_ns(sd0_ns: float, sd1_ns: float, n0: int, n1: int, alpha: float, power: float = TARGET_POWER) -> float:
    """两样本、双侧 α、目标功效 power 下的最小可检测效应。

    MDE = (z_{1-α/2} + z_{power}) * sqrt(sd0²/n0 + sd1²/n1)

    n0 = n1 时退化为教科书的 2.8016 * sd * sqrt(2/n)。
    这里保留不等 n 的一般形式，即使本批数据都是等 n。
    """
    if n0 <= 0 or n1 <= 0:
        raise ValueError("n 必须为正")
    z_alpha = z_for_two_sided_alpha(alpha)
    z_power = z_for_power(power)
    return (z_alpha + z_power) * math.sqrt(sd0_ns**2 / n0 + sd1_ns**2 / n1)


def holm_effective_alpha(family_m: int | None, alpha: float = ALPHA_FAMILY) -> float:
    """Holm 家族设计期的有效 α。

    Holm 的最小阈值是 α/m（最显著那一项）。要在**整族**上保证设计期功效，
    必须按最严阈值 α/m 反推样本量，因此这里取 α_eff = α/m。
    族外不校正，α_eff = α。
    """
    if family_m is None:
        return alpha
    return alpha / family_m


# ---------------------------------------------------------------- bootstrap

def bootstrap_quantile_diffs(
    values0: np.ndarray,
    values1: np.ndarray,
    dataset_index: int,
    probs: Sequence[float] = QUANTILE_PROBS,
    resamples: int = BOOTSTRAP_RESAMPLES,
    base_seed: int = BOOTSTRAP_BASE_SEED,
) -> dict[float, dict[str, float]]:
    """分位数差 (class0 − class1) 的 bootstrap 百分位 95% CI。

    固定种子：`default_rng([base_seed, dataset_index])`，与登记表顺序绑定。
    独立对两类做有放回重抽样，宽度 B×n 的索引按 BOOTSTRAP_CHUNK 分块生成。
    """
    n0 = values0.size
    n1 = values1.size
    rng = np.random.default_rng([base_seed, dataset_index])
    samples = {p: np.empty(resamples, dtype=np.float64) for p in probs}

    done = 0
    while done < resamples:
        block = min(BOOTSTRAP_CHUNK, resamples - done)
        idx0 = rng.integers(0, n0, size=(block, n0), dtype=np.int32)
        idx1 = rng.integers(0, n1, size=(block, n1), dtype=np.int32)
        q0 = np.quantile(values0[idx0], probs, axis=1)
        q1 = np.quantile(values1[idx1], probs, axis=1)
        for position, prob in enumerate(probs):
            samples[prob][done : done + block] = q0[position] - q1[position]
        done += block

    point0 = np.quantile(values0, probs)
    point1 = np.quantile(values1, probs)
    result: dict[float, dict[str, float]] = {}
    for position, prob in enumerate(probs):
        draws = samples[prob]
        result[prob] = {
            "q0_ns": float(point0[position]),
            "q1_ns": float(point1[position]),
            "diff_ns": float(point0[position] - point1[position]),
            "ci_low_ns": float(np.quantile(draws, 0.025)),
            "ci_high_ns": float(np.quantile(draws, 0.975)),
            "boot_se_ns": float(np.std(draws, ddof=1)),
            "boot_mean_ns": float(np.mean(draws)),
            "resamples": int(resamples),
            "seed": f"[{base_seed}, {dataset_index}]",
        }
    return result


# ---------------------------------------------------------------- 汇总

@dataclass
class PairStats:
    pair: ClassPair
    index: int
    n0: int
    n1: int
    mean0_ns: float
    mean1_ns: float
    sd0_ns: float
    sd1_ns: float
    delta_ns: float
    se_ns: float
    mde_alpha_ns: float
    mde_holm_ns: float
    alpha_eff: float
    rel_mde_alpha_percent: float
    rel_mde_holm_percent: float
    ci_low_ns: float = field(default=0.0)
    ci_high_ns: float = field(default=0.0)
    quantiles: dict[float, dict[str, float]] = field(default_factory=dict)


def compute_pair_stats(pair: ClassPair, index: int, need_quantiles: bool = False) -> PairStats:
    values0, values1 = load_pair(pair)
    mean0 = mean_ns(values0)
    mean1 = mean_ns(values1)
    sd0 = sd_ns_sample(values0)
    sd1 = sd_ns_sample(values1)
    n0 = int(values0.size)
    n1 = int(values1.size)
    alpha_eff = holm_effective_alpha(pair.family_m)
    mde_alpha = mde_ns(sd0, sd1, n0, n1, ALPHA_FAMILY)
    mde_holm = mde_ns(sd0, sd1, n0, n1, alpha_eff)
    se = se_diff_ns(values0, values1)
    grand_mean = 0.5 * (mean0 + mean1)
    stats = PairStats(
        pair=pair,
        index=index,
        n0=n0,
        n1=n1,
        mean0_ns=mean0,
        mean1_ns=mean1,
        sd0_ns=sd0,
        sd1_ns=sd1,
        delta_ns=mean0 - mean1,
        se_ns=se,
        mde_alpha_ns=mde_alpha,
        mde_holm_ns=mde_holm,
        alpha_eff=alpha_eff,
        rel_mde_alpha_percent=100.0 * mde_alpha / grand_mean,
        rel_mde_holm_percent=100.0 * mde_holm / grand_mean,
        ci_low_ns=(mean0 - mean1) - 1.959963984540054 * se,
        ci_high_ns=(mean0 - mean1) + 1.959963984540054 * se,
    )
    if need_quantiles:
        stats.quantiles = bootstrap_quantile_diffs(values0, values1, index)
    return stats


def fmt(value: float, digits: int = 3) -> str:
    return f"{value:.{digits}f}"


def fmt_signed(value: float, digits: int = 3) -> str:
    return f"{value:+.{digits}f}"


def relpath(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def iter_grouped(stats_list: Iterable[PairStats]):
    """按 (模块, 臂) 分组，保持登记表顺序。返回 (key, items) 迭代器。"""
    groups: dict[tuple[str, str], list[PairStats]] = {}
    for item in stats_list:
        groups.setdefault((item.pair.module, item.pair.arm), []).append(item)
    return list(groups.items())
