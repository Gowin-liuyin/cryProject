#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""给 FINAL_AUDIT.md（第 9 版）补上 §3.11 的 P2 收尾行与 §7.6 的版本差异对照。

口径：只追加两节，不改前文；插入位置唯一命中，否则脚本退出。
"""

from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
TARGET = REPOSITORY / "docs/evidence/platform-completion-20261016/FINAL_AUDIT.md"

SECTION_3_11 = """### 3.11 本轮 P2 收尾行（8 行，全部「已满足」；行内写明的边界不因"已满足"而升级）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 说明 / 剩余缺口（本审计实测） | 核对命令（已实跑返回 0） |
|---|---|---|---|---|---|---|
| P2-01 | P2 收尾 | R06 低危发现 F1 的闭合验证记录 | `docs/evidence/r06-noleak-fix-20261020/AUDIT.md`、`docs/evidence/r06-noleak-20261016/AUDIT.md` | 已满足 | **唯一的低危技术缺口 F1 彻底清零**：M2 采集件新增 `--self-test` 显式功能门模式，功能门检查仅在显式传入时生效，计时模式 stderr 恒空、退出码只反映参数/IO/内存错误；重跑 dynamic-diff 7 模式 × 120 次全部 rc=0、stdout/stderr 逐字节一致、diff 差异块 0；static-scan 的 **B 类由 1 条降为 0 条**。**边界**：未覆盖面（上游快照、网络路径、进程级可观察面等）仍如实列出，**不构成恒时证明、不主张零泄露** | `grep -q '原 F1 的 1 条已消除' …/r06-noleak-fix-20261020/AUDIT.md` 等 |
| P2-02 | P2 收尾 | quick 档 Holm 演练的缺陷复现、修复与重跑 | `docs/evidence/screenshots-20261020/{reproduce-quick-terminal.log,reproduce-quick-terminal-p2b.log}`、`scripts/reproduce_all.sh` | 已满足 | **先复现再修复**：修复前实跑日志显示五个家族的 Holm 演练全部 `No such file or directory`（在子目录里用相对路径调用 `platform_holm`），而脚本仍以退出码 0 结束，失败被吞掉。修法三处：工作目录取绝对路径、Holm 失败按失败返回、演练失败不再记成跑通。修复后重跑：五个家族演练真实执行并打印 `holm.csv`/`pooled.csv`，CTest **263/263 通过、0 失败**，退出码 0。**边界**：演练不锁频、不绑核、每臂只 1 次运行，**不是任何模块的正式统计结论** | `test "$(grep -c 'platform_holm --input' …-p2b.log)" -eq 5 && ! grep -q 'platform_holm 运行失败' …-p2b.log` |
| P2-03 | P2 收尾 | 真实运行截图与人工签收佐证（4 张图 + 说明 + 摘要清单） | `deliverables/research/multi-leakage-platform-20261016/screenshots/{SCREENSHOTS.md,SHA256SUMS,01…04.png}` | 已满足 | ①quick 档实跑（**本轮实时采集**，含 263/263 汇总）；②Memcheck 秘密标记命中（**归档的真实 Linux 运行输出**，命中 `poly_frommsg` 并给出 `compress.c`→`indcpa.c`→`kem.c` 调用栈）；③锁频控制器逐条状态（**归档的真实 Linux 运行输出**，`restore_match=yes` / `config_changed=no`）；④离线展示页的真实浏览器渲染（本轮实时采集）。图上路径与主机名按匿名包同一套身份替换规则改写，其余逐字未改。**边界**：图是佐证，不替代原始日志与证据文件；若赛事方要求现场屏幕照片，仍须人工重跑替换 | `test -f …/screenshots/SCREENSHOTS.md` 等 + `shasum -a 256 -c SHA256SUMS` |
| P2-04 | P2 收尾 | 官方报告 PDF 的中文字形渲染修复与门禁 | `scripts/{libreoffice-fonts.conf,check_pdf_render.py,build_official_report.sh,build_official_approval.py}` | 已满足 | **本轮发现的提交级缺陷**：本机 LibreOffice 26.8.1.1 找不到 macOS 中文系统字体，导出的《作品设计报告》PDF 里**汉字整段不显示**（文本层仍在，纯文本检查抓不到）。修法：导出前显式给出系统字体目录，导出后检查「是否内嵌中文字体」与「前几页渲染是否几乎全白」，任一不满足即构建失败。修复后官方 PDF **101 页**且中文字形正常；平台报告（96 页）、队友说明（21 页）、审批签字页（2 页）四份 PDF 全部通过同一门禁 | `python3 scripts/check_pdf_render.py <四份 PDF> \\| grep -q '通过'` |
| P2-05 | P2 收尾 | 附件三《审批及签字页》待签字版 | `CACR2026EA16XZ-审批及签字页.{docx,pdf}`、`scripts/build_official_approval.py` | 已满足（**系统可确定的字段已填；签字与盖章仍待本人完成**） | 作品编号填 **CACR2026EA16XZ**、作品题目填最终题名；队伍成员姓名/院系/专业/任务分工/签字、指导教师意见与院系盖章**一律留空**，脚本不得代填。**边界**：本行只表示「待签字版已生成」，**不表示人工签字、盖章与官方上传已完成** | `python3 -c "…assert '作品编号：CACR2026EA16XZ' in t and '[待填写]' in t and '盖章' in t"` |
| P2-06 | P2 收尾 | 报告口径回填（题面 12 条 12/12 与过期口径清理） | `deliverables/research/multi-leakage-platform-20261016/{report.md,report.tex,report-data.json}` | 已满足 | 摘要与附录 A 统一为 **12 条全部满足（12/12）**；正文里「11 满足 + 1 部分」「本轮 final5 只重出报告」「复算产物是 final4」「另有低危发现 F1」等**过期口径**按实况改写；`document_state` 更新为 P2 收尾版；来源集由 65 份增至 **66 份**（新增 E66 截图佐证）；离线 HTML 的 markdown 粗体标记不再显示成裸星号。**边界**：报告正文**不回填**匿名包自身的成员数与摘要（包内随附的就是报告本身，回填会自指） | `grep -q '12 条全部满足（12/12）' …/report.md && ! grep -q '第 6 条为部分' …/report.md` |
| P2-07 | P2 收尾 | final10-20261020 匿名包的成包、审计与解出复算记录 | `deliverables/support/…/final10-20261020-verification.json`、`docs/evidence/platform-report-20261016/final10-20261020/*`、`…/refresh-20261016/zip-recompute-final10.log` | 已满足 | 包审计 `status=pass`、**直接身份标记 0**、860 成员、859 摘要、195 个本地 HTML 链接；PDF 元数据审计：无作者、私有标记 0、无 JavaScript、96 页；离线回放：6 份数据集、12 个 C 输出逐字一致、输入原始字节未变；解出复算 **CTest 5/5 通过、0 失败**（2.70 s）。**边界**：本轮未做新硬件采集，外部统计工具未重跑 | `grep -q '"direct_identity_markers": 0' …/package-verification.json` 等 |
| P2-08 | P2 收尾 | 第 9 版核对命令的全量实跑明细 | `docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json`、`scripts/run_final_audit_checks.py` | 已满足 | CSV **84 行**：可执行核对命令 **81 条**全部返回 0，占位（可选未做）3 条；证据路径 **269 条、0 缺失**。核对命令由脚本按 CSV 逐条执行，退出码、耗时与输出前 4 KB 全部落盘，可复跑。**边界**：脚本只报告实际退出码、不改判，判定由本审计正文负责 | `test -f …/final-audit-checks-20261020.json && python3 -c "…assert d['rows']==84 and d['executable_commands']==81"` |

