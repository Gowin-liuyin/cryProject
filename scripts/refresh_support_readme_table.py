#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""重新生成支撑包 README 里的「历次成包」表（SHA-256 与成员数一律取自各自的验证 JSON）。

为什么要有这个脚本：2026-10-21 的独立复核发现那张表里 `final2` / `final3` 两行的
SHA-256 被抄成了别的包的摘要——**手抄的摘要列不可核**。这里改成从
`final*-verification.json` 逐个读出来生成，抄错的可能从此消失。

同时把**明确作废**的 revision 标出来（当前只有 final12：包内离线 HTML 有坏链接，
包审计失败；以及 final24：包内分发了含真实邮箱与本机主机名的校验器副本，门禁豁免了它）。
"""

import json
import re
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
README = SUPPORT / "README.md"

# 明确作废的 revision → 作废原因
RETIRED = {
    "final12-20261021": "**作废**：包内离线 HTML 有坏链接（`<a href=\"3\">`），包审计失败",
    "final24-20261021": "**作废**：包内分发了含真实邮箱与本机主机名的校验器副本，门禁豁免了它",
}


def main():
    rows = []
    for verification in sorted(SUPPORT.glob("final*-verification.json")):
        revision = verification.name[:-len("-verification.json")]
        payload = json.loads(verification.read_text(encoding="utf-8"))
        if payload.get("status") != "pass":
            continue
        rows.append((revision, payload["members"], payload["hashed_members"],
                     payload["local_html_links"], payload["zip_sha256"]))
    def revision_number(revision):
        match = re.search(r"final(\d+)-", revision)
        return int(match.group(1)) if match else 0

    rows.sort(key=lambda item: revision_number(item[0]))

    # 只放**数据行**：替换时原有的表头与分隔行（match.group(1)+group(2)）会被保留，
    # 这里再带一份就会变成「表头/分隔/表头/分隔/数据」
    # （2026-10-21 第 9 轮复核 A2 条）。
    lines = []
    for revision, members, hashed, links, digest in rows:
        status = RETIRED.get(revision, "已核验")
        lines.append("| `%s` | %d | %d | %d | `%s` | %s |"
                     % (revision, members, hashed, links, digest, status))
    table = "\n".join(lines)

    text = README.read_text(encoding="utf-8")
    pattern = re.compile(r"(\| revision \| 成员 \| 摘要 \| 本地 HTML 链接 \| SHA-256 \| 状态 \|\n)"
                         r"(\|---\|---:\|---:\|---:\|---\|---\|\n)"
                         r"((?:\|.*\n)+)")
    if not pattern.search(text):
        raise SystemExit("支撑包 README 里找不到历次成包表")
    text = pattern.sub(lambda match: match.group(1) + match.group(2) + table + "\n", text, count=1)

    # 首屏补一句「唯一送审包」，避免「目录里最新的那个」的歧义
    current = rows[-1]
    line = ("\n> **送审以这一行为准，其余包一律不得上传**：当前有效包 `%s`（SHA-256 `%s`）。\n"
            % (current[0], current[4]))
    if "送审以这一行为准" not in text:
        marker = "## 匿名化口径"
        if marker in text:
            text = text.replace(marker, line + "\n" + marker, 1)
    README.write_text(text, encoding="utf-8")
    print("历次成包表已按各自的验证 JSON 重建（%d 个 revision）" % len(rows))
    for revision, *_ in rows:
        if revision in RETIRED:
            print("  标作废：", revision, "—", RETIRED[revision])


if __name__ == "__main__":
    main()
