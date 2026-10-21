#!/usr/bin/env python3
"""把「当前有效包」相关的**当前状态声明**统一指向某一个 revision。

用法：python3 scripts/point_current_package.py finalNN-YYYYMMDD

**只改当前状态，不碰历史**（2026-10-21 第 7 轮 E-1 与第 8 轮 A1/A2 条的教训）：

- 包 README：只改头部「当前有效：`finalNN-...`」、「当前有效包」表的
  「文件」行与「SHA-256」行，以及「送审以这一行为准」那一行；
  **「历次成包」表里的历史行原字节不动**（历史行各自有自己的摘要，
  串包名会让历史行声称别的包的摘要）。
- `HANDOFF_DONE.md`：只改「**匿名支撑包**：`...zip`」与带「（**当前有效**）」
  标记的那一处；历史节（final5 当时的时点快照）原字节保留。

用法不对、或 README 声明的包与包审计 JSON 不一致时明确报错，不静默改。
"""
import hashlib
import json
import re
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
README = SUPPORT / "README.md"
HANDOFF = REPOSITORY / "HANDOFF_DONE.md"


def section(text, heading):
    """取出某个二级标题小节的正文（不含标题行本身）。

    注意：下一节的分界要用「换行 + ## 」来找；直接 find("## ") 会命中本节标题自身。
    """
    start = text.find(heading)
    if start < 0:
        raise SystemExit("README 里找不到小节：%s" % heading)
    end = text.find("\n## ", start + len(heading))
    if end < 0:
        end = len(text)
    return start, end


def update_readme(revision, package, verification, package_sha):
    text = README.read_text(encoding="utf-8")
    start, end = section(text, "## 当前有效包")
    block = text[start:end]
    block = re.sub(r"\|\s*文件\s*\|\s*`[^`]*`\s*\|",
                   "| 文件 | `%s` |" % package.name, block, count=1)
    block = re.sub(r"\|\s*SHA-256\s*\|\s*`[0-9a-f]{64}`\s*\|",
                   "| SHA-256 | `%s` |" % package_sha, block, count=1)
    block = re.sub(r"\*\*\d+ / \d+ / \d+\*\*",
                   "**%d / %d / %d**" % (verification["members"],
                                        verification["hashed_members"],
                                        verification["local_html_links"]), block, count=1)
    block = re.sub(r"zip-recompute-final\d+\.log",
                   "zip-recompute-%s.log" % re.sub(r"-\d{8}$", "", revision), block)
    # 日期后缀要认**任意** \\d{8}：写死 -20261021 时，final32-20261020 这类
    # revision 的回放原件路径永远匹配不上（2026-10-21 第 9 轮复核 A6 条）。
    block = re.sub(r"docs/evidence/platform-report-20261016/final\d+-\d{8}/",
                   "docs/evidence/platform-report-20261016/%s/" % revision, block)
    text = text[:start] + block + text[end:]

    text = re.sub(r"当前有效[：:]\s*`+(final[0-9]+-[0-9]{8})`+",
                  "当前有效：`%s`" % revision, text, count=1)
    # 「送审以这一行为准」那行也是**当前状态**声明：换包时必须一起更新，
    # 否则它会继续指向上一版包（2026-10-21 第 8 轮复核 A2 条）。
    text = re.sub(r"(送审以这一行为准[^\n]*当前有效包 `)final[0-9]+-[0-9]{8}(`)",
                  r"\g<1>%s\g<2>" % revision, text, count=1)
    text = re.sub(r"(送审以这一行为准[^\n]*SHA-256 `)[0-9a-f]{64}(`)",
                  r"\g<1>%s\g<2>" % package_sha, text, count=1)
    README.write_text(text, encoding="utf-8")


def update_handoff(revision, package, verification, package_sha):
    text = HANDOFF.read_text(encoding="utf-8")
    # 只改「**匿名支撑包**：`...zip`」那处；历史节（已被取代的时点快照）不动。
    text = re.sub(r"\*\*匿名支撑包\*\*：`CACR2026EA16XZ-platform-final\d+-2026\d+\.zip`",
                  "**匿名支撑包**：`%s`" % package.name, text, count=1)
    text = re.sub(r"`[0-9a-f]{64}`（\*\*当前有效\*\*）",
                  "`%s`（**当前有效**）" % package_sha, text, count=1)
    text = re.sub(r"\*\*\d+ 成员\*\*、\d+ 摘要、\d+ 个本地 HTML 链接",
                  "**%d 成员**、%d 摘要、%d 个本地 HTML 链接" % (
                      verification["members"], verification["hashed_members"],
                      verification["local_html_links"]), text, count=1)
    HANDOFF.write_text(text, encoding="utf-8")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("用法：python3 scripts/point_current_package.py finalNN-YYYYMMDD")
    revision = sys.argv[1]
    package = SUPPORT / ("CACR2026EA16XZ-platform-" + revision + ".zip")
    verification = json.loads(
        (SUPPORT / (revision + "-verification.json")).read_text(encoding="utf-8"))
    package_sha = hashlib.sha256(package.read_bytes()).hexdigest()
    if verification.get("zip_sha256") != package_sha:
        raise SystemExit("包摘要与包审计 JSON 不一致：" + revision)
    update_readme(revision, package, verification, package_sha)
    update_handoff(revision, package, verification, package_sha)
    print("当前有效包已指向 %s（%d 成员 / %d 摘要 / %d 链接，sha %s）"
          % (revision, verification["members"], verification["hashed_members"],
             verification["local_html_links"], package_sha[:12]))
    print("（历史成包表与交接历史节未改）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
