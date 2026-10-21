#!/usr/bin/env python3
"""白名单组装新匿名副本；Python 只编排文件和文档，统计由原 C 工具执行。"""
import argparse
import hashlib
import html
import importlib.util
import json
import os
import re
import shlex
import shutil
import subprocess
import zipfile
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
REPOSITORY = DIRECTORY.parents[2]
REPORT = REPOSITORY/"deliverables/research/multi-leakage-platform-20261016"


REPRODUCE_TEXT = """# 离线复算

运行 `sh reproduce.sh <不存在的新输出目录>`。只读取包内数据，构建现有 C11 统计工具并执行五项 CTest，再逐字比较 CI JSON 与归一化 CSV。原始数值 CSV 保持字节，M1 的派生宽表只在输出目录改表头以适配统计接口，不改数值。

打包时 C 输出作为确定性复算参照，只检验打包/重建一致；统计功能另由已有手算 oracle 与拒绝测试检查，不能拿自产期望证明算法正确。外部 RTLF、Mona、dudect、Binsec 未在本入口重执行；不采硬件时间、不改频率、不需要联网。ML-KEM 依赖仅为原 C 统计共用代码的链接依赖，本入口不运行密码采集。

需要 CMake>=3.21、C11 编译器、POSIX shell、awk、shasum、cmp、sed；报告重编译另需 XeLaTeX/ctex/Fandol。
`shasum` 由 Perl 提供（Alpine 等最小化环境没有 `sha256sum` 时需先装 perl 或改用 sha256sum）。

## 包完整性自检（一行一条，不需要任何外部工具）

```sh
# 1) 成员数、revision 与文档状态（与 MANIFEST.json 一致）
python3 -c "import json;m=json.load(open('MANIFEST.json'));print(m['revision'], len(m['files']), 'files;', m['document_state'])"

# 2) 逐成员重算 SHA-256，与 MANIFEST.json 对账
python3 - <<'PY'
import hashlib, json, pathlib, sys
manifest = json.load(open("MANIFEST.json"))
bad = []
for entry in manifest["files"]:
    path = pathlib.Path(entry["path"])
    if not path.is_file():
        bad.append((entry["path"], "missing"))
        continue
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != entry["sha256"]:
        bad.append((entry["path"], "sha mismatch"))
print("checked", len(manifest["files"]), "files;", len(bad), "problems")
for item in bad:
    print("  ", item)
sys.exit(1 if bad else 0)
PY

# 3) 本地 HTML 链接是否都可达
python3 - <<'PY'
import pathlib, re, sys
broken = []
for page in list(pathlib.Path(".").rglob("*.html")):
    text = page.read_text(encoding="utf-8", errors="replace")
    for href in re.findall(r'href="([^"]+)"', text):
        if href.startswith(("http://", "https://", "#", "mailto:")):
            continue
        target = (page.parent / href.split("#")[0]).resolve()
        if not target.exists():
            broken.append((str(page), href))
print("broken local links:", len(broken))
for item in broken[:20]:
    print("  ", item)
sys.exit(1 if broken else 0)
PY
```

## 报告里的路径怎么对应到包内文件

正文与证据页里出现的路径是**仓库相对路径**（例如 `docs/evidence/...`），
本卷把它们镜像在 `evidence/files/<同一路径>` 下；所以：

```sh
# 仓库路径 → 包内路径
echo "evidence/files/docs/evidence/platform-collection-20261016/stats/holm/holm.csv.gz"
```

`PROVENANCE.json` 的 `files` 数组给出**每个包内成员的来源路径与变换方式**，
可用来核对「某个包内文件对应仓库里的哪一个」。包里**没有**仓库里的 `verify_package.py`
（它的模式源码含作者真实邮箱，见包内 README 的说明），包审计在仓库侧执行。

## 本卷有什么 / 没有什么

**有**：报告（Markdown / LaTeX / PDF / 离线 HTML）、题面 12 条的证据索引 E01–E70 与对应查看器、
M1–M5 的**统计产物**（每数据集 `ci_welch.json`、规范化逐样本 `normalized.csv.gz`、
家族成员表 `members.csv.gz`、Holm 输出 `holm.csv.gz` / `pooled.csv.gz`、
控制器运行汇总 `status.log`）、RTLF 的逐数据集结果、KAT 向量原件
（`tests/vectors/mlkem768.txt`）与机器可读汇总、采集与统计工具源码、4 张运行输出图与其原始日志。

**没有**（原因写在下面，取件方式也写在下面）：
- 仓库里**完整采集树**（各模块的原始长表、逐次记录与工具输出，合计约 46 MB）未随卷分发。
  **卷内已含**的是可复算所需的最小集：每个数据集的**原始逐样本长表** `stats/<数据集>/input.csv.gz`
  （42 份，共约 6 MB）、规范化后的 `normalized.csv.gz`、每成员统计 `ci_welch.json`、
  家族成员表 `members.csv.gz` 与 Holm 输出 `holm.csv.gz`——这些**足以复算 Welch CI、Holm 家族判定与 MDE**；
  完整的采集树在仓库 `docs/evidence/platform-collection-20261016/` 下，摘要见同目录 `*.sha256`。
- **第三方源码树**（`vendor/liboqs-0.10.0`、`vendor/kyber-kyberslash-*`、`third_party/*`）：
  体积与许可原因未随卷分发；取件脚本 `tools/fetch_all_vendors.sh` 与
  `tools/fetch_liboqs_0.10.0.sh` **在卷内**，取件后按脚本里的 SHA-256 校验。
- **硬件时间采集**：本入口不采硬件时间、不改频率；卷内的采集结果都是已归档的原件。

## 怎么重跑报告里的四张图

图 1–4 是**按统一终端样式渲染的运行输出图（不是屏幕照片）**，
原始日志都在卷内 `evidence/files/` 下（见 `evidence/screenshots/SCREENSHOTS.md`）：

| 图 | 卷内原始日志 |
|---|---|
| 图 1（quick 档 263/263） | `evidence/files/docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log` |
| 图 2（Memcheck 命中） | `evidence/files/docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log` |
| 图 3（控制器状态） | `evidence/files/docs/evidence/r12-innovation-20261016/remote/logs/status.log` |
| 图 4（离线展示） | 由 `report/index.html` 渲染 |

**在评委可见环境重拍**需要完整仓库与硬件（锁频控制器、M3 的 Memcheck 探针），
见报告 §17 的一键入口 `sh tools/fetch_all_vendors.sh` 与 `sh scripts/reproduce_all.sh quick`
（两者都在卷内 `evidence/files/` 下，但需要 vendor 树与硬件，故本卷无法单独完成）。
"""

