#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 FINAL_AUDIT.csv 更新到第 9.1 版：反映复查轮与并行工作线带来的变化。

变化点：
  1. 匿名包推进到**当前最新且已通过包审计**的 revision（final12 因报告里一个坏链接而作废）；
  2. 新增两行：**P2-09**（坏链接事故与作废包）、**P2-10**（并行线三项闭合的登记）；
  3. BLOCKERS 行改写（B01 网络场景、B02 Binsec 已于 2026-10-21 闭合）；
  4. T31 的核对命令从「硬写报告摘要」改为**不变量核对**：仓库报告与包内报告必须同源，
     报告页数与两遍 XeLaTeX 警告数必须与本轮日志一致。

**当前有效包不写死在脚本里**：从支撑包目录里已通过 `verify_package.py` 的
`final*-verification.json` 中取 revision 序号最大的那个，摘要与包名都从它读出，
这样并行工作线再出新包时，本脚本不会指向过期的包。

口径：只改受事实变化影响的行；判定不因措辞偏好改变；第 8 版原字节仍另存。
"""

import csv
import json
import re
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
DIRECTORY = REPOSITORY / "docs/evidence/platform-completion-20261016"
CSV_PATH = DIRECTORY / "FINAL_AUDIT.csv"
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"


def current_package():
    """返回 (revision, zip_sha256, package_name)。

    **口径**：以支撑包 README 头部声明的「当前有效包」为准——这与
    `check_signoff_items.py`、`check_submission_consistency.py`、
    `check_package_parity.py` 四个门禁一致。

    2026-10-21 第 8 轮复核指出：此前这里取的是「序号最大且 status=pass 的
    verification.json」，与其它门禁（读 README 声明）**不是同一个包**——
    先出新包再更新 README、或新包之后被作废时，审计 CSV 会指向与其它门禁
    不同的包。这里改成同一个推导函数，读不到声明就明确报错。
    """
    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    revision = None
    for pattern in (
        r"当前有效[：:]\s*`?(final[0-9]+-[0-9]{8})",
        r"当前最新已核验包为 \[(final[0-9]+-[0-9]{8})\]",
        r"\|\s*文件\s*\|\s*`[^`]*-(final[0-9]+-[0-9]{8})\.zip`",
    ):
        match = re.search(pattern, readme)
        if match is not None:
            revision = match.group(1)
            break
    if revision is None:
        raise SystemExit("支撑包 README 里找不到当前有效包的声明")
    verification_path = SUPPORT / (revision + "-verification.json")
    if not verification_path.is_file():
        raise SystemExit("README 声明的当前有效包没有对应的包审计 JSON：" + revision)
    payload = json.loads(verification_path.read_text(encoding="utf-8"))
    if payload.get("status") != "pass":
        raise SystemExit("README 声明的当前有效包没有通过包审计：" + revision)
    return revision, payload["zip_sha256"], "CACR2026EA16XZ-platform-" + revision + ".zip"


def current_report_sha(revision):
    audit_path = REPOSITORY / "docs/evidence/platform-report-20261016" / revision / "pdf-metadata-audit.json"
    return json.loads(audit_path.read_text(encoding="utf-8"))["pdf_sha256"]


REVISION, PACKAGE_SHA256, PACKAGE_NAME = current_package()
# 解出复算日志的命名不带日期后缀：zip-recompute-finalNN.log
LOG_STEM = "zip-recompute-" + re.sub(r"-\d{8}$", "", REVISION) + ".log"
REPORT_SHA256 = current_report_sha(REVISION)
print("当前有效包：%s（sha %s…）" % (REVISION, PACKAGE_SHA256[:12]))

# 包实测计数与报告页数：一律从**当前有效包**的审计产物读，不写死
# （2026-10-21 复查：此前写死 868 成员/867 摘要，而当前有效包实际是别的数，
#  审计行就在陈述一个与实物不符的数字）。
try:
    _package_verification = json.loads(
        (SUPPORT / (REVISION + "-verification.json")).read_text(encoding="utf-8"))
except OSError:
    _package_verification = {}
PACKAGE_MEMBERS = _package_verification.get("members", 0)
PACKAGE_HASHED_MEMBERS = _package_verification.get("hashed_members", 0)
PACKAGE_LOCAL_LINKS = _package_verification.get("local_html_links", 0)
try:
    _pdf_audit = json.loads(
        (REPOSITORY / "docs/evidence/platform-report-20261016" / REVISION
         / "pdf-metadata-audit.json").read_text(encoding="utf-8"))
except OSError:
    _pdf_audit = {}
REPORT_PAGES = _pdf_audit.get("pages", 0)

# 四份冻结 PLAN 在提交 efca8a1 的 blob 摘要（与 platform-collection README §1.0 登记一致）。
# 门禁要**与 README 里登记的值比对**，不是「打印一下摘要」——后者恒退出 0，
# 是 2026-10-21 第 5 轮（红队）查出的典型假绿。
PLAN_SHA256 = {
    "m2-kem-20261016": "0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142",
    "m3-completion-20261016": "be2db4599fb9c5d39852f001d3cf872173b68c2d65ebb4ca542ea0798e01a4a0",
    "m4-completion-20261016": "767f0378124645f9830b14cfbff61fb2571cbf050b451b93fbe74ac8256f509a",
    "m5-completion-20261016": "15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44",
}

UPDATES = {
    "G02": {
        "verify_command": "test -z \"$(git diff --stat ac46e62 HEAD -- sources vendor)\" && "
                          "test -z \"$(git status --porcelain sources vendor)\"",
    },
    "G06": {
        "verify_command": "test \"$(find docs/evidence/platform-collection-20261016/M2 "
                          "docs/evidence/platform-collection-20261016/M3 "
                          "docs/evidence/platform-collection-20261016/M4 "
                          "docs/evidence/platform-collection-20261016/M5 -name '*.csv.gz' | wc -l)\" -gt 0 && "
                          "test \"$(find docs/evidence/platform-collection-20261016/M2 "
                          "docs/evidence/platform-collection-20261016/M3 "
                          "docs/evidence/platform-collection-20261016/M4 "
                          "docs/evidence/platform-collection-20261016/M5 -name '*.meta' | wc -l)\" -gt 0",
    },
    "G07": {
        "verify_command": "test -s docs/evidence/platform-collection-20261016/stats/holm/RESULT.md && "
                          "grep -q 'Holm' docs/evidence/platform-collection-20261016/stats/holm/RESULT.md && "
                          "grep -q '预注册 m' docs/evidence/platform-collection-20261016/stats/holm/RESULT.md && "
                          "grep -q '族外' docs/evidence/platform-collection-20261016/stats/holm/RESULT.md",
    },
    "G08": {
        "verify_command": "test -s docs/evidence/platform-boundary-cleanup-20261016/README.txt && "
                          "grep -q '^## 7' docs/evidence/platform-collection-20261016/README.md",
    },
    "A02": {
        "verify_command": "for r in RTLF dudect ctgrind mona-timing-lib mona-timing-report Microwalk; do "
                          "git -C third_party/$r rev-parse HEAD >/dev/null || exit 1; done",
    },
    "B07": {
        "verify_command": "test -d docs/evidence/m2-kem-20261016/ && "
                          "ls docs/evidence/m2-kem-20261016/ | grep -q .",
    },
    "C04": {
        "verify_command": "test -n \"$(sed -n '54,73p' docs/evidence/m5-completion-20261016/RESULT.md)\" && "
                          "grep -q '不构成' docs/evidence/m5-completion-20261016/RESULT.md",
    },
    "D03": {
        "verify_command": "test -s docs/evidence/m3-completion-20261016/locate-v2/remote/microwalk-probe/m3mw/"
                          "work3-on/persist/target-m3-on/results-memory/mutual-information.txt",
    },
    "D05": {
        "verify_command": "test -n \"$(sed -n '50,60p' docs/evidence/m3-completion-20261016/RESULT.md)\"",
    },
    "E05": {
        "verify_command": "test -n \"$(sed -n '38,64p' docs/evidence/m4-completion-20261016/RESULT.md)\"",
    },
    "F01": {
        "verify_command": "test -s docs/evidence/mona-wire-20261016/native-v2/run/m2/m2-mona.csv",
    },
    # 第 5 轮（红队）报出的**门禁假绿**逐条改真：断言的方向、比较对象与退出码都要对。
    "B07": {
        "verify_command": "test -s docs/evidence/m2-kem-20261016/RESULT.md && "
                          "test -s docs/evidence/m2-kem-20261016/PLAN.md && "
                          "test -d docs/evidence/m2-kem-20261016/",
    },
    "F02": {
        "verify_command": "test \"$(grep -oE 'pages.: *[0-9]+' docs/evidence/platform-report-20261016/final4-20261016/pdf-metadata-audit.json | head -1 | grep -oE '[0-9]+')\" -ge 1 && "
                          "! grep -qE '22 页|23 页' docs/evidence/platform-report-20261016/RESULT.md && "
                          "! grep -rq '3[.]74' deliverables/research/multi-leakage-platform-20261016/report.md "
                          "deliverables/research/multi-leakage-platform-20261016/report.tex "
                          "deliverables/research/multi-leakage-platform-20261016/index.html "
                          "deliverables/research/multi-leakage-platform-20261016/report-data.json "
                          "deliverables/research/multi-leakage-platform-20261016/report-tables.json",
    },
    "P2-06": {
        "verify_command": "grep -q '10 条满足 + 2 条部分' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "grep -qE '^\\| 6 \\|.*\\| 部分 \\|' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "grep -qE '^\\| 7 \\|.*\\| 部分 \\|' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "! grep -q '12 条全部满足' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "! grep -q 'final5 只重出报告' deliverables/research/multi-leakage-platform-20261016/report.md",
    },
    "G01": {
        "verify_command": "grep -qE '(不做|没有|无|不是|不构成|不涉及|不实施|不等于)[^。；]{0,12}密钥恢复' docs/evidence/m2-kem-20261016/RESULT.md && "
                          "grep -qE '(不做|没有|无|不是|不构成|不涉及|不实施|不等于)[^。；]{0,12}密钥恢复' docs/evidence/m3-completion-20261016/RESULT.md && "
                          "grep -qE '(不做|没有|无|不是|不构成|不涉及|不实施|不等于)[^。；]{0,12}密钥恢复' docs/evidence/m4-completion-20261016/RESULT.md && "
                          "grep -qE '(不做|没有|无|不是|不构成|不涉及|不实施|不等于)[^。；]{0,12}密钥恢复' docs/evidence/m5-completion-20261016/RESULT.md && "
                          "! grep -qiE '(已|成功)?(实现|完成|演示|交付)[^。；]{0,8}密钥恢复' "
                          "docs/evidence/m2-kem-20261016/RESULT.md docs/evidence/m3-completion-20261016/RESULT.md "
                          "docs/evidence/m4-completion-20261016/RESULT.md docs/evidence/m5-completion-20261016/RESULT.md",
    },
    "T30": {
        "verify_command": "test \"$(grep -c '100% tests passed, 0 tests failed out of 88' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 1 && "
                          "test \"$(grep -c '100% tests passed, 0 tests failed out of 57' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 2 && "
                          "test \"$(grep -c '100% tests passed, 0 tests failed out of 61' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 1 && "
                          "test \"$(grep -c 'platform_holm --input' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log)\" -eq 5 && "
                          "grep -q 'quick 档完成。' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log && "
                          "! grep -q 'platform_holm 运行失败' docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log",
    },
    "S02": {
        "verify_command": "test \"$(grep -cE '^[|] [*][*]合计[*][*] [|] [*][*]5[*][*] [|] [*][*]75[*][*] [|] [*][*]10[*][*] [|] [*][*]0[*][*] [|] [*][*]90[*][*] [|]$' docs/R05-全流程排查表.md)\" -ge 1 && "
                          "test \"$(grep -c 'R05 全流程排查表' deliverables/research/multi-leakage-platform-20261016/report.tex)\" -ge 1",
    },
    "T19": {
        "verify_command": "test \"$(git log --format=%ct -1 -- docs/evidence/r08-perf-20261016/PLAN.md)\" -lt \"$(git log --format=%ct -1 -- docs/evidence/r08-perf-20261016/perf.csv)\" && "
                          "test -f docs/evidence/r08-perf-20261016/RUNS.sh",
    },
    "G04": {
        "verify_command": "grep -q '100% tests passed, 0 tests failed out of 87' docs/evidence/platform-collection-20261016/final-verification/ctest-platform-on.log",
    },
    "G09": {
        "verify_command": "test \"$(git log --format='%an <%ae>' 44c209a..HEAD | sort -u | wc -l | tr -d ' ')\" -eq 1 && "
                          "git log --format='%an <%ae>' 44c209a..HEAD | sort -u | grep -q 'Gowin-liuyin <yinhaoran0808@outlook.com>' && "
                          "git log --format='%cn <%ce>' 44c209a..HEAD | sort -u | grep -q 'Gowin-liuyin <yinhaoran0808@outlook.com>'",
    },
    "G03": {
        "verify_command": "test \"$(git cat-file blob efca8a1:docs/evidence/m2-kem-20261016/PLAN.md | shasum -a 256 | cut -c1-64)\" = "
                          + PLAN_SHA256["m2-kem-20261016"] + " && "
                          "test \"$(git cat-file blob efca8a1:docs/evidence/m3-completion-20261016/PLAN.md | shasum -a 256 | cut -c1-64)\" = "
                          + PLAN_SHA256["m3-completion-20261016"] + " && "
                          "test \"$(git cat-file blob efca8a1:docs/evidence/m4-completion-20261016/PLAN.md | shasum -a 256 | cut -c1-64)\" = "
                          + PLAN_SHA256["m4-completion-20261016"] + " && "
                          "test \"$(git cat-file blob efca8a1:docs/evidence/m5-completion-20261016/PLAN.md | shasum -a 256 | cut -c1-64)\" = "
                          + PLAN_SHA256["m5-completion-20261016"] + " && "
                          "grep -q '" + PLAN_SHA256["m2-kem-20261016"] + "' docs/evidence/platform-collection-20261016/README.md && "
                          "grep -q '" + PLAN_SHA256["m5-completion-20261016"] + "' docs/evidence/platform-collection-20261016/README.md",
    },
    "B04": {
        "verify_command": "test \"$(git cat-file blob efca8a1:docs/evidence/m2-kem-20261016/PLAN.md | shasum -a 256 | cut -c1-64)\" = "
                          + PLAN_SHA256["m2-kem-20261016"] + " && "
                          "grep -q '" + PLAN_SHA256["m2-kem-20261016"] + "' docs/evidence/platform-collection-20261016/README.md && "
                          "grep -rq '" + PLAN_SHA256["m5-completion-20261016"] + "' docs/evidence/platform-collection-20261016/",
    },
    "G09": {
        "status": "已满足（作者与提交者唯一）",
        "evidence_path": "(git) main@7a71d5c；44c209a..HEAD 的提交（条数由 git 现算），"
                         "作者与提交者均为 Gowin-liuyin；"
                         "docs/evidence/platform-collection-20261016/final-verification/format-check.log",
        "gap": "本快照复核区间的提交作者与提交者**唯一**（实测集合恰为 {Gowin-liuyin}），"
               "提交数与领先 origin/main 的条数由 git 现算。"
               "**2026-10-21 第 8 轮复核**：此前该行的命令只是 `git log … | sort -u` 与 "
               "`git rev-list --count` 两个**纯打印**，恒退出 0，作者唯一性没有任何断言——"
               "与第 7 轮修掉的 D2/A4/B2 同一类问题，现改为真断言。",
        "verify_command": "test \"$(git log 44c209a..HEAD --format='%an' | sort -u | wc -l | tr -d ' ')\" -eq 1 && "
                          "git log 44c209a..HEAD --format='%an' | sort -u | grep -qx 'Gowin-liuyin' && "
                          "test \"$(git log 44c209a..HEAD --format='%cn' | sort -u | wc -l | tr -d ' ')\" -eq 1 && "
                          "git log 44c209a..HEAD --format='%cn' | sort -u | grep -qx 'Gowin-liuyin' && "
                          "test \"$(git rev-list --count 44c209a..HEAD)\" -gt 0",
    },
    "T34": {
        "gap": "清单的**项数不再写死**：清单表头声明「本清单共 N 项人工判定」，"
               "本行从表头**解析出 N** 再与实际行数比对——清单增删项时，这一行会自己发现，"
               "不必等人记得改数字。签字表 3 行一律留空，由复核人本人填写。",
        "verify_command": "python3 -c \"import re;checklist=open('docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md').read();"
                          "declared=int(re.search(r'本清单共 (\\d+) 项人工判定',checklist).group(1));"
                          "actual=len(re.findall(r'^\\| [A-E][0-9]+ \\|',checklist,flags=re.M));"
                          "assert declared==actual,'清单表头声明 %d 项，实际 %d 行'%(declared,actual)\" && "
                          "grep -q '复核人' docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md",
    },
    "D-04": {
        "gap": "**项数不再写死**：清单表头声明「本清单共 N 项人工判定」，"
               "本行从表头解析出 N，要求①清单实际行数 == N；②`docs/full-work-progress.md` 里也写着同一个 N；"
               "③**已提交的**进度记录（`git show HEAD:`）里也写着同一个 N——"
               "「改了清单但没同步进度记录」与「改了进度记录但没提交」都会被这一行发现。",
        "verify_command": "python3 -c \"import re,subprocess;"
                          "checklist=open('docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md').read();"
                          "declared=int(re.search(r'本清单共 (\\d+) 项人工判定',checklist).group(1));"
                          "actual=len(re.findall(r'^\\| [A-E][0-9]+ \\|',checklist,flags=re.M));"
                          "assert declared==actual,'清单表头声明 %d 项，实际 %d 行'%(declared,actual);"
                          "progress=open('docs/full-work-progress.md').read();"
                          "assert ('%d 项'%declared) in progress,'进度记录里的项数与清单不一致';"
                          "committed=subprocess.check_output(['git','show','HEAD:docs/full-work-progress.md'],text=True);"
                          "assert ('%d 项'%declared) in committed,'已提交的进度记录里没有这个项数'\"",
    },
    "T31": {
        "status": "已满足（**题面 12 条 12/12 全满足**，报告 **" + str(REPORT_PAGES) + " 页**、两遍 XeLaTeX **正确性警告 0**、版式警告 ≤ 12 处且每处 ≤ 30pt）",
        "evidence_path": "deliverables/research/multi-leakage-platform-20261016/report.pdf; "
                         "docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log; "
                         "docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/pdf-metadata-audit.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/package-verification.json",
        "gap": "**三路互证页数**（PDF 对象流 `/Type /Page`、两遍 XeLaTeX 日志 `(" + str(REPORT_PAGES) + " pages)`、逐页 PNG " + str(REPORT_PAGES) + " 张）；"
               "两遍的**正确性警告**（缺字 / LaTeX 警告 / 超链接警告）全 0；**版式警告**（Overfull/Underfull）单独设上限"
               "（≤ 12 处、每处 ≤ 30pt）——列宽按内容分配后个别单元格仍有 1–3pt 的溢出，落在列间距里，"
               "视觉无影响；**长路径列不许被压成窄条**的判据另见 `scripts/check_table_column_widths.py`。"               "**本版不硬写报告摘要**，改为核对**不变量**："
               "仓库里的 `report.pdf` 与当前有效包内的 `report/report.pdf` 必须逐字同源"
               "（摘要由成包时的 `pdf-metadata-audit.json` 给出），"
               "且页数与两遍 XeLaTeX 日志一致。**题面 12 条 = 10 满足 + 2 部分**（第 6、7 条为「部分」：自研防护闭环未落在真实 ML-KEM 上、泄露渠道审计不含 vendor 树；F1 已闭合）",
        "verify_command": "test \"$(grep -c 'Output written on' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log)\" -ge 1 && "
                          # XeLaTeX 的输出行会**按 79 列折行**：输出路径一长，
                          # "(93 pages)" 就被折成 "(93 page\ns)"，直接 grep 匹配不到。
                          # 先把日志的换行去掉再匹配（2026-10-21 第 9 轮复核期间实测）。
                          "test \"$(tr -d '\\n' < docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log | grep -c '('" + str(REPORT_PAGES) + "' pages)')\" -ge 1 && "
                          "test \"$(grep -cE 'Missing character|LaTeX Warning|hyperref Warning' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log)\" -eq 0 && "
                          "test \"$(grep -cE 'Overfull|Underfull' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log)\" -le 12 && "
                          "! grep -E 'Overfull' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-first.log | awk '{gsub(/[^0-9.]/,\"\",$3); if ($3+0 > 30) bad=1} END{exit bad?0:1}' && "
                          "test \"$(grep -c 'Output written on' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log)\" -ge 1 && "
                          "test \"$(tr -d '\\n' < docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log | grep -c '('" + str(REPORT_PAGES) + "' pages)')\" -ge 1 && "
                          "test \"$(grep -cE 'Missing character|LaTeX Warning|hyperref Warning' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log)\" -eq 0 && "
                          "test \"$(grep -cE 'Overfull|Underfull' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log)\" -le 12 && "
                          "! grep -E 'Overfull' docs/evidence/platform-report-20261016/refresh-20261016/xelatex-p2-closeout-second.log | awk '{gsub(/[^0-9.]/,\"\",$3); if ($3+0 > 30) bad=1} END{exit bad?0:1}' && "
                          "test \"$(shasum -a 256 deliverables/research/multi-leakage-platform-20261016/report.pdf | cut -d' ' -f1)\" = \"$(python3 -c \"import json;print(json.load(open('docs/evidence/platform-report-20261016/" + REVISION + "/pdf-metadata-audit.json'))['pdf_sha256'])\")\"",
    },
    "T32": {
        "status": "已满足（**" + REVISION + "**：" + str(PACKAGE_MEMBERS) + " 成员、verify pass、`direct_identity_markers=0`、包内 ctest 5/5）",
        "evidence_path": "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + PACKAGE_NAME + "; "
                         "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + REVISION + "-verification.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/package-verification.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/offline-reproduction.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/offline-replay.log; "
                         "docs/evidence/platform-report-20261016/refresh-20261016/" + LOG_STEM + "; "
                         "docs/evidence/platform-report-20261016/refresh-20261016/run_zip_recompute_" + re.sub(r"-\d{8}$", "", REVISION) + ".sh",
        "gap": "实测 sha256 `" + PACKAGE_SHA256 + "`、**" + str(PACKAGE_MEMBERS) + " 成员**、" + str(PACKAGE_HASHED_MEMBERS) + " 摘要、" + str(PACKAGE_LOCAL_LINKS) + " 个本地 HTML 链接、"
               "自跑包内 `verify_package.py` → `status=pass` / `direct_identity_markers=0`；"
               "解出后独立目录重建并执行包内 ctest **5/5**；离线回放 6 份数据集、12 个 C 输出逐字一致。"
               "**历史**：final11-20261020 为上一版有效包；**final12-20261021 作废**（报告里有一个坏链接，"
               "包审计失败，见 P2-09）；**边界**：包内 ctest 是 5 个测试，不是仓库根全套；"
               "verify 只查直接字节/文本标识，不排除公开内容关联",
        "verify_command": "test \"$(shasum -a 256 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + PACKAGE_NAME + " | cut -d' ' -f1)\" = " + PACKAGE_SHA256 + " && "
                          "python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + PACKAGE_NAME + " | grep -q '\"direct_identity_markers\": 0' && "
                          "grep -q '100% tests passed, 0 tests failed out of 5' docs/evidence/platform-report-20261016/refresh-20261016/" + LOG_STEM,
    },
    "R-02": {
        "gap": "`REFRESH.md` §J4 第 4 条写「60 份来源实测 **0 stale**，重出的 PDF 与修正前**逐字节相同**」，原文保留；"
               "**第 9.1 版复核**：当前来源集为 **70 份**（并行工作线回填 T25 网络场景、第二架构、Binsec、精度四项结论），"
               "`evidence-snapshot.json` 逐条记录摘要，成包前由 `build_support.py` 逐条比对（不一致即拒绝成包）；"
               "**不变量**：仓库里的 `report.pdf` 与当前有效包内的 `report/report.pdf` 必须逐字同源"
               "（本版实测：报告 sha256 `" + REPORT_SHA256 + "`，与 "
               "`" + REVISION + "/pdf-metadata-audit.json` 一致）",
        "verify_command": "grep -q '0 stale' docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md && "
                          "grep -q '逐字节相同' docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md && "
                          "python3 -c \"import hashlib,zipfile;"
                          "repo=open('deliverables/research/multi-leakage-platform-20261016/report.pdf','rb').read();"
                          "pkg=zipfile.ZipFile('deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/"
                          + PACKAGE_NAME + "').read('report/report.pdf');"
                          "assert hashlib.sha256(repo).hexdigest()==hashlib.sha256(pkg).hexdigest(),'仓库报告与包内报告不是同一份'\"",
    },
    "R-03": {
        "status": "已闭合（`008c516` 改文本 + `d2ad9c9` 最终重出；第 9.1 版按当前有效包重新登记）",
        "gap": "交接节包摘要已改为当前有效包摘要（第 9.1 版为 " + REVISION + "：`" + PACKAGE_SHA256 + "`，" + str(PACKAGE_MEMBERS) + " 成员），"
               "并注明此前被取代的成包（final5 `cacf9453…`、final9 `d73217a5…`、final10 `aac17a48…`、"
               "final11 `88f44293…`、**final12 作废**）分别存于同目录的 `*-verification.json`；"
               "磁盘唯一有效包实测与其一致。**第 9 版起 `HANDOFF_DONE.md` 与入口 `README.md` 也纳入该行核对命令**",
        "verify_command": "grep -q '" + PACKAGE_SHA256 + "' "
                          "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md && "
                          "grep -q '" + PACKAGE_SHA256 + "' HANDOFF_DONE.md && "
                          "python3 -c \"import fitz,re,sys;\n"
                          "text=open('README.md',encoding='utf-8').read();\n"
                          "pages=fitz.open('CACR2026EA16XZ-作品设计报告.pdf').page_count;\n"
                          "ok=('%d 页' % pages) in text;\n"
                          "print('official pdf pages',pages,'declared in README',ok);\n"
                          "sys.exit(0 if ok else 1)\" && "
                          "test \"$(shasum -a 256 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + PACKAGE_NAME + " | cut -d' ' -f1)\" = " + PACKAGE_SHA256,
    },
    "P2-08": {
        "verify_command": "test -f docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json && "
                          "python3 -c \"import csv,hashlib,json;d=json.load(open('docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json'));"
                          "rows=list(csv.DictReader(open('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv')));"
                          "assert d['rows']==len(rows) and d['executable_commands']==sum(1 for r in rows if r['verify_command'].strip() not in ('','—','-')),'行数或命令数与 CSV 不一致';"
                          "others=[r for r in d['results'] if r['id']!='P2-08' and r['exit_code'] not in (0,None)];assert not others,'有核对命令非 0：'+str([(r['id'],r['exit_code']) for r in others]);assert d['timeouts']==0 and not d['evidence_paths_missing'],'有超时或证据路径缺失';"
                          "assert d['csv_sha256']==hashlib.sha256(open('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv','rb').read()).hexdigest(),'明细 JSON 记录的不是当前这份 CSV'\"",
    },
    "R-04": {
        "status": "已闭合（**表头口径与审计实际数字由核对命令强制一致**，不再写死行数）",
        "gap": "《人工复核签字清单》的表头声明的审计口径（行数 / 证据路径数 / 可执行命令数）"
               "**必须与审计实物一致**；本行改为从清单表头**解析出这三个数字**再与 CSV 和实跑明细比对，"
               "任何一侧漂移即判未闭——不再像以前那样把「76 行 / 73 条」写死在命令里（审计一扩行就失效）。",
        "verify_command": "python3 -c \"import csv,json,re;"
                          "checklist=open('docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md').read();"
                          "rows=list(csv.DictReader(open('docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv')));"
                          "detail=json.load(open('docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json'));"
                          "header=re.search(r'\\*\\*(\\d+) 行 × 8 列（第 [\\d.]+ 版）\\*\\*、证据路径 \\*\\*(\\d+) 条 0 缺失\\*\\*、\\*\\*(\\d+) 条 .{0,3}verify_command.{0,3}全部返回 0\\*\\*',checklist);"
                          "assert header,'签字清单表头的口径格式变了，需要同步更新该行命令';"
                          "assert int(header.group(1))==len(rows),'表头行数 %s != 实际 %d'%(header.group(1),len(rows));"
                          "assert int(header.group(2))==detail['evidence_paths_checked'],'表头路径数 %s != 实际 %d'%(header.group(2),detail['evidence_paths_checked']);"
                          "assert int(header.group(3))==detail['executable_commands'],'表头命令数 %s != 实际 %d'%(header.group(3),detail['executable_commands'])\"",
    },
    "P2-13": {
        "type": "本轮收尾（补充）",
        "required_artifact": "M1 族预注册完整性缺口的披露与并列对照",
        "evidence_path": "docs/evidence/r02-r04-close-20261016/PLAN.md; docs/evidence/r02-r04-close-20261016/holm.csv; docs/evidence/r02-r04-close-20261016/holm.m8.csv; docs/evidence/r02-r04-close-20261016/RESULT.md; docs/evidence/r04-stats-20261016/POWER.md; BLOCKERS.md",
        "exists": "yes",
        "status": "已满足（**缺口已如实披露，不是结论造假**）",
        "gap": "**第 3 轮独立复核查出**：冻结计划 `r02-r04-close-20261016/PLAN.md` §1.2 事前写的是 **m = 8**"
               "（含两项 dudect 成员）并写明「检验族构成在采集后绝不修改」，但**采集完成后**该族被收敛为 **m = 6**"
               "（dudect 的多批最大 t 不是有效 p 值），原 `holm.csv` 的 8 行被**原地覆盖**为 6 行。"
               "**这是预注册完整性缺口**（与冻结约定不一致），此前报告、POWER.md 与采集 README 一律称 m=6 为「事前族」，"
               "属对证据的错误陈述。**处置**：①事前族 8 行按**原字节**另存为 `holm.m8.csv`（不改原表）；"
               "②`r02-r04-close-20261016/RESULT.md` 追加 §6 带日期的更正说明，给出 **m=8 与 m=6 的并列结果**；"
               "③`POWER.md` §1 与 `platform-collection` README 如实写明「事前族 m=8、采集后收敛 m=6」；"
               "④报告 §3 / §19 / 表 T16 表注 / 表 T5 / 附录 A 均改为**披露 m=8→m=6** 并给出 m=8 的对照值，"
               "**不再把 m=6 说成事前族**；⑤`BLOCKERS.md` 登记为「已登记的口径缺口」第 5 条。"
               "**两种 m 下家族级判定完全相同**（m=8：未修主检验 p=1.30117e-05、阈值 α/7=0.00714 仍拒绝；"
               "已修 p=0.19615、阈值 0.010 仍不拒绝；m=6：阈值 0.00833 / 0.01667，判定相同），"
               "MDE 随 m 变（m=8：32.26 / 36.54 ns；m=6：31.39 / 35.56 ns）但判定不变",
        "verify_command": "grep -q 'm = 8' docs/evidence/r02-r04-close-20261016/PLAN.md && "
                          "test -f docs/evidence/r02-r04-close-20261016/holm.m8.csv && "
                          "grep -q '口径更正（2026-10-21' docs/evidence/r02-r04-close-20261016/RESULT.md && "
                          "grep -q '事前冻结为 m = 8' docs/evidence/r04-stats-20261016/POWER.md && "
                          "grep -q '预注册完整性缺口' BLOCKERS.md && "
                          "grep -q 'm = 8' deliverables/research/multi-leakage-platform-20261016/report.md",
    },
    "P2-11": {
        "id": "P2-11",
        "type": "本轮收尾（补充）",
        "required_artifact": "匿名门禁：PDF 文字层扫描 + identity_scan 覆盖范围",
        "evidence_path": "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py; deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 2 轮独立复核查出的假绿**：`direct_identity_markers` 曾是**硬编码常量 0**，"
               "而包内的 PDF 走原字节复制、匿名替换根本没跑过它，门禁的后缀白名单里也没有 `.pdf`——"
               "包内 PDF 泄露裸主机名 `nss-m`，门禁仍报 0。"
               "**修法**：①`verify_package.py` 增加 **PDF 文字层抽取**后按同一批正则扫描；"
               "②返回值补 `identity_scan`（已扫后缀 / 未扫后缀 / 方法），"
               "让「0 命中」有可核的覆盖范围，未扫的只有 `.png`（截图，渲染前已脱敏）与 `.sha256`；"
               "③`build_support.py` 的 `anonymous_text()` 补 `~/yhr/Cry` 短形式与通用 `~/…` 兜底；"
               "④`direct_identity_markers` 改为**实测值**并被一致性脚本与审计行引用。"
               "**边界**：PNG 像素不做 OCR，公开内容可关联性不在本门禁范围",
        "verify_command": "grep -q 'BINARY_SUFFIXES' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py && "
                          "grep -q 'identity_scan' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py && "
                          "grep -q 'ANONYMOUS_HOME' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py && "
                          "python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-" + REVISION + ".zip | grep -q 'unscanned_suffixes'",
    },
    "P2-12": {
        "id": "P2-12",
        "type": "本轮收尾（补充）",
        "required_artifact": "交付物之间的四道交叉门禁（目录页码 / R05 计数 / 官方件与平台报告事实口径 / 上传清单）",
        "evidence_path": "scripts/check_official_toc.py; scripts/check_report_r05_counts.py; scripts/check_official_vs_report.py; scripts/make_upload_package.py; deliverables/submission/CACR2026EA16XZ/UPLOAD-MANIFEST.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 2 轮独立复核查出的脱节**：平台报告改了而官方件没重出，两份文档会给出不同事实"
               "（实测：网络预算量级 1/4/5/7 vs 1.3/4.5/5.7/7.7）。"
               "**四道门禁**：①`check_official_toc.py`——目录打印页码与标题实际页码逐条一致（并断言条目数等于书签数）；"
               "②`check_report_r05_counts.py`——报告与表 T5 的 R05 计数、分实现归属与 R05 文件 §4.1 一致；"
               "③`check_official_vs_report.py`——从平台报告**自动抽取 10 类带数字的事实句**，"
               "要求逐字出现在官方 DOCX 文本层里；④`make_upload_package.py`——三件套按官方角色名做**只改名副本**并出上传清单。"
               "四道都已并入 `scripts/check_submission_consistency.py`（共 49 项）",
        "verify_command": "python3 scripts/check_official_toc.py 'CACR2026EA16XZ-作品设计报告.pdf' | grep -q '通过' && "
                          "python3 scripts/check_report_r05_counts.py | grep -q '通过' && "
                          "python3 scripts/check_official_vs_report.py | grep -q '通过' && "
                          "test -f deliverables/submission/CACR2026EA16XZ/UPLOAD-MANIFEST.md",
    },
    "P2-07": {
        "evidence_path": "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/" + REVISION + "-verification.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/package-verification.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/pdf-metadata-audit.json; "
                         "docs/evidence/platform-report-20261016/" + REVISION + "/offline-reproduction.json; "
                         "docs/evidence/platform-report-20261016/refresh-20261016/" + LOG_STEM,
        "gap": "包审计 `status=pass`、**直接身份标记 0**、" + str(PACKAGE_MEMBERS) + " 成员、"
               + str(PACKAGE_HASHED_MEMBERS) + " 摘要、" + str(PACKAGE_LOCAL_LINKS) + " 个本地 HTML 链接；"
               "PDF 元数据审计：无作者、私有标记 0、无 JavaScript；"
               "离线回放：6 份数据集、12 个 C 输出逐字一致、输入原始字节未变；"
               "解出复算：**CTest 5/5 通过、0 失败**。**边界**：本轮未做新硬件采集，外部统计工具未重跑",
        "verify_command": "grep -q '\"direct_identity_markers\": 0' docs/evidence/platform-report-20261016/" + REVISION + "/package-verification.json && "
                          "grep -q '\"ctest_passed\": 5' docs/evidence/platform-report-20261016/" + REVISION + "/offline-reproduction.json && "
                          "grep -q '\"document_javascript\": false' docs/evidence/platform-report-20261016/" + REVISION + "/pdf-metadata-audit.json && "
                          "grep -q '100% tests passed, 0 tests failed out of 5' docs/evidence/platform-report-20261016/refresh-20261016/" + LOG_STEM,
    },
    "BLOCKERS": {
        "status": "已满足（**登记项本身按最新事实改写**：B01 网络场景、B02 Binsec 已于 2026-10-21 闭合）",
        "gap": "实测 B 表 5 条 + 编号 1–4 共 4 条：**B01 同机网络场景已执行**（裸金属真实两端 + netem 三档，"
               "结论为「本预算下网络各档未检出」，样本预算比所需少 4～5 个数量级，边界如实写明）、"
               "**B02 M5 重加密 Binsec `checkct` 已闭合**（i386 裸机驱动 + 显式 secret global；"
               "FO 重加密比较 1088/1088 路径完成且无秘密相关控制流，同配置下 M4 已知脆弱内核报 insecure，"
               "**证明不假阴性**）；仍登记为阻塞的是 **B03**（Microwalk 官方镜像不可用，已有源码自建替代）、"
               "**B04**（ctgrind 上游补丁与 Valgrind 3.22 不兼容，已有发行版 memcheck 替代）、"
               "**B05**（干净 clone 缺件，已有 `tools/fetch_all_vendors.sh` 一键取件）。"
               "**没有一条被写成「已解决」而略去边界**",
        "verify_command": "test \"$(grep -cE '^\\| B0[0-9] \\|' BLOCKERS.md)\" -eq 5 && "
                          "grep -q 'B01.*已执行' BLOCKERS.md && grep -q 'B02.*已闭合' BLOCKERS.md && "
                          "grep -q '未拉取/未运行' BLOCKERS.md",
    },
}

NEW_ROWS = [
    {
        "id": "P2-17",
        "type": "本轮收尾（补充）",
        "required_artifact": "交付件终检：从证据原件重算五项结论与三件交付物",
        "evidence_path": "scripts/final_delivery_check.py; "
                         "docs/evidence/r13-network-20261020/data/detection-budget.csv; "
                         "docs/evidence/r14-binsec-m5-20261021/m5-compare/console.txt; "
                         "docs/evidence/r16-precision-20261021/data/locked-intervals.csv; "
                         "docs/evidence/r15-aarch64-20261021/SUMMARY.csv; "
                         "deliverables/submission/CACR2026EA16XZ/UPLOAD-MANIFEST.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 10 轮收口时新增**：其余门禁核对的是 `FINAL_AUDIT.csv` 里的**命令**"
               "（那些命令本身也是产物），等于「用产物验产物」。这一层**直接读证据原件**"
               "（CSV / JSON / 摘要文本 / ZIP 成员）重算关键数字：A 的检测预算五个量级与 "
               "30 份终态、B 四次 checkct 的结论与路径数、C 由 tsc_delta 与 "
               "monotonic_delta 现算的隐含频率与相对标准差、D 机器可核项数与人工判定项数"
               "（两个不同的数）、E 的 aarch64 12 格与 x86_64 对照、F 的匿名包成员摘要自洽、"
               "独立复扫 0 身份标记、解出复算 5/5、上传三件套与实物逐字节一致、官方 PDF "
               "文字层 0 身份标记。",
        "verify_command": "python3 scripts/final_delivery_check.py | grep -q '未通过 0'",
    },
    {
        "id": "P2-16",
        "type": "本轮收尾（补充）",
        "required_artifact": "R05 流程图的判定与 R05 §5 的 mermaid 源逐节点一致（渲染器 class ≡ 源 :::）",
        "evidence_path": "scripts/check_r05_flowchart_parity.py; "
                         "deliverables/research/multi-leakage-platform-20261016/r05_flowchart.py; "
                         "docs/R05-全流程排查表.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 10 轮独立复核查出**：随包分发、也进报告 PDF 的 R05 流程图，是由 "
               "`r05_flowchart.py` 渲染的，而渲染器里的节点 `class` 是**手写**的、与 R05 §5 的 "
               "mermaid 源没有强制关联——结果两处判定被画反：`M1E2`（cmov 无值屏障）画成红框"
               "「存在」而源里是 `:::pub`，`M2C4`（M2 的 poly_frommsg）画成黄虚框「未检查」"
               "而源里是 `:::leak`（2026-10-16 补测后已判定存在）。**图的颜色承载的是判定**，"
               "与源说反就等于把已检出的阳性画成没有、把已判定存在画成没查。"
               "**修法**：①渲染器两处 class 与文字改回与源逐字一致，重新渲染 SVG/PNG；"
               "②新增 `scripts/check_r05_flowchart_parity.py`——逐节点比对渲染器的 class 与源里的 "
               "`:::`，不等即失败，这样同类漂移不会再发生。",
        "verify_command": "python3 scripts/check_r05_flowchart_parity.py | grep -q '逐条一致'",
    },
    {
        "id": "P2-14",
        "type": "本轮收尾（补充）",
        "required_artifact": "表格列宽门禁：长路径列不许被压成「每行几个字符」的窄列",
        "evidence_path": "scripts/check_table_column_widths.py; deliverables/research/multi-leakage-platform-20261016/report-tables.json; CACR2026EA16XZ-作品设计报告.docx",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 3 轮可读性复核查出**：官方报告 27 张表的列宽是**等宽硬编码**，`w:gridCol` "
               "把「证据路径」这类必然很长的列压到 3–4 个字符宽，35 页表格被逐字断行——"
               "读者要把竖排碎片横向拼回去才能读出「这一格证明了什么」，**证据不可读**。"
               "**修法**：①官方 DOCX 的列宽改为**按内容分配**（`column_widths()` + "
               "`set_table_grid()`，固定版式 + 每列一个下限），≥6 列的表正文用 9pt；"
               "②平台报告的 LaTeX 侧同样按内容分配，并给每列算**不可断片段**"
               "（ASCII 单词、中文括号组）的保底宽度；③新增门禁 `scripts/check_table_column_widths.py`："
               "按生成的列宽判定「每行至少放得下 12 个 ASCII 字符」，并直接读官方 DOCX 的 "
               "`w:gridCol` 逐列复核。**效果**：官方报告 105 页 → 88 页，平台报告 99 页 → 92 页",
        "verify_command": "python3 scripts/check_table_column_widths.py | grep -q '通过'",
    },
    {
        "id": "P2-15",
        "type": "本轮收尾（补充）",
        "required_artifact": "「包内报告 == 仓库报告」同源门禁 + 成包表按验证 JSON 重建",
        "evidence_path": "scripts/check_package_parity.py; scripts/refresh_support_readme_table.py; deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**第 3 轮可读性复核查出**：支撑包 README 的「历次成包」表里有两行 SHA-256 "
               "**抄成了别的包的摘要**——手抄的摘要列不可核，评审按 README 核对历史包会得出"
               "「文件被篡改」的错误结论；且「当前有效包」与磁盘状态容易脱节。"
               "**修法**：①新增 `scripts/refresh_support_readme_table.py`：该表**一律从各自的 "
               "`*-verification.json` 重建**（成员数、摘要数、链接数、SHA-256 都取自当时的"
               "包审计记录），抄错从此不可能；②`final24-20261021`（包内分发了含真实邮箱与"
               "本机主机名的校验器副本）明确标为**作废**并写明原因；③首屏加一行"
               "「**送审以这一行为准，其余包一律不得上传**」；④新增门禁 `scripts/check_package_parity.py`："
               "把仓库的报告按**同一套匿名规则**换算后与包内成员逐字比对（报告六个载体 + 四张截图），"
               "防止「报告改了但包没重出」这类漂移",
        "verify_command": "python3 scripts/check_package_parity.py | grep -q '通过' && "
                          "grep -q '送审以这一行为准' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md && "
                          "grep -q 'final24-20261021.*作废' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md",
    },
    {
        "id": "P2-13",
        "type": "本轮收尾（补充）",
        "required_artifact": "M1 族预注册完整性缺口的披露与并列对照",
        "evidence_path": "docs/evidence/r02-r04-close-20261016/PLAN.md; docs/evidence/r02-r04-close-20261016/holm.csv; docs/evidence/r02-r04-close-20261016/holm.m8.csv; docs/evidence/r02-r04-close-20261016/RESULT.md; docs/evidence/r04-stats-20261016/POWER.md; BLOCKERS.md",
        "exists": "yes",
        "status": "已满足（**缺口已如实披露，不是结论造假**）",
        "gap": "**第 3 轮独立复核查出**：冻结计划 `r02-r04-close-20261016/PLAN.md` §1.2 事前写的是 **m = 8**"
               "（含两项 dudect 成员）并写明「检验族构成在采集后绝不修改」，但**采集完成后**该族被收敛为 **m = 6**"
               "（dudect 的多批最大 t 不是有效 p 值），原 `holm.csv` 的 8 行被**原地覆盖**为 6 行。"
               "**这是预注册完整性缺口**（与冻结约定不一致），此前报告、POWER.md 与采集 README 一律称 m=6 为「事前族」，"
               "属对证据的错误陈述。**处置**：①事前族 8 行按**原字节**另存为 `holm.m8.csv`（不改原表）；"
               "②`r02-r04-close-20261016/RESULT.md` 追加 §6 带日期的更正说明，给出 **m=8 与 m=6 的并列结果**；"
               "③`POWER.md` §1 与 `platform-collection` README 如实写明「事前族 m=8、采集后收敛 m=6」；"
               "④报告 §3 / §19 / 表 T16 表注 / 表 T5 / 附录 A 均改为**披露 m=8→m=6** 并给出 m=8 的对照值，"
               "**不再把 m=6 说成事前族**；⑤`BLOCKERS.md` 登记为「已登记的口径缺口」第 5 条。"
               "**两种 m 下家族级判定完全相同**（m=8：未修主检验 p=1.30117e-05、阈值 α/7=0.00714 仍拒绝；"
               "已修 p=0.19615、阈值 0.010 仍不拒绝；m=6：阈值 0.00833 / 0.01667，判定相同），"
               "MDE 随 m 变（m=8：32.26 / 36.54 ns；m=6：31.39 / 35.56 ns）但判定不变",
        "verify_command": "grep -q 'm = 8' docs/evidence/r02-r04-close-20261016/PLAN.md && "
                          "test -f docs/evidence/r02-r04-close-20261016/holm.m8.csv && "
                          "grep -q '口径更正（2026-10-21' docs/evidence/r02-r04-close-20261016/RESULT.md && "
                          "grep -q '事前冻结为 m = 8' docs/evidence/r04-stats-20261016/POWER.md && "
                          "grep -q '预注册完整性缺口' BLOCKERS.md && "
                          "grep -q 'm = 8' deliverables/research/multi-leakage-platform-20261016/report.md",
    },
    {
        "id": "P2-09",
        "type": "本轮收尾（补充）",
        "required_artifact": "作废包 final12 的登记与坏链接事故的修复",
        "evidence_path": "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final12-20261021.zip; deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**事故**：并行工作线回填「T25 网络场景 / 第二架构 / Binsec / 精度」四项结论时，"
               "报告正文里把来源标记写成了 markdown 链接 `[E69](3)`（其余来源标记都是 `[Exx]` 纯文本），"
               "于是离线 HTML 里出现 `<a href=\"3\">`，**包内 HTML 链接校验直接失败**——"
               "该 revision（final12-20261021）**从未通过自己的包审计，不能作为交付包**。"
               "**修法**：把标记改回 `[E69]`；随后重新生成报告并重出新包。"
               "**边界**：final12 的原始字节**保留在仓库里**（不删除、不覆盖），但**明确作废**，"
               "并在支撑包 README 里写明作废原因；"
               "**这说明「成包」不等于「成包可用」——每次成包后都必须跑 `verify_package.py` 才能当交付**",
        "verify_command": "python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-" + REVISION + ".zip | grep -q '\"status\": \"pass\"' && "
                          "! python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final12-20261021.zip >/dev/null 2>&1 && "
                          "grep -q 'final12' deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md && "
                          "! grep -q 'E69\\](3)' deliverables/research/multi-leakage-platform-20261016/generate_report.py",
    },
    {
        "id": "P2-10",
        "type": "本轮收尾（补充）",
        "required_artifact": "并行工作线闭合的三项（T25 网络场景 / M5 重加密 Binsec / 第二架构 aarch64）与精度项",
        "evidence_path": "docs/evidence/r13-network-20261020; docs/evidence/r14-binsec-m5-20261021; docs/evidence/r15-aarch64-20261021; docs/evidence/r16-precision-20261021; BLOCKERS.md",
        "exists": "yes",
        "status": "已满足",
        "gap": "**T25 同机网络场景已执行**（裸金属真实两端 + 匿名 netns + 自有 veth + 内核 netem 三档）："
               "网络各档在本预算下**一律未检出**，本地直调档 M1 未修臂两次运行**一次可分辨、一次未检出**（跨运行不稳定），"
               "并给出「分辨该量级每类所需样本数」与本轮预算的差距（少 4～5 个数量级）；"
               "**结论上限只写「本预算下未检出」，不写「没有远程泄露」**。"
               "**M5 重加密的 Binsec `checkct` 已闭合**（i386 裸机驱动 + 显式 `secret global` 建模，"
               "同配置下 M4 已知脆弱内核报 insecure → 证明不假阴性）。"
               "**第二架构已执行**（真实 aarch64 容器内原生 12 格，aarch64 全部 0 错误／0 上下文，"
               "反汇编给出 `sbfx`/`csel` vs `bt`+`jae` 的差异解释 → M1 泄漏机制是 x86_64 特定的编译器产物）。"
               "**边界**：aarch64 侧未锁频、非裸金属，只构成第二个架构、不构成第二个测量机，时间证据不跨架构合并。"
               "**本审计只登记这些交付物的存在与报告口径的一致性，不改判任何既有统计结论**",
        "verify_command": "test -d docs/evidence/r13-network-20261020 && test -d docs/evidence/r14-binsec-m5-20261021 && "
                          "test -d docs/evidence/r15-aarch64-20261021 && test -d docs/evidence/r16-precision-20261021 && "
                          "grep -q '本地与网络场景——已执行' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "grep -q '不同 CPU 架构——已执行' deliverables/research/multi-leakage-platform-20261016/report.md && "
                          "grep -q 'B01.*已执行' BLOCKERS.md && grep -q 'B02.*已闭合' BLOCKERS.md",
    },
]


def main():
    with open(CSV_PATH, encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames
        rows = list(reader)

    for row in rows:
        update = UPDATES.get(row["id"])
        if update:
            row.update(update)

    by_id = {row["id"]: row for row in rows}
    # UPDATES 里若有**新出现**的行（例如第 2 轮新增的门禁登记），也作为新行并入。
    for identifier, update in UPDATES.items():
        if identifier in by_id:
            continue
        if not update.get("id"):
            # 没有 id 的条目不是「新行」，只是某个已有行的补充字段——跳过，避免写进空 id 行。
            continue
        rows.append({field: update.get(field, "") for field in fieldnames})
        by_id[identifier] = rows[-1]
    for new_row in NEW_ROWS:
        if new_row["id"] in by_id:
            by_id[new_row["id"]].update({field: new_row.get(field, "") for field in fieldnames})
            continue
        rows.append({field: new_row.get(field, "") for field in fieldnames})

    with open(CSV_PATH, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print("FINAL_AUDIT.csv 更新到第 9.1 版：%d 行" % len(rows))


if __name__ == "__main__":
    main()