> **本组共同边界：** P2-01 的闭合**只针对**「防护过程不通过日志/异常/返回码泄露」，不是恒时证明；
> P2-02 的演练数值**不是**正式统计结论，quick 档仍是**缺件跳过后的最小集**；
> P2-03 的截图是**佐证**，现场屏幕照片仍须人工补；P2-04 只保证**字形渲染**，不改变报告内容；
> P2-05 只生成待签字版，**签字、盖章与官方上传未完成**；P2-06 的 12/12 **不等于**竞赛验收；
> P2-07 的包内 ctest 是 5 个测试的子集；P2-08 的脚本只报告退出码。

"""

SECTION_7_6 = """### 7.6 第 8 版（`d2ad9c9` 快照）→ 第 9 版（被审对象提交 `95a7b531`，本版）

| 项 | 第 8 版（`d2ad9c9`，2026-10-16） | 第 9 版（本版，2026-10-20） | 触发证据 |
|---|---|---|---|
| 时点声明 | 快照 `d2ad9c9`，全部已提交 | 被审对象提交 **`95a7b531`**；其后并行的 T25 网络线三个提交只改 `tools/platform_network/`，不触及被审对象 | `git rev-parse`；`git show --stat` |
| 未闭不一致 | **0**（8 行已闭、0 行未闭） | **0**（保持；并新增 8 行 P2 收尾行，全部已满足） | §2.1、§4 |
| 低危技术缺口 | **F1 未闭**（T18 行） | **F1 已闭**（P2-01 行；static-scan B 类 1 → 0） | `docs/evidence/r06-noleak-fix-20261020/AUDIT.md` §7 |
| 题面第 6 条 | 报告记「部分」 | **改判「满足」**，题面 12 条 **12/12 全满足** | 报告附录 A 表 T26 第 6 行；`generate_report.py` 摘要 |
| CSV 规模 | 76 数据行 × 8 列（65/0/0/0/3/8/0） | **84 数据行 × 8 列（73/0/0/0/3/8/0）** | `FINAL_AUDIT.csv` |
| 命令实跑 | 73 条全部 0（3 条 `—`） | **81 条全部 0**（3 条 `—`）；证据路径 **269 条、0 缺失**；明细落盘 | `scripts/run_final_audit_checks.py` |
| 报告 | final5：91 页、PDF `d391114c…`、题面 11+1 | **96 页、PDF `325cd6d0…`**、题面 **12/12**；来源 65 → **66** 份 | 两遍 XeLaTeX（0 警告）、`pdf-metadata-audit.json` |
| 官方作品设计报告 | 74 页 PDF（**汉字整段不显示**，LibreOffice 找不到中文字体） | **101 页 PDF、中文字形正常**；新增渲染门禁 | `scripts/check_pdf_render.py`；`scripts/libreoffice-fonts.conf` |
| 匿名包 | final9-20261020：852 成员、`d73217a5…` | **final10-20261020：860 成员、`aac17a48…`**、`direct_identity_markers=0`、包内 ctest 5/5（2.70 s） | 自跑 `verify_package.py`；`zip-recompute-final10.log` |
| 一键复现 quick 档 | 194/194（缺件跳过的最小集） | **263/263**；**本轮修掉 Holm 演练未真跑且失败被吞掉的缺陷** | `reproduce-quick-terminal{,-p2b}.log` |
| 人工签收材料 | 仅签字清单 | 新增 **4 张真实运行截图 + 逐张说明**、**附件三待签字版**（编号与题目已填，签字盖章留空） | `screenshots/SCREENSHOTS.md`；`CACR2026EA16XZ-审批及签字页.pdf` |