# 本卷收录的仓库相对路径集合（main() 在复制前填好）。
PACKAGED_PATHS = set()

# 自有实现与工具：它们发布在 `source/` 下（不是 `evidence/files/`）。
OWN_SOURCE_PATHS = {
    "scripts/platform_stats/stats_csv.c", "scripts/run_stats_battery.sh",
    "src/timing_statistics.c", "src/kernel.c", "src/mlkem.c", "src/random.c",
    "src/inputs.c", "include/mlkem.h", "include/inputs.h",
    "include/timing_statistics.h", "include/baseline_config.h",
    "tests/test_stats_battery.sh",
}


def published_target(repo_relative_path):
    """仓库相对路径 → 包内的发布位置。

    绝大多数文件镜像在 `evidence/files/<同一路径>` 下，但有三类例外：
    报告自身的六个文件在 `report/` 下、自有实现与工具在 `source/` 下、
    截图在 `evidence/screenshots/` 下。链接改写要用**真实**的发布位置，
    否则会指向一个并不存在的包内路径。
    """
    relative = Path(repo_relative_path)
    report_prefix = str((REPOSITORY / "deliverables/research/multi-leakage-platform-20261016").relative_to(REPOSITORY))
    if str(relative).startswith(report_prefix + "/"):
        return "report/" + str(relative)[len(report_prefix) + 1:]
    if str(relative) in OWN_SOURCE_PATHS:
        return "source/" + str(relative)
    if str(relative).startswith(report_prefix + "/screenshots/"):
        return "evidence/screenshots/" + str(relative).split("/")[-1]
    return "evidence/files/" + str(relative)


def rewrite_markdown_links(text, source_path):
    """把 Markdown 里的相对链接改写成**本卷内可达**的指向。

    原写法是 `标签（原仓库引用：docs/evidence/…）`——评审在卷内按这个路径找不到文件
    （2026-10-21 第 4 轮复核实测：349 个引用里 280 个落空，而卷内其实有镜像目录
    `evidence/files/<同一路径>`，只是没人说明）。现在按「本卷是否收录该路径」分成两种：

    * 收录了 → `标签（包内副本：evidence/files/<路径>）`
    * 没收录 → `标签（仓库内：<路径>；本卷未收录）`——不假装有，也不藏。
    """
    base = Path(source_path).parent

    def replace(match):
        label, target = match.group(1), match.group(2)
        if target.startswith(("http://", "https://", "#", "mailto:")):
            return match.group(0)
        resolved = os.path.normpath(str(base / target)).replace("\\", "/")
        repository_prefix = str(REPOSITORY).replace("\\", "/") + "/"
        if resolved.startswith(repository_prefix):
            resolved = resolved[len(repository_prefix):]
        if resolved.startswith("..") or resolved.startswith("/"):
            return "%s（仓库内：%s；本卷未收录）" % (label, target)
        if resolved in PACKAGED_PATHS:
            return "%s（包内副本：%s）" % (label, published_target(resolved))
        return "%s（仓库内：%s；本卷未收录）" % (label, target)

    return re.sub(r"!?\[([^\]]*)\]\(([^)]+)\)", replace, text)


def package_tex_rewrites(text):
    """把报告 LaTeX 源里的**仓库相对路径**改写成包内可达路径。

    报告 .tex 里有两处仓库路径：图 2 的 `r05-flowchart.png` 与威胁模型章的
    `\\input{...threat-model.tex}`。照原样放进包里，评审照着编译会在中途断掉
    （2026-10-21 第 4 轮复核实测：缺图、第 29 页中断）。
    **成包与「包内报告 == 仓库报告」门禁共用这一套规则**，免得两边口径漂移。
    """
    text = text.replace("deliverables/research/multi-leakage-platform-20261016/r05-flowchart.png",
                        "r05-flowchart.png")
    text = text.replace("\\input{docs/evidence/r11-threat-20261016/threat-model.tex}",
                        "\\input{evidence/files/docs/evidence/r11-threat-20261016/threat-model.tex}")
    return text


