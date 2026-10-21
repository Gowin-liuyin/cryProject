#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成「上传清单」：把三件套按官方要求的角色名做**只改名的副本**，并登记各自摘要。

背景（2026-10-21 复查）：官方通知写「文件以系统编号命名」，`docs/evidence/aris-report-synthesis-20261010/REQUIREMENTS_AUDIT.md:68`
进一步给出三个角色名：
  「编号-2026密码竞赛复赛作品设计报告」「编号-2026密码竞赛复赛相关支撑材料」「编号-2026密码竞赛审批及签字页」。
而仓库根的三件套用的是「编号-作品设计报告」「…-platform-finalNN.zip」「编号-审批及签字页」——
都以编号开头，但不是通知要求的角色名；**支撑材料那个还带 revision 与日期**，像内部产物。

本脚本做的是**只改名的副本**：内容一个字节都不动，副本放在 `build/upload-20261021/`，
并写一份 `UPLOAD-MANIFEST.md`（含三件套的原路径、官方名、摘要、大小、页数/成员数）。
**上传哪个文件、什么时候上传，仍由人决定并执行。**

用法：
  python3 scripts/make_upload_package.py [--out build/upload-20261021]
"""

import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
SYSTEM_NUMBER = "CACR2026EA16XZ"

ROLE_NAMES = {
    "report": "2026密码竞赛复赛作品设计报告",
    "support": "2026密码竞赛复赛相关支撑材料",
    "approval": "2026密码竞赛审批及签字页",
}


def current_package():
    """当前有效匿名包：取支撑包 README 头部声明的「当前最新已核验包」。"""
    readme = (SUPPORT / "README.md").read_text(encoding="utf-8")
    # README 头部结构改过三次，三种写法都认：表头「当前有效：finalNN-…」、
    # 正文「当前最新已核验包为 [finalNN-…]」、以及「当前有效包」表的「文件」行。
    revision = None
    for pattern in (r"当前有效[：:]\s*`?(final\d+-\d{8})",
                    r"当前最新已核验包为 \[(final\d+-\d{8})\]",
                    r"\|\s*文件\s*\|\s*`[^`]*-(final\d+-\d{8})\.zip`"):
        match = re.search(pattern, readme)
        if match is not None:
            revision = match.group(1)
            break
    if revision is None:
        raise SystemExit("支撑包 README 里找不到当前有效包的声明")
    return revision, SUPPORT / ("CACR2026EA16XZ-platform-" + revision + ".zip")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def signoff_item_count():
    """签字清单里的机器+人工检查点条数：按表行实际数，不写死。

    2026-10-21 第 8 轮复核 A9 条：生成器写死「29 个检查点」，而清单实有 30 项
    （A1–A8 / B1–B5 / C1–C6 / D1–D6 / E1–E5），重跑即回退。
    """
    import re

    checklist = (REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md").read_text(
        encoding="utf-8")
    return len(re.findall(r"^\| [A-E][0-9]+ \|", checklist, re.M))


def signoff_signature_rows():
    """签字表行数（人工判定栏之后的签字行）。"""
    import re

    checklist = (REPOSITORY / "docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md").read_text(
        encoding="utf-8")
    rows = re.findall(r"^\|\s*(?:复核人|签名|日期|签字)[^|]*\|.*\|$", checklist, re.M)
    return max(len(rows), 3)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="build/upload-20261021")
    parser.add_argument("--tracked-out", default="deliverables/submission/CACR2026EA16XZ",
                        help="被跟踪的上传清单目录（清单与三件套副本一并落在这里）")
    arguments = parser.parse_args()
    output_directory = REPOSITORY / arguments.out
    if output_directory.exists():
        shutil.rmtree(output_directory)
    output_directory.mkdir(parents=True)

    revision, package = current_package()
    entries = [
        {"role": "作品设计报告", "role_name": ROLE_NAMES["report"], "suffix": ".pdf",
         "source": "CACR2026EA16XZ-作品设计报告.pdf",
         "source_absolute": REPOSITORY / "CACR2026EA16XZ-作品设计报告.pdf",
         "note": "正文与官方模板封面；目录页码与实际页码逐条一致"},
        {"role": "支撑材料", "role_name": ROLE_NAMES["support"], "suffix": ".zip",
         "source": package.name,
         "source_absolute": package,
         "note": "匿名支撑包 " + revision + "；直接身份标记 0，解出复算 CTest 5/5"},
        {"role": "审批及签字页", "role_name": ROLE_NAMES["approval"], "suffix": ".pdf",
         "source": "CACR2026EA16XZ-审批及签字页.pdf",
         "source_absolute": REPOSITORY / "CACR2026EA16XZ-审批及签字页.pdf",
         "note": "作品编号与题目已填；队员签字、指导教师意见与院系盖章须本人手写"},
    ]

    lines = ["# 上传清单（按官方通知的角色命名）", "",
             "官方通知要求「**文件以系统编号命名**」，三个上传项分别是作品设计报告、支撑材料、审批及签字页。",
             "本目录里的三个文件是**按角色名改名的副本**：内容与仓库里的原件逐字节相同（摘要见下表），",
             "**上传动作仍由人完成**。", "",
             "| 上传项 | 本目录文件 | 仓库原件 | SHA-256 | 大小 | 说明 |",
             "|---|---|---|---|---|---|"]
    manifest = []
    for entry in entries:
        source_path = entry["source_absolute"]
        if not source_path.is_file():
            raise SystemExit("缺少原件：" + str(source_path))
        target_name = SYSTEM_NUMBER + "-" + entry["role_name"] + entry["suffix"]
        target_path = output_directory / target_name
        shutil.copyfile(source_path, target_path)
        digest = sha256(target_path)
        if digest != sha256(source_path):
            raise SystemExit("副本与原件摘要不一致：" + target_name)
        size = target_path.stat().st_size
        detail = ""
        if entry["suffix"] == ".pdf":
            import fitz
            detail = "，%d 页" % fitz.open(str(target_path)).page_count
        elif entry["suffix"] == ".zip":
            with zipfile.ZipFile(target_path) as archive:
                detail = "，%d 个成员" % len(archive.namelist())
        lines.append("| %s | `%s` | `%s` | `%s` | %d 字节%s | %s |"
                     % (entry["role"], target_name, entry["source"], digest, size, detail, entry["note"]))
        manifest.append({"role": entry["role"], "upload_file": target_name,
                         "source": entry["source"], "sha256": digest, "bytes": size})

    lines += ["", "## 人工动作（机器不能代劳）", "",
              "1. 打印 `CACR2026EA16XZ-审批及签字页.pdf`：三名队员手写姓名/院系/专业/分工并签字；",
              "   指导老师手写推荐意见并签字、填日期；所在单位或部门盖章、填日期；填「年 月 日」。",
              "2. 在 `docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md` 的 %d 个检查点人工判定栏与 %d 行签字表里"
              % (signoff_item_count(), signoff_signature_rows()),
              "   逐项填写并签字（**机器不能代签**）。",
              "3. 按上表把三个文件分别上传（作品设计报告 / 支撑材料 / 审批及签字页），",
              "   上传窗口至 **2026-10-22 18:00**（Asia/Shanghai）。",
              "4. 若赛事方要求现场屏幕照片：在评委可见环境重跑 `scripts/reproduce_all.sh quick`、",
              "   M3 的 Memcheck 探针与锁频控制器采集命令，并替换 `screenshots/` 里的**图 1 与图 4**"
               "（图 2、图 3 是归档的真实 Linux 运行输出，需在 Linux 实测机上重跑；"
               "四张图的真实性分两类见 `SCREENSHOTS.md`）。", ""]
    (output_directory / "UPLOAD-MANIFEST.md").write_text("\n".join(lines), encoding="utf-8")
    # 同一份清单也落到**被跟踪**的目录：build/ 被 .gitignore 排除，
    # 清单若只留在 build/ 里，随仓库走的复核人就看不到它（第 8 轮复核 A8 条）。
    tracked_directory = REPOSITORY / arguments.tracked_out
    tracked_directory.mkdir(parents=True, exist_ok=True)
    (tracked_directory / "UPLOAD-MANIFEST.md").write_text("\n".join(lines), encoding="utf-8")
    for entry in manifest:
        source_copy = output_directory / entry["upload_file"]
        if source_copy.is_file():
            shutil.copyfile(source_copy, tracked_directory / entry["upload_file"])
    (tracked_directory / "upload-manifest.json").write_text(
        json.dumps({"system_number": SYSTEM_NUMBER, "package_revision": revision,
                    "entries": manifest}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("上传清单已生成：" + str(output_directory.relative_to(REPOSITORY)))
    for item in manifest:
        print("  %-8s %s  %s…" % (item["role"], item["upload_file"], item["sha256"][:16]))


if __name__ == "__main__":
    main()
