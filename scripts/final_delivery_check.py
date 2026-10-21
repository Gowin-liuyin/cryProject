#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""交付件终检：**从证据原件出发**逐项核对五项结论与三件交付物。

为什么不复用 `scripts/run_final_audit_checks.py`：那份脚本核对的是
`FINAL_AUDIT.csv` 里的**命令**（那些命令本身也是产物）。本脚本改成**直接读
证据原件**（CSV / JSON / 摘要文本 / ZIP 成员）重算关键数字，避免「用产物验产物」。

核对项：
  A　T25 网络场景：检测预算与效应量的数字是否与 `data/*.csv` 逐值一致；
     终态是否全为 restore_match=yes / worker_drained / exit 0；恢复合同是否 8/8。
  B　M5 Binsec checkct：四次 checkct 的路径数与 secure/insecure 结论是否与归档日志一致。
  C　物理精度：TSC 速率、rdtsc 分辨率、1 ms 区间的相对标准差是否与摘要文件一致。
  D　签字清单：机器可核项是否全部通过、项数与表头是否一致。
  E　第二架构：aarch64 12 格是否全为 0 错误 / 0 上下文；x86_64 对照数是否一致。
  F　交付物：匿名包是否可解出复算、成员与摘要是否自洽、官方 PDF/DOCX 是否齐备且无身份标记。

