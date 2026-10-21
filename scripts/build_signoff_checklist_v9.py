#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""更新《人工复核签字清单》：改表头口径，并补入本轮机器可核项的实际结果。

口径：
  * A–E 各表的**检查点、证据路径与人工判定栏一律不动**（签字栏保持空白，由复核人本人填写）；
  * 只改表头的版本口径（行数、命令数、路径数），并追加一节「机器可核结果」，
    内容全部来自 scripts/check_signoff_items.py 的实跑输出（JSON 落盘在同目录）；
  * 需要人眼判断的部分（逐处看上下文、措辞是否得当）只给检索定位，结论仍留空。
"""

import json
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
CHECKLIST = REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md"
RESULTS = REPOSITORY / "docs/evidence/closeout-20261016/signoff-machine-checks-20261020.json"

OLD_HEADER = """> 机器可核对的项已由审计脚本覆盖（见 `FINAL_AUDIT.md` / `FINAL_AUDIT.csv`：
> 76 行 × 8 列（第 6 版）、证据路径 0 缺失、73 条 `verify_command` 全部返回 0）。
> 本清单只列**机器不容易判、或必须人为担责**的部分。"""

NEW_HEADER = """> 机器可核对的项已由审计脚本覆盖（见 `FINAL_AUDIT.md` / `FINAL_AUDIT.csv`：
> **84 行 × 8 列（第 9 版）**、证据路径 **269 条 0 缺失**、**81 条 `verify_command` 全部返回 0**；
> 实跑明细见 `docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json`）。
> 本清单只列**机器不容易判、或必须人为担责**的部分。
>
> **2026-10-20 更新：** ①表头口径推进到第 9 版；②末尾新增「机器可核项的复核结果」一节，
> 记录 `scripts/check_signoff_items.py` 的实跑结果（32 项全部通过，明细见
> `docs/evidence/closeout-20261016/signoff-machine-checks-20261020.json`）；
> ③**F1 已闭合**（B3/E3 一行的说明已更新）；④各表的**人工判定栏与签字栏一律留空**，
> 由复核人本人核对后填写——机器结果不能替代人的担责。"""

OLD_E3 = "| E3 | 未通过日志/异常/返回码输出秘密或验证结果 | 复核 T18 的静态扫描与动态 diff；注意已登记的低危项 F1 是否已按建议处理 | `docs/evidence/r06-noleak-20261016/AUDIT.md` | | |"
NEW_E3 = "| E3 | 未通过日志/异常/返回码输出秘密或验证结果 | 复核 T18 的静态扫描与动态 diff；**F1 已于 2026-10-20 闭合**（static-scan 的 B 类由 1 条降为 0 条），闭合记录见 fix 目录，仍须人工确认未覆盖面 | `docs/evidence/r06-noleak-20261016/AUDIT.md`、`docs/evidence/r06-noleak-fix-20261020/AUDIT.md` | | |"

RESULTS_SECTION = """
---

## 机器可核项的复核结果（2026-10-20，第 9 版复核自动生成）

下表由 `python3 scripts/check_signoff_items.py` 实跑生成，逐条命令与原始输出见
[`signoff-machine-checks-20261020.json`](signoff-machine-checks-20261020.json)。
**这些结果只是「机器能判的那一面」**：A1 的逐处措辞、A2 的限定范围是否说全、
C1 的数字抽查是否覆盖到本作品的关键结论，仍需复核人本人看过后签字。