**计数变化（第 8 版 → 第 9 版）：** 口径 A（41）**38/0/0/0/3 不变**；口径 B（32）**29/0/0/0/3 不变**；
A′（43 行）**40/0/0/0/3 不变**；B′（34 项）**31/0/0/0/3 不变**；A″（66 行）**63/0/0/0/3 不变**、
B″（57 项）**54/0/0/0/3 不变**（P2 收尾行按第 1–8 版的同一口径单列，不并入口径 A/B/A′/B′/A″/B″）；
CSV 合计（76 → **84 行**）**65 → 73 已满足 / 3 可选未做 / 8 已闭不一致 / 0 未闭不一致**。
**本次复核未改动原文 41 行中任何一行的判定**；改动只发生在**收尾行与 P2 新增行**，
且每一处都对应本轮可复跑的实测（命令、摘要、页数、成员数、日志）。

"""

MARKER_3_11 = "---\n\n## 4. 矛盾清单"
MARKER_7_6 = "---\n\n*本文件由只读审计路 S11 生成"


def _refuse_to_write():
    """本脚本已被 scripts/build_final_audit_v91.py（第 9.1 版）取代。

    FINAL_AUDIT.md 与 FINAL_AUDIT.csv 是同一份审计的两半，却由两个互不相干的
    生成器产出（一个只写 .md、一个只写 .csv），谁先跑都不会让另一方同步——
    2026-10-21 复查时两者已就「当前有效包、成员数、页数、解出复算日志」给出
    两套说法。v91 是唯一生成源；本脚本不再写 FINAL_AUDIT.md。
    """
    raise SystemExit(
        "本脚本已被 build_final_audit_v91.py 取代，不再写 FINAL_AUDIT.md；"
        "请运行 python3 scripts/build_final_audit_v91.py"
    )


def main():
    _refuse_to_write()
    text = TARGET.read_text(encoding="utf-8")
    if text.count(MARKER_3_11) != 1:
        raise SystemExit("§3.11 插入点命中异常")
    text = text.replace(MARKER_3_11, SECTION_3_11 + MARKER_3_11)
    if text.count(MARKER_7_6) != 1:
        raise SystemExit("§7.6 插入点命中异常")
    text = text.replace(MARKER_7_6, SECTION_7_6 + MARKER_7_6)
    TARGET.write_text(text, encoding="utf-8")
    print("FINAL_AUDIT.md 已补入 §3.11 与 §7.6")


if __name__ == "__main__":
    main()
