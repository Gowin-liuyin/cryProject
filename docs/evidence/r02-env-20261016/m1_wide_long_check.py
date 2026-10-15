#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T09 输入去重核对：M1 的宽表导出与长表原件是否为同一批样本。

`docs/evidence/tooling-strengthen-20261015/csv/{vulnerable,fixed}-message-zero-ones.csv`
是成对宽表（两列）；`docs/evidence/liboqs010-locked-20261015/runs/{vulnerable,fixed}/samples.csv`
是长表（含 5 个类）。若两者同一批样本，本文只取长表一次，避免在 T09 里重复计数。

用法：python3 docs/evidence/r02-env-20261016/m1_wide_long_check.py
"""

from __future__ import annotations

import csv
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))


def load_wide(path):
    with open(path, newline="") as handle:
        reader = csv.reader(handle)
        header = next(reader)
        first = []
        second = []
        for row in reader:
            first.append(int(row[0]))
            second.append(int(row[1]))
    return header, first, second


def load_long(path, category):
    values = []
    with open(path, newline="") as handle:
        for row in csv.DictReader(handle):
            if row["input_category"] == category:
                values.append(int(row["elapsed_nanoseconds"]))
    return values


def main():
    ok = True
    for arm in ("vulnerable", "fixed"):
        wide = os.path.join(REPO, "docs/evidence/tooling-strengthen-20261015/csv",
                            "%s-message-zero-ones.csv" % arm)
        long_path = os.path.join(REPO, "docs/evidence/liboqs010-locked-20261015/runs",
                                 arm, "samples.csv")
        header, wide_zero, wide_ones = load_wide(wide)
        long_zero = load_long(long_path, "message-zero")
        long_ones = load_long(long_path, "message-ones")
        same_zero = sorted(wide_zero) == sorted(long_zero)
        same_ones = sorted(wide_ones) == sorted(long_ones)
        same_order_zero = wide_zero == long_zero
        same_order_ones = wide_ones == long_ones
        print("arm=%s header=%s" % (arm, header))
        print("  n wide=%d/%d long=%d/%d" % (len(wide_zero), len(wide_ones),
                                             len(long_zero), len(long_ones)))
        print("  message-zero multiset equal: %s   (row order equal: %s)" % (same_zero, same_order_zero))
        print("  message-ones  multiset equal: %s   (row order equal: %s)" % (same_ones, same_order_ones))
        ok = ok and same_zero and same_ones
    print()
    print("CONCLUSION same_sample_set=%s" % ("yes" if ok else "no"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
