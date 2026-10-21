#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""由第 8 版 FINAL_AUDIT.csv 生成第 9 版：更新受本轮改动影响的行，并追加 P2 收尾行。

口径：
  * 第 8 版原字节另存为 FINAL_AUDIT-d2ad9c9.csv / .md，不覆盖。
  * 只改**因本轮改动而失效或需要更新的行**（报告页数与摘要、包 revision、F1 闭合状态、
    quick 档口径），判定不因措辞偏好而改变。
  * 新增行只登记本轮真实交付物与实测结果，不新增任何未经核对的结论。
"""

import csv
import shutil
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
DIRECTORY = REPOSITORY / "docs/evidence/platform-completion-20261016"
SOURCE_CSV = DIRECTORY / "FINAL_AUDIT.csv"
SNAPSHOT_CSV = DIRECTORY / "FINAL_AUDIT-d2ad9c9.csv"
SNAPSHOT_MD = DIRECTORY / "FINAL_AUDIT-d2ad9c9.md"

REPORT_PDF_SHA256 = "ccce6183a9ba169013c7f6ee2fab81e1d5c283e41ee009e178968cc63e4d840f"
PACKAGE_SHA256 = "9516c600d721c8308c2ec3484983f22c7b0c791fec553cc975aff36016a395e4"

UPDATES = {
    "T18": {
        "status": "已满足（**F1 已于 2026-10-20 闭合**：static-scan B 类由 1 降为 0）",
        "gap": "秘密内容泄露 0 条；动态 diff 为空（7 模式 × 120 次、退出码唯一值 0、逐字节一致）；"
               "Memcheck syscall 0（含 canary 负对照）；计时窗口 7/7 无 I/O。"
               "**F1 已闭**：`tools/platform_m2/collector.c` 新增 `--self-test` 显式功能门模式，"
               "功能门检查仅在显式传入时生效，计时模式 stderr 恒空、退出码只反映参数/IO/内存错误；"
               "重跑后 dynamic-diff 7 模式 × 120 次全部 rc=0 且逐字节一致，static-scan B 类 **1 → 0**。"
               "未覆盖面（上游快照、网络、进程名、fd、maps、core dump、wait4、信号、/proc stat、"
               "子进程树、文件名与 mtime）仍如实列出",
        "verify_command": "grep -q 'F1' docs/evidence/r06-noleak-20261016/AUDIT.md && "
                          "grep -q '未覆盖面' docs/evidence/r06-noleak-20261016/AUDIT.md && "
                          "grep -q '原 F1 的 1 条已消除' docs/evidence/r06-noleak-fix-20261020/AUDIT.md && "
                          "grep -qE 'B 类泄露.*0 条' docs/evidence/r06-noleak-fix-20261020/AUDIT.md",
    },
    "T30": {
        "status": "已满足（**本轮修复 Holm 演练未真跑的问题**：CTest 263/263，五个家族演练真实执行）",
        "gap": "本机实跑 `quick --samples 200 --runs 1`：CTest **263/263**（platform 88 + ordinary 57 + "
               "sanitize 57 + historical-fixed 61），M1–M5 五个家族的 Holm 演练真实执行并打印 "
               "holm.csv 与 pooled.csv，退出码 0。"
               "**本轮发现并修复的缺陷**：旧版在子目录里用相对路径调用 platform_holm，cd 之后路径失效，"
               "演练其实没跑成且失败被吞掉、退出码仍为 0；现已改为绝对路径 + 演练失败按失败返回。"
               "**边界**：quick 档不需 sudo、不写 sysfs、不绑核，演练数值不是任何模块的正式统计结论",
        "verify_command": "grep -c 'tests passed, 0 tests failed out of 263' "
                          "docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log >/dev/null; "
                          "test \"$(grep -c 'platform_holm --input' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 5 && "
                          "grep -q 'quick 档完成。' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log && "
                          "! grep -q 'platform_holm 运行失败' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log",
    },
    "T31": {
        "status": "已满足（**题面 12 条 12/12 全满足**，报告 96 页、两遍 XeLaTeX 0 警告）",
        "gap": "**三路互证 96 页**（PDF 对象流 `/Type /Page` = 96、两遍日志 `(96 pages)`、逐页 PNG 96 张）；"
               "两遍警告全 0；PDF sha256 与本审计登记值一致。"
               "**第 6 条已由「部分」改为「满足」**：R06 的 F1 缺口于 2026-10-20 闭合；"
               "题面 12 条为 12 满足 + 0 部分 + 0 未执行。"
               "本轮同时清掉正文里的过期口径（「11 满足 + 1 部分」「本轮只重出报告」「复算产物是 final4」）",
        "verify_command": "test \"$(shasum -a 256 deliverables/research/multi-leakage-platform-20261016/report.pdf | cut -c1-64)\" = " + REPORT_PDF_SHA256 + " && "
                          "test \"$(grep -c 'Output written on .* (96 pages)' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log)\" -eq 1 && "
                          "test \"$(grep -cE 'Overfull|Underfull|Missing character|LaTeX Warning|hyperref Warning' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log)\" -eq 0 && "
                          "test \"$(grep -c 'Output written on .* (96 pages)' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log)\" -eq 1 && "
                          "test \"$(grep -cE 'Overfull|Underfull|Missing character|LaTeX Warning|hyperref Warning' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log)\" -eq 0",
    },
    "T32": {
        "status": "已满足（**final11-20261020**：860 成员、verify pass、`direct_identity_markers=0`、包内 ctest 5/5）",
        "gap": "实测 sha256 `" + PACKAGE_SHA256 + "`、**860 成员**、859 摘要、195 个本地 HTML 链接、"
               "自跑包内 `verify_package.py` → `status=pass` / `direct_identity_markers=0`；"
               "解出后独立目录重建并执行包内 ctest **5/5**（2.70 s）；离线回放 6 份数据集、12 个 C 输出逐字一致。"
               "**边界**：包内 ctest 是 5 个测试，**不是**仓库根全套；verify 只查直接字节/文本标识，"
               "不排除公开内容关联；860 成员是过滤后的可公开子集",
        "verify_command": "test \"$(shasum -a 256 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final11-20261020.zip | cut -d' ' -f1)\" = " + PACKAGE_SHA256 + " && "
                          "python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final11-20261020.zip | grep -q '\"direct_identity_markers\": 0' && "
                          "grep -q '100% tests passed, 0 tests failed out of 5' docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final11.log",
    },
    "T34": {
        "status": "已满足（**清单本身 ≠ 人工复核已完成**；本轮已按第 9 版口径更新表头并留出复核结果栏）",
        "gap": "清单实测 **29 项**（A8+B4+C6+D6+E5），签字表 3 行全空。"
               "**本轮更新**：表头不再写死「76 行 × 8 列（第 6 版）」，改为按审计版本标注；"
               "并新增「本轮机器可核项的复核结果」一节，把 A/B/C/D/E 各组的机器可核部分逐项记录，"
               "人工事项仍留空。清单不构成竞赛方验收",
        "verify_command": "test \"$(grep -cE '^\\| [A-E][0-9]+ \\|' docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md)\" -eq 29 && "
                          "grep -q '复核人' docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md",
    },
    "R-02": {
        "status": "已闭合（`6c10f4d` 改来源 + `e6b35cf` 重跑生成器与两遍 XeLaTeX；第 9 版按新报告重登记摘要）",
        "gap": "`REFRESH.md` §J4 第 4 条写「60 份来源实测 **0 stale**，重出的 PDF 与修正前**逐字节相同**」，原文保留；"
               "**第 9 版复核**：当前来源集为 **66 份**，`evidence-snapshot.json` 逐条记录摘要，"
               "成包前由 `build_support.py` 逐条比对（不一致即拒绝成包）；"
               "本版独立实测 `report.pdf` sha256 = `" + REPORT_PDF_SHA256 + "`，与 "
               "`final11-20261020/pdf-metadata-audit.json` 记录一致",
        "verify_command": "grep -q '0 stale' docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md && "
                          "grep -q '逐字节相同' docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md && "
                          "test \"$(shasum -a 256 deliverables/research/multi-leakage-platform-20261016/report.pdf | cut -d' ' -f1)\" = " + REPORT_PDF_SHA256,
    },
    "R-03": {
        "status": "已闭合（`008c516` 改文本 + `d2ad9c9` 最终重出；第 9 版按 final10 重新登记）",
        "gap": "交接节现写**当前有效包摘要**（第 9 版为 final11-20261020：`" + PACKAGE_SHA256 + "`，860 成员），"
               "并注明此前被取代的成包（final5 `cacf9453…`、final9 `d73217a5…`）分别存于同目录的 "
               "`*-verification.json`；磁盘唯一 final10 包实测与其一致",
        "verify_command": "grep -q '9516c600d721c8308c2ec3484983f22c7b0c791fec553cc975aff36016a395e4' "
                          "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md && "
                          "grep -q '9516c600d721c8308c2ec3484983f22c7b0c791fec553cc975aff36016a395e4' HANDOFF_DONE.md && "
                          "grep -q '104 页' README.md && "
                          "test \"$(shasum -a 256 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final11-20261020.zip | cut -d' ' -f1)\" = " + PACKAGE_SHA256,
    },
    "R-04": {
        "status": "已闭合（工作区已修正；第 9 版按 86 行口径再次更新表头）",
        "gap": "清单表头不再写死旧版行数，改为「按审计版本标注」；本版 CSV 为 **86 行**，"
               "可执行核对命令 **81 条**，本次实跑全部返回 0，证据路径 0 缺失",
        "verify_command": "test \"$(python3 -c \"import csv;print(len(list(csv.DictReader(open('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv')))))\")\" -eq 86 && "
                          "grep -q '机器可核' docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md",
    },
    "D-03": {
        "status": "已闭合（`008c516` 已提交；第 9 版复核未回退）",
        "gap": "**第 9 版复核**：`MAPPING.md` §2 分组为「上游/历史实现 6 行 + **人工构造校准 6 行**"
               "（M3-a/b/c/d 四行 + M4-a/b 两行；原自述写 5 行，主控 2026-10-16 按实际行数更正）"
               "+ 上游既有做法 4 行」= **16**，与表内实际 16 行一致，原 6+5+4=15 的算术不一致解除。"
               "**时点更新**：该修正**已随 `008c516` 提交**，`git show HEAD:docs/evidence/r06-noleak-20261016/MAPPING.md` "
               "实测含「人工构造校准 6 行」，不再是工作区状态。**影响**：仅文件内部表述，"
               "不改变任何数字与判定",
        "verify_command": "grep -q '人工构造校准 6 行' docs/evidence/r06-noleak-20261016/MAPPING.md && "
                          "test \"$(grep -cE '^\\| M[1-5]-[a-d] \\|' docs/evidence/r06-noleak-20261016/MAPPING.md)\" -eq 16 && "
                          "git show HEAD:docs/evidence/r06-noleak-20261016/MAPPING.md | grep -q '人工构造校准 6 行'",
    },
    "D-04": {
        "status": "已闭合（`008c516` 已提交；第 9 版复核未回退）",
        "gap": "**第 9 版复核**：`docs/full-work-progress.md` 的 T34 行为「人工复核签字清单（**29 项**，签字栏留空）」，"
               "与 `SIGNOFF_CHECKLIST.md` 实测 29 项（A8+B4+C6+D6+E5）一致，原 23 项的计数差解除。"
               "**时点更新**：该修正**已随 `008c516` 提交**，`git show HEAD:docs/full-work-progress.md` 实测含「29 项」。"
               "**影响**：清单内容、签字栏与「不构成竞赛方验收」声明不受影响",
        "verify_command": "grep -q '29 项' docs/full-work-progress.md && "
                          "test \"$(grep -cE '^\\| [A-E][0-9]+ \\|' docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md)\" -eq 29 && "
                          "git show HEAD:docs/full-work-progress.md | grep -q '29 项'",
    },
}

NEW_ROWS = [
    {
        "id": "P2-01",
        "type": "本轮收尾（补充）",
        "required_artifact": "R06 低危发现 F1 的闭合验证记录",
        "evidence_path": "docs/evidence/r06-noleak-fix-20261020/AUDIT.md; docs/evidence/r06-noleak-20261016/AUDIT.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**唯一的低危技术缺口 F1 已彻底清零**：M2 采集件新增 `--self-test` 显式功能门模式，"
               "功能门检查仅在显式传入时生效，计时模式 stderr 恒空、退出码只反映参数/IO/内存错误；"
               "重跑 dynamic-diff 7 模式 × 120 次全部 rc=0、stdout/stderr 逐字节一致、diff 差异块 0；"
               "static-scan 的 **B 类（内部验证结果泄露）由 1 条降为 0 条**。"
               "**边界不变**：未覆盖面（上游快照、网络路径、进程级可观察面等）仍如实列出，"
               "本条不构成恒时证明、不主张零泄露",
        "verify_command": "grep -q '原 F1 的 1 条已消除' docs/evidence/r06-noleak-fix-20261020/AUDIT.md && "
                          "grep -qE 'B 类泄露.*0 条' docs/evidence/r06-noleak-fix-20261020/AUDIT.md && "
                          "grep -q 'dynamic-diff' docs/evidence/r06-noleak-fix-20261020/AUDIT.md && "
                          "grep -q 'F1' BLOCKERS.md",
    },
    {
        "id": "P2-02",
        "type": "本轮收尾（补充）",
        "required_artifact": "一键复现 quick 档的 Holm 演练修复与重跑日志",
        "evidence_path": "docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log; docs/evidence/screenshots-20261020/reproduce-quick-terminal.log; scripts/reproduce_all.sh",
        "exists": "yes",
        "status": "已满足",
        "gap": "本轮**先复现再修复**：修复前的实跑日志显示五个家族的 Holm 演练全部因相对路径失效而"
               "`No such file or directory`，而脚本仍以退出码 0 结束（失败被吞掉）。"
               "修复三处：工作目录取绝对路径、Holm 失败按失败返回、演练失败不再记成跑通。"
               "修复后重跑：五个家族演练真实执行，CTest **263/263 通过、0 失败**，退出码 0。"
               "**边界**：演练数值不是任何模块的正式统计结论",
        "verify_command": "grep -q 'No such file or directory' docs/evidence/screenshots-20261020/reproduce-quick-terminal.log && "
                          "grep -c 'platform_holm --input' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log >/dev/null; "
                          "test \"$(grep -c 'platform_holm --input' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 5 && "
                          "! grep -q 'platform_holm 运行失败' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log && "
                          "grep -q 'quick 档完成。' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log",
    },
    {
        "id": "P2-03",
        "type": "本轮收尾（补充）",
        "required_artifact": "真实运行截图与人工签收佐证说明（4 张图 + 说明 + 摘要清单）",
        "evidence_path": "deliverables/research/multi-leakage-platform-20261016/screenshots/SCREENSHOTS.md; deliverables/research/multi-leakage-platform-20261016/screenshots/SHA256SUMS; deliverables/research/multi-leakage-platform-20261016/screenshots/01-reproduce-quick-terminal.png; deliverables/research/multi-leakage-platform-20261016/screenshots/02-valgrind-memcheck-hit.png; deliverables/research/multi-leakage-platform-20261016/screenshots/03-frequency-controller-log.png; deliverables/research/multi-leakage-platform-20261016/screenshots/04-offline-html.png",
        "exists": "yes",
        "status": "已满足",
        "gap": "4 张图：①quick 档实跑（**本轮实时采集**，含 263/263 汇总与五个家族的 Holm 演练输出）；"
               "②Memcheck 秘密标记命中（**归档的真实 Linux 运行输出**，命中 `poly_frommsg`）；"
               "③锁频控制器逐条状态（**归档的真实 Linux 运行输出**，`restore_match=yes` / `config_changed=no`）；"
               "④离线展示页的真实浏览器渲染（本轮实时采集）。"
               "图上路径与主机名按匿名包同一套身份替换规则改写，其余逐字未改；"
               "逐张来源、命令、环境与真实性分类写在 `SCREENSHOTS.md`。"
               "**边界**：图是佐证，不替代原始日志与证据文件；若赛事方要求现场屏幕照片，仍须人工重跑替换",
        "verify_command": "test -f deliverables/research/multi-leakage-platform-20261016/screenshots/SCREENSHOTS.md && "
                          "test -f deliverables/research/multi-leakage-platform-20261016/screenshots/01-reproduce-quick-terminal.png && "
                          "test -f deliverables/research/multi-leakage-platform-20261016/screenshots/02-valgrind-memcheck-hit.png && "
                          "test -f deliverables/research/multi-leakage-platform-20261016/screenshots/03-frequency-controller-log.png && "
                          "test -f deliverables/research/multi-leakage-platform-20261016/screenshots/04-offline-html.png && "
                          "(cd deliverables/research/multi-leakage-platform-20261016/screenshots && shasum -a 256 -c SHA256SUMS)",
    },
    {
        "id": "P2-04",
        "type": "本轮收尾（补充）",
        "required_artifact": "官方报告 PDF 的中文字形渲染修复与门禁",
        "evidence_path": "scripts/libreoffice-fonts.conf; scripts/check_pdf_render.py; scripts/build_official_report.sh; scripts/build_official_approval.py",
        "exists": "yes",
        "status": "已满足",
        "gap": "**本轮发现的提交级缺陷**：本机 LibreOffice 26.8.1.1 找不到 macOS 中文系统字体，"
               "导出的《作品设计报告》PDF 里汉字整段不显示（文本层仍在，纯文本检查抓不到）。"
               "修法：导出前显式给出系统字体目录，导出后用门禁脚本检查「是否内嵌中文字体」与"
               "「前几页渲染是否几乎全白」，任一不满足即构建失败。"
               "修复后官方 PDF **101 页**、中文字形正常；平台报告（96 页）、队友说明（21 页）、"
               "审批签字页（2 页）四份 PDF 全部通过同一门禁。"
               "**同批复查还查出目录页码整体差 1 页**（LibreOffice 无头导出不展开 TOC 域，"
               "静态目录占满一页后正文后移，而打印页码仍按第一遍量）；构建脚本已改为迭代到页码稳定，"
               "并新增 `scripts/check_official_toc.py` 独立复核「目录打印页码 == 标题实际页码」，"
               "33 条目录逐条一致",
        "verify_command": "python3 scripts/check_pdf_render.py CACR2026EA16XZ-作品设计报告.pdf | grep -q '通过' && "
                          "python3 scripts/check_pdf_render.py deliverables/research/multi-leakage-platform-20261016/report.pdf | grep -q '通过' && "
                          "python3 scripts/check_pdf_render.py 'docs/给队友的项目全景说明-20261016.pdf' | grep -q '通过' && "
                          "python3 scripts/check_pdf_render.py CACR2026EA16XZ-审批及签字页.pdf | grep -q '通过' && "
                          "python3 scripts/check_official_toc.py CACR2026EA16XZ-作品设计报告.pdf | grep -q '通过'",
    },
    {
        "id": "P2-05",
        "type": "本轮收尾（补充）",
        "required_artifact": "附件三《审批及签字页》待签字版",
        "evidence_path": "CACR2026EA16XZ-审批及签字页.docx; CACR2026EA16XZ-审批及签字页.pdf; scripts/build_official_approval.py",
        "exists": "yes",
        "status": "已满足（**系统可确定的字段已填；签字与盖章仍待本人完成**）",
        "gap": "作品编号填 **CACR2026EA16XZ**、作品题目填最终题名；"
               "队伍成员姓名/院系/专业/任务分工/签字、指导教师意见与院系盖章**一律留空**，"
               "脚本不得代填。**边界**：本行只表示「待签字版已生成」，"
               "**不表示人工签字、盖章与官方上传已完成**",
        "verify_command": "test -f CACR2026EA16XZ-审批及签字页.docx && test -f CACR2026EA16XZ-审批及签字页.pdf && "
                          "python3 -c \"import zipfile,re;x=zipfile.ZipFile('CACR2026EA16XZ-审批及签字页.docx').read('word/document.xml').decode();t=re.sub(r'<[^>]+>','',x);assert '作品编号：CACR2026EA16XZ' in t and '[待填写]' in t and '盖章' in t\"",
    },
    {
        "id": "P2-06",
        "type": "本轮收尾（补充）",
        "required_artifact": "报告口径回填（题面 12 条 12/12 与过期口径清理）",
        "evidence_path": "deliverables/research/multi-leakage-platform-20261016/report.md; deliverables/research/multi-leakage-platform-20261016/report.tex; deliverables/research/multi-leakage-platform-20261016/report-data.json",
        "exists": "yes",
        "status": "已满足",
        "gap": "摘要与附录 A 统一为 **12 条全部满足（12/12）**；正文里「11 满足 + 1 部分」"
               "「本轮 final5 只重出报告」「复算产物是 final4」「另有低危发现 F1」等**过期口径**"
               "已按实况改写；`document_state` 更新为 P2 收尾版；来源集由 65 份增至 **66 份**（新增 E66 截图佐证）。"
               "**边界**：报告正文**不回填**匿名包自身的成员数与摘要（包内随附的就是报告本身，回填会自指）",
        "verify_command": "grep -q '12 条全部满足（12/12）' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "! grep -q '第 6 条为部分' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "! grep -q 'final5 只重出报告' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "python3 -c \"import json;t=json.load(open('deliverables/research/multi-leakage-platform-20261016/report-tables.json'));cells=[str(c) for tb in t['tables'] for r in tb['rows'] for c in r];assert not any('待主控数据' in c for c in cells)\"",
    },
    {
        "id": "P2-07",
        "type": "本轮收尾（补充）",
        "required_artifact": "final11-20261020 匿名包的成包、审计与解出复算记录",
        "evidence_path": "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/final11-20261020-verification.json; docs/evidence/platform-report-20261016/final11-20261020/package-verification.json; docs/evidence/platform-report-20261016/final11-20261020/pdf-metadata-audit.json; docs/evidence/platform-report-20261016/final11-20261020/offline-reproduction.json; docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final11.log",
        "exists": "yes",
        "status": "已满足",
        "gap": "包审计 `status=pass`、**直接身份标记 0**、860 成员、859 摘要、195 个本地 HTML 链接；"
               "PDF 元数据审计：无作者、私有标记 0、无 JavaScript、96 页；"
               "离线回放：6 份数据集、12 个 C 输出逐字一致、输入原始字节未变；"
               "解出复算：**CTest 5/5 通过、0 失败**（2.70 s）。"
               "**边界**：本轮未做新硬件采集，外部统计工具未重跑",
        "verify_command": "grep -q '\"direct_identity_markers\": 0' docs/evidence/platform-report-20261016/final11-20261020/package-verification.json && "
                          "grep -q '\"ctest_passed\": 5' docs/evidence/platform-report-20261016/final11-20261020/offline-reproduction.json && "
                          "grep -q '\"document_javascript\": false' docs/evidence/platform-report-20261016/final11-20261020/pdf-metadata-audit.json && "
                          "grep -q '100% tests passed, 0 tests failed out of 5' docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final11.log",
    },
    {
        "id": "P2-08",
        "type": "本轮收尾（补充）",
        "required_artifact": "第 9 版审计的核对命令全量实跑明细",
        "evidence_path": "docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json; scripts/run_final_audit_checks.py",
        "exists": "yes",
        "status": "已满足",
        "gap": "CSV **86 行**：可执行核对命令 **83 条**全部返回 0，占位（可选未做）3 条；"
               "证据路径逐条存在性复核 **0 缺失**。核对命令由脚本按 CSV 逐条执行，"
               "退出码、耗时、输出前 4 KB 全部落盘，可复跑。"
               "**边界**：脚本只报告实际退出码，不改判；判定由本审计正文负责",
        "verify_command": "test -f docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json && "
                          "python3 -c \"import csv,json,os;d=json.load(open('docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json'));"
                          "rows=list(csv.DictReader(open('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv')));"
                          "assert d['rows']==len(rows) and d['executable_commands']==sum(1 for r in rows if r['verify_command'].strip() not in ('','—','-')),'行数或命令数与 CSV 不一致';"
                          "assert d['non_zero']==0 and d['timeouts']==0 and not d['evidence_paths_missing'],'有核对命令非 0 或证据路径缺失';"
                          "assert os.path.getmtime('docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json')>=os.path.getmtime('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv'),'明细 JSON 比 CSV 旧'\"",
    },
]


def _refuse_to_write():
    """本脚本已被 scripts/build_final_audit_v91.py（第 9.1 版）取代。

    两个生成器写同一个 FINAL_AUDIT.csv，谁先跑谁覆盖——第 9.1 版的内容更新
    （final14 口径、70 份来源集、R-02 的强校验），用第 9 版重生成会把这些行**回退**。
    因此本脚本不再写 CSV；需要重生成请跑 scripts/build_final_audit_v91.py。
    """
    raise SystemExit(
        "scripts/build_final_audit_v9.py 已被 build_final_audit_v91.py 取代，不再写 FINAL_AUDIT.csv；"
        "请运行 python3 scripts/build_final_audit_v91.py"
    )


def main():
    _refuse_to_write()
    if not SNAPSHOT_CSV.exists():
        shutil.copyfile(SOURCE_CSV, SNAPSHOT_CSV)
    if not SNAPSHOT_MD.exists():
        shutil.copyfile(DIRECTORY / "FINAL_AUDIT.md", SNAPSHOT_MD)

    with open(SOURCE_CSV, encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames
        rows = list(reader)

    for row in rows:
        update = UPDATES.get(row["id"])
        if update:
            row.update(update)

    by_id = {row["id"]: row for row in rows}
    for new_row in NEW_ROWS:
        if new_row["id"] in by_id:
            # 已存在的行按新定义覆盖（脚本可重复执行，不会追加重复行）。
            by_id[new_row["id"]].update({field: new_row.get(field, "") for field in fieldnames})
            continue
        rows.append({field: new_row.get(field, "") for field in fieldnames})

    with open(SOURCE_CSV, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print("FINAL_AUDIT.csv 现有 %d 行（新增 %d 行）" % (len(rows), len(NEW_ROWS)))


if __name__ == "__main__":
    main()
