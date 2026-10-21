#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""匿名替换规则的回归测试（2026-10-21 第 5 轮红队复核新增）。

背景：红队实测发现 `anonymous_text()` 曾用**子串替换**处理仓库目录名——
仓库目录叫 `work` 时，`worker_exit_code` 被改成 `[REPOSITORY_NAME]er_exit_code`；
叫 `clone` 时，「干净 clone 实测」被改坏。**那会直接污染发出去的支撑材料卷**
（评审无法与源日志对齐），也让「包内报告 == 仓库报告」这条门禁在别的目录下必然假红。

本测试固定住三条性质：
1. **普通词不受影响**：常见英文词（clone / work / build …）无论是否恰好与目录名同名，都不被替换；
2. **路径形态被替换**：`<名字>/…`、`/<名字>/…` 这类路径段会被替换成占位符；
3. **身份串照常被替换**：绝对路径、邮箱、主机名等仍按原规则替换。

用法：python3 test_anonymize_text.py
"""

import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("support_build", str(HERE / "build_support.py"))
SUPPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SUPPORT)


def main():
    failures = []

    # 1) 普通词不受影响：把仓库目录名临时换成常见英文词再试
    original = SUPPORT.REPOSITORY
    try:
        for name in ("work", "clone", "build"):
            SUPPORT.REPOSITORY = original.parents[1] / name
            for sample in ("worker_exit_code=0", "干净 clone 实测", "the build system",
                           "r13-network-20261020", "work_done"):
                result = SUPPORT.anonymous_text(sample)
                if result != sample:
                    failures.append("目录名 %s：普通词被改写 %r → %r" % (name, sample, result))
        # 2) 路径形态被替换：用一个**不是现有专属占位符**的目录名验证路径规则
        SUPPORT.REPOSITORY = original.parents[1] / "zebra"
        for sample, expected in (("zebra/x", "[REPOSITORY_NAME]/x"),
                                 ("/home/u/zebra/y", "[ANONYMOUS_HOME]/[REPOSITORY_NAME]/y")):
            result = SUPPORT.anonymous_text(sample)
            if result != expected:
                failures.append("路径形态未按预期替换：%r → %r（期望 %r）" % (sample, result, expected))
        # 仓库本名 cryProject 有专属占位符 [REPO_DIR]（它能把读者引到公开仓库，必须换掉）
        SUPPORT.REPOSITORY = original.parents[1] / "cryProject"
        if "cryProject" in SUPPORT.anonymous_text("路径 cryProject/x"):
            failures.append("仓库本名没有被替换成占位符")
    finally:
        SUPPORT.REPOSITORY = original

    # 3) 身份串照常被替换
    sample = "邮箱 yinhaoran0808@outlook.com；绝对路径 /Users/yin/code；远端 10.144.144.5"
    result = SUPPORT.anonymous_text(sample)
    for forbidden in ("yinhaoran0808@outlook.com", "/Users/yin", "10.144.144.5"):
        if forbidden in result:
            failures.append("身份串没有被替换：%s（结果 %r）" % (forbidden, result))

    if failures:
        print("不通过：")
        for item in failures:
            print("  - " + item)
        return 1
    print("通过：匿名替换不会改写普通词，路径形态与身份串按规则替换。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