| 清单项 | 机器可核的内容 | 结果 |
|---|---|---|
"""

ITEM_MAP = [
    ("A1", "报告全文检索「恒时」（36 处命中）且无肯定式恒时主张"),
    ("A2", "M5 与 R03 的阴性结论都写明限定（不构成恒时证明、不给总体误报率）"),
    ("A3", "M2/M3 的 RESULT 都区分定位层与端到端层"),
    ("A4", "「人工构造校准」在 R05 与 M3/M4 的 RESULT 中均有标注"),
    ("A5", "族外对照文件（RTLF / R12 / R09）都出现「族外」"),
    ("A6", "M4 家族合并 Δ 3.74 在报告全部载体中 0 命中；分臂值 4.089 / 0.055 在位"),
    ("A7", "锁频价值未写成「必然降低方差」，写的是确定性"),
    ("A8", "R05 用「不适用 / 未检查」，报告用「未执行」，两套口径不混用"),
    ("B1", "匿名包 `direct_identity_markers = 0`（final10-20261020）"),
    ("B2", "包内抽样 10 个文件，真名 / 邮箱 / 主机名 / 私有路径 0 命中"),
    ("B3", "报告 PDF 元数据：无作者、私有标记 0、无 JavaScript"),
    ("B4", "仓库内无私钥块头、无 `SUDO_PW=` / `password=` 之类口令串"),
    ("C1", "抽查 7 处关键数字（54/54、36/36、26.16、42/42、存在 5、不存在 75、quick 档四个计数）逐字一致"),
    ("C2", "图目录在位且图数与报告引用相符（R04 45 张）"),
    ("C3", "官方 PDF 目录条目页码全部落在实测页数范围内"),
    ("C4", "性能表写明基频 4300000 kHz 与 ns/周期换算口径"),
    ("C5", "MDE 表写明 α 与功效口径"),
    ("C6", "「量化尺度约 10 ns」在证据与报告里都在"),
    ("D1", "冻结 PLAN 的 sha256 与 BASELINE 记录一致"),
    ("D2", "锁频运行 `restore_match=yes` 命中，反面命中为 0"),
    ("D3", "失败运行归档目录（R08 18 个、R09 1 个）在位"),
    ("D4", "PLAN 的提交时间早于对应原始数据"),
    ("D5", "干净 clone 的 quick 档日志在案；本轮另在仓库本体实跑 263/263"),
    ("D6", "匿名 ZIP 解出后 CTest 5/5 通过"),
    ("E1", "本平台自有交付与证据里，密钥恢复 / exploit 的表述都在否定语境"),
    ("E2", "R06 的计时窗口 I/O 检查结论在案"),
    ("E3", "F1 已闭合：B 类 1 → 0，且闭合记录在案"),
    ("E4", "报告写明「其它架构未做」「不做第二架构」"),
    ("E5", "`sources/` 与 `vendor/` 相对基线与工作区均无改动"),
]


def main():
    results = json.loads(RESULTS.read_text(encoding="utf-8"))
    by_id = {}
    for item in results["results"]:
        by_id.setdefault(item["id"], []).append(item)

    lines = [RESULTS_SECTION]
    for prefix, description in ITEM_MAP:
        matched = [item for item in results["results"] if item["id"].startswith(prefix)]
        status = "通过" if matched and all(item["result"] == "pass" for item in matched) else "未通过"
        detail = "；".join("%s：%s" % (item["id"], item["output_head"].strip().splitlines()[-1][:90])
                           for item in matched if item["output_head"].strip())
        lines.append("| %s · 机器可核 | %s | %s%s |\n" % (prefix, description, status,
                                                ("（%s）" % detail) if detail else ""))
    lines.append("""> **机器可核项合计 %d 条，通过 %d 条、未通过 %d 条。**
> 复跑命令：`python3 scripts/check_signoff_items.py`。
> **这些自动结果不替代人工判定**：A1 的逐处措辞、C1 的抽查覆盖面、D2/D3 的运行计数是否被
> 复核人认可，仍以本清单上方的签字为准。
""" % (results["items"], results["pass"], results["fail"]))

    text = CHECKLIST.read_text(encoding="utf-8")
    for old, new in ((OLD_HEADER, NEW_HEADER), (OLD_E3, NEW_E3)):
        if text.count(old) != 1:
            raise SystemExit("待替换段落命中异常：" + old[:40])
        text = text.replace(old, new)
    marker = "\n---\n\n## 签字"
    if text.count(marker) != 1:
        raise SystemExit("签字节插入点命中异常")
    text = text.replace(marker, "".join(lines) + marker)
    CHECKLIST.write_text(text, encoding="utf-8")
    print("SIGNOFF_CHECKLIST.md 已更新：机器可核项 %d 条，通过 %d 条" % (results["items"], results["pass"]))


if __name__ == "__main__":
    main()
