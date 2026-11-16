#!/usr/bin/env python3
"""把观测者 CSV 与 wrapper 的类别表 join 成 mde_budget.py / Welch 用的两列宽表。

输入：
  smt   观测者 CSV：batch_index,victim_run_id,batch_elapsed_nanoseconds（值=第 3 列，ns）
        类别表：batch_index,class_label
  cache 观测者 CSV：victim_run_id,line_index,reload_tsc（每样本连续 line_count 行，
        值=第 3 列 reload_tsc；样本序号=行序号//line_count）
        类别表：sample_index,class_label
输出：表头 message-zero,message-ones 的两列 CSV，每批/样本一行；两类样本数必须相等。
单位与观测者原值一致（smt=ns，cache=tsc），不改写、不缩放。
"""

import argparse
import csv
import sys


def load_classes(path):
    labels = {}
    with open(path, newline="") as stream:
        reader = csv.reader(stream)
        header = next(reader)
        if len(header) != 2 or header[1] != "class_label":
            raise SystemExit(f"error: bad classes header: {header}")
        for row in reader:
            if len(row) != 2:
                raise SystemExit(f"error: bad classes row: {row}")
            index = int(row[0])
            if index in labels:
                raise SystemExit(f"error: duplicate class index {index}")
            labels[index] = row[1]
    return labels


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--observer-csv", required=True)
    parser.add_argument("--classes-csv", required=True)
    parser.add_argument("--protocol", choices=["smt", "cache"], required=True)
    parser.add_argument("--line-count", type=int, default=2)
    parser.add_argument("--output", required=True)
    arguments = parser.parse_args()

    labels = load_classes(arguments.classes_csv)
    values = {label: [] for label in ("message-zero", "message-ones")}
    with open(arguments.observer_csv, newline="") as stream:
        reader = csv.reader(stream)
        next(reader)
        rows = [row for row in reader if row]

    if arguments.protocol == "smt":
        if len(rows) != len(labels):
            raise SystemExit(
                f"error: row count {len(rows)} != classes count {len(labels)}")
        for row in rows:
            batch_index = int(row[0])
            label = labels.get(batch_index)
            if label is None or label not in values:
                raise SystemExit(f"error: missing label for batch {batch_index}")
            values[label].append(float(row[2]))
    else:
        if len(rows) % arguments.line_count != 0:
            raise SystemExit(f"error: row count {len(rows)} not divisible by line count")
        sample_count = len(rows) // arguments.line_count
        if sample_count != len(labels):
            raise SystemExit(
                f"error: sample count {sample_count} != classes count {len(labels)}")
        for sample_index in range(sample_count):
            label = labels.get(sample_index)
            if label is None or label not in values:
                raise SystemExit(f"error: missing label for sample {sample_index}")
            for line_row in rows[sample_index * arguments.line_count :
                                 (sample_index + 1) * arguments.line_count]:
                values[label].append(float(line_row[2]))

    if len(values["message-zero"]) != len(values["message-ones"]):
        raise SystemExit(
            "error: class imbalance "
            f"{len(values['message-zero'])} vs {len(values['message-ones'])}")
    with open(arguments.output, "w", newline="") as stream:
        stream.write("message-zero,message-ones\n")
        for zero_value, ones_value in zip(values["message-zero"], values["message-ones"]):
            stream.write(f"{zero_value:g},{ones_value:g}\n")
    print(
        f"join ok: {len(values['message-zero'])} pairs per class, "
        f"protocol={arguments.protocol}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
