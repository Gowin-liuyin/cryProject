#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""交叉核对四份交付产物的关键数字是否一致。

产物：
  1. 官方作品设计报告 DOCX（根目录）
  2. 官方作品设计报告 PDF（根目录，与 DOCX 同源）
  3. 平台补充报告 report.md（支撑材料卷正文来源）
  4. 平台补充报告 report.pdf（支撑材料卷）
  5. 给队友的项目全景说明 PDF
  6. 匿名支撑包 final6 的包审计 JSON

核对项（全部必须一致，否则退出码非 0）：
  * 赛题 12 条状态：12 条全部「满足」；
  * R06 F1：B 类泄露 1 → 0；
  * R09 合并 CI 三个关键值：m1unfixed-Os 不含 0，m1fixed-O0 与 m1fixed-O3 含 0；
  * R08/R09 控制器归档口径：54/54 与 36/36；
  * 页数：平台补充报告、官方 PDF、队友说明。
"""

import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
OFFICIAL_DOCX = REPOSITORY / "CACR2026EA16XZ-作品设计报告.docx"
OFFICIAL_PDF = REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf"
PLATFORM_MD = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report.md"
PLATFORM_PDF = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/report.pdf"
TEAMMATE_PDF = REPOSITORY / "docs/给队友的项目全景说明-20261016.pdf"
def current_support_revision(readme_text):
    """从支撑包 README 里取「当前有效包」的 revision 名。

    README 的头部结构改过三次（表头「当前有效：finalNN-...」/ 正文
    「当前最新已核验包为 [finalNN-...]」/ 「当前有效包」表的「文件」行），
    三种写法都认，取第一个命中的；都不命中就明确报错，不静默用旧值。
    """
    for pattern in (
        r"当前有效[：:]\s*`?(final[0-9]+-[0-9]{8})",
        r"当前最新已核验包为 \[(final[0-9]+-[0-9]{8})\]",
        r"\|\s*文件\s*\|\s*`[^`]*-(final[0-9]+-[0-9]{8})\.zip`",
    ):
        match = re.search(pattern, readme_text)
        if match is not None:
            return match.group(1)
    raise SystemExit("支撑包 README 里找不到当前有效包的声明")


SUPPORT_DIRECTORY = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
# 当前有效包以包 README 头部声明为准（不写死 revision 名：包一换就失效）。
_SUPPORT_README = (SUPPORT_DIRECTORY / "README.md").read_text(encoding="utf-8")
# 包 README 的头部结构改过（表头「当前有效：finalNN-...」/ 正文「当前最新已核验包为
# [finalNN-...]」/ 「当前有效包」表的「文件」行），三种写法都认，取第一个命中的。
SUPPORT_REVISION = current_support_revision(_SUPPORT_README)
SUPPORT_JSON = SUPPORT_DIRECTORY / (SUPPORT_REVISION + "-verification.json")
CELLS_CSV = REPOSITORY / "docs/evidence/r09-optlevel-20261016/result.csv.cells.csv"
SCREENSHOT_DIRECTORY = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/screenshots"
APPROVAL_DOCX = REPOSITORY / "CACR2026EA16XZ-审批及签字页.docx"
APPROVAL_PDF = REPOSITORY / "CACR2026EA16XZ-审批及签字页.pdf"

failures = []


def check(name, condition, detail=""):
    status = "OK  " if condition else "FAIL"
    print("%s %s%s" % (status, name, ("  — " + detail) if detail else ""))
    if not condition:
        failures.append(name)


def docx_text(path):
    with zipfile.ZipFile(path) as archive:
        xml = archive.read("word/document.xml").decode("utf-8")
    xml = re.sub(r"</w:p>", "\n", xml)
    return re.sub(r"<[^>]+>", "", xml)


def pdf_text(path):
    import fitz

    document = fitz.open(str(path))
    return "".join(document[index].get_text() for index in range(document.page_count))


def pdf_pages(path):
    import fitz

    return fitz.open(str(path)).page_count


def main():
    for path in (OFFICIAL_DOCX, OFFICIAL_PDF, PLATFORM_MD, PLATFORM_PDF, TEAMMATE_PDF, SUPPORT_JSON):
        if not path.is_file():
            raise SystemExit("缺少产物：" + str(path))

    official_docx = docx_text(OFFICIAL_DOCX)
    official_pdf = pdf_text(OFFICIAL_PDF)
    platform_md = PLATFORM_MD.read_text(encoding="utf-8")
    platform_pdf = pdf_text(PLATFORM_PDF)
    teammate_pdf = pdf_text(TEAMMATE_PDF)
    support = json.loads(SUPPORT_JSON.read_text(encoding="utf-8"))

    # 1) 题面 12 条的对照矩阵：状态词表与实际状态必须一致
    # 2026-10-21 第 6 轮复核（逐字对照题面）查出：第 6、7 条其实是「部分」
    # （自研防护闭环未落在真实 ML-KEM 上、泄露渠道审计不含实际发生防护的 vendor 树），
    # 而矩阵却写「12/12 全部满足」，与同报告 §24 的自认缺口直接冲突。
    # 现在按**实际状态**核对：10 行为「满足」、2 行为「部分」，四份载体都写明这个口径。
    for name, text in (("官方 DOCX", official_docx), ("官方 PDF", official_pdf),
                       ("平台 report.md", platform_md), ("平台 report.pdf", platform_pdf),
                       ("队友说明 PDF", teammate_pdf)):
        # PDF 文字层里空格与换行会被重排，匹配前先**去掉所有空白**
        squeezed = re.sub(r"\s+", "", text)
        check("%s 写明题面 12 条的 10 满足 + 2 部分口径" % name,
              ("10条满足+2条部分" in squeezed) or ("10满足+2部分" in squeezed))
    check("平台 report.md 附录 A 表 T26 第 6 条为「部分」",
          re.search(r"^\| 6 \|.*\| 部分 \|", platform_md, re.M) is not None)
    check("平台 report.md 附录 A 表 T26 第 7 条为「部分」",
          re.search(r"^\| 7 \|.*\| 部分 \|", platform_md, re.M) is not None)
    satisfied_rows = len(re.findall(r"^\| \d+ \|.*\| 满足 \| §", platform_md, re.M))
    partial_rows = len(re.findall(r"^\| \d+ \|.*\| 部分 \| §", platform_md, re.M))
    check("平台 report.md 附录 A 12 行状态 = 10 满足 + 2 部分",
          satisfied_rows == 10 and partial_rows == 2,
          "满足 %d 行、部分 %d 行" % (satisfied_rows, partial_rows))
    # 「不按 12/12 全满足计」这类**免责句**允许出现；只查「把 12 条说成全部满足」的断言。
    check("平台 report.md 无「12 条全部满足」断言", "12 条全部满足" not in platform_md)
    check("队友说明 PDF 无旧表残留「缺」状态",
          "主报告里还没有性能对比结果" not in teammate_pdf)

    # 2) R06 F1：B 类 1 → 0
    check("平台 report.md 记 B 类泄露 0 条", ("**0 条**" in platform_md and "B 类泄露" in platform_md)
          or "B 类由 1 条降为 0 条" in platform_md)
    check("官方 DOCX 记 F1 已闭合", "F1" in official_docx and ("已闭合" in official_docx or "闭合" in official_docx))
    check("平台 report.md 引用 F1 修复验证证据路径",
          "docs/evidence/r06-noleak-fix-20261020/AUDIT.md" in platform_md)

    # 3) R09 合并 CI
    cells = {}
    with CELLS_CSV.open(encoding="utf-8") as handle:
        import csv

        for row in csv.DictReader(handle):
            cells[row["cell"]] = row
    for cell, expect_contains_zero in (("m1unfixed-Os", False), ("m1fixed-O0", True), ("m1fixed-O3", True)):
        row = cells[cell]
        low = float(row["delta_ns_pooled_ci_low"])
        high = float(row["delta_ns_pooled_ci_high"])
        contains_zero = low <= 0 <= high
        check("R09 %s 合并 CI 含 0 = %s" % (cell, expect_contains_zero),
              contains_zero == expect_contains_zero,
              "Δ_pool %s [%s, %s]" % (row["delta_ns_pooled"], row["delta_ns_pooled_ci_low"],
                                       row["delta_ns_pooled_ci_high"]))
    check("平台 report.md 含 m1unfixed-Os 合并 CI 值 −26.16",
          "26.16" in platform_md or "26.162" in platform_md)

    # 4) 控制器归档口径
    for name, text in (("平台 report.md", platform_md), ("平台 report.pdf", platform_pdf),
                       ("官方 PDF", official_pdf), ("官方 DOCX", official_docx)):
        check("%s 写明 54/54 与 36/36" % name, "54/54" in text and "36/36" in text)

    # 5) 页数
    platform_pages = pdf_pages(PLATFORM_PDF)
    official_pages = pdf_pages(OFFICIAL_PDF)
    teammate_pages = pdf_pages(TEAMMATE_PDF)
    # 平台报告的页数声明写在它自己的 README 里——**从声明里读出来再比对**，
    # 不写死数字：报告一改页数就变，写死会让这道门禁立刻变成假绿或假红。
    platform_readme = (REPOSITORY / "deliverables/research/multi-leakage-platform-20261016/README.md").read_text(encoding="utf-8")
    declared_match = re.search(r"当前已核验副本为 \[(\d+) 页 PDF\]", platform_readme)
    if declared_match is None:
        declared_platform_pages = -1
    else:
        declared_platform_pages = int(declared_match.group(1))
    check("平台 report.pdf 页数与 report.md 声明一致", platform_pages == declared_platform_pages,
          "实际 %d 页、声明 %d 页" % (platform_pages, declared_platform_pages))
    check("官方 PDF 页数与 README 声明一致",
          ("%d 页" % official_pages) in (REPOSITORY / "README.md").read_text(encoding="utf-8"),
          "实际 %d 页" % official_pages)
    check("队友说明 PDF 页数合理（≥ 20 页）", teammate_pages >= 20, "实际 %d 页" % teammate_pages)
    import fitz as _fitz
    with _fitz.open(str(OFFICIAL_PDF)) as _document:
        _bookmark_titles = {entry[1].strip() for entry in _document.get_toc()}
    _missing_titles = sorted(title for title in _bookmark_titles if title and title not in official_docx)
    check("官方 PDF 的每个书签标题都能在 DOCX 正文里找到",
          not _missing_titles, "缺 %d 个：%s" % (len(_missing_titles), _missing_titles[:3]))

    # 6) 匿名支撑包审计
    readme_text = _SUPPORT_README
    current_revision = SUPPORT_REVISION
    current_zip = SUPPORT_DIRECTORY / ("CACR2026EA16XZ-platform-" + current_revision + ".zip")
    check("匿名包 %s 审计状态 pass" % current_revision, support.get("status") == "pass", str(support.get("status")))
    check("匿名包 %s 成员数与包 README 声明一致" % current_revision,
          str(support.get("members")) in readme_text[:4000], str(support.get("members")))
    check("匿名包 %s 直接身份标记 0" % current_revision, support.get("direct_identity_markers") == 0)
    check("匿名包 %s 的扫描范围已记录，未扫描后缀只有图片与摘要清单" % current_revision,
          bool(support.get("identity_scan"))
          # 白名单只留 .png（图片像素无法 OCR，scope 已明示）；.sha256 已纳入
          # 文本扫描，不该再被允许退回「未扫描」（2026-10-21 第 9 轮复核 A13 条）。
          and not [suffix for suffix in support["identity_scan"]["unscanned_suffixes"]
                   if suffix != ".png"],
          str(support.get("identity_scan", {}).get("unscanned_suffixes")))
    # 不写死 revision 的摘要：拿实际 ZIP 的 sha256 与包审计 JSON、README 声明三方比对。
    import hashlib as _hashlib
    # 当前有效包以 README 头部声明为准（不写死 revision 名，避免包一换就失效）。
    actual_zip_sha = _hashlib.sha256(current_zip.read_bytes()).hexdigest()
    check("匿名包 %s ZIP SHA-256 与包审计 JSON 一致" % current_revision,
          support.get("zip_sha256") == actual_zip_sha,
          "%s vs %s" % (support.get("zip_sha256"), actual_zip_sha))
    check("匿名包 %s ZIP SHA-256 在 README 头部声明" % current_revision,
          actual_zip_sha in readme_text[:4000], actual_zip_sha)

    # 7) 官方 PDF 的目录打印页码与标题实际页码逐条一致
    toc_result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_official_toc.py"),
                                 str(OFFICIAL_PDF)], capture_output=True, text=True)
    check("官方 PDF 目录页码与实际页码一致", toc_result.returncode == 0,
          toc_result.stdout.strip().splitlines()[-1] if toc_result.stdout.strip() else "")

    # 8) 报告里的 R05 计数必须与 R05 文件 §4.1 的合计行一致（补格前后的旧计数不得残留）
    versus_result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_official_vs_report.py")],
                                  capture_output=True, text=True)
    check("官方报告与平台报告的事实口径一致", versus_result.returncode == 0,
          versus_result.stdout.strip().splitlines()[-1] if versus_result.stdout.strip() else "")

    r05_result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_report_r05_counts.py")],
                                 capture_output=True, text=True)
    check("报告 R05 计数与 docs/R05-全流程排查表.md §4.1 一致", r05_result.returncode == 0,
          r05_result.stdout.strip().splitlines()[-1] if r05_result.stdout.strip() else "")

    # 9) PDF 中文字形确实渲染出来（文本层有中文不等于字形能显示）
    for label, pdf_path in (("官方 PDF", OFFICIAL_PDF), ("平台 PDF", PLATFORM_PDF),
                            ("队友说明 PDF", TEAMMATE_PDF), ("审批签字页 PDF", APPROVAL_PDF)):
        result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_pdf_render.py"),
                                 str(pdf_path)], capture_output=True, text=True)
        check("%s 中文字形渲染检查通过" % label, result.returncode == 0,
              result.stdout.strip().splitlines()[-1] if result.stdout.strip() else "")

    # 10) 附件三审批签字页：系统编号已填，成员栏留空待手写
    check("审批签字页 DOCX 存在", APPROVAL_DOCX.is_file())
    check("审批签字页 PDF 存在", APPROVAL_PDF.is_file())
    if APPROVAL_DOCX.is_file():
        approval_text = docx_text(APPROVAL_DOCX)
        check("审批签字页写明系统编号 CACR2026EA16XZ", "CACR2026EA16XZ" in approval_text)
        check("审批签字页保留待填写的队员栏", "[待填写]" in approval_text)
        check("审批签字页保留承诺语与盖章栏", "团队签字承诺" in approval_text and "盖章" in approval_text)

    # 11) 上传清单（按官方角色名的只改名副本）与人工动作说明
    # 上传清单要查**被跟踪的那一份**：`build/` 被 .gitignore 排除，在干净 clone 上
    # 查 build/ 必然失败，而真正随仓库走的那份反而没人核对。
    # 2026-10-21 第 8 轮复核 A8 条。
    upload_manifest = REPOSITORY / "deliverables/submission/CACR2026EA16XZ/UPLOAD-MANIFEST.md"
    check("上传清单已生成且被跟踪（官方角色名的只改名副本）", upload_manifest.is_file(),
          str(upload_manifest.relative_to(REPOSITORY)) if upload_manifest.is_file()
          else "缺 " + str(upload_manifest.relative_to(REPOSITORY)))
    if upload_manifest.is_file():
        manifest_text = upload_manifest.read_text(encoding="utf-8")
        # 清单里的支撑材料必须是**当前有效包**，报告的摘要/页数必须是实物
        check("上传清单里的支撑材料是当前有效包",
              SUPPORT_REVISION in manifest_text,
              "当前有效包 " + SUPPORT_REVISION)
        check("上传清单里的报告摘要与实物一致",
              re.search(r"[0-9a-f]{64}", manifest_text) is not None
              and _hashlib.sha256(OFFICIAL_PDF.read_bytes()).hexdigest() in manifest_text,
              "官方报告 sha256 " + _hashlib.sha256(OFFICIAL_PDF.read_bytes()).hexdigest()[:12])

    # 12) 表格列宽：长内容列不许被压成「每行几个字符」的窄列
    width_result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_table_column_widths.py")],
                                  capture_output=True, text=True)
    check("表格列宽按内容分配（长路径列不被压成窄条）", width_result.returncode == 0,
          width_result.stdout.strip().splitlines()[-1] if width_result.stdout.strip() else "")

    # 13) 包内报告与仓库报告同源（按同一套匿名规则复算后逐字一致）
    parity_result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/check_package_parity.py")],
                                   capture_output=True, text=True)
    check("匿名包内的报告与仓库报告同源", parity_result.returncode == 0,
          parity_result.stdout.strip().splitlines()[-1] if parity_result.stdout.strip() else "")

    # 13) 真实运行截图
    for name in ("01-reproduce-quick-terminal.png", "02-valgrind-memcheck-hit.png",
                 "03-frequency-controller-log.png", "04-offline-html.png",
                 "SCREENSHOTS.md", "SHA256SUMS"):
        check("截图材料齐备：" + name, (SCREENSHOT_DIRECTORY / name).is_file())

    # 11) 入口文档里的官方报告页数必须与实物一致（防止 README/HANDOFF 悄悄过期）
    for label, doc_path in (("入口 README", REPOSITORY / "README.md"),
                            ("交接文档", REPOSITORY / "HANDOFF_DONE.md")):
        doc_text = doc_path.read_text(encoding="utf-8")
        stale = []
        for match in re.finditer(r"(\d+)\s*页", doc_text):
            window = doc_text[max(0, match.start() - 60):match.end() + 20]
            if ("官方" in window or "作品设计报告" in window) and int(match.group(1)) != official_pages:
                stale.append(match.group(0))
        check("%s 里官方报告的页数与实物一致（%d 页）" % (label, official_pages),
              not stale, "过期写法：%s" % "、".join(stale[:5]) if stale else "")

    print()
    if failures:
        print("不一致项 %d 个：" % len(failures))
        for item in failures:
            print("  -", item)
        return 1
    print("全部一致：通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
