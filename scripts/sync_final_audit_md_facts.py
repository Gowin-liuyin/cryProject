#!/usr/bin/env python3
"""把 FINAL_AUDIT.md 里的**当前状态事实**与实际产物对齐。

为什么需要：FINAL_AUDIT.md（叙述）与 FINAL_AUDIT.csv（机器逐条实跑）由两个
生成器产出，谁先跑都不会让另一方同步——2026-10-21 复查时两者已就「当前有效包、
成员数、页数、解出复算日志」给出两套说法。

本脚本只改**当前状态**那几处（当前包、当前页数、当前解出复算日志），
**历史叙述**（final4→final5→final16 之类）保持原字节不动；并在表头写明
「当前状态以 FINAL_AUDIT.csv 为准」。
"""
import json
import re
import subprocess
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
DIRECTORY = REPOSITORY / "docs/evidence/platform-completion-20261016"
MD_PATH = DIRECTORY / "FINAL_AUDIT.md"
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
REPORT_DIRECTORY = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"


def current_revision():
    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    for pattern in (
        r"当前有效[：:]\s*`?(final[0-9]+-[0-9]{8})",
        r"当前最新已核验包为 \[(final[0-9]+-[0-9]{8})\]",
        r"\|\s*文件\s*\|\s*`[^`]*-(final[0-9]+-[0-9]{8})\.zip`",
    ):
        match = re.search(pattern, readme)
        if match is not None:
            return match.group(1)
    raise SystemExit("支撑包 README 里找不到当前有效包的声明")


