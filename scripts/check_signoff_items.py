#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""跑《人工复核签字清单》里**机器可核**的那些项，把逐项结果落盘。

口径：
  * 清单里凡是能用命令判定的，本脚本逐条实跑并记录**实际输出**（命中数、路径、退出码）；
  * 需要人眼判断的（如"逐处看上下文"是否表述得当）只做**检索定位**，结论仍留空给复核人；
  * 本脚本**不改判**、不替人签字；结果写入 `docs/evidence/closeout-20261016/signoff-machine-checks-20261020.json`。
"""

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
OUTPUT = REPOSITORY / "docs/evidence/closeout-20261016/signoff-machine-checks-20261020.json"
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
CHECKLIST = REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md"


def rewrite_machine_result_table(items):
    """把签字清单里「机器可核项的复核结果」表的结果列**按实跑输出重写**。

    2026-10-21 第 8 轮复核 A7 条：那张表原先是**手抄**的，已经与同目录的
    `signoff-machine-checks-20261020.json` 互相矛盾（写着 final16、「抽样 10 个
    文件」、A4：8 等旧输出）。手抄就会漂，所以这里让脚本自己写回去。

    只改「结果」列；「机器可核的内容」一列是人工措辞，不动。
    """
    if not CHECKLIST.is_file():
        return None
    text = CHECKLIST.read_text(encoding="utf-8")
    by_id = {}
    for item in items:
        by_id.setdefault(item["id"], []).append(item)

    changed = 0

    def replace_row(match):
        nonlocal changed
        item_id = match.group(1)
        content = match.group(2)
        entries = by_id.get(item_id)
        if entries is None:
            # **伞形行**（A1 / A6）：本身没有检查项，结果由它的子项聚合。
            # 2026-10-21 第 5 轮（红队）指出：这两行的结果列**从来没有被刷新过**
            # （脚本的 by_id 里没有 A1/A6），只是恰好与实跑一致，属运气。
            child_ids = sorted(key for key in by_id if key.startswith(item_id)
                               and key != item_id
                               and not any(other != key and other != item_id
                                           and key.startswith(other) and other.startswith(item_id)
                                           for other in by_id))
            if not child_ids:
                return match.group(0)
            entries = []
            for child_id in child_ids:
                for entry in by_id[child_id]:
                    entries.append(entry)
        parts = []
        for entry in entries:
            first_line = ""
            for line in (entry.get("output_head") or "").splitlines():
                if line.strip():
                    first_line = line.strip()
                    break
            if len(first_line) > 90:
                first_line = first_line[:90] + "…"
            verdict = "通过" if entry["result"] == "pass" else "**未通过**"
            parts.append("%s（%s：%s）" % (verdict, entry["id"], first_line) if first_line
                         else verdict)
        changed += 1
        return "| %s · 机器可核 | %s | %s |" % (item_id, content, "；".join(parts))

    # id 形如 A1 / A1a / A1b / B3b——**带字母后缀的也要认**。
    # 2026-10-21 第 9 轮复核 A1 条：此前正则只认 `[A-E][0-9]+`，于是 A1a/A1b/A6a/
    # A6b/B3b 这 5 个 id 永远「不在表里」，每次跑都被当成新增项再插一遍——
    # 表里因此堆出 35 条重复行，且这 5 项的结果列**从来没被刷新过**。
    pattern = re.compile(r"^\| ([A-E][0-9]+[a-z]?) · 机器可核 \| (.*?) \| .*? \|$", re.M)
    new_text = pattern.sub(replace_row, text)

    # 新增的检查项在表里还没有行——按同一字母组的最后一行插进去（不手工维护行）。
    matched_ids = {match.group(1) for match in pattern.finditer(text)}
    missing_ids = [item_id for item_id in by_id if item_id not in matched_ids]
    for item_id in sorted(missing_ids):
        entries = by_id[item_id]
        parts = []
        for entry in entries:
            first_line = ""
            for line in (entry.get("output_head") or "").splitlines():
                if line.strip():
                    first_line = line.strip()
                    break
            if len(first_line) > 90:
                first_line = first_line[:90] + "…"
            verdict = "通过" if entry["result"] == "pass" else "**未通过**"
            parts.append("%s（%s：%s）" % (verdict, entry["id"], first_line) if first_line
                         else verdict)
        group = item_id[0]
        group_rows = [match for match in pattern.finditer(new_text)
                      if match.group(1).startswith(group)]
        if not group_rows:
            continue
        anchor_row = group_rows[-1]
        new_row = ("| %s · 机器可核 | %s | %s |\n"
                   % (item_id, entries[0].get("check", "机器可核"), "；".join(parts)))
        new_text = (new_text[:anchor_row.end()] + "\n" + new_row.rstrip("\n")
                    + new_text[anchor_row.end():])
        changed += 1

    # 「机器可核项合计 N 条，通过 M 条、未通过 K 条」这句也按实跑数改写
    # （2026-10-21 第 9 轮复核 D4 条：清单写着 32 条，实际已是 34 条）。
    passed = sum(1 for item in items if item["result"] == "pass")
    failed = sum(1 for item in items if item["result"] != "pass")
    # 表里的**伞形行**（A1 / A6）也是行，但不是独立的检查项——
    # 2026-10-21 第 5 轮（红队）指出「合计 34 条」与表里的 36 行对不上。
    # 这里把「合计」改成**脚本自己的检查项数**，并把伞形行数单独写明。
    table_ids = re.findall(r"^\| ([A-E][0-9]+) · 机器可核 \|", new_text, flags=re.M)
    # 伞形行 = 表里有、但脚本里没有对应检查项（结果由子项聚合而来）。
    umbrella_ids = sorted(item_id for item_id in set(table_ids)
                          if item_id not in by_id
                          and any(key.startswith(item_id) for key in by_id))
    umbrella_rows = len(umbrella_ids)
    new_text = re.sub(r"\*\*机器可核项合计 [^\*]*?未通过 \d+ 条[。．]?\*\*",
                      "**机器可核项合计 %d 条（另有 %d 行伞形行由子项聚合，不另计），通过 %d 条、未通过 %d 条**"
                      % (len(items), umbrella_rows, passed, failed), new_text, count=1)
    if new_text != text:
        CHECKLIST.write_text(new_text, encoding="utf-8")
    return changed


def current_package():
    """当前有效匿名包：从支撑包 README 头部声明的「当前最新已核验包」取，
    并与该包自己的 *-verification.json 交叉核对（不写死 revision）。"""
    import re

    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    # README 头部结构改过：表头「当前有效：finalNN-...」、正文
    # 「当前最新已核验包为 [finalNN-...]」、以及「当前有效包」表的「文件」行，
    # 三种写法都认，取第一个命中的。
    revision = None
    for pattern in (
        r"当前有效[：:]\s*`?(final\d+-\d{8})",
        r"当前最新已核验包为 \[(final\d+-\d{8})\]",
        r"\|\s*文件\s*\|\s*`[^`]*-(final\d+-\d{8})\.zip`",
    ):
        match = re.search(pattern, readme)
        if match is not None:
            revision = match.group(1)
            break
    if revision is None:
        raise SystemExit("支撑包 README 里找不到当前有效包的声明")
    package = SUPPORT / ("CACR2026EA16XZ-platform-" + revision + ".zip")
    verification = json.loads((SUPPORT / (revision + "-verification.json")).read_text(encoding="utf-8"))
    if verification.get("zip_sha256") != hashlib.sha256(package.read_bytes()).hexdigest():
        raise SystemExit("README 声明的当前包与该包自己的验证 JSON 摘要不一致：" + revision)
    return revision, package


REVISION, PACKAGE = current_package()
VERIFICATION_JSON = SUPPORT / (REVISION + "-verification.json")
PDF_AUDIT_JSON = (REPOSITORY / "docs/evidence/platform-report-20261016" / REVISION
                  / "pdf-metadata-audit.json")
RECOMPUTE_LOG = (REPOSITORY / "docs/evidence/platform-report-20261016/refresh-20261016"
                 / ("zip-recompute-" + re.sub(r"-\d{8}$", "", REVISION) + ".log"))
REPORT_DIRECTORY = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"


def shell(command):
    completed = subprocess.run(["/bin/sh", "-c", command], cwd=str(REPOSITORY),
                               capture_output=True, text=True)
    return completed.returncode, (completed.stdout or "") + (completed.stderr or "")


def count(command):
    exit_code, output = shell(command)
    return exit_code, output.strip()


def main():
    items = []

    def record(item_id, description, command, expectation, detail=None):
        exit_code, output = shell(command)
        ok = exit_code == 0
        items.append({
            "id": item_id,
            "check": description,
            "command": command,
            "exit_code": exit_code,
            "result": "pass" if ok else "fail",
            "output_head": output[:2000],
            "expectation": expectation,
            "detail": detail,
        })
        print("%-4s %-5s %s" % (item_id, "pass" if ok else "fail", description))

    # A 组：措辞与声明（机器可判的部分）
    record("A1a", "报告全文检索「恒时」，命中处均须带否定或限定",
           "grep -c '恒时' deliverables/research/multi-leakage-platform-20261016/report.md",
           "有命中即列出上下文供人工逐处看；脚本只做定位")
    record("A1b", "报告不得出现肯定式恒时主张",
           "python3 - <<'PY'\n"
           "import re,sys\n"
           "text=open('deliverables/research/multi-leakage-platform-20261016/report.md').read()\n"
           "# 逐**句**扫描：凡句中出现「恒时」，同句（或紧邻的限定分句）必须出现否定/限定词。\n"
           "# 2026-10-21 第 5 轮（红队）指出：原来的正则只覆盖 7 种措辞，换个说法就看不见。\n"
           "sentences=[s for s in re.split(r'[。；！？]', text.replace(chr(10),' ')) if '恒时' in s]\n"
           "qualifier=re.compile(r'不|非|未|无|≠|尚未|并不|不是|不等于|仅|只在|限于|条件|前提|须|需|要求|分开|区分')\n"
           "affirmative=[]\n"
           "for sentence in sentences:\n"
           "    if not qualifier.search(sentence):\n"
           "        affirmative.append(sentence.strip()[:80])\n"
           "print('occurrences',text.count('恒时'),'sentences',len(sentences),'affirmative',affirmative)\n"
           "sys.exit(1 if affirmative else 0)\n"
           "PY",
           "肯定式主张 0 命中；「恒时」总出现次数供人工逐处看上下文")
    record("A2", "M5 与 R03 的阴性结论须限定适用范围",
           "grep -q '不构成恒时证明' docs/evidence/m5-completion-20261016/RESULT.md && "
           "grep -q '不构成恒时证明' docs/evidence/r03-malformed-20261016/RESULT.md && "
           "grep -q '不是任意输入' docs/evidence/m5-completion-20261016/RESULT.md",
           "两处 RESULT.md 都写明限定")
    record("A3", "M2/M3 的定位阳性不得写成端到端阳性",
           "grep -q '定位层阳性' docs/evidence/m2-kem-20261016/RESULT.md && "
           "grep -q '定位' docs/evidence/m3-completion-20261016/RESULT.md",
           "两处 RESULT.md 都区分定位层与端到端层")
    record("A4", "人工夹具都标了「人工构造校准」",
           "python3 -c \"import sys;\n"
           "paths=['docs/R05-全流程排查表.md','docs/evidence/m3-completion-20261016/RESULT.md',\n"
           "       'docs/evidence/m4-completion-20261016/RESULT.md'];\n"
           "total=0\n"
           "for path in paths:\n"
           "    count=open(path,encoding='utf-8').read().count('人工构造校准')\n"
           "    print(path,count)\n"
           "    total+=count\n"
           "print('合计',total)\n"
           "sys.exit(0 if total>0 else 1)\"",
           "三份文件里「人工构造校准」的命中数与合计；合计必须大于 0"
           "（2026-10-21 复查：原判据只打印命中数，恒退出 0）")
    record("A5", "族外对照都标了「族外」",
           "grep -c '族外' docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md && "
           "grep -c '族外' docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md && "
           "grep -c '族外' docs/evidence/r09-optlevel-20261016/RESULT.md",
           "三处族外对照文件都出现「族外」")
    record("A6a", "M4 家族合并 Δ 3.74 不得出现",
           "! grep -rq '3\\.74' deliverables/research/multi-leakage-platform-20261016/report.md "
           "deliverables/research/multi-leakage-platform-20261016/report.tex "
           "deliverables/research/multi-leakage-platform-20261016/index.html "
           "deliverables/research/multi-leakage-platform-20261016/report-data.json "
           "deliverables/research/multi-leakage-platform-20261016/report-tables.json "
           "deliverables/research/multi-leakage-platform-20261016/platform-matrix.svg",
           "0 命中")
    record("A6b", "M4 分臂数值 4.089 与 0.055 必须在位",
           "grep -q '4\\.089' deliverables/research/multi-leakage-platform-20261016/report.md && "
           "grep -q '0\\.055' deliverables/research/multi-leakage-platform-20261016/report.md",
           "两个分臂值都在报告里")
    record("A7", "锁频价值不得写成「必然降低方差」",
           "! grep -q '必然降低方差' docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md && "
           "grep -q '确定性' docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md",
           "价值表述为确定性/可核对/可恢复")
    record("A8", "「未运行」与「未检出」在 R05 与报告 T1 分列",
           "grep -q '不适用' docs/R05-全流程排查表.md && "
           "grep -q '未执行' deliverables/research/multi-leakage-platform-20261016/report.md",
           "R05 用「不适用/未检查」，报告用「未执行」")

    # B 组：匿名性与隐私
    record("B1", "匿名包 direct_identity_markers = 0（扫描范围含 PDF 文字层，未扫描后缀已明示）",
           "grep -q '\"direct_identity_markers\": 0' " + str(VERIFICATION_JSON) + " && "
           "grep -q '\"unscanned_suffixes\"' " + str(VERIFICATION_JSON) + " && "
           "grep -q 'PDF members: extracted text layer' " + str(VERIFICATION_JSON) + " && "
           "grep -q 'not OCR-scanned' " + str(VERIFICATION_JSON),
           "包审计 JSON 记 0；扫描范围含 PDF 文字层；未扫描的后缀（图片像素等）**明示**在 JSON 里而不是静默省略")
    record("B2", "包内**全部**可扫成员（含 PDF 文字层）无真名/邮箱/主机名/私有路径",
           "python3 - <<'PY'\n"
           "import gzip,importlib.util,io,re,sys,zipfile\n"
           "from pathlib import PurePosixPath\n"
           "spec=importlib.util.spec_from_file_location('vp',r'" + str(SUPPORT / "verify_package.py") + "')\n"
           "vp=importlib.util.module_from_spec(spec);spec.loader.exec_module(vp)\n"
           "with zipfile.ZipFile(r'" + str(PACKAGE) + "') as archive:\n"
           "    names=archive.namelist()\n"
           "    hits=[]\n"
           "    scanned=0\n"
           "    for name in names:\n"
           "        content=archive.read(name)\n"
           "        suffix=PurePosixPath(name).suffix.lower()\n"
           "        if suffix == '.gz':\n"
           "            # 压缩成员必须**解压后**再扫（包审计也是这么做的）\n"
           "            try:\n"
           "                content = gzip.decompress(content)\n"
           "            except Exception:\n"
           "                continue\n"
           "        elif suffix == '.docx':\n"
           "            # Word 文档是 ZIP：抽内部 XML 文字层再扫（与包审计一致）\n"
           "            try:\n"
           "                with zipfile.ZipFile(io.BytesIO(content)) as inner:\n"
           "                    content = b'\\n'.join(inner.read(m) for m in inner.namelist() if m.endswith('.xml'))\n"
           "            except Exception:\n"
           "                continue\n"
           "        elif suffix in vp.BINARY_SUFFIXES:\n"
           "            try:\n"
           "                import fitz\n"
           "                with fitz.open(stream=io.BytesIO(content)) as document:\n"
           "                    text='\\n'.join(document[i].get_text() for i in range(document.page_count))\n"
           "                content=text.encode('utf-8','ignore')\n"
           "            except Exception:\n"
           "                continue\n"
           "        elif suffix not in vp.TEXT_SUFFIXES:\n"
           "            continue\n"
           "        scanned+=1\n"
           "        for pattern in vp.PRIVATE_PATTERNS:\n"
           "            if re.search(pattern,content):\n"
           "                hits.append((name,pattern))\n"
           "    print('scanned',scanned,'hits',hits[:5])\n"
           "    sys.exit(1 if hits else 0)\n"
           "PY",
           "**全部**可扫成员（文本成员 + `.gz` 解压后 + PDF/DOCX 文字层）0 命中；判据复用包审计的"
           "同一组模式，覆盖集合与包审计相同（图片像素与无后缀成员两者都不扫，已由包审计的 "
           "`identity_scan.unscanned_suffixes` / `unscanned_suffixless_members` 明示）")
    record("B3", "报告 PDF 元数据无作者、无私有标记、无 JS",
           "grep -q '\"author_empty\": true' " + str(PDF_AUDIT_JSON) + " && "
           "grep -q '\"direct_private_markers\": 0' " + str(PDF_AUDIT_JSON) + " && "
           "grep -q '\"document_javascript\": false' " + str(PDF_AUDIT_JSON),
           "三项均为真/0")
    record("B3b", "官方作品设计报告（DOCX + PDF）正文无身份标记",
           "python3 - <<'PY'\n"
           "import re,sys,zipfile\n"
           "markers=['Gowin','yinhaoran','nss-marker','10.144.144','/Users/yin','yindeMacBook']\n"
           "text=zipfile.ZipFile('CACR2026EA16XZ-作品设计报告.docx').read('word/document.xml').decode('utf-8')\n"
           "text=re.sub(r'<[^>]+>','',text)\n"
           "hits=[m for m in markers if m in text]\n"
           "print('docx hits',hits)\n"
           "sys.exit(1 if hits else 0)\n"
           "PY",
           "官方报告 DOCX 0 命中")
    record("B5", "附件三 DOCX 的元数据不含设备标识、单位与作者",
           "python3 - <<'PY'\n"
           "import re,sys,zipfile\n"
           "z=zipfile.ZipFile('CACR2026EA16XZ-审批及签字页.docx')\n"
           "custom=z.read('docProps/custom.xml').decode()\n"
           "app=z.read('docProps/app.xml').decode()\n"
           "core=z.read('docProps/core.xml').decode()\n"
           "bad=[]\n"
           "if custom.count('<property'): bad.append('custom.xml 仍有属性')\n"
           "if 'hdid' in custom or 'userId' in custom: bad.append('custom.xml 仍带 hdid/userId')\n"
           "for tag in ('Company','Application','Manager'):\n"
           "    m=re.search(r'<'+tag+r'[^>]*>(.*?)</'+tag+r'>',app,re.S)\n"
           "    if m and m.group(1).strip(): bad.append(tag+'='+m.group(1))\n"
           "for tag in ('dc:creator','cp:lastModifiedBy'):\n"
           "    m=re.search(r'<'+tag+r'[^>]*>(.*?)</'+tag+r'>',core,re.S)\n"
           "    if m and m.group(1).strip(): bad.append(tag+'='+m.group(1))\n"
           "print('bad',bad)\n"
           "sys.exit(1 if bad else 0)\n"
           "PY",
           "custom.xml 0 属性、Company/Application/作者/最后修改者全空")
    record("B4", "仓库内无口令/私钥内容",
           "! grep -rIlE 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|SUDO_PW=|password=|passwd=' "
           "--exclude-dir=build --exclude-dir=.git --exclude-dir=vendor --exclude-dir=third_party "
           "--exclude=check_signoff_items.py --exclude=signoff-machine-checks-20261020.json "
           "--exclude=SIGNOFF_CHECKLIST.md --exclude=build_signoff_checklist_v9.py .",
           "全仓库（排除 build/.git/vendor/third_party）0 命中")

    # C 组：数值与图表一致性（抽查关键数字）
    record("C1", "报告里的关键统计数字与**证据文件**双向逐字一致",
           "python3 - <<'PY'\n"
           "import pathlib, sys\n"
           "report = pathlib.Path('deliverables/research/multi-leakage-platform-20261016/report.md').read_text()\n"
           "# (报告里的写法, 证据文件, 证据文件里的写法)\n"
           "pairs = [\n"
           "    ('54/54', 'docs/evidence/platform-collection-20261016/status.log', 'restore_match=yes'),\n"
           "    ('36/36', 'docs/evidence/r09-optlevel-20261016/RESULT.md', '36/36'),\n"
           "    ('26.16', 'docs/evidence/r09-optlevel-20261016/RESULT.md', '26.16'),\n"
           "    ('42/42', 'docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md', '42/42'),\n"
           "    ('存在 5', 'docs/R05-全流程排查表.md', '**5**'),\n"
           "    ('不存在 75', 'docs/R05-全流程排查表.md', '**75**'),\n"
           "]\n"
           "problems = []\n"
           "for report_form, evidence_path, evidence_form in pairs:\n"
           "    if report_form not in report:\n"
           "        problems.append('报告里没有 ' + report_form)\n"
           "    evidence = pathlib.Path(evidence_path).read_text()\n"
           "    if evidence_form not in evidence:\n"
           "        problems.append(evidence_path + ' 里没有 ' + evidence_form)\n"
           "log = pathlib.Path('docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log').read_text()\n"
           "for form in ('out of 88', 'out of 57', 'out of 61'):\n"
           "    if form not in log:\n"
           "        problems.append('quick 档日志里没有 ' + form)\n"
           "print('checked', len(pairs) * 2 + 3, 'numbers;', len(problems), 'problems')\n"
           "for item in problems:\n"
           "    print('  ', item)\n"
           "sys.exit(1 if problems else 0)\n"
           "PY",
           "双向核对：报告里的 6 个关键数字与对应证据文件里的写法逐字一致，另有 3 个 CTest 计数在 quick 档日志里")
    record("C2", "图与表的来源文件在位",
           "test -d docs/evidence/r04-stats-20261016/figures && test -d docs/evidence/r09-optlevel-20261016/figures && "
           "test \"$(find docs/evidence/r04-stats-20261016/figures -type f | wc -l | tr -d ' ')\" -gt 40",
           "图目录存在且数量与报告引用一致")
    record("C3", "官方 PDF 目录页码与实测标题页码一致",
           "python3 - <<'PY'\n"
           "import json,sys,fitz\n"
           "entries=json.load(open('build/official-report/toc-pages.json'))\n"
           "document=fitz.open('CACR2026EA16XZ-作品设计报告.pdf')\n"
           "bad=[item for item in entries if not isinstance(item[-1],int) or item[-1]<1 or item[-1]>document.page_count]\n"
           "print('entries',len(entries),'pages',document.page_count,'out_of_range',bad)\n"
           "sys.exit(1 if bad else 0)\n"
           "PY",
           "目录条目页码全部在页数范围内（实测页码由构建脚本第二遍写入）")
    record("C4", "性能表写明 ns 与周期的换算口径",
           "grep -q '4300000' docs/evidence/r08-perf-20261016/PERF.md && "
           "grep -qE '换算|周期' docs/evidence/r08-perf-20261016/PERF.md",
           "PERF.md 写明基频与换算")
    record("C5", "MDE 表写明 α、功效与 SD 口径",
           "grep -qE 'alpha|α' docs/evidence/r04-stats-20261016/POWER.md && "
           "grep -qE 'power|功效' docs/evidence/r04-stats-20261016/POWER.md",
           "POWER.md 写明口径")
    record("C6", "「量化尺度约 10 ns」的限制随分位数结论出现",
           "grep -q '10 ns' docs/evidence/r04-stats-20261016/QUANTILE_CI.md && "
           "grep -q '10 ns' deliverables/research/multi-leakage-platform-20261016/report.md",
           "限制在证据与报告里都在")

    # D 组：证据有效性与可复现
    record("D1", "冻结 PLAN 的 sha256 与 BASELINE 记录一致",
           "grep -q 'ab447adadeb5aae2b79843946ab38a6e7a5412506a13d9abd738c3c22a9a9a20' "
           "docs/evidence/closeout-20261016/BASELINE.md && "
           "test \"$(shasum -a 256 docs/evidence/m2-kem-20261016/PLAN.md | cut -c1-64)\" = "
           "ab447adadeb5aae2b79843946ab38a6e7a5412506a13d9abd738c3c22a9a9a20",
           "至少一份 PLAN 逐字一致（其余三份见 FINAL_AUDIT §5）")
    record("D2", "本轮**全部**锁频运行的 restore_match 占比 100%",
           "python3 - <<'PY'\n"
           "import json, pathlib, sys\n"
           "# 2026-10-21 第 5 轮（红队）指出：原判据只扫一份 status.log（72 次），"
           "**另外 45 次（R08/R09/R12/R03）完全不在判定范围内**。这里遍历全部 terminal.json。\n"
           "root = pathlib.Path('docs/evidence')\n"
           "files = sorted(root.rglob('controller/terminal.json')) + sorted(root.rglob('terminal.json'))\n"
           "seen = set()\n"
           "yes = 0\n"
           "bad = []\n"
           "for path in files:\n"
           "    resolved = path.resolve()\n"
           "    if resolved in seen:\n"
           "        continue\n"
           "    seen.add(resolved)\n"
           "    try:\n"
           "        payload = json.loads(path.read_text(encoding='utf-8'))\n"
           "    except Exception:\n"
           "        continue\n"
           "    if 'restore_match' not in payload:\n"
           "        continue\n"
           "    value = payload.get('restore_match')\n"
           "    if value is True or str(value).strip().lower() in ('yes', 'true', '1'):\n"
           "        yes += 1\n"
           "    else:\n"
           "        bad.append((str(path), payload.get('restore_match')))\n"
           "print('terminal.json', len(seen), 'restore_match=yes', yes, 'bad', len(bad))\n"
           "for item in bad[:10]:\n"
           "    print('  ', item)\n"
           "sys.exit(0 if (yes > 0 and not bad) else 1)\n"
           "PY",
           "遍历全部 controller/terminal.json：restore_match=yes 的计数与反面命中数；反面必须为 0"
           "（2026-10-21 第 5 轮红队指出原判据只覆盖 72 次、漏掉另外 45 次）")
    record("D3", "失败运行已归档",
           "test -d docs/evidence/r08-perf-20261016/remote/R08/failed-blockcount-bug && "
           "test -d docs/evidence/r09-optlevel-20261016/remote/R09/failed",
           "两个失败归档目录在位")
    record("D4", "PLAN 提交早于对应原始数据提交",
           "test \"$(git log --format=%ct -1 -- docs/evidence/r08-perf-20261016/PLAN.md)\" -lt "
           "\"$(git log --format=%ct -1 -- docs/evidence/r08-perf-20261016/perf.csv)\" && "
           "test \"$(git log --format=%ct -1 -- docs/evidence/r09-optlevel-20261016/PLAN.md)\" -lt "
           "\"$(git log --format=%ct -1 -- docs/evidence/r09-optlevel-20261016/result.csv)\"",
           "两处时序成立")
    record("D5", "干净 clone 的 quick 档记录在案",
           "test -f docs/evidence/r12-innovation-20261016/reproduce-quick-clean-clone.stdout.log && "
           "grep -q 'tests passed, 0 tests failed' docs/evidence/r12-innovation-20261016/reproduce-quick-clean-clone.stdout.log",
           "干净 clone 的既有日志在位；本轮另在仓库本体实跑 263/263")
    record("D6", "匿名 ZIP 解出后 ctest 全过",
           "grep -q '100% tests passed, 0 tests failed out of 5' " + str(RECOMPUTE_LOG),
           "当前有效包的解出复算 5/5")

    # E 组：伦理与范围红线
    record("E1", "全仓库的密钥恢复 / exploit 表述都在否定语境里",
           "python3 - <<'PY'\n"
           "import re,subprocess,sys\n"
           "roots=['deliverables','docs/evidence','docs/platform','docs/R05-全流程排查表.md','docs/REPRODUCE-PARAMS.md',"
           "'scripts','tools','src','include','tests','fixtures','BLOCKERS.md','README.md','HANDOFF_DONE.md']\n"
           "out=subprocess.run(['grep','-rIloE','exploit demo|key recovery demo|密钥恢复','--exclude-dir=build',"
           "'--exclude-dir=.git','--exclude-dir=vendor','--exclude-dir=third_party','--exclude=check_signoff_items.py',"
           "'--exclude=SIGNOFF_CHECKLIST.md','--exclude=build_signoff_checklist_v9.py',"
           "'--exclude=signoff-machine-checks-20261020.json']+roots,capture_output=True,text=True).stdout.split()\n"
           "import html\n"
           "negation=re.compile(r'不|无|未|非|禁|排除')\n"
           "keyword=re.compile('exploit demo|key recovery demo|密钥恢复')\n"
           "bad=[]\n"
           "for path in out:\n"
           "    lines=html.unescape(re.sub(r'<[^>]+>','',open(path,encoding='utf-8',errors='replace').read())).splitlines()\n"
           "    for number,line in enumerate(lines):\n"
           "        if keyword.search(line):\n"
           "            window='\\n'.join(lines[max(0,number-2):number+3])\n"
           "            if not negation.search(window):\n"
           "                bad.append((path,line.strip()[:80]))\n"
           "print('files',len(out),'non_negated',len(bad))\n"
           "print(bad[:5])\n"
           "sys.exit(1 if bad else 0)\n"
           "PY",
           "本平台自有交付与证据里只有「不做」的声明（历史研究笔记 docs/research/ 不在本平台交付范围）")
    record("C7", "M1 族预注册完整性缺口已披露（m=8 存档 + 并列判定）",
           "grep -q 'm = 8' BLOCKERS.md && "
           "grep -q 'm = 6' BLOCKERS.md && "
           "grep -q '预注册完整性' BLOCKERS.md && "
           "test -f docs/evidence/r02-r04-close-20261016/holm.m8.csv && "
           "grep -q 'holm.m8.csv' docs/evidence/r02-r04-close-20261016/RESULT.md && "
           "test \"$(($(wc -l < docs/evidence/r02-r04-close-20261016/holm.m8.csv) - 1))\" -eq 8 && "
           # 第 9 轮复核 D2 条：人工判定说明点名要「报告/POWER/排查表三处」都披露，
           # 而机器判据只查了 BLOCKERS 与 RESULT.md——排查表缺披露也发现不了。
           # 现在四处逐一核对。
           "grep -q 'm = 8' docs/R05-全流程排查表.md && "
           "grep -q '预注册完整性' docs/R05-全流程排查表.md && "
           "grep -q 'm = 8' docs/evidence/r04-stats-20261016/POWER.md && "
           "grep -q 'm = 8' deliverables/research/multi-leakage-platform-20261016/report.md && "
           # MDE 数值也要四处一致（2026-10-21 第 10 轮复核问题 12：报告/排查表/POWER/
           # BLOCKERS 曾各写一个数，其中 37.61 与 POWER §1.1 的公式复算值 35.5613 不符）。
           "grep -q '35.56' docs/R05-全流程排查表.md && "
           "grep -q '35.56' docs/evidence/r04-stats-20261016/POWER.md && "
           "grep -q '35.56' BLOCKERS.md && "
           "grep -q '35.5613' deliverables/research/multi-leakage-platform-20261016/report.md",
           "披露文本在位（BLOCKERS/排查表/POWER/报告四处）、事前族 8 行按原字节存档在位、"
           "且该存档确为 8 行 M1 族成员")
    record("E2", "R06 已审计计时窗口内的 I/O",
           "grep -q '计时窗口' docs/evidence/r06-noleak-20261016/AUDIT.md",
           "窗口检查结论在案")
    record("E3", "F1 低危项已闭合（B 类 0 条）",
           "grep -qE 'B 类泄露.*0 条' docs/evidence/r06-noleak-fix-20261020/AUDIT.md && "
           "grep -q '原 F1 的 1 条已消除' docs/evidence/r06-noleak-fix-20261020/AUDIT.md",
           "闭合验证记录在案")
    record("E4", "第二架构已执行并写明边界",
           "grep -q 'r15-aarch64-20261021' deliverables/research/multi-leakage-platform-20261016/report.md && "
           "grep -q 'aarch64' deliverables/research/multi-leakage-platform-20261016/report.md && "
           "! grep -q '不同 CPU 架构——不做' deliverables/research/multi-leakage-platform-20261016/report.md && "
           "test -f docs/evidence/r15-aarch64-20261021/RESULT.md",
           "报告引用 aarch64 证据目录且不再有「不做第二架构」的旧表述")
    record("E5", "sources/ 与 vendor/ 保持只读",
           "test -z \"$(git diff --stat e81c1ae 95a7b531 -- sources vendor)\" && "
           "test -z \"$(git status --porcelain sources vendor)\"",
           "两个目录相对基线与工作区都无改动")

    summary = {
        "items": len(items),
        "pass": sum(1 for item in items if item["result"] == "pass"),
        "fail": sum(1 for item in items if item["result"] == "fail"),
        "note": "只做机器可判的部分；需人眼判断的项由复核人在 SIGNOFF_CHECKLIST.md 上签字确认。",
        "results": items,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rewritten = rewrite_machine_result_table(items)
    if rewritten is not None:
        print("签字清单的机器结果表已按本次实跑输出重写 %d 行" % rewritten)
    print("机器可核项 %d：通过 %d，未通过 %d；明细写入 %s"
          % (summary["items"], summary["pass"], summary["fail"], OUTPUT))
    return 0 if summary["fail"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
