#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对 R05 流程图的**判定**与 `docs/R05-全流程排查表.md` §5 的 mermaid 源一致。

背景（2026-10-21 第 10 轮独立复核）：报告与匿名包里随包分发的
`r05-flowchart.png` 是由 `deliverables/research/multi-leakage-platform-20261016/
r05_flowchart.py` 渲染的，而渲染器里的节点 `class` 是**手写**的、与 R05 §5 的
mermaid 源没有强制关联。结果两处判定被画反了：

* `M1E2`（cmov 无值屏障）在图里是**红框＝「存在」**，而源里是 `:::pub`（无该类来源）；
* `M2C4`（M2 的 poly_frommsg）在图里是**黄虚框＝「未检查」**，而源里是 `:::leak`
  （已由反汇编判定为存在）。

**图的颜色承载的是判定**，与源说反就等于把「已检出的阳性」画成没有、把「已判定
存在」画成没查。本门禁逐节点比对渲染器的 `class` 与源里的 `:::`，不等即失败。

用法：python3 scripts/check_r05_flowchart_parity.py
退出码 0 表示逐节点一致。
"""
import importlib.util
import re
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SOURCE = REPOSITORY / "docs/R05-全流程排查表.md"
RENDERER = (REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"
            / "r05_flowchart.py")
# mermaid 节点标签有两种写法：`["…"]` 与 `{"…"}`，两种都要认
CLASS_PATTERN = re.compile(
    r"\b(M[0-9][A-Z]?[0-9]?[A-Z]?)[\[{][^\]}]*[\]}]\s*:::(pub|leak|fix|art)\b")


def source_classes():
    """从 R05 §5 的 mermaid 源码里取每个节点的 `:::` 判定。"""
    text = SOURCE.read_text(encoding="utf-8")
    classes = {}
    for match in CLASS_PATTERN.finditer(text):
        node_id, class_name = match.group(1), match.group(2)
        if node_id in classes and classes[node_id] != class_name:
            raise SystemExit("R05 §5 里同一个节点出现两种判定：" + node_id)
        classes[node_id] = class_name
    return classes


def renderer_classes():
    """取渲染器里每个节点的 class。"""
    spec = importlib.util.spec_from_file_location("r05_flowchart", str(RENDERER))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    classes = {}
    for column in module.FLOW["columns"]:
        for node in column["nodes"]:
            classes[node["id"]] = node["class"]
    return classes


def main():
    source = source_classes()
    rendered = renderer_classes()
    if not source:
        raise SystemExit("没从 R05 §5 解析出任何节点判定")
    missing = sorted(set(source) - set(rendered))
    extra = sorted(set(rendered) - set(source))
    mismatched = sorted(node for node in set(source) & set(rendered)
                        if source[node] != rendered[node])
    if missing or extra or mismatched:
        for node in mismatched:
            print("判定不一致：%s 源=%s 图=%s" % (node, source[node], rendered[node]))
        for node in missing:
            print("源里有、渲染器没有：%s（源=%s）" % (node, source[node]))
        for node in extra:
            print("渲染器有、源里没有：%s（图=%s）" % (node, rendered[node]))
        raise SystemExit("流程图与 R05 §5 的 mermaid 源不一致")
    print("通过：%d 个节点的判定与 R05 §5 的 mermaid 源逐条一致" % len(source))
    return 0


if __name__ == "__main__":
    sys.exit(main())