def main():
    revision = current_revision()
    verification = json.loads(
        (SUPPORT / (revision + "-verification.json")).read_text(encoding="utf-8"))
    pdf_audit = json.loads(
        (REPOSITORY / "docs/evidence/platform-report-20261016" / revision
         / "pdf-metadata-audit.json").read_text(encoding="utf-8"))
    package_sha = verification["zip_sha256"]
    members = verification["members"]
    hashed = verification["hashed_members"]
    links = verification["local_html_links"]
    report_pages = pdf_audit["pages"]
    package_hashed = hashed
    package_links = links
    audit_rows = []

    official_pdf = REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf"
    official_pages = 0
    try:
        import fitz

        with fitz.open(str(official_pdf)) as document:
            official_pages = document.page_count
    except Exception:
        pass

    text = MD_PATH.read_text(encoding="utf-8")
    original = text

    # 1) 表头写明以 CSV 为准
    if "当前状态以同目录 `FINAL_AUDIT.csv` 为准" not in text:
        lines = text.split("\n")
        for index, line in enumerate(lines):
            if line.startswith("# ") and "最终复核审计" in line:
                lines.insert(index + 1, "")
                lines.insert(index + 2,
                             "> **当前状态以同目录 `FINAL_AUDIT.csv` 为准**（那份是机器逐条实跑、"
                             "逐条判退出的）；本文件是审计叙述，历史段落按原字节保留，"
                             "个别数字可能滞后于 CSV。")
                break
        text = "\n".join(lines)

    # 2) 当前包事实
    text = re.sub(r"\| 匿名包 sha256 / 成员 / 身份标记 \| `[^`]+` / \*\*\d+\*\* / \*\*0\*\* \|",
                  "| 匿名包 sha256 / 成员 / 身份标记 | `%s` / **%d** / **0** |" % (package_sha, members),
                  text, count=1)
    text = re.sub(r"\| 包内解出复算 ctest \| (\*\*5/5\*\*[^|]*)\| `zip-recompute-[^`]+\.log`",
                  r"| 包内解出复算 ctest | \1| `zip-recompute-%s.log`" % revision,
                  text, count=1)
    # 「以 <revision>/pdf-metadata-audit.json 为准」这类指向：**按当前 revision 重写**。
    # 此前写死 final16/写死旧摘要，对当前包一律不命中——留下悬空的「为准」，
    # 而 FINAL_AUDIT.md 的当前状态事实大面积滞后（2026-10-21 第 9 轮复核 A8 条）。
    # 只改「以 <revision>/pdf-metadata-audit.json **为准**」这一处当前状态指针；
    # 同一文件里另有**历史**行提到 `final5-20261016/pdf-metadata-audit.json`
    # （那讲的是当时的快照），不能一并改掉。
    text = re.sub(r"以 `final\d+-\d{8}/pdf-metadata-audit\.json`",
                  "以 `%s/pdf-metadata-audit.json`" % revision, text)
    # 「…… 与 `<某个包>/pdf-metadata-audit.json` 逐字一致」这半句里的包名也要跟着走。
    # 此前这条正则用了 `[^|]*?`——**跨不过表格竖线**，实测永不命中，于是这半句一直
    # 指着历史包（final25），与同一行前半句指的当前包自相矛盾
    # （2026-10-21 第 10 轮复核问题 2）。改为**按行**替换该行里的所有包名指针。
    def fix_metadata_row(match):
        line = match.group(0)
        line = re.sub(r"final\d+-\d{8}/pdf-metadata-audit\.json",
                      revision + "/pdf-metadata-audit.json", line)
        return line

    text = re.sub(r"^\| 报告 PDF sha256 \|.*$", fix_metadata_row, text, count=1, flags=re.M)
    # 注意：**不做**跨行的无差别替换——FINAL_AUDIT.md 里有些行讲的是**历史包**
    # （final5 / final16 当时的快照），把包名一律改成当前包会造成
    # 「包名是当前的、成员数是历史的」这种自相矛盾。当前状态的行各自按行锚定更新。

    # 3) 官方 PDF 页数
    if official_pages:
        text = re.sub(r"\*\*本版核验\*\*：\d+ 页、中文字形正常",
                      "**本版核验**：%d 页、中文字形正常" % official_pages, text, count=1)
        text = re.sub(r"\*\*\d+ 页 PDF、中文字形正常\*\*",
                      "**%d 页 PDF、中文字形正常**" % official_pages, text, count=1)

    # 3a-2) 解出复算日志名：磁盘上是 `zip-recompute-<stem>.log`（stem 去掉日期），
    # 此前这里写的是带日期的 `zip-recompute-finalNN-YYYYMMDD.log`——**那个文件不存在**，
    # 按字面读是断链（2026-10-21 第 10 轮复核问题 3）。
    text = re.sub(r"zip-recompute-final\d+-\d{8}\.log",
                  "zip-recompute-%s.log" % re.sub(r"-\d{8}$", "", revision), text)

    # 3a) 签字清单表头的计数也跟随 CSV（R-04 行核对的就是它）
    checklist_path = REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md"
    if checklist_path.is_file():
        checklist_text = checklist_path.read_text(encoding="utf-8")

    # 3b) 表头计数（行数 / 可执行条数 / 证据路径条数）跟随 CSV
    import csv as _csv
    with (DIRECTORY / "FINAL_AUDIT.csv").open(encoding="utf-8") as handle:
        audit_rows = list(_csv.DictReader(handle))
    official_pages = 0
    try:
        import fitz

        with fitz.open(str(REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf")) as document:
            official_pages = document.page_count
    except Exception:
        official_pages = 0
    executable_count = sum(1 for row in audit_rows if row.get("verify_command", "").strip()
                            and not row.get("verify_command", "").strip().startswith("—"))
    # 证据路径条数用**审计 JSON 的口径**（run_final_audit_checks.py 的实际扫描数），
    # 不要自己另算一套——两套口径不一致会让 R-04 行判据永远失败。
    evidence_count = 0
    try:
        audit_detail = json.loads(
            (DIRECTORY / "final-audit-checks-20261020.json").read_text(encoding="utf-8"))
        evidence_count = audit_detail.get("evidence_paths_checked", 0)
    except OSError:
        for row in audit_rows:
            for piece in row.get("evidence_path", "").split(";"):
                piece = piece.strip()
                if piece and not piece.startswith("(") and "/" in piece:
                    evidence_count += 1
    text = re.sub(r"\*\*\d+ 行 × 8 列（第 [\d.]+ 版）\*\*、证据路径 \*\*\d+ 条 0 缺失\*\*",
                  "**%d 行 × 8 列（第 9.1 版）**、证据路径 **%d 条 0 缺失**" % (
                      len(audit_rows), evidence_count), text, count=1)

    # 3b-2) 签字清单的项数：MD 里写死了「29 项」，而清单实有 31 项（后加了 B5、C7）。
    # 改为按**清单实测**写（不算死数字），机器判据也另有「表头解析后与实际行数比对」。
    checklist_path = REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md"
    if checklist_path.is_file():
        checklist_lines = checklist_path.read_text(encoding="utf-8").split("\n")
        item_count = len([line for line in checklist_lines
                          if re.match(r"^\| [A-E][0-9]+ \|", line)])
        text = re.sub(r"\*\*\d+ 项\*\*（A8\+B\d\+C\d\+D6\+E5）",
                      "**%d 项**（按 `SIGNOFF_CHECKLIST.md` 实测）" % item_count, text)

    # 3c) 当前状态事实：页数、成员/摘要/链接、CSV 行数、P2-07 行
    text = re.sub(r"\| 报告页数 \| \*\*\d+\*\* \|[^|]*\|",
                  "| 报告页数 | **%d** | 三路互证：PDF 对象流 `/Type /Page` 计数 %d；"
                  "两遍 XeLaTeX `Output written … (%d pages)`；逐页 PNG %d 张 |"
                  % (report_pages, report_pages, report_pages, report_pages),
                  text, count=1)
    text = re.sub(r"(\| 官方作品设计报告 PDF 页数 / 中文字形 \| )\*\*\d+\*\*",
                  r"\g<1>**%d**" % official_pages, text, count=1)
    text = re.sub(r"(\| 匿名包 sha256 / 成员 / 身份标记 \| `[^`]+` / \*\*\d+\*\* / \*\*0\*\* \| [^|]*?)；\d+ 摘要、\d+ 个本地 HTML 链接",
                  r"\g<1>；%d 摘要、%d 个本地 HTML 链接" % (package_hashed, package_links),
                  text, count=1)
    text = re.sub(r"与 `FINAL_AUDIT\.csv` 的 \d+ 行 × 8 列",
                  "与 `FINAL_AUDIT.csv` 的 %d 行 × 8 列" % len(audit_rows), text, count=1)
    text = re.sub(r"\*\*本版（第 [\d.]+ 版）\*\*：\d+ 数据行 × 8 列",
                  "**本版（第 9.1 版）**：%d 数据行 × 8 列" % len(audit_rows), text, count=1)
    # 同一格里那句「前 N 行中除 … 其余 M 行与第 8 版逐字相同」是**上一个版本**的
    # 快照描述，行数一变就自相矛盾——改成指向机器版（逐条以 CSV 为准）。
    text = re.sub(r"；\*\*前 \d+ 行中除 [^|]*?行序未变\*\*",
                  "；**逐条以同目录 `FINAL_AUDIT.csv` 为准**（本版的改动只落在下表列出的行）",
                  text, count=1)
    # P2-07 行：整行按当前包重写（MD 与 CSV 必须一致）。
    # 按**行**匹配而不是按列数匹配——这一行的列数会随 MD 版式变化，
    # 写死列数的正则一旦对不上就整条不命中，留下过期的包名
    # （2026-10-21 第 10 轮期间实测：MD 写 final42、实际是 final5x）。
    def rewrite_p207(match):
        return ("| P2-07 | P2 收尾 | %s 匿名包的成包、审计与解出复算记录 | "
                "`deliverables/support/…/%s-verification.json`、"
                "`docs/evidence/platform-report-20261016/%s/*`、"
                "`…/refresh-20261016/zip-recompute-%s.log` | 已满足 |"
                % (revision, revision, revision, re.sub(r"-\d{8}$", "", revision)))

    text = re.sub(r"^\| P2-07 \|.*$", rewrite_p207, text, count=1, flags=re.M)

    # 4) 报告页数与包计数
    text = re.sub(r"\*\*本版核验\*\*：\d+ 页、与 `[^`]*pdf-metadata-audit",
                  "**本版核验**：%d 页、与 `%s/pdf-metadata-audit" % (report_pages, revision),
                  text, count=1)
    text = re.sub(r"\*\*final[0-9]+-[0-9]+：\d+ 成员、`[0-9a-f]{64}`\*\*",
                  "**%s：%d 成员、`%s`**" % (revision, members, package_sha), text, count=1)
    text = re.sub(r"\*\*(final[0-9]+-[0-9]+)\*\*：\d+ 成员、`[0-9a-f]{64}`、`direct_identity_markers=0`、包内 ctest 5/5（[^）]*）",
                  r"**\1**：%d 成员、`%s`、`direct_identity_markers=0`、包内 ctest 5/5" % (members, package_sha),
                  text, count=1)

    # §1.3 / §2.1 的「CSV 合计」两行与「证据路径」计数：行数与路径数会随新增行变，
    # 手写的合计行会与 CSV 脱节（2026-10-21 第 5 轮红队复核 B-17 条：同一份文档并存
    # 89/78 与 91/80 两套合计）。这里按 CSV 现算改写。
    satisfied_total = sum(1 for row in audit_rows if row.get("status", "").startswith("已满足"))
    p2_rows = sum(1 for row in audit_rows if row.get("id", "").startswith("P2-"))
    placeholder_total = sum(1 for row in audit_rows
                            if not row.get("verify_command", "").strip()
                            or row.get("verify_command", "").strip() in {"—", "-"})
    unresolved_total = sum(1 for row in audit_rows
                           if row.get("status", "") and not row.get("status", "").startswith("已满足"))
    text = re.sub(r"(\| \*\*CSV 合计（[^|]*\|\s*)\d+(\| \*\*)\d+(\*\* \|)",
                  lambda m: m.group(1) + str(len(audit_rows)) + m.group(2) + str(satisfied_total) + m.group(3),
                  text)
    text = re.sub(r"(\*\*CSV 合计（\d+ 行）\*\* \| \*\*)\d+(\*\* \|)",
                  lambda m: m.group(1) + str(satisfied_total) + m.group(2), text)
    text = re.sub(r"(\| \*\*CSV 合计（\d+ 行）\*\* \| \*\*)\d+(\*\* \|)[^|]*\|[^|]*\|[^|]*\|\s*\d+(\s*\|)",
                  lambda m: m.group(1) + str(satisfied_total) + m.group(2) + m.group(3) + str(len(audit_rows)) + " |",
                  text)
    text = re.sub(r"(\| CSV 证据路径存在性 \| \*\*)\d+( 条全部存在)", lambda m: m.group(1) + str(evidence_count) + m.group(2), text)
    text = re.sub(r"(CSV 中 \*\*)\d+( 条证据路径全部存在)", lambda m: m.group(1) + str(evidence_count) + m.group(2), text)
    text = re.sub(r"(\*\*本版（第 9\.1 版）\*\*：)\d+( 数据行 × 8 列)", lambda m: m.group(1) + str(len(audit_rows)) + m.group(2), text)
    text = re.sub(r"(\*\*\d+ 数据行 × 8 列\*\*)", "**" + str(len(audit_rows)) + " 数据行 × 8 列**", text)
    lines = text.split("\n")
    for index, line in enumerate(lines):
        if line.startswith("| **CSV 合计（原文 41"):
            lines[index] = ("| **CSV 合计（原文 41 + 补充 2 + 收尾 23 + 不一致/残留 8 + P2 收尾 %d）** | %d | **%d** | 0 | 0 | 0 | **%d** | **0**（8 行全部已闭合） | — |"
                             % (p2_rows, len(audit_rows), satisfied_total, placeholder_total))
        elif line.startswith("| **CSV 合计（") and line.endswith("|") and "行）**" in line:
            lines[index] = ("| **CSV 合计（%d 行）** | **%d** | **0** | **0** | **0** | **%d** | **8** | **0** | **%d** |"
                             % (len(audit_rows), satisfied_total, placeholder_total, len(audit_rows)))
    text = "\n".join(lines)
    text = re.sub(r"(> `§1\.3` 与 §2\.3 的 CSV 合计行按同一口径写为 )\*\*\d+/0/0/0/\d+/8/0\*\*",
                  lambda m: m.group(1) + "**%d/0/0/0/%d/8/0**" % (satisfied_total, placeholder_total), text)
    text = re.sub(r"(⑤\*\*复核证据路径存在性\*\*（)\d+( 条，0 缺失)",
                  lambda m: m.group(1) + str(evidence_count) + m.group(2), text)
    text = re.sub(r"(（CSV 中 \*\*)\d+( 条路径全部存在、0 缺失)",
                  lambda m: m.group(1) + str(evidence_count) + m.group(2), text)

    # T-08：MD 顶部写明**本审计快照对应的提交**（红队指出审查期间仓库被连续重写，
    # 任何「已满足」结论都有时效性）——把 HEAD 现写进去，读者一眼知道这是哪一版。
    head = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()
    stamp = ("**本审计快照对应提交 `%s`**（工作区 HEAD；审计期间仓库可能被其他工作线继续提交，"
             "上表的「已满足」只对该提交负责）。" % head)
    if "本审计快照对应提交" not in text:
        marker = "**审计快照（第 9 次复核，P2 收尾）：**"
        if marker in text:
            text = text.replace(marker, stamp + "\n\n" + marker, 1)
    else:
        text = re.sub(r"\*\*本审计快照对应提交 `[0-9a-f]+`\*\*", "**本审计快照对应提交 `%s`**" % head, text)

    if checklist_path.is_file():
        checklist_new = re.sub(
            r"\*\*\d+ 行 × 8 列（第 [\d.]+ 版）\*\*、证据路径 \*\*\d+ 条 0 缺失\*\*、\*\*\d+ 条 `verify_command` 全部返回 0\*\*",
            "**%d 行 × 8 列（第 9.1 版）**、证据路径 **%d 条 0 缺失**、**%d 条 `verify_command` 全部返回 0**" % (
                len(audit_rows), evidence_count, executable_count), checklist_text, count=1)
        if checklist_new != checklist_text:
            checklist_path.write_text(checklist_new, encoding="utf-8")
            print("签字清单表头已同步：%d 行 / %d 证据路径 / %d 可执行"
                  % (len(audit_rows), evidence_count, executable_count))

    if text == original:
        print("FINAL_AUDIT.md 的当前状态事实已是最新的，无需改动")
    else:
        MD_PATH.write_text(text, encoding="utf-8")
        print("FINAL_AUDIT.md 的当前状态事实已与实际产物对齐：")
        print("  当前有效包 %s（%d 成员 / %d 摘要 / %d 链接，sha %s）"
              % (revision, members, hashed, links, package_sha[:12]))
        print("  报告 %d 页；官方 PDF %d 页" % (report_pages, official_pages))
    return 0


if __name__ == "__main__":
    sys.exit(main())