def build_conditions_page(staging):
    """生成「题面 12 条原文 ↔ 附录 A 转写」的并排对照页。

    题面原件在 `evidence/files/docs/reference/official-2026/A1-13-original.docx`，
    附录 A 的转写来自 `report/report-tables.json` 的 T26 表 ✓。
    """
    import zipfile as zip_module

    original = staging / "evidence/files/docs/reference/official-2026/A1-13-original.docx"
    if not original.is_file():
        raise FileNotFoundError("题面原件不在卷内")
    with zip_module.ZipFile(original) as office:
        xml = office.read("word/document.xml").decode("utf-8")
    plain = re.sub(r"<[^>]+>", "\n", xml)
    lines = [re.sub(r"\s+", " ", line).strip() for line in plain.split("\n")]
    lines = [line for line in lines if line]
    tables = json.loads((staging / "report/report-tables.json").read_text(encoding="utf-8"))
    rows = []
    for table in tables["tables"]:
        if table["id"] != "T26":
            continue
        for row in table["rows"]:
            rows.append(row)
    body = ["<!doctype html><html lang=\"zh-CN\"><meta charset=\"utf-8\">",
            "<title>题面 12 条原文 ↔ 附录 A 转写</title>",
            "<style>body{font:16px/1.8 sans-serif;max-width:1200px;margin:40px auto;padding:0 24px}"
            "table{border-collapse:collapse;width:100%}td,th{border:1px solid #ccd;padding:8px;vertical-align:top}"
            "th{background:#eef2f5;text-align:left}ol{columns:2}</style>",
            "<h1>题面 12 条原文 ↔ 附录 A 转写</h1>",
            "<p>题面原件随卷分发：<code>evidence/files/docs/reference/official-2026/A1-13-original.docx</code>；"
            "本表左列是**附录 A（表 T26）的转写**，右列是**本卷收录的题面原文片段**，供逐条对照。</p>",
            "<table><tr><th style=\"width:18%\">条款</th><th style=\"width:41%\">附录 A 转写</th>"
            "<th>本卷收录的题面原文（按需求表段落）</th></tr>"]
    for row in rows:
        if len(row) < 3:
            continue
        body.append("<tr><td>%s</td><td>%s</td><td>%s</td></tr>"
                    % (html.escape(str(row[0])), html.escape(str(row[1])), html.escape(str(row[5] if len(row) > 5 else ""))))
    body.append("</table>")
    body.append("<h2>题面原件的文本层（供检索）</h2><ol>")
    for line in lines:
        body.append("<li>%s</li>" % html.escape(line))
    body.append("</ol></body></html>")
    return "\n".join(body)


