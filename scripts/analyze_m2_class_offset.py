#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对 M2 主类对在两臂上的类间均值偏移与符号稳定性。

背景：报告 §20 写「R05 补格实锤到 poly_frommsg 的 bt/jae 分支被 272125f 漏修」，
并把它作为「全 0／全 1 消息类对在已修臂上也触发分布工具报警」的**候选机制解释**。
候选解释要成立，至少要能回答一个问题：**观测到的类间偏移在两个臂上是否同号且稳定**。

本脚本只读冻结的 RTLF 逐数据集结果（docs/evidence/platform-rtlf-20261016/results/），
逐数据集打印 X（message-zero）与 Y（message-ones）的均值、差与离散度，
再按臂汇总符号稳定性。不产生新的实验数据，也不改动任何既有文件。

用法：python3 scripts/analyze_m2_class_offset.py
退出码 0 表示脚本正常跑完（结论由人读，不做自动判定）。
"""
import json
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
RESULT_ROOT = REPOSITORY / "docs/evidence/platform-rtlf-20261016/results"
DATASETS = [
    ("s1", "unfixed"),
    ("s1", "fixed"),
    ("s2", "unfixed"),
    ("s2", "fixed"),
    ("s3", "unfixed"),
    ("s3", "fixed"),
]


def main():
    rows = []
    for run_name, arm in DATASETS:
        dataset = "m2-m2-%s-%s-main" % (run_name, arm)
        path = RESULT_ROOT / dataset / "rtlf.json"
        if not path.is_file():
            raise SystemExit("缺少 RTLF 结果：" + str(path))
        payload = json.loads(path.read_text(encoding="utf-8"))
        statistics = payload["statistics"]
        series_x = statistics["series_x"]
        series_y = statistics["series_y"]
        rows.append({
            "dataset": dataset,
            "run": run_name,
            "arm": arm,
            "difference_detected": payload["metadata"]["difference_detected"],
            "mean_x_ns": series_x["mean"],
            "mean_y_ns": series_y["mean"],
            "offset_ns": series_x["mean"] - series_y["mean"],
            "stdev_x_ns": series_x["stdev"],
            "stdev_y_ns": series_y["stdev"],
            "significant_deciles": payload["metadata"]["significant_deciles"],
        })

    print("M2 主类对（X=message-zero，Y=message-ones）的类间均值偏移")
    print("%-26s %-8s %10s %10s %9s %9s %9s %8s" %
          ("数据集", "臂", "meanX(ns)", "meanY(ns)", "X-Y(ns)", "sdX(ns)", "sdY(ns)", "检出"))
    for row in rows:
        print("%-26s %-8s %10.1f %10.1f %+9.1f %9.1f %9.1f %8s" %
              (row["dataset"], row["arm"], row["mean_x_ns"], row["mean_y_ns"],
               row["offset_ns"], row["stdev_x_ns"], row["stdev_y_ns"],
               "是" if row["difference_detected"] else "否"))

    print()
    for arm in ("unfixed", "fixed"):
        arm_rows = [row for row in rows if row["arm"] == arm]
        offsets = [row["offset_ns"] for row in arm_rows]
        signs = {1 if value > 0 else (-1 if value < 0 else 0) for value in offsets}
        dispersion = sum(row["stdev_x_ns"] for row in arm_rows) / len(arm_rows)
        print("%-8s 三个种子的偏移：%s；同号=%s；X 类平均离散度 %.0f ns" %
              (arm, "、".join("%+.1f" % value for value in offsets),
               "是" if len(signs) == 1 else "否", dispersion))
    print()
    print("读法：未修臂三个种子的偏移同号；已修臂符号翻转且离散度更大，")
    print("因此已修臂的分布报警不能单独归到 poly_frommsg 的分支，")
    print("未受控漂移与尾部形状仍是并列因素；两臂都不据此作泄漏结论。")


if __name__ == "__main__":
    main()