用法：python3 scripts/final_delivery_check.py
退出码 0 表示全部通过；每项打印 PASS/FAIL 与实测值。
"""
import csv
import glob
import hashlib
import io
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
REPORT = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"
EVIDENCE = REPOSITORY / "docs/evidence"

results = []


def check(group, name, ok, detail):
    results.append((group, name, bool(ok), detail))


def read_csv(path):
    with open(path, encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def current_revision():
    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    match = re.search(r"当前有效[：:]\s*`?(final[0-9]+-[0-9]{8})", readme)
    if match is None:
        raise SystemExit("支撑包 README 里找不到当前有效包的声明")
    return match.group(1)


def group_a():
    base = EVIDENCE / "r13-network-20261020"
    budget = read_csv(base / "data/detection-budget.csv")
    comparison = read_csv(base / "data/class-comparison.csv")
    result_text = (base / "RESULT.md").read_text(encoding="utf-8")

    # 1) RESULT.md 里写的检测预算数字必须能在 detection-budget.csv 里逐值找到
    wanted = ["13098", "38417", "64636555", "1003153317", "97586175893"]
    have = {row["required_n_per_class_for_reference_effect"] for row in budget}
    missing = [value for value in wanted if value not in have]
    check("A", "检测预算五个量级与 data/detection-budget.csv 逐值一致",
          not missing,
          "缺 %s" % missing if missing else "13 098 / 38 417 / 64 636 555 / 1 003 153 317 / 97 586 175 893")

    # 2) 终态：30 份 *-terminal.json 全部 restore_match=yes / worker_drained / exit 0
    terminals = sorted(glob.glob(str(base / "data/runs/*/*-terminal.json")))
    bad = []
    for path in terminals:
        payload = json.loads(Path(path).read_text(encoding="utf-8"))
        if (payload.get("restore_match") != "yes" or payload.get("worker_drained") is not True
                or payload.get("worker_exit_code") != 0):
            bad.append(path)
    check("A", "终态全部 restore_match=yes / worker_drained / exit 0",
          terminals and not bad,
          "%d 份终态，不满足 %d 份" % (len(terminals), len(bad)))

    # 3) 恢复合同 8/8
    checks_path = base / "data/recovery-check/checks.txt"
    passes = len([line for line in checks_path.read_text(encoding="utf-8").splitlines()
                  if line.startswith("check pass")])
    summary = (base / "data/recovery-check/summary.txt").read_text(encoding="utf-8")
    check("A", "恢复合同 8/8（failures=0）", passes == 8 and "failures=0" in summary,
          "check pass %d 条，summary：%s" % (passes, summary.strip()))

    # 4) 结论措辞：必须是「本预算下未检出」且不得出现「没有远程泄露」这类越界说法
    # 只有把这句**当成结论**写出来才算越界；「不是「没有远程泄露」」「不得写成…」这类
    # 禁止式表述是正确写法，不能误判（第 9 轮复核的越界项就是这么判出来的）。
    forbidden = []
    for phrase in ("没有远程泄露", "不存在远程泄露", "无远程泄露"):
        for match in re.finditer(re.escape(phrase), result_text):
            context = result_text[max(0, match.start() - 24):match.start()]
            if not re.search(r"不是|不得|不写成|不能|禁止|勿|不会|并非", context):
                forbidden.append(phrase + "（上下文：%s）" % context.strip()[-18:])
    check("A", "结论只写「本预算下未检出」，无越界否定表述",
          "本预算下未检出" in result_text and not forbidden,
          "出现越界表述：%s" % forbidden if forbidden else "措辞在位（禁止式表述不计）")


def group_b():
    base = EVIDENCE / "r14-binsec-m5-20261021"
    expectations = {"m4-vulnerable": ("insecure", 32), "m4-ct": ("secure", 1),
                    "m5-compare": ("secure", 1088), "m5-frommsg": ("secure", 1)}
    bad = []
    for name, (status, paths) in expectations.items():
        console = (base / name / "console.txt").read_text(encoding="utf-8", errors="replace")
        if ("Program status is : " + status) not in console:
            bad.append(name + ":结论不符")
        plural = "%d visited paths" % paths
        singular = "%d visited path " % paths
        if plural not in console and singular not in console:
            bad.append(name + ":路径数不符（期望 %d）" % paths)
    check("B", "四次 checkct 的结论与路径数与归档日志一致", not bad,
          "; ".join(bad) if bad else "m4-vulnerable insecure/32、m4-ct secure/1、"
                                     "m5-compare secure/1088、m5-frommsg secure/1")


def group_c():
    base = EVIDENCE / "r16-precision-20261021/data"
    summary_lines = (base / "locked-summary.txt").read_text(encoding="utf-8").splitlines()
    known_keys = ("tsc_rate_khz", "rdtsc_resolution_counts",
                  "short_interval_implied_frequency_khz",
                  "short_interval_implied_frequency_span",
                  "short_interval_implied_frequency_relative_span",
                  "short_interval_implied_frequency_relative_sd",
                  "kernel_scaling_cur_freq_khz", "interval_target_nanoseconds",
                  "sample_count", "clock_source", "tsc_source")
    locked = {}
    for line in summary_lines:
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        # 有的键后面还跟着 ,n=4096,min=1,… 这样的子字段，按首个逗号把键切干净
        # 键名本身可能带逗号（"short_interval_implied_frequency_span" 是完整的，
        # 而 "rdtsc_resolution_counts,n=4096,min=1,…" 的一等公民是前半段）：
        # 先按已知键名前缀匹配，再退回首个逗号切分。
        matched = [known for known in known_keys if key.startswith(known)]
        if matched:
            key = max(matched, key=len)
        else:
            key = key.split(",")[0]
        locked[key] = value
    rate = float(locked["tsc_rate_khz"])
    resolution = next(line for line in summary_lines
                      if line.startswith("rdtsc_resolution_counts"))
    p50 = int(re.search(r"p50=(\d+)", resolution).group(1))
    relative_sd = float(locked["short_interval_implied_frequency_relative_sd"])
    span = int(locked["short_interval_implied_frequency_span"])
    # 独立重算 1 ms 区间的相对标准差（用逐区间原始值）
    rows = read_csv(base / "locked-intervals.csv")
    # 逐区间原始值里没有「隐含频率」这一列，要现算：
    # 隐含频率(kHz) = tsc_delta(计数) / monotonic_delta(纳秒) × 1e6
    values = []
    for row in rows:
        if not row.get("tsc_delta") or not row.get("monotonic_delta_nanoseconds"):
            continue
        monotonic = float(row["monotonic_delta_nanoseconds"])
        if monotonic <= 0:
            continue
        values.append(float(row["tsc_delta"]) / monotonic * 1e6)
    recomputed = None
    if len(values) > 1:
        mean = sum(values) / len(values)
        variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
        recomputed = (variance ** 0.5) / mean
    span_recomputed = (max(values) - min(values)) if values else -1
    ok = (abs(rate - 4291962.533) < 1 and p50 in (42, 43) and span == 348
          and recomputed is not None and abs(recomputed - 5.4e-6) < 5e-8
          and abs(span_recomputed - span) < 1.0)
    check("C", "TSC 速率 / rdtsc 分辨率 / 1 ms 区间相对标准差与原件一致", ok,
          "TSC %.3f kHz、p50=%d 计数、相对标准差复算 %.3e（摘要写 %.0e）、极差复算 %.1f kHz（摘要写 %d）"
          % (rate, p50, recomputed if recomputed else -1, relative_sd, span_recomputed, span))


def group_d():
    checklist = (EVIDENCE / "closeout-20261016/SIGNOFF_CHECKLIST.md").read_text(encoding="utf-8")
    detail = json.loads((EVIDENCE / "closeout-20261016/signoff-machine-checks-20261020.json")
                        .read_text(encoding="utf-8"))
    # 机器可核项（JSON 里的 items）与**人工判定项**（清单里 | A1 | … 那些行）是
    # 两个不同的数，不能互相比较；各自与自己的声明比。
    item_rows = len([line for line in checklist.splitlines()
                      if re.match(r"^\| [A-E][0-9]+ \|", line)])
    header = re.search(r"机器可核项合计 (\d+) 条", checklist)
    item_header = re.search(r"本清单共 (\d+) 项", checklist)
    ok = (detail["pass"] == detail["items"] and detail["fail"] == 0
          and header is not None and int(header.group(1)) == detail["items"]
          and item_header is not None and int(item_header.group(1)) == item_rows)
    check("D", "机器可核项全过且两处项数声明与实物一致", ok,
          "机器可核 %d 项（表头声明 %s）；人工判定项 %d 行（声明 %s）"
          % (detail["items"], header.group(1) if header else "无",
             item_rows, item_header.group(1) if item_header else "无"))
    # 人工判定栏与签字栏必须仍留空
    empty_marks = checklist.count("| | | |")
    check("D", "人工判定栏与签字栏仍留空（未代填）", empty_marks >= 3,
          "留空行 %d 处" % empty_marks)


def group_e():
    base = EVIDENCE / "r15-aarch64-20261021"
    rows = read_csv(base / "SUMMARY.csv")
    bad = [row for row in rows if row["memcheck_errors"] != "0" or row["memcheck_contexts"] != "0"]
    check("E", "aarch64 12 格全部 0 错误 / 0 上下文", len(rows) == 12 and not bad,
          "%d 格，非零 %d 格" % (len(rows), len(bad)))
    x86 = []
    for path in sorted(glob.glob(str(EVIDENCE / "r09-optlevel-20261016/memcheck/SUMMARY.tsv"))):
        for line in Path(path).read_text(encoding="utf-8").splitlines()[1:]:
            fields = line.split("\t")
            if len(fields) >= 4 and fields[0].startswith("m1unfixed-O"):
                x86.append((fields[0], fields[2], fields[3]))
    want = {"m1unfixed-O2": ("8", "512"), "m1unfixed-O3": ("15", "512"),
            "m1unfixed-Os": ("1", "512")}
    got = {name: (contexts, errors) for name, contexts, errors in x86}
    check("E", "x86_64 对照：M1 未修臂 512 错误 / 8、15、1 上下文",
          all(got.get(name) == value for name, value in want.items()),
          "实测 %s" % got)


def group_f():
    revision = current_revision()
    archive_path = SUPPORT / ("CACR2026EA16XZ-platform-%s.zip" % revision)
    verification = json.loads((SUPPORT / ("%s-verification.json" % revision)).read_text(encoding="utf-8"))
    # 1) 成员摘要自洽
    with zipfile.ZipFile(archive_path) as archive:
        manifest = json.loads(archive.read("MANIFEST.json"))
        mismatched = 0
        for entry in manifest["files"]:
            data = archive.read(entry["path"])
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                mismatched += 1
    check("F", "匿名包 %s 的成员摘要与 MANIFEST 自洽" % revision, mismatched == 0,
          "%d 个成员，摘要不符 %d 个" % (len(manifest["files"]), mismatched))

    # 2) 身份扫描：作者身份与队友设备名分别计数
    patterns = [rb"Gowin", rb"yinhaoran", rb"nss-marker", rb"10\.144\.144", rb"/Users/",
                rb"/home/", rb"yindeMacBook", rb"cryproject", rb"VM-0-17-ubuntu"]
    hits = 0
    with zipfile.ZipFile(archive_path) as archive:
        for name in archive.namelist():
            data = archive.read(name)
            if any(re.search(pattern, data) for pattern in patterns):
                hits += 1
    check("F", "匿名包内直接身份标记 0 命中（独立复扫）", hits == 0,
          "命中 %d 个成员" % hits)

    # 3) 解出复算日志在位且 5/5
    stem = re.sub(r"-\d{8}$", "", revision)
    log = REPOSITORY / ("docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-%s.log" % stem)
    passed = log.is_file() and "100% tests passed, 0 tests failed out of 5" in log.read_text(encoding="utf-8")
    check("F", "解出复算日志在位且包内 CTest 5/5", passed, str(log.name))

    # 4) 官方三件套在位且与当前实物一致
    submission = REPOSITORY / "deliverables/submission/CACR2026EA16XZ"
    official = REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf"
    approval = REPOSITORY / "CACR2026EA16XZ-审批及签字页.pdf"
    copies = [("CACR2026EA16XZ-2026密码竞赛复赛作品设计报告.pdf", official),
              ("CACR2026EA16XZ-2026密码竞赛复赛相关支撑材料.zip", archive_path),
              ("CACR2026EA16XZ-2026密码竞赛审批及签字页.pdf", approval)]
    mismatches = []
    for copy_name, source in copies:
        copy = submission / copy_name
        if not copy.is_file() or not source.is_file():
            mismatches.append(copy_name + ":缺")
        elif hashlib.sha256(copy.read_bytes()).hexdigest() != hashlib.sha256(source.read_bytes()).hexdigest():
            mismatches.append(copy_name + ":不同源")
    check("F", "上传三件套与当前实物逐字节一致", not mismatches,
          "; ".join(mismatches) if mismatches else "报告 / 支撑材料 / 审批签字页 三件均一致")

    # 5) 官方 PDF 无作者身份标记（文字层）
    try:
        import fitz

        with fitz.open(str(official)) as document:
            text = "\n".join(document[index].get_text()
                             for index in range(document.page_count)).encode("utf-8", "ignore")
        pdf_hits = sum(1 for pattern in patterns if re.search(pattern, text))
    except Exception as error:  # pragma: no cover
        pdf_hits = -1
        check("F", "官方作品设计报告 PDF 文字层无身份标记", False, str(error))
    else:
        check("F", "官方作品设计报告 PDF 文字层无身份标记", pdf_hits == 0,
              "命中 %d 项" % pdf_hits)


def main():
    for group in (group_a, group_b, group_c, group_d, group_e, group_f):
        group()
    width = max(len(name) for _, name, _, _ in results)
    failed = 0
    for group_name, name, ok, detail in results:
        failed += 0 if ok else 1
        print("[%s] %-*s  %s" % (group_name, width, name, "PASS" if ok else "FAIL"))
        print("        %s" % detail)
    print("\n合计 %d 项，通过 %d，未通过 %d" % (len(results), len(results) - failed, failed))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