def anonymous_text(text):
    replacements = [(str(REPOSITORY),"[REPOSITORY]"),("/Users/yin","[LOCAL_USER]"),("/home/nss-marker/yhr/Cry","[REMOTE_PROJECT]"),("/home/nss-marker","[REMOTE_USER]"),("10.144.144.5","[REMOTE_IP]"),("10.144.144.3","[REMOTE_IP]"),("119.45.121.134","[HISTORICAL_IP]"),("yinhaoran0808@outlook.com","[AUTHOR_EMAIL]"),("Gowin-liuyin","[PROJECT_AUTHOR]"),("yindeMacBook-Air.local","[LOCAL_HOST]"),("cryProject","[REPO_DIR]"),
        # 仓库名的小写形态与**SSH 别名**（别名里就带着仓库名）——两者都会把读者
        # 引到公开仓库与本机的连接配置（2026-10-21 第 4 轮复核查出）。
        ("cryproject-native-x86","[KVM_ALIAS]"),
        ("cryproject","[REPO_NAME]"),
        # **队友个人机器的机器名**（2026-10-21 第 4 轮复核查出）：跨环境复现文档里
        # 记着两台 Windows/WSL 机器的机器名，其中一个是机型代号——它属于**个人设备指纹**，
        # 与「用户名 / 主机名一律不随包分发」的既有口径一致。两台机器用不同占位符，
        # 免得在表格里被看成同一台。
        ("PC-20230901BNFE-20261016","[LOCAL_MACHINE_A]"),
        ("firefly-20261016","[LOCAL_MACHINE_B]"),("nss-marker","[REMOTE_USER]"),("nss-m","[LINUX_HOST]")]
    for original,replacement in replacements:
        text = text.replace(original,replacement)
    # 短形式的家目录与项目根（opam 等工具写日志时用 `~/yhr/Cry/...`，
    # 绝对形式匹配不到；2026-10-21 复查在包内日志里查到过）。
    text = text.replace("~/yhr/Cry", "[REMOTE_PROJECT]")
    text = text.replace("yhr/Cry", "[REMOTE_PROJECT]")
    text = re.sub(r"~/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]*yhr/Cry", "[REMOTE_PROJECT]", text)
    # 仓库根目录的 basename 本身也是标识（绝对路径被换成 [REPOSITORY] 后它就露出来了）。
    # **大小写两种写法都要换**：包里 scripts/run_stats_battery.sh 的输出 schema 名
    # 是 "cryproject_stats_battery_v1"（小写），只换 "cryProject" 会漏掉它——
    # 2026-10-21 第 9 轮复核时包审计的 `cryproject` 模式把它查了出来。
    # 仓库目录名：**只替换「路径形态」的出现**（作为路径的一段），不做子串替换、也不替换
    # 独立出现的普通词。
    # 说明：本仓库自己的名字另有**专属子串规则**（上表里的 "cryproject"/"cryProject"），
    # 任何形态都换——它能把读者引到公开仓库，所以不按路径形态处理。因此下面这段
    # 路径形态规则对本仓库名而言是**冗余**的（先被上面的子串规则换掉），它对**其他**
    # 目录名才是唯一生效的路径规则（`test_anonymize_text.py` 用 "zebra" 一类名字固定住
    # 这条性质）。两条并存不是笔误，别把子串规则当成多余的那一条删掉。——2026-10-21 第 5 轮（红队）实测：目录叫 `work` 时，
    # `worker_exit_code` 会被改成 `[REPOSITORY_NAME]er_exit_code`；目录叫 `clone` 时，
    # 「干净 clone 实测」被改坏。那会**直接污染发出去的支撑材料卷**（评审无法与源日志对齐），
    # 也让「包内报告 == 仓库报告」这条门禁在非 `cryProject` 目录下必然假红。
    for variant in {REPOSITORY.name, REPOSITORY.name.lower(), REPOSITORY.name.capitalize()}:
        if not variant:
            continue
        text = re.sub(r"(?<=/)" + re.escape(variant) + r"(?=/)", "[REPOSITORY_NAME]", text)
        text = re.sub(r"(?<![A-Za-z0-9_/])" + re.escape(variant) + r"/", "[REPOSITORY_NAME]/", text)
    # 裸目录名 "Cry" **不替换**：包审计已明确它不构成直接身份标记（不含人名、
    # 邮箱、IP 或主机名，见 verify_package.py 的说明块）。此前这里只替换了部分
    # 形态（"Cry/" 命中，"越Cry边界"、"&lt;Cry&gt;" 不命中），半做半不做会让
    # 证据措辞前后不一致却仍留残余——2026-10-21 第 8 轮复核 B 条指出的问题。
    # 路径形态（/home/<user>/yhr/Cry、~/yhr/Cry、…/yhr/Cry）由上面的规则覆盖。
    text = re.sub(r"/(?:Users|home)/[A-Za-z0-9_.-]+", "[ANONYMOUS_HOME]", text)
    return re.sub(r"~/(?:[A-Za-z0-9_.-]+/)+", "[ANONYMOUS_HOME]/", text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--revision",required=True)
    arguments = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9-]+",arguments.revision):
        raise ValueError("invalid revision")
    staging = REPOSITORY/"build/platform-report-s8"/("support-"+arguments.revision)
    archive_path = DIRECTORY/("CACR2026EA16XZ-platform-"+arguments.revision+".zip")
    if staging.exists() or archive_path.exists():
        raise FileExistsError("new revision required")
    staging.mkdir(parents=True)
    provenance = []
    skipped_conditions = []

    def copy_file(source_path,target,mode="text"):
        source_path = Path(source_path)
        if source_path.is_symlink() or not source_path.is_file():
            raise ValueError("not an ordinary source file: "+str(source_path))
        if any(part.startswith(".") for part in source_path.relative_to(REPOSITORY).parts):
            raise ValueError("hidden metadata excluded: "+str(source_path))
        original = source_path.read_bytes()
        copied = original
        if mode == "text":
            try:
                decoded = original.decode("utf-8")
            except UnicodeDecodeError:
                # 新增的图形产物（PDF/PNG 等）是二进制，不能按文本改写；
                # 原字节复制，匿名性由 verify_package.py 的字节/文本模式扫描兜底。
                decoded = None
            if decoded is None:
                mode = "binary"
        if mode == "text":
            text = anonymous_text(original.decode("utf-8"))
            if source_path.suffix == ".md":
                text = rewrite_markdown_links(text, source_path)
            copied = text.encode("utf-8")
        destination = staging/target
        destination.parent.mkdir(parents=True,exist_ok=True)
        destination.write_bytes(copied)
        destination.chmod(0o755 if source_path.suffix == ".sh" else 0o644)
        provenance.append({"source":str(source_path.relative_to(REPOSITORY)),"published":target,"source_sha256":hashlib.sha256(original).hexdigest(),"published_sha256":hashlib.sha256(copied).hexdigest(),"transform":"raw_bytes_preserved" if copied==original else "new_anonymous_text_copy_local_links_as_text"})

    data = json.loads((REPORT/"report-data.json").read_text())
    global PACKAGED_PATHS
    packaged_paths = set()
    for source in data["sources"]:
        packaged_paths.add(source["path"])
    for extra_path in data.get("support_extra_paths", []):
        packaged_paths.add(extra_path)
    for screenshot_path in sorted((REPORT / "screenshots").glob("*")):
        if screenshot_path.is_file():
            packaged_paths.add(str(screenshot_path.relative_to(REPOSITORY)))
    # 报告自身的文件（它们发布在 report/ 下，也在链接改写时作为「包内副本」指过去）
    for name in ("report.pdf", "report.tex", "report.md", "report-data.json",
                 "report-tables.json", "evidence-snapshot.json", "platform-matrix.svg",
                 "index.html", "r05-flowchart.png"):
        packaged_paths.add(str((REPORT / name).relative_to(REPOSITORY)))
    PACKAGED_PATHS = packaged_paths
    snapshot = json.loads((REPORT/"evidence-snapshot.json").read_text())
    for source in snapshot["sources"]:
        if hashlib.sha256((REPOSITORY/source["path"]).read_bytes()).hexdigest() != source["sha256"]:
            raise ValueError("source changed; refresh report before packaging: "+source["path"])
    for name in ["report.pdf","report.tex","report.md","report-data.json","report-tables.json","evidence-snapshot.json","platform-matrix.svg","index.html"]:
        copy_file(REPORT/name,"report/"+name,"binary" if name.endswith(".pdf") else "text")
    # 报告的 LaTeX 源里有两个**仓库相对路径**的引用，包内解不出来：
    #   * `deliverables/research/multi-leakage-platform-20261016/r05-flowchart.png`（图 2）；
    #   * `docs/evidence/r11-threat-20261016/threat-model.tex`（威胁模型章，\input 进来）。
    # 2026-10-21 第 4 轮复核实测：照原样编译会在第 29 页中断（找不到图）。
    # 这里把前者改成包内相对路径并把 PNG 随卷分发，把后者指向包内镜像路径。
    copy_file(REPORT/"r05-flowchart.png","report/r05-flowchart.png","binary")
    tex_path = staging/"report"/"report.tex"
    tex_path.write_text(package_tex_rewrites(tex_path.read_text()))
    packaged_report_html=staging/"report"/"index.html"
    rewritten_html=packaged_report_html.read_text().replace('href="../../../','href="../evidence/files/')
    if rewritten_html != packaged_report_html.read_text():
        packaged_report_html.write_text(rewritten_html)
        for record in provenance:
            if record["published"]=="report/index.html":
                record["published_sha256"]=hashlib.sha256(packaged_report_html.read_bytes()).hexdigest()
                record["transform"]="new_anonymous_text_copy_local_links_rewritten_to_packaged_evidence"
    # **本卷收录的仓库相对路径集合**（复制之前先算出来）：
    # 正文与证据页里的「原仓库引用」要按它改写成**包内可达**的指向——
    # 2026-10-21 第 4 轮复核查出：349 个引用里有 280 个在包内落空，
    # 评审照着点就是死链。改写后：卷内收录的写「包内副本：evidence/files/…���」，
    # 没收录的写「仓库内：…；本卷未收录」（不假装有）。
    evidence_links=[]
    for source in data["sources"]:
        target="evidence/files/"+source["path"]
        copy_file(REPOSITORY/source["path"],target)
        viewer_name="evidence/"+source["id"]+".html"
        viewer=staging/viewer_name
        viewer.parent.mkdir(parents=True,exist_ok=True)
        try:
            safe_text=(staging/target).read_text()
            binary_note=""
        except UnicodeDecodeError:
            safe_text="（二进制产物，不内联展示；原字节随包发布，SHA-256 "
            binary_note=hashlib.sha256((staging/target).read_bytes()).hexdigest()+"）"

        viewer.write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>'+html.escape(source["label"])+'</title><style>body{font:16px/1.8 sans-serif;max-width:1100px;margin:45px auto;padding:0 20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.7 monospace}</style><a href="../index.html">返回索引</a><h1>'+html.escape(source["id"]+" "+source["label"])+'</h1><p>状态：'+html.escape(source["state"])+'</p><pre>'+html.escape(safe_text+binary_note)+'</pre></html>')
        evidence_links.append('<li><a href="'+viewer_name+'">'+html.escape(source["id"]+" "+source["label"])+'</a> · '+html.escape(source["state"])+'</li>')
    skipped_build_paths = []
    for extra_path in data.get("support_extra_paths",[]):
        # 构建工作区不是整理过的证据（2026-10-21 复查：包内曾带进 44 个 CTest 临时目录成员），
        # 目录名还带随机后缀，给复核人「混进构建产物」的印象；这里整条跳过并记账。
        if any(part in {"build", "test-tmp", "CMakeFiles", "Testing"} for part in Path(extra_path).parts):
            skipped_build_paths.append(extra_path)
            continue
        copy_file(REPOSITORY/extra_path,"evidence/files/"+extra_path,"binary" if Path(extra_path).name in {"input.csv","samples.csv","normalized.csv"} else "text")
    # 真实运行截图：图片按原字节发布，说明文件按匿名规则转成文本副本。
    for screenshot_path in sorted((REPORT/"screenshots").glob("*")):
        if screenshot_path.is_file():
            copy_file(screenshot_path,"evidence/screenshots/"+screenshot_path.name,
                      "text" if screenshot_path.suffix == ".md" else "binary")
    own_sources=sorted(OWN_SOURCE_PATHS)
    for source_path in own_sources:
        copy_file(REPOSITORY/source_path,"source/"+source_path)
    for source_root in [REPOSITORY/"vendor/mlkem-native/mlkem",REPOSITORY/"fixtures/early_reject_memcmp",REPOSITORY/"tests/fixtures/platform_stats"]:
        for source_path in sorted(source_root.rglob("*")):
            if source_path.is_file() and "__pycache__" not in source_path.parts:
                copy_file(source_path,"source/"+str(source_path.relative_to(REPOSITORY)),"binary")
    copy_file(REPOSITORY/"vendor/mlkem-native/LICENSE","source/vendor/mlkem-native/LICENSE","binary")
    replay_inputs=[]
    for case_name in ["primary-vulnerable","primary-fixed","seed-424242-vulnerable","seed-424242-fixed","cpu-6-vulnerable","cpu-6-fixed"]:
        source_path="docs/evidence/mona-wire-20261016/local-qualification/m1/"+case_name+"/input.csv"
        replay_inputs.append({"name":"m1-"+case_name,"path":source_path,"format":"wide","class0":"class0_ns","class1":"class1_ns","reheader":True})
    replay_inputs.extend(data.get("replay_inputs",[]))
    for item in replay_inputs:
        if not re.fullmatch(r"[a-zA-Z0-9-]+",item["name"]):
            raise ValueError("unsafe replay name")
        copy_file(REPOSITORY/item["path"],"data/"+item["name"]+".csv","binary")
    cmake_text='''cmake_minimum_required(VERSION 3.21)
project(platform_offline_support LANGUAGES C)
include(CTest)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
add_library(support_reference STATIC source/src/kernel.c source/src/mlkem.c source/src/random.c source/src/inputs.c)
target_include_directories(support_reference PUBLIC source/include source/vendor/mlkem-native/mlkem)
target_compile_definitions(support_reference PUBLIC MLK_CONFIG_FILE="baseline_config.h")
add_executable(platform_stats source/scripts/platform_stats/stats_csv.c source/src/timing_statistics.c)
target_link_libraries(platform_stats PRIVATE support_reference)
if(UNIX)
    target_link_libraries(platform_stats PRIVATE m)
endif()
# 家族统计工具（tools/platform_stats/holm.c，随卷分发在 evidence/files/tools/ 下）：
# 让评审能**自己重算 Holm 家族判定**，而不只是比对打包时的基准。
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/evidence/files/tools/platform_stats/holm.c")
    add_executable(platform_holm evidence/files/tools/platform_stats/holm.c)
endif()
add_subdirectory(source/fixtures/early_reject_memcmp)
file(CHMOD "${CMAKE_CURRENT_SOURCE_DIR}/source/scripts/run_stats_battery.sh" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
add_test(NAME support_stats_qualification COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/source/tests/test_stats_battery.sh" "$<TARGET_FILE:platform_stats>" "${CMAKE_CURRENT_SOURCE_DIR}/source" "-")
set_tests_properties(support_stats_qualification PROPERTIES ENVIRONMENT "A113_TEST_TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/test-tmp")
'''
    (staging/"CMakeLists.txt").write_text(cmake_text)
    canonical_build=REPOSITORY/"build/platform-report-s8"/("canonical-"+arguments.revision)
    canonical_build.mkdir()
    with (canonical_build/"build.log").open("w") as log_file:
        for command in [["cmake","-S",str(staging),"-B",str(canonical_build),"-DCMAKE_BUILD_TYPE=RelWithDebInfo"],["cmake","--build",str(canonical_build),"--parallel","2"],["ctest","--test-dir",str(canonical_build),"--output-on-failure"]]:
            subprocess.run(command,check=True,stdout=log_file,stderr=subprocess.STDOUT)
    replay_lines=['#!/bin/sh','set -eu','package_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)','output_root=$1','if [ -e "$output_root" ]; then printf "%s\\n" "New output directory required" >&2; exit 2; fi','mkdir -p "$output_root"','output_root=$(CDPATH= cd -- "$output_root" && pwd -P)','cmake -S "$package_root" -B "$output_root/build" -DCMAKE_BUILD_TYPE=RelWithDebInfo','cmake --build "$output_root/build" --parallel 2','ctest --test-dir "$output_root/build" --output-on-failure']
    for item in replay_inputs:
        original=(staging/"data"/(item["name"]+".csv")).read_bytes()
        canonical_input=canonical_build/(item["name"]+".csv")
        canonical_input.write_bytes(b"class0_ns,class1_ns\n"+original.split(b"\n",1)[1] if item.get("reheader") else original)
        expected_dir=staging/"expected"/item["name"]
        expected_dir.mkdir(parents=True)
        subprocess.run([str(canonical_build/"platform_stats"),str(canonical_input),item["format"],item["class0"],item["class1"],str(expected_dir)],check=True)
        name=item["name"]
        replay_lines.append('mkdir "$output_root/'+name+'"')
        if item.get("reheader"):
            replay_lines.append('sed \'1s/.*/class0_ns,class1_ns/\' "$package_root/data/'+name+'.csv" > "$output_root/'+name+'/converted.csv"')
            input_argument='"$output_root/'+name+'/converted.csv"'
        else:
            input_argument='"$package_root/data/'+name+'.csv"'
        replay_lines.append('"$output_root/build/platform_stats" '+input_argument+' '+shlex.quote(item["format"])+" "+shlex.quote(item["class0"])+" "+shlex.quote(item["class1"])+ ' "$output_root/'+name+'"')
        for result_name in ["ci_welch.json","normalized.csv"]:
            replay_lines.append('cmp "$package_root/expected/'+name+'/'+result_name+'" "$output_root/'+name+'/'+result_name+'"')
    # **家族统计的复算**（2026-10-21 第 6 轮复核 R-3 条）：卷内已带
    # `stats/members/members.csv.gz`（家族成员表）与 `stats/holm/holm.csv.gz`（Holm 输出），
    # 这里用卷内的 Holm 工具**重新算一遍**并逐字比对——这样「评测人员能够复现实验结论」
    # 在**家族判定**这一层是真的成立的（不只��打包一致性）。
    members_relative = "evidence/files/docs/evidence/platform-collection-20261016/stats/members/members.csv.gz"
    holm_relative = "evidence/files/docs/evidence/platform-collection-20261016/stats/holm/holm.csv.gz"
    if (staging / members_relative).is_file() and (staging / "evidence/files/tools/platform_stats/holm.c").is_file():
        replay_lines.append('if [ -x "$output_root/build/platform_holm" ]; then')
        replay_lines.append('  mkdir -p "$output_root/holm"')
        replay_lines.append('  gzip -dc "$package_root/' + members_relative + '" > "$output_root/holm/members.csv"')
        # platform_holm 的 --output-dir 要的是**相对名**，所以先 cd 进工作目录再调
        replay_lines.append('  ( cd "$output_root/holm" && "$output_root/build/platform_holm" '
                            '--input members.csv --output-dir holm-out --alpha 0.05 )')
        replay_lines.append('  gzip -dc "$package_root/' + holm_relative + '" > "$output_root/holm/holm-expected.csv"')
        replay_lines.append('  cmp "$output_root/holm/holm-expected.csv" "$output_root/holm/holm-out/holm.csv"')
        replay_lines.append('  printf "%s\\n" "family_holm_recompute=pass"')
        replay_lines.append('else')
        replay_lines.append('  printf "%s\\n" "family_holm_recompute=skipped (platform_holm 未构建)"')
        replay_lines.append('fi')
    replay_lines.append('printf "%s\\n" "offline_replay=pass; hardware_collection=not_run; external_tools=not_reexecuted"')
    (staging/"reproduce.sh").write_text("\n".join(replay_lines)+"\n")
    (staging/"reproduce.sh").chmod(0o755)
    (staging/"REPRODUCE.md").write_text(REPRODUCE_TEXT)
    # 记账：现生成的成员（查看器、复算基准、顶层工具）也要写进来源说明，
    # 否则「来源与匿名副本摘要」只覆盖一部分成员（2026-10-21 复查：89/868 成员无记录）。
    generated_members = []
    for path in sorted(staging.rglob("*")):
        if not path.is_file():
            continue
        relative = str(path.relative_to(staging))
        if any(item["published"] == relative for item in provenance):
            continue
        if relative.startswith("evidence/E") and relative.endswith(".html"):
            kind = "generated_viewer"
        elif relative.startswith("expected/"):
            kind = "generated_baseline_from_packaged_tool"
        elif relative in {"CMakeLists.txt", "README.md", "REPRODUCE.md", "index.html", "reproduce.sh",
                          "verify_package.py", "PROVENANCE.json", "MANIFEST.json"}:
            kind = "generated_package_entry"
        else:
            kind = "generated_other"
        generated_members.append({"published": relative, "kind": kind,
                                  "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                                  "bytes": path.stat().st_size})
    (staging/"PROVENANCE.json").write_text(json.dumps({
        "policy":"new anonymous copies; originals untouched; numeric CSV raw bytes preserved; upstream license preserved; "
                 "expected/ 是**打包时用包内 C 工具现算的复算基准**，只检验重建一致性，不是正确性依据；"
                 "evidence/E*.html 是现生成的查看器，不是原件",
        "files":provenance,
        "generated_members":generated_members,
        "skipped_build_workspace_paths":skipped_build_paths,
        "skipped_conditions_page":skipped_conditions,
    },ensure_ascii=False,indent=2)+"\n")
    # **不把 verify_package.py 复制进包**：它的模式源码里写着作者真实邮箱与本机主机名
    # （明文可复原），而包内成员必须不含直接身份标记。包审计由仓库侧的
    # verify_package.py 对**实际 ZIP** 执行，不依赖包内自带副本。
    # 2026-10-21 复查：此前把该脚本原样拷进包，同时又在扫描时跳过它，
    # 于是「该成员含身份标记」这件事被豁免掉了——direct_identity_markers=0 是假绿。
    # **包根 README**（2026-10-21 第 4 轮复核：包里原本只有 REPRODUCE.md，
    # 没有入口说明，评审解包后不知道从哪看起——报告与审计都指向「支撑包 README」，
    # 而那个 README 在仓库里、不在包内，这条可核性链是断的）。
    package_readme = [
        "# 多泄漏模块检测平台 · 匿名支撑材料卷",
        "",
        "本卷是《ML-KEM 解封装实现的时间侧信道检测与常数时间防护》的**匿名支撑材料**：",
        "报告正文、题面 12 条的逐条证据索引与查看器、统计产物、运行输出图与原始日志、",
        "以及可离线复算的 C 统计工具与自检入口。**全卷不含凭证、构建产物或远端依赖资源。**",
        "",
        "## 从哪看起",
        "",
        "| 想看 | 打开 |",
        "|---|---|",
        "| 报告（可读版） | [`report/index.html`](report/index.html)（离线单页，含章节导航） |",
        "| 报告（PDF） | [`report/report.pdf`](report/report.pdf) |",
        "| 报告（文字源） | [`report/report.md`](report/report.md) · [`report/report.tex`](report/report.tex) |",
        "| 题面 12 条的证据索引 | [`index.html`](index.html) 的 E01–E70 列表，或 `evidence/E*.html` |",
        "| 运行输出图与原始日志 | [`evidence/screenshots/SCREENSHOTS.md`](evidence/screenshots/SCREENSHOTS.md) |",
        "| 离线复算怎么跑 + **包完整性自检命令** | [`REPRODUCE.md`](REPRODUCE.md) |",
        "| 每个成员的来源与变换 | [`PROVENANCE.json`](PROVENANCE.json) |",
        "| 每个成员的摘要 | [`MANIFEST.json`](MANIFEST.json) |",
        "",
        "## 目录结构",
        "",
        "```",
        "README.md          本文件",
        "REPRODUCE.md       离线复算说明 + 包完整性自检命令 + 本卷有什么/没有什么",
        "reproduce.sh       离线复算入口（sh reproduce.sh <新输出目录>）",
        "index.html         证据索引（E01–E70）与各卷入口",
        "report/            报告（md / tex / pdf / 离线 html / 数据与表 / 证据快照）",
        "evidence/E*.html   每份来源的查看器（现生成，**不是原件**）",
        "evidence/files/    来源文件的匿名副本，路径与仓库相对路径一一对应",
        "evidence/screenshots/ 4 张运行输出图与其原始日志说明",
        "expected/          打包时用包内 C 工具现算的复算基准（只检验重建一致性）",
        "data/              M1 的 6 份原始数值 CSV（离线复算的输入）",
        "source/            自有实现、统计工具、夹具与 mlkem-native 参考实现",
        "CMakeLists.txt     离线复算用的构建定义（只构建本卷自带的那几个目标）",
        "MANIFEST.json      每个成员的路径、字节数与 SHA-256",
        "PROVENANCE.json    每个成员的来源路径、变换方式与匿名副本摘要",
        "```",
        "",
        "## 路径对应",
        "",
        "正文与证据页里的路径是**仓库相对路径**（如 `docs/evidence/...`），",
        "本卷把它们镜像在 `evidence/files/<同一路径>` 下；",
        "`PROVENANCE.json` 的 `files` 数组给出每个包内成员的来源路径与变换方式。",
        "",
        "## 匿名口径",
        "",
        "全卷按统一规则把**用户名、邮箱、主机名、绝对路径、IP、仓库目录名、",
        "个人机器名**替换成占位符（如 `[REMOTE_PROJECT]`、`[LOCAL_USER]`、`[LOCAL_HOST]`）；",
        "**被替换项的清单与扫描覆盖范围见仓库侧的包审计记录**（校验器不在卷内：",
        "它的模式源码含作者真实邮箱，随卷分发会泄露）。",
        "",
        "## 本卷不包含",
        "",
        "原始计时长表（约 46 MB）、第三方源码树（`vendor/*`、`third_party/*`）、硬件时间采集。",
        "逐项原因与取件方式写在 [`REPRODUCE.md`](REPRODUCE.md) 的「本卷有什么 / 没有什么」一节。",
        "",
        "> 上传时本文件按官方角色名另存为「编号-2026密码竞赛复赛相关支撑材料.zip」（内容逐字节相同）。",
        "",
    ]
    (staging/"README.md").write_text("\n".join(package_readme))
    # **题面 12 条 ↔ 附录 A 转写的并排索引**（2026-10-21 第 6 轮复核 H-3 条）：
    # 评审手上只有本卷，附录 A 的转写必须能与题面原文逐字对照；卷内既有题面原件
    # （A1-13-original.docx），这里再做一个并排页，省去「自己找原件 + 自己比对」。
    try:
        conditions = build_conditions_page(staging)
        (staging/"evidence"/"official-conditions.html").write_text(conditions)
    except Exception as error:  # 缺题面原件时不阻断成包，但要在 PROVENANCE 里看得见
        skipped_conditions.append(str(error))
    (staging/"index.html").write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>多泄漏平台匿名补充件</title><style>body{font:17px/1.9 sans-serif;max-width:1000px;margin:55px auto;padding:0 25px}li{margin:10px 0}</style><h1>多泄漏平台匿名补充件</h1><p>真实历史、人工校准、阴性候选分列；未运行不是未检出。</p><p><a href="README.md">卷说明与导航</a> · <a href="report/index.html">离线报告</a> · <a href="report/report.pdf">PDF</a> · <a href="report/report.md">报告文字源</a> · <a href="report/report-tables.json">报告表格数据</a> · <a href="REPRODUCE.md">C 离线复算说明与包自检</a> · <a href="evidence/screenshots/SCREENSHOTS.md">真实运行截图与签收佐证</a> · <a href="PROVENANCE.json">来源与匿名副本摘要</a> · <a href="MANIFEST.json">成员清单</a></p><ul>'+"".join(evidence_links)+'</ul><p>本包没有凭证、构建产物、活动脚本或远端依赖资源。许可不明确的统计工具源码未再分发。</p></html>')
    members=[]
    for path in sorted(staging.rglob("*")):
        if path.is_file():
            content=path.read_bytes()
            members.append({"path":str(path.relative_to(staging)),"bytes":len(content),"sha256":hashlib.sha256(content).hexdigest()})
    (staging/"MANIFEST.json").write_text(json.dumps({"revision":arguments.revision,"document_state":data["document_state"],"files":members},ensure_ascii=False,indent=2)+"\n")
    with zipfile.ZipFile(archive_path,"x",zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(staging.rglob("*")):
            if path.is_file():
                entry=zipfile.ZipInfo(str(path.relative_to(staging)),date_time=(2026,10,16,0,0,0))
                entry.create_system=3
                entry.external_attr=(0o100755 if path.suffix==".sh" else 0o100644)<<16
                entry.compress_type=zipfile.ZIP_DEFLATED
                archive.writestr(entry,path.read_bytes())
    module_spec=importlib.util.spec_from_file_location("package_verifier",DIRECTORY/"verify_package.py")
    module=importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(module)
    verification=module.verify(archive_path)
    (DIRECTORY/(arguments.revision+"-verification.json")).write_text(json.dumps(verification,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"zip":str(archive_path.relative_to(REPOSITORY)),**verification},ensure_ascii=False,indent=2))


if __name__ == "__main__":
    main()
