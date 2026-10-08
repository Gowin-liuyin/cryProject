#!/usr/bin/env python3
"""对照正式重写报告与已归档的 C 报告、CSV。

数字和行数都从归档文件读出，再看报告有没有原文写出。
不在 macOS 上重算 Linux 的 long double 区间。
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
import zipfile
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from xml.etree import ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[3]
DOCX = (
    REPO_ROOT
    / "deliverables/submission/CACR2026EA16XZ/rewrite-20261008"
    / "CACR2026EA16XZ-作品设计报告-重写版.docx"
)
PDF = DOCX.with_suffix(".pdf")
REWRITE_DIR = DOCX.parent
W_NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
SEALED_ZIP_SHA256 = (
    "58d6a60460952cec2a9c1cbc478f35a36e904ecab44252fc594fb98df34f5d26"
)
SEALED_ZIP = (
    REPO_ROOT
    / "deliverables/support/submission-v3-20261007"
    / "待编号-2026密码竞赛复赛相关支撑材料.zip"
)
PROXY_README = REPO_ROOT / "docs/evidence/author-proxy-v3-20261008/README.md"
BAREMETAL = REPO_ROOT / "docs/evidence/baremetal-ryzen-20261008"
R07_RAW = REPO_ROOT / "docs/evidence/r07-linux-20261008/raw"
E02_REPORT = (
    REPO_ROOT / "docs/evidence/native-final-20261007/performance/performance.report"
)
FINITE_SUMMARY = (
    REPO_ROOT / "docs/evidence/finite-calibration-20261007/model/summary.report"
)
FINITE_RAW = REPO_ROOT / "docs/evidence/finite-calibration-20261007/model/raw.csv"
LABEL_SUMMARY = (
    REPO_ROOT
    / "docs/evidence/reference-label-control-20261007/qualified/control/summary.report"
)
LABEL_RAW = (
    REPO_ROOT
    / "docs/evidence/reference-label-control-20261007/qualified/control/raw.csv"
)
PARTIAL_SENTENCE = (
    "R02 与 R04 仍为部分签收：没有锁定频率的数据集，也没有真实密文总体的误报率或检出率。"
)
DENIAL_SENTENCE = "这些记录不是频率锁定、恒时证明或竞赛签收。"
AFFIRMATIVE_CLAIMS = (
    "频率已锁定",
    "已锁定频率",
    "完成了频率锁定",
    "视为频率锁定",
    "恒时证明成立",
    "已证明恒时",
    "给出了恒时证明",
    "竞赛签收完成",
    "已完成竞赛签收",
    "范围内签收",
    "R02 已签收",
    "R04 已签收",
    "完全签收",
)
PATH_RE = re.compile(
    r"docs/(?:evidence/[A-Za-z0-9_./-]+|"
    r"upstream-security-review\.md|"
    r"current-version-defense-review\.md|"
    r"full-work-acceptance\.md)"
)
MINUS_CHARS = str.maketrans({"−": "-", "–": "-", "—": "-"})


def extract_paragraphs(docx_path: Path) -> list[str]:
    with zipfile.ZipFile(docx_path) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))
    paragraphs = []
    for paragraph in root.iter(W_NS + "p"):
        text = "".join(node.text or "" for node in paragraph.iter(W_NS + "t")).strip()
        if text:
            paragraphs.append(text)
    return paragraphs


def cited_records(paragraphs: list[str]) -> list[str]:
    found = set()
    for paragraph in paragraphs:
        for match in PATH_RE.finditer(paragraph):
            found.add(match.group(0).rstrip("/"))
    return sorted(found)


def data_row_count(path: Path) -> int:
    rows = [line for line in path.read_bytes().splitlines() if line.strip()]
    if not rows:
        return 0
    first = rows[0].decode("utf-8", "replace")
    if first[:1].isdigit():
        return len(rows)
    return len(rows) - 1


def same_row_count(paths: list[Path]) -> int:
    counts = {data_row_count(path) for path in paths}
    if len(counts) != 1:
        raise RuntimeError(f"行数不一致: {sorted(path.name for path in paths)} {counts}")
    return counts.pop()


def analyze_record(path: Path) -> tuple[str, int, str]:
    implementation = ""
    significant_count = None
    primary_result = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("implementation="):
            implementation = line.split("=", 1)[1]
        elif line.startswith("significant_comparison_count="):
            significant_count = int(line.split("=", 1)[1])
        elif "primary=yes" in line:
            match = re.search(r"result=([A-Za-z_]+)", line)
            if match:
                primary_result = match.group(1)
    if not implementation:
        implementation = path.name.split("-seed", 1)[0]
    if significant_count is None or not primary_result:
        raise RuntimeError(f"分析报告缺少字段: {path}")
    return implementation, significant_count, primary_result


def uniform_analyze(paths: list[Path]) -> dict[str, tuple[int, str, int]]:
    grouped: dict[str, list[tuple[int, str]]] = defaultdict(list)
    for path in paths:
        implementation, significant_count, primary_result = analyze_record(path)
        grouped[implementation].append((significant_count, primary_result))
    summary = {}
    for implementation, rows in grouped.items():
        counts = {count for count, _ in rows}
        results = {result for _, result in rows}
        if len(counts) != 1 or len(results) != 1:
            raise RuntimeError(f"{implementation} 的分析字段不一致: {rows}")
        summary[implementation] = (counts.pop(), results.pop(), len(rows))
    return summary


def baremetal_facts() -> dict[str, object]:
    ordinary_csvs = sorted((BAREMETAL / "performance").glob("ordinary-*.csv"))
    mechanism_csvs = sorted((BAREMETAL / "mechanism").glob("*-seed*.csv"))
    performance_report = (BAREMETAL / "performance/performance.report").read_text(
        encoding="utf-8"
    )
    quoted_lines = [
        line
        for line in performance_report.splitlines()
        if line.startswith(
            (
                "clock=",
                "time_unit=",
                "comparison=",
                "formal_completed_calls=",
                "warmup_completed_calls=",
                "interval_scope=",
                "report_status=",
                "source_identity=",
            )
        )
    ]
    mechanism_reports = sorted(
        path
        for path in (BAREMETAL / "mechanism").glob("*.report")
        if not path.name.endswith(".groups.report")
    )
    analyze = uniform_analyze(mechanism_reports)
    preflight = (BAREMETAL / "preflight.log").read_text(encoding="utf-8", errors="replace")
    frequency_after = (BAREMETAL / "frequency-after.log").read_text(
        encoding="utf-8", errors="replace"
    )
    tokens = {}
    for key in ("governor", "frequency_policy", "cur_khz", "max_khz"):
        values = set(re.findall(rf"^{key}=(\S+)", preflight, re.MULTILINE))
        if len(values) != 1:
            raise RuntimeError(f"preflight {key} 不唯一: {values}")
        tokens[key] = f"{key}={values.pop()}"
    compress_lines: dict[str, int] = {}
    sanitize_log = (BAREMETAL / "sanitize-build.log").read_text(
        encoding="utf-8", errors="replace"
    )
    for line in sanitize_log.splitlines():
        match = re.search(
            r"/(vulnerable|hardened)-source/.+compress\.c:(\d+):\d+: error:",
            line,
        )
        if match and "-Werror=sign-conversion" in line:
            compress_lines[match.group(1)] = int(match.group(2))
    sanitize_exit = None
    other_nonzero = []
    for line in (BAREMETAL / "step-exits.tsv").read_text(encoding="utf-8").splitlines()[1:]:
        step_name, _started, _finished, exit_code = line.split("\t")
        if step_name == "sanitize-build":
            sanitize_exit = int(exit_code)
        elif exit_code != "0":
            other_nonzero.append(f"{step_name}={exit_code}")
    meta_paths = list((BAREMETAL / "performance").glob("*.meta")) + list(
        (BAREMETAL / "mechanism").glob("*.meta")
    )
    return {
        "ordinary_runs": len(ordinary_csvs),
        "ordinary_rows_each": same_row_count(ordinary_csvs),
        "mechanism_runs": len(mechanism_csvs),
        "mechanism_rows_each": same_row_count(mechanism_csvs),
        "collect_rows": data_row_count(BAREMETAL / "collect/data.csv"),
        "calibrate_rows": data_row_count(BAREMETAL / "calibrate/raw.csv"),
        "label_rows": data_row_count(BAREMETAL / "reference-label-control/raw.csv"),
        "quoted_lines": quoted_lines,
        "analyze": analyze,
        "preflight": preflight,
        "frequency_after": frequency_after,
        "tokens": tokens,
        "compress_lines": compress_lines,
        "sanitize_exit": sanitize_exit,
        "other_nonzero": other_nonzero,
        "sanitize_log": sanitize_log,
        "meta_paths": meta_paths,
    }


def section_between(text: str, start: str, end: str) -> str:
    start_at = text.find(start)
    end_at = text.find(end, start_at if start_at >= 0 else 0)
    if start_at < 0 or end_at < 0:
        return ""
    return text[start_at : end_at + len(end)]


def parse_after(paragraphs: list[str], caption_prefix: str) -> list[str]:
    for index, paragraph in enumerate(paragraphs):
        if paragraph.startswith(caption_prefix):
            return paragraphs[index + 1 :]
    raise RuntimeError(f"报告中没有找到 {caption_prefix}")


def parse_e02_table(paragraphs: list[str]) -> dict[tuple[str, str], tuple[str, str, str, str]]:
    rows = {}
    pending = parse_after(paragraphs, "表B.1")
    index = 0
    while index + 5 < len(pending):
        block, implementation, mean, p50, p90, p99 = pending[index : index + 6]
        if (
            re.fullmatch(r"\d+", block)
            and implementation in {"reference", "hardened", "deployable"}
            and re.fullmatch(r"\d+\.\d+", mean)
            and re.fullmatch(r"\d+", p50)
            and re.fullmatch(r"\d+", p90)
            and re.fullmatch(r"\d+", p99)
        ):
            rows[(block, implementation)] = (mean, p50, p90, p99)
            index += 6
            continue
        if rows:
            break
        index += 1
    return rows


def parse_groups_table(paragraphs: list[str]) -> dict[tuple[str, str], str]:
    pending = parse_after(paragraphs, "表5.10")
    index = 0
    headers: list[str] = []
    while index < len(pending) and not re.fullmatch(r"\d{4,}", pending[index]):
        headers.append(pending[index])
        index += 1
    implementations = [
        header
        for header in headers
        if header in {"reference", "vulnerable", "hardened", "deployable"}
    ]
    rows = {}
    while index + len(implementations) < len(pending) and re.fullmatch(r"\d{4,}", pending[index]):
        seed = pending[index]
        values = pending[index + 1 : index + 1 + len(implementations)]
        if not all(re.fullmatch(r"[−–—-]?\d+\.\d+", value) for value in values):
            break
        for implementation, value in zip(implementations, values):
            rows[(seed, implementation)] = value.translate(MINUS_CHARS)
        index += 1 + len(implementations)
    return rows


def parse_finite_table(paragraphs: list[str]) -> list[tuple[str, str, str]]:
    pending = parse_after(paragraphs, "表5.7")
    rows = []
    index = 0
    while index + 2 < len(pending):
        effect, equal_count, graded_count = pending[index : index + 3]
        if all(re.fullmatch(r"\d+", cell) for cell in (effect, equal_count, graded_count)):
            rows.append((effect, equal_count, graded_count))
            index += 3
            continue
        if rows:
            break
        index += 1
    return rows


def parse_label_table(paragraphs: list[str]) -> list[tuple[str, str, str, str]]:
    pending = parse_after(paragraphs, "表5.8")
    rows = []
    index = 0
    while index + 3 < len(pending):
        block, combinations, rejections, probability = pending[index : index + 4]
        if (
            re.fullmatch(r"\d+", block)
            and re.fullmatch(r"\d+", combinations)
            and re.fullmatch(r"\d+", rejections)
            and re.fullmatch(r"\d+\.\d+", probability)
        ):
            rows.append((block, combinations, rejections, probability))
            index += 4
            continue
        if rows:
            break
        index += 1
    return rows


def printed_mean(raw_mean: str) -> str:
    quantized = Decimal(raw_mean).quantize(Decimal("0.001"), rounding=ROUND_HALF_UP)
    return f"{quantized:.3f}"


def compare_e02(paragraphs: list[str], failures: list[str]) -> int:
    table = parse_e02_table(paragraphs)
    mismatches = 0
    seen = 0
    for line in E02_REPORT.read_text(encoding="utf-8").splitlines():
        if not line.startswith("run=ordinary-"):
            continue
        seen += 1
        match = re.search(
            r"run=ordinary-([a-z]+)-block(\d+) .* mean_ns=(\S+) "
            r"p50_ns=(\S+) p90_ns=(\S+) p99_ns=(\S+)",
            line,
        )
        if not match:
            failures.append(f"无法解析 E02 行: {line}")
            mismatches += 1
            continue
        key = (match.group(2), match.group(1))
        expected = (
            printed_mean(match.group(3)),
            match.group(4),
            match.group(5),
            match.group(6),
        )
        actual = table.get(key)
        if actual != expected:
            failures.append(f"E02 {key} 报告={actual} 归档={expected}")
            mismatches += 1
    if seen != len(table):
        failures.append(f"E02 行数 报告={len(table)} 归档={seen}")
        mismatches += abs(seen - len(table))
    return mismatches


def compare_groups(paragraphs: list[str], failures: list[str]) -> int:
    table = parse_groups_table(paragraphs)
    mismatches = 0
    seen = 0
    for path in sorted(R07_RAW.glob("*.groups.report")):
        match = re.match(
            r"(reference|vulnerable|hardened|deployable)-seed(\d+)\.groups\.report",
            path.name,
        )
        if not match:
            continue
        seen += 1
        text = path.read_text(encoding="utf-8")
        value_match = re.search(r"mean_difference_ns=(-?\d+\.\d+)", text)
        if not value_match:
            failures.append(f"分组报告缺少均值差: {path.name}")
            mismatches += 1
            continue
        key = (match.group(2), match.group(1))
        expected = value_match.group(1)
        actual = table.get(key)
        if actual != expected:
            failures.append(f"表5.10 {key} 报告={actual} 归档={expected}")
            mismatches += 1
    if seen != len(table):
        failures.append(f"表5.10 行数 报告={len(table)} 归档={seen}")
        mismatches += abs(seen - len(table))
    return mismatches


def compare_finite(paragraphs: list[str], report_text: str, failures: list[str]) -> int:
    table = {effect: (equal_count, graded_count) for effect, equal_count, graded_count in parse_finite_table(paragraphs)}
    mismatches = 0
    archived: dict[tuple[str, str], str] = {}
    for line in FINITE_SUMMARY.read_text(encoding="utf-8").splitlines():
        match = re.search(
            r"model=(\w+) effect_ns=(\d+) population=(\d+) raw_rejections=(\d+)",
            line,
        )
        if not match:
            continue
        model, effect, population, rejections = match.groups()
        archived[(model, effect)] = rejections
        if model.startswith("common_"):
            token = f"{rejections}/{population}"
            if token not in report_text:
                failures.append(f"报告没有写出共同模型 {model} {token}")
                mismatches += 1
    effects = sorted({effect for model, effect in archived if model.startswith("independent_")}, key=int)
    for effect in effects:
        expected = (
            archived.get(("independent_equal", effect)),
            archived.get(("independent_graded", effect)),
        )
        actual = table.get(effect)
        if actual != expected:
            failures.append(f"表5.7 效应 {effect} 报告={actual} 归档={expected}")
            mismatches += 1
    if len(table) != len(effects):
        failures.append(f"表5.7 行数 报告={len(table)} 归档={len(effects)}")
        mismatches += abs(len(table) - len(effects))
    return mismatches


def compare_labels(paragraphs: list[str], failures: list[str]) -> int:
    table = {block: (combinations, rejections, probability) for block, combinations, rejections, probability in parse_label_table(paragraphs)}
    mismatches = 0
    seen = 0
    for line in LABEL_SUMMARY.read_text(encoding="utf-8").splitlines():
        match = re.search(
            r"source_run=ordinary-reference-block(\d+) .* assignment_count=(\d+) "
            r"raw_rejections=(\d+) conditional_probability=(\d+\.\d+)",
            line,
        )
        if not match:
            continue
        seen += 1
        expected = (match.group(2), match.group(3), match.group(4))
        actual = table.get(match.group(1))
        if actual != expected:
            failures.append(f"表5.8 块 {match.group(1)} 报告={actual} 归档={expected}")
            mismatches += 1
    if seen != len(table):
        failures.append(f"表5.8 行数 报告={len(table)} 归档={seen}")
        mismatches += abs(seen - len(table))
    return mismatches


def r07_phrase_failures(report_text: str) -> list[str]:
    failures = []
    reports = [
        path
        for path in R07_RAW.glob("*.report")
        if not path.name.endswith(".groups.report")
    ]
    summary = uniform_analyze(reports)
    vulnerable = summary.get("vulnerable")
    if vulnerable is None:
        return ["R07 缺少 vulnerable 分析报告"]
    count, primary, runs = vulnerable
    if f"均有{count}项" not in report_text:
        failures.append(f"报告没有写出 R07 vulnerable 显著项数 {count}（{runs} 次，{primary}）")
    if primary == "significant" and "预定主比较均显著" not in report_text:
        failures.append("报告没有写出 R07 预定主比较显著")
    for implementation in ("reference", "hardened", "deployable"):
        other = summary.get(implementation)
        if other is None:
            failures.append(f"R07 缺少 {implementation} 分析报告")
            continue
        other_count, other_primary, _runs = other
        if other_count != 0 or other_primary != "not_significant":
            failures.append(f"R07 {implementation} 为 {other_count}/{other_primary}，与现有正文口径不同")
    if "十项显著数均为0" not in report_text:
        failures.append("报告没有写出其余实现十项显著数为 0")
    return failures


def baremetal_phrase_failures(report_text: str, facts: dict[str, object]) -> list[str]:
    section = section_between(report_text, "裸金属记录单独列为", PARTIAL_SENTENCE)
    failures = []
    if not section:
        return ["报告没有裸金属材料段"]
    analyze = facts["analyze"]
    vulnerable = analyze.get("vulnerable")
    if vulnerable is None:
        failures.append("裸金属缺少 vulnerable 分析报告")
    else:
        count, primary, _runs = vulnerable
        phrase = f"significant_comparison_count 均为 {count}"
        if phrase not in section or f"result={primary}" not in section:
            failures.append(f"裸金属段没有写出 vulnerable {phrase} result={primary}")
    for implementation in ("reference", "hardened", "deployable"):
        other = analyze.get(implementation)
        if other is None:
            failures.append(f"裸金属缺少 {implementation} 分析报告")
            continue
        other_count, other_primary, _runs = other
        phrase = f"significant_comparison_count 均为 {other_count}"
        if phrase not in section or f"result={other_primary}" not in section:
            failures.append(f"裸金属段没有写出 {implementation} {phrase} result={other_primary}")
    required = [
        "docs/evidence/baremetal-ryzen-20261008",
        "不并入 docs/evidence/r07-linux-20261008",
        "Ubuntu 24.04.4",
        "AMD Ryzen 9 9950X",
        "powersave",
        "频率没有锁定",
        facts["tokens"]["governor"],
        facts["tokens"]["frequency_policy"],
        facts["tokens"]["cur_khz"],
        facts["tokens"]["max_khz"],
        "frequency_control=not_configured",
        "cpu_affinity=not_pinned",
        "CLOCK_MONOTONIC",
        "单位 ns",
        f"{facts['ordinary_runs']}×{facts['ordinary_rows_each']}",
        f"{facts['mechanism_runs']}×{facts['mechanism_rows_each']}",
        f"collect/data.csv 为 {facts['collect_rows']} 条",
        f"calibrate/raw.csv 为 {facts['calibrate_rows']} 条",
        f"reference-label-control/raw.csv 为 {facts['label_rows']} 条",
        f"sanitize-build 退出码为 {facts['sanitize_exit']}",
        "-Werror=sign-conversion",
        "baseline_native_poly_frommsg",
        DENIAL_SENTENCE,
        PARTIAL_SENTENCE,
    ]
    for implementation, line_number in facts["compress_lines"].items():
        required.append(f"{implementation} compress.c:{line_number}")
    required.extend(facts["quoted_lines"])
    for phrase in required:
        if phrase not in section:
            failures.append(f"裸金属段缺少: {phrase}")
    for phrase in ("Ubuntu 24.04.4", "AMD Ryzen 9 9950X"):
        if phrase not in facts["preflight"]:
            failures.append(f"preflight 没有 {phrase}")
    if facts["tokens"]["governor"] not in facts["frequency_after"]:
        failures.append("frequency-after 与 preflight 的调速器记录不同")
    if facts["tokens"]["cur_khz"] not in facts["frequency_after"]:
        failures.append("frequency-after 与 preflight 的当前频率记录不同")
    if "baseline_native_poly_frommsg" not in facts["sanitize_log"]:
        failures.append("sanitize 日志没有 baseline_native_poly_frommsg")
    if set(facts["compress_lines"]) != {"vulnerable", "hardened"}:
        failures.append(f"sign-conversion 位置不是两份实现: {facts['compress_lines']}")
    if facts["sanitize_exit"] != 2:
        failures.append(f"sanitize-build 退出码为 {facts['sanitize_exit']}")
    if facts["other_nonzero"]:
        failures.append(f"裸金属另有非零退出: {facts['other_nonzero']}")
    for meta_path in facts["meta_paths"]:
        meta_text = meta_path.read_text(encoding="utf-8", errors="replace")
        for token in ("frequency_control=not_configured", "cpu_affinity=not_pinned", "clock=CLOCK_MONOTONIC", "time_unit=ns"):
            if token not in meta_text:
                failures.append(f"{meta_path.name} 缺少 {token}")
                break
    return failures


E02_N01_CROSS = "E02 与 N01 的探索区间均跨零"
RYZEN_NO_CROSS = "Ryzen 裸金属的探索区间不跨零"
RYZEN_NOT_SIGNOFF = "这些记录仍不是频率锁定、恒时证明或竞赛签收"


def ordinary_interval_bounds(facts: dict[str, object]) -> list[tuple[Decimal, Decimal]]:
    bounds = []
    for line in facts["quoted_lines"]:
        if not str(line).startswith("comparison="):
            continue
        lower_match = re.search(r"interval_lower_ns=(-?[0-9]+(?:\.[0-9]+)?)", str(line))
        upper_match = re.search(r"interval_upper_ns=(-?[0-9]+(?:\.[0-9]+)?)", str(line))
        if lower_match is None or upper_match is None:
            raise RuntimeError(f"裸金属比较行没有区间: {line}")
        bounds.append((Decimal(lower_match.group(1)), Decimal(upper_match.group(1))))
    if not bounds:
        raise RuntimeError("裸金属普通报告没有比较区间")
    return bounds


def linux_ordinary_claim_failures(
    paragraphs: list[str], facts: dict[str, object]
) -> list[str]:
    bounds = ordinary_interval_bounds(facts)
    if any(lower <= 0 for lower, _upper in bounds):
        return []
    failures = []
    for paragraph in paragraphs:
        for sentence in re.split(r"[。；]", paragraph):
            names_every_linux = (
                "真实 Linux 普通记录" in sentence
                and "均跨零" in sentence
                and ("E02" not in sentence or "N01" not in sentence)
            )
            anaphora = "其探索区间均跨零" in sentence and (
                "E02" not in sentence or "N01" not in sentence
            )
            if names_every_linux or anaphora:
                failures.append(
                    "裸金属区间下界为正，报告仍把真实 Linux 普通记录的探索区间写成均跨零"
                )
                break
        else:
            continue
        break
    summary = next(
        (
            paragraph
            for paragraph in paragraphs
            if paragraph.startswith("测试表明，当前原生构建")
        ),
        "",
    )
    if not summary:
        failures.append("报告没有第7.1节工作总结段")
    else:
        for phrase in (E02_N01_CROSS, RYZEN_NO_CROSS, RYZEN_NOT_SIGNOFF):
            if phrase not in summary:
                failures.append(f"第7.1节没有写明: {phrase}")
    return failures


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def identity_failures(report_text: str) -> list[str]:
    failures = []
    readme = PROXY_README.read_text(encoding="utf-8")
    package_match = re.search(r"包 SHA-256：`([0-9a-f]{64})`", readme)
    source_match = re.search(r"源清单 SHA-256：`([0-9a-f]{64})`", readme)
    if not package_match or not source_match:
        return ["封存执行说明里没有两枚 SHA-256"]
    package_hash = package_match.group(1)
    source_hash = source_match.group(1)
    if package_hash not in report_text:
        failures.append("报告没有写明封存包 SHA-256")
    if source_hash not in report_text:
        failures.append("报告没有写明源清单 SHA-256")
    if not SEALED_ZIP.is_file():
        failures.append(f"封存包不存在: {SEALED_ZIP.relative_to(REPO_ROOT)}")
    else:
        actual = sha256_file(SEALED_ZIP)
        if actual != package_hash or actual != SEALED_ZIP_SHA256:
            failures.append(f"封存包摘要变化: {actual}")
    step_lines = (
        REPO_ROOT / "docs/evidence/author-proxy-v3-20261008/results/step-exits.tsv"
    ).read_text(encoding="utf-8").splitlines()[1:]
    exit_codes = [line.split("\t")[-1] for line in step_lines]
    if exit_codes and all(code == "0" for code in exit_codes):
        phrase = f"{len(exit_codes)}个执行步骤全部退出0"
        if phrase not in report_text:
            failures.append(f"报告没有写出 {phrase}")
    else:
        failures.append(f"封存步骤退出码不是全 0: {exit_codes}")
    manifest = (
        REPO_ROOT / "docs/evidence/author-proxy-v3-20261008/results/source-manifest.log"
    ).read_text(encoding="utf-8", errors="replace")
    ok_count = len(re.findall(r": OK$", manifest, re.MULTILINE))
    if f"{ok_count}项源清单" not in report_text:
        failures.append(f"报告没有写出 {ok_count}项源清单")
    test_counts = []
    for name in ("gcc-tests.log", "clang-sanitize-tests.log"):
        log_text = (
            REPO_ROOT / "docs/evidence/author-proxy-v3-20261008/results" / name
        ).read_text(encoding="utf-8", errors="replace")
        match = re.search(r"out of (\d+)", log_text)
        if not match:
            failures.append(f"{name} 没有测试总数")
            continue
        test_counts.append(match.group(1))
    if len(set(test_counts)) == 1 and f"各{test_counts[0]}项" not in report_text:
        failures.append(f"报告没有写出各{test_counts[0]}项")
    finite_rows = data_row_count(FINITE_RAW)
    label_rows = data_row_count(LABEL_RAW)
    if str(finite_rows) not in report_text:
        failures.append(f"报告没有写出有限模型行数 {finite_rows}")
    if str(label_rows) not in report_text:
        failures.append(f"报告没有写出标签控制行数 {label_rows}")
    return failures


def pdf_failures(facts: dict[str, object]) -> list[str]:
    if not PDF.is_file():
        return ["重写版 PDF 不存在"]
    import shutil
    import subprocess

    pdftotext = shutil.which("pdftotext")
    if not pdftotext:
        return ["系统没有 pdftotext，无法核对 PDF 正文"]
    result = subprocess.run(
        [pdftotext, "-enc", "UTF-8", str(PDF), "-"],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        return [f"pdftotext 退出 {result.returncode}"]
    compact = re.sub(r"\s+", "", result.stdout.decode("utf-8", "replace"))
    phrases = [
        "裸金属记录单独列为",
        "docs/evidence/baremetal-ryzen-20261008",
        "不并入docs/evidence/r07-linux-20261008",
        "Ubuntu24.04.4",
        "AMDRyzen99950X",
        "频率没有锁定",
        "frequency_control=not_configured",
        "cpu_affinity=not_pinned",
        "CLOCK_MONOTONIC",
        "compress.c:709",
        "compress.c:710",
        "-Werror=sign-conversion",
        "baseline_native_poly_frommsg",
        f"sanitize-build退出码为{facts['sanitize_exit']}",
        re.sub(r"\s+", "", PARTIAL_SENTENCE),
        re.sub(r"\s+", "", DENIAL_SENTENCE),
        f"{facts['ordinary_runs']}×{facts['ordinary_rows_each']}",
        f"{facts['mechanism_runs']}×{facts['mechanism_rows_each']}",
    ]
    phrases.extend(re.sub(r"\s+", "", line) for line in facts["quoted_lines"])
    readme = PROXY_README.read_text(encoding="utf-8")
    phrases.extend(re.findall(r"`([0-9a-f]{64})`", readme))
    failures = []
    for phrase in phrases:
        if phrase not in compact:
            failures.append(f"PDF 缺少: {phrase}")
    bounds = ordinary_interval_bounds(facts)
    if all(lower > 0 for lower, _upper in bounds):
        if "其探索区间均跨零" in compact:
            failures.append("PDF 仍写其探索区间均跨零")
        old_claim = re.sub(
            r"\s+",
            "",
            "真实 Linux 普通记录揭示了有限运行中的性能波动，其探索区间均跨零",
        )
        if old_claim in compact:
            failures.append("PDF 仍把真实 Linux 普通记录的探索区间写成均跨零")
        for phrase in (E02_N01_CROSS, RYZEN_NO_CROSS, RYZEN_NOT_SIGNOFF):
            if re.sub(r"\s+", "", phrase) not in compact:
                failures.append(f"PDF 缺少: {phrase}")
    return failures


def check_materials(skip_pdf: bool) -> int:
    failures: list[str] = []
    paragraphs = extract_paragraphs(DOCX)
    report_text = "\n".join(paragraphs)
    records = cited_records(paragraphs)
    absent = [record for record in records if not (REPO_ROOT / record).exists()]
    print(f"cited_materials={len(records)} absent={len(absent)}")
    for record in records:
        state = "present" if (REPO_ROOT / record).exists() else "ABSENT"
        print(f"cited {state} {record}")
    failures.extend(f"引用不存在: {record}" for record in absent)
    facts = baremetal_facts()
    print(
        "ordinary_runs={ordinary_runs} ordinary_rows_each={ordinary_rows_each} "
        "mechanism_runs={mechanism_runs} mechanism_rows_each={mechanism_rows_each} "
        "collect_rows={collect_rows} calibrate_rows={calibrate_rows} "
        "reference_label_rows={label_rows}".format(**facts)
    )
    print(f"finite_model_rows={data_row_count(FINITE_RAW)}")
    print(f"label_control_rows={data_row_count(LABEL_RAW)}")
    mismatches = 0
    mismatches += compare_e02(paragraphs, failures)
    mismatches += compare_groups(paragraphs, failures)
    mismatches += compare_finite(paragraphs, report_text, failures)
    mismatches += compare_labels(paragraphs, failures)
    print(f"statistic_mismatches={mismatches}")
    failures.extend(r07_phrase_failures(report_text))
    failures.extend(baremetal_phrase_failures(report_text, facts))
    bounds = ordinary_interval_bounds(facts)
    positive_lowers = sum(1 for lower, _upper in bounds if lower > 0)
    print(f"baremetal_positive_lowers={positive_lowers}/{len(bounds)}")
    failures.extend(linux_ordinary_claim_failures(paragraphs, facts))
    failures.extend(identity_failures(report_text))
    if "R02 范围内签收" in report_text or "R04 范围内签收" in report_text:
        failures.append("报告把 R02 或 R04 写成范围内签收")
    section = section_between(report_text, "裸金属记录单独列为", PARTIAL_SENTENCE)
    claim_hits = [phrase for phrase in AFFIRMATIVE_CLAIMS if phrase in section]
    print(f"affirmative_claim_hits={len(claim_hits)}")
    failures.extend(f"裸金属段出现抬高表述: {phrase}" for phrase in claim_hits)
    if skip_pdf:
        print("pdf_check=skipped")
    else:
        pdf_misses = pdf_failures(facts)
        print(f"pdf_phrase_misses={len(pdf_misses)}")
        failures.extend(pdf_misses)
    if failures:
        print(f"failures={len(failures)}")
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print("failures=0")
    print("materials_check=pass")
    return 0


def support_archives() -> list[Path]:
    archives = []
    support = REPO_ROOT / "deliverables/support"
    for path in support.rglob("*.zip"):
        if "CACR2026EA16XZ" in path.name:
            archives.append(path)
    return sorted(archives)


def entry_covers(entry: str, cited: str) -> bool:
    target = REPO_ROOT / cited
    if target.is_file():
        return entry == cited
    return entry == cited or entry.startswith(cited + "/")


def check_archive() -> int:
    failures = []
    archives = support_archives()
    print(f"support_archives={len(archives)}")
    if len(archives) != 1:
        failures.append(f"期望 1 个 CACR2026EA16XZ 支撑包，实际 {len(archives)}")
        archive = archives[0] if archives else None
    else:
        archive = archives[0]
    if archive is not None:
        size = archive.stat().st_size
        digest = sha256_file(archive)
        with zipfile.ZipFile(archive) as bundle:
            entries = bundle.namelist()
            print(f"archive={archive.relative_to(REPO_ROOT)}")
            print(f"sha256={digest}")
            print(f"bytes={size}")
            print(f"entries={len(entries)}")
            print(f"name_has_CACR2026EA16XZ={'CACR2026EA16XZ' in archive.name}")
            print(f"within_4gb={size <= 4 * 1024 * 1024 * 1024}")
            if size > 4 * 1024 * 1024 * 1024:
                failures.append("支撑包超过 4GB")
            paragraphs = extract_paragraphs(DOCX)
            cited = cited_records(paragraphs)
            for record in cited:
                if not any(entry_covers(entry, record) for entry in entries):
                    failures.append(f"支撑包缺少 {record}")
            for entry in entries:
                if not any(entry_covers(entry, record) for record in cited):
                    failures.append(f"支撑包含有未引用条目 {entry}")
            failures.extend(manifest_failures(bundle))
    if not SEALED_ZIP.is_file():
        failures.append("封存 v3 zip 不存在")
    else:
        actual = sha256_file(SEALED_ZIP)
        print(f"sealed {SEALED_ZIP.relative_to(REPO_ROOT)} sha256={actual}")
        if actual != SEALED_ZIP_SHA256:
            failures.append("封存 v3 zip 被改写")
    if failures:
        print(f"failures={len(failures)}")
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print("failures=0")
    print("archive_check=pass")
    return 0


def manifest_failures(bundle: zipfile.ZipFile) -> list[str]:
    failures = []
    names = set(bundle.namelist())
    manifests = [
        name
        for name in sorted(names)
        if Path(name).name == "SHA256SUMS" or Path(name).name.endswith(".SHA256SUMS")
    ]
    print(f"archive_manifests={len(manifests)}")
    for manifest in manifests:
        text = bundle.read(manifest).decode("utf-8")
        base = str(Path(manifest).parent)
        for line in text.splitlines():
            match = re.match(r"^([0-9a-f]{64})  +(\S.*)$", line.strip())
            if not match:
                continue
            digest, listed = match.group(1), match.group(2).strip()
            target = listed if listed in names else str(Path(base) / listed)
            if target not in names:
                if listed.startswith("runner-01") or listed.startswith("/"):
                    continue
                failures.append(f"{manifest} 指向包外文件 {listed}")
                continue
            actual = hashlib.sha256(bundle.read(target)).hexdigest()
            if actual != digest:
                failures.append(f"{manifest} 与匿名副本不一致: {listed}")
    return failures


def scan_bytes(payload: bytes, needles: tuple[bytes, ...]) -> dict[str, int]:
    return {needle.decode("utf-8", "replace"): payload.count(needle) for needle in needles}


def check_secrets(password_file: str | None) -> int:
    failures = []
    identity_needles = (
        b"nss-marker",
        b"/home/nss-marker",
        b"/home/ubuntu",
        b"/Users/yin",
        b"yinhaoran",
        b"Gowin-liuyin",
        b"10.144.144.5",
        b"nss@",
    )
    archives = support_archives()
    if len(archives) != 1:
        print("password_hits=not_scanned")
        print("FAIL 没有唯一的支撑包可扫描")
        return 1
    archive = archives[0]
    totals = {needle.decode(): 0 for needle in identity_needles}
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.namelist():
            counts = scan_bytes(bundle.read(entry), identity_needles)
            for key, count in counts.items():
                totals[key] += count
    for key, count in totals.items():
        print(f"archive_{key}={count}")
        if count:
            failures.append(f"支撑包含有 {key} {count} 次")
    password_hits = 0
    if password_file:
        needle = Path(password_file).read_text(encoding="utf-8").strip().encode("utf-8")
        if not needle:
            failures.append("密码扫描文件是空的")
        else:
            with zipfile.ZipFile(archive) as bundle:
                for entry in bundle.namelist():
                    password_hits += bundle.read(entry).count(needle)
            for path in sorted(REWRITE_DIR.rglob("*")):
                if path.is_file():
                    password_hits += path.read_bytes().count(needle)
        print("password_hits=" + str(password_hits))
    else:
        print("password_hits=not_scanned")
        failures.append("没有提供密码扫描文件")
    if password_hits:
        failures.append("密码出现在支撑包或重写报告目录")
    rewrite_hits = 0
    for path in sorted(REWRITE_DIR.rglob("*")):
        if path.is_file():
            rewrite_hits += path.read_bytes().count(b"nss-marker")
    print(f"rewrite_tree_nss_marker={rewrite_hits}")
    if rewrite_hits:
        failures.append("重写报告目录含有 nss-marker")
    paragraphs = extract_paragraphs(DOCX)
    report_text = "\n".join(paragraphs)
    section = section_between(report_text, "裸金属记录单独列为", PARTIAL_SENTENCE)
    claim_hits = [phrase for phrase in AFFIRMATIVE_CLAIMS if phrase in section]
    print(f"affirmative_claim_hits={len(claim_hits)}")
    for phrase in claim_hits:
        print(f"claim {phrase}")
        failures.append(f"抬高表述: {phrase}")
    partial_present = PARTIAL_SENTENCE in report_text
    denial_present = DENIAL_SENTENCE in report_text
    print(f"r02_r04_partial={str(partial_present).lower()}")
    print(f"denial_present={str(denial_present).lower()}")
    if not partial_present:
        failures.append("报告没有保留 R02 与 R04 部分签收")
    if not denial_present:
        failures.append("报告没有写明这些记录不是频率锁定、恒时证明或竞赛签收")
    if "频率没有锁定" not in section:
        failures.append("裸金属段没有写明频率没有锁定")
    if failures:
        print(f"failures={len(failures)}")
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print("failures=0")
    print("secrets_check=pass")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", action="store_true")
    parser.add_argument("--secrets", action="store_true")
    parser.add_argument("--password-file", default=None)
    parser.add_argument("--skip-pdf", action="store_true")
    args = parser.parse_args()
    if args.archive:
        return check_archive()
    if args.secrets:
        return check_secrets(args.password_file)
    return check_materials(args.skip_pdf)


if __name__ == "__main__":
    sys.exit(main())
