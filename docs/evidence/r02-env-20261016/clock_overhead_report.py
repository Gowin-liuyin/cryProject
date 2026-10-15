#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T07 读钟开销：从既有 raw-clock 归档复算「连续两次 clock_gettime 的空窗口」分布。

数据来源（**仓库内既有原件**，不新采集）：
  docs/evidence/raw-clock-20261010/run-aa43771/remote-originals.tar.gz
  成员 output/P{1,2,3}.csv —— 每行是一次空 pair：
      before_ns = clock_gettime(CLOCK_MONOTONIC_RAW)
      atomic_signal_fence(seq_cst) x2   （没有其它工作）
      after_ns  = clock_gettime(CLOCK_MONOTONIC_RAW)
  见该归档 source/raw_clock_calibration.c 的 record_pair()。
  `elapsed_ns = after_ns - before_ns` 就是「一次紧邻读钟」的空窗口耗时。

用法：python3 docs/evidence/r02-env-20261016/clock_overhead_report.py
"""

from __future__ import annotations

import csv
import io
import os
import statistics
import sys
import tarfile

HERE = os.path.dirname(os.path.abspath(__file__))
ARCHIVE = os.path.join(HERE, "..", "raw-clock-20261010", "run-aa43771", "remote-originals.tar.gz")
ARCHIVE = os.path.normpath(ARCHIVE)
MEMBERS = ["output/P1.csv", "output/P2.csv", "output/P3.csv"]


def percentile(sorted_values, fraction):
    if not sorted_values:
        return float("nan")
    position = fraction * (len(sorted_values) - 1)
    lower = int(position)
    upper = min(lower + 1, len(sorted_values) - 1)
    weight = position - lower
    return sorted_values[lower] * (1.0 - weight) + sorted_values[upper] * weight


def summarise(label, values):
    ordered = sorted(values)
    total = sum(ordered)
    return dict(
        label=label, n=len(ordered),
        mean_ns=total / len(ordered),
        p50_ns=percentile(ordered, 0.50),
        p90_ns=percentile(ordered, 0.90),
        p99_ns=percentile(ordered, 0.99),
        p999_ns=percentile(ordered, 0.999),
        min_ns=ordered[0], max_ns=ordered[-1],
        zero_count=sum(1 for value in ordered if value == 0),
    )


def main():
    if not os.path.isfile(ARCHIVE):
        print("archive missing: %s" % ARCHIVE, file=sys.stderr)
        return 1

    per_member = {}
    pooled_main = []
    with tarfile.open(ARCHIVE, "r:gz") as archive:
        for member in MEMBERS:
            handle = archive.extractfile(member)
            if handle is None:
                print("member missing: %s" % member, file=sys.stderr)
                return 1
            text = io.TextIOWrapper(handle, encoding="utf-8", newline="")
            warmup = []
            main_phase = []
            mismatch = 0
            for row in csv.DictReader(text):
                elapsed = int(row["elapsed_ns"])
                reconstructed = int(row["after_ns"]) - int(row["before_ns"])
                if elapsed != reconstructed:
                    mismatch += 1
                if row["phase"] == "warmup":
                    warmup.append(elapsed)
                else:
                    main_phase.append(elapsed)
            per_member[member] = (summarise("%s warmup" % member, warmup),
                                  summarise("%s main" % member, main_phase),
                                  mismatch)
            pooled_main.extend(main_phase)

    rows = []
    for member in MEMBERS:
        warmup, main_phase, mismatch = per_member[member]
        rows.append(warmup)
        rows.append(main_phase)
        print("%s: elapsed==after-before mismatch rows = %d" % (member, mismatch))
    rows.append(summarise("P1+P2+P3 main pooled", pooled_main))

    print()
    print("| series | n | mean_ns | p50_ns | p90_ns | p99_ns | p99.9_ns | min_ns | max_ns | zeros |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for row in rows:
        print("| %s | %d | %.6f | %.1f | %.1f | %.1f | %.1f | %d | %d | %d |" % (
            row["label"], row["n"], row["mean_ns"], row["p50_ns"], row["p90_ns"],
            row["p99_ns"], row["p999_ns"], row["min_ns"], row["max_ns"], row["zero_count"]))

    print()
    print("archive_sha256_target=%s" % ARCHIVE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
