#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核对匿名包内的报告与仓库里的报告**同源**。

为什么要有这个门禁：包里随附的报告是**匿名副本**（路径与身份串按包内规则替换过），
所以两者不可能逐字节相同；但**换算之后必须逐字一致**——否则包里就是一份**旧报告**，
评审拿到的证据与仓库里的对不上（2026-10-21 复查轮实测出现过「报告重出但包没重建」的不一致）。

做法：用 `build_support.py` 的同一套 `anonymous_text()` 规则把仓库的报告换算成包内应有的样子，
再与包内成员逐字比对；报告的六个载体与四张截图一并核对。

用法：
  python3 scripts/check_package_parity.py
退出码 0 表示同源。
"""

import importlib.util
import json
import re
import sys
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
REPORT = REPOSITORY / "deliverables/research/multi-leakage-platform-20261016"


def load_anon():
    spec = importlib.util.spec_from_file_location("support_build", str(SUPPORT / "build_support.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.anonymous_text, getattr(module, "package_tex_rewrites", None), module


def packaged_paths_from(archive):
    """从包自己的 PROVENANCE.json 取「仓库路径 → 包内发布位置」的映射。

    成包脚本按这份集合把正文里的链接改写成「包内副本 / 本卷未收录」；
    同源门禁必须用**同一套**规则复算，否则包内与仓库永远对不上。
    """
    try:
        provenance = json.loads(archive.read("PROVENANCE.json"))
    except (KeyError, ValueError):
        return {}, set()
    mapping = {item["source"]: item["published"]
               for item in provenance.get("files", []) if item.get("source")}
    return mapping, set(mapping)


def expected_bytes(path, anonymize, tex_rewrites=None, support_module=None, packaged=None, publish_map=None):
    original = path.read_bytes()
    try:
        text = original.decode("utf-8")
    except UnicodeDecodeError:
        return original
    text = anonymize(text)
    if path.suffix == ".md":
        if support_module is not None:
            # 与成包脚本**同一套**链接改写规则（包内副本 / 本卷未收录）
            support_module.PACKAGED_PATHS = set(packaged or ())
            if publish_map:
                # 用包自己的「仓库路径 → 发布位置」映射覆盖成包脚本的默认规则
                support_module.published_target = lambda relative: publish_map.get(
                    relative, "evidence/files/" + relative)
            text = support_module.rewrite_markdown_links(text, path)
        else:
            text = re.sub(r"!?\[([^\]]*)\]\((?!https?://)([^)]+)\)", r"\1（原仓库引用：\2）", text)
    if path.suffix == ".tex" and tex_rewrites is not None:
        # 报告 .tex 里两处仓库相对路径在包内被改写（成包脚本与本门禁共用同一套规则）。
        text = tex_rewrites(text)
    return text.encode("utf-8")


def current_revision():
    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    for pattern in (r"当前有效[：:]\s*`?(final\d+-\d{8})",
                    r"当前最新已核验包为 \[(final\d+-\d{8})\]",
                    r"\|\s*文件\s*\|\s*`[^`]*-(final\d+-\d{8})\.zip`"):
        match = re.search(pattern, readme)
        if match is not None:
            return match.group(1)
    raise SystemExit("支撑包 README 里找不到当前有效包的声明")


def main():
    anonymize, tex_rewrites, support_module = load_anon()
    revision = current_revision()
    package = SUPPORT / ("CACR2026EA16XZ-platform-" + revision + ".zip")
    if not package.is_file():
        raise SystemExit("当前有效包不存在：" + str(package))

    failures = []
    with zipfile.ZipFile(package) as archive:
        members = set(archive.namelist())
        publish_map, packaged = packaged_paths_from(archive)
        for name, local in (("report/report.md", REPORT / "report.md"),
                            ("report/report.tex", REPORT / "report.tex"),
                            ("report/index.html", REPORT / "index.html"),
                            ("report/report-data.json", REPORT / "report-data.json"),
                            ("report/report-tables.json", REPORT / "report-tables.json"),
                            ("report/evidence-snapshot.json", REPORT / "evidence-snapshot.json")):
            if name not in members:
                failures.append("包内缺成员：" + name)
                continue
            expected = expected_bytes(local, anonymize, tex_rewrites, support_module, packaged, publish_map)
            if name == "report/index.html":
                expected = expected.replace(b'href="../../../', b'href="../evidence/files/')
            if expected != archive.read(name):
                failures.append("包内与仓库不一致（换算后仍不同）：" + name)
        for shot in sorted((REPORT / "screenshots").glob("*")):
            if not shot.is_file():
                continue
            member = "evidence/screenshots/" + shot.name
            if member not in members:
                failures.append("包内缺截图：" + shot.name)
            elif archive.read(member) != shot.read_bytes():
                failures.append("包内截图与仓库不一致：" + shot.name)

    print("当前有效包：%s" % package.name)
    if failures:
        print("不一致：")
        for item in failures:
            print("  - " + item)
        print("→ 包与仓库不同源：重跑 `build_support.py --revision <新号>` 再核对。")
        return 1
    print("通过：包内报告与截图与仓库同源（按同一套匿名规则换算后逐字一致）。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
