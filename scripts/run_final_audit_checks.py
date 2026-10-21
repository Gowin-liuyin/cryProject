#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""跑 FINAL_AUDIT.csv 里的全部 verify_command，并把逐条退出码落盘。

用途：最终复核审计（第 9 版及以后）要能复核「全部核对命令返回 0」这一说法，
而不是只写一句结论。这里把 CSV 当成唯一的核对清单逐条执行，输出 JSON 明细。

口径：
  * 命令在仓库根目录执行，用 shell（/bin/sh）解释，与审计里登记的写法一致。
  * 命令列为 `—` 的行是「可选未做」，记为占位、不执行、不计入失败。
  * 每条命令的 stdout/stderr 单独记到输出 JSON（超长按前 4 KB 截断），
    退出码、耗时、是否超时都逐条落盘。
  * 同时复核 CSV 的 `evidence_path` 列：按 `;` 切分后逐条判定文件是否存在。
  * 脚本**不改判**：只报告实际退出码，判定仍由审计正文负责。

用法：
  python3 scripts/run_final_audit_checks.py \
      --csv docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv \
      --out docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json
"""

import argparse
import csv
import hashlib
import json
import re
import subprocess
import sys
import time
from pathlib import Path, PurePosixPath

REPOSITORY = Path(__file__).resolve().parents[1]
PLACEHOLDERS = ("", "—", "-")


def run_command(command, timeout):
    started = time.monotonic()
    try:
        completed = subprocess.run(["/bin/sh", "-c", command], cwd=str(REPOSITORY),
                                   capture_output=True, text=True, timeout=timeout)
        return completed.returncode, False, (completed.stdout or "") + (completed.stderr or ""), started
    except subprocess.TimeoutExpired:
        return None, True, "命令超时（%d 秒）" % timeout, started


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--timeout", type=int, default=600)
    arguments = parser.parse_args()

    with open(arguments.csv, encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    results = []
    for index, row in enumerate(rows, 1):
        command = row["verify_command"].strip()
        if command in PLACEHOLDERS:
            results.append({
                "index": index,
                "id": row["id"],
                "exit_code": None,
                "placeholder": True,
                "timed_out": False,
                "seconds": 0.0,
                "output_head": "占位命令（可选未做），不执行",
            })
            print("[%2d/%d] %-6s 占位（不执行）" % (index, len(rows), row["id"]))
            continue
        exit_code, timed_out, output, started = run_command(command, arguments.timeout)
        results.append({
            "index": index,
            "id": row["id"],
            "exit_code": exit_code,
            "placeholder": False,
            "timed_out": timed_out,
            "seconds": round(time.monotonic() - started, 2),
            "output_head": output[:4096],
        })
        print("[%2d/%d] %-6s exit=%s %s" % (index, len(rows), row["id"], exit_code,
                                             "超时" if timed_out else ""))

    missing_paths = []
    checked_paths = 0
    # 2026-10-21 复查：此前「不是纯路径」的声明被**静默跳过**，读者从报告里
    # 看不到哪些证据路径其实没被核对过。现在把跳过的条目逐条列出来。
    skipped_paths = []
    for row in rows:
        # 一格里可能有多条声明，用「；」再切一次；`.../name` 这种省略号写法
        # 按**同格上一条路径的目录**补全——2026-10-21 第 9 轮复核 A9 条：此前
        # 5 条真实且已存在的路径（含省略号写法与以 (git) 开头的整格）被整条跳过，
        # 它们的存在性其实从没验证过。
        previous_directory = ""
        for candidate in row["evidence_path"].split(";"):
            candidate = candidate.strip().strip("`")
            if not candidate:
                continue
            for piece in candidate.split("；"):
                piece = piece.strip().strip("`")
                if not piece:
                    continue
                if piece.startswith(".../"):
                    if previous_directory:
                        piece = previous_directory + "/" + piece[4:]
                    else:
                        skipped_paths.append({"id": row["id"], "path": piece,
                                              "reason": "省略号写法，且同格没有可补全的前置路径"})
                        continue
                match = re.match(r"^(.*?)（(.*)）\s*$", piece)
                if match is not None:
                    piece = match.group(1).strip()
                if not piece:
                    # 只剩说明文字（典型是「（无）」）：**不能静默丢弃**——
                    # 丢了读者就不知道「N 条」的分母里少算了什么
                    # （2026-10-21 第 10 轮复核问题 7）。
                    skipped_paths.append({"id": row["id"], "path": candidate,
                                          "reason": "占位：只有说明文字，没有路径"})
                    continue
                if piece.startswith("(") or piece.startswith("（"):
                    skipped_paths.append({"id": row["id"], "path": piece,
                                          "reason": "不是路径，是说明文字"})
                    continue
                if "…" in piece or "..." in piece:
                    skipped_paths.append({"id": row["id"], "path": piece,
                                          "reason": "省略号写法，无法定位到具体文件"})
                    continue
                if " " in piece:
                    # 显式白名单：只有当**整条**落在已知路径前缀下、或首段本身
                    # 就是一个真实存在的仓库相对路径时，才当路径处理；否则记 skipped。
                    # 此前靠「首段存在性」反推，判定依据不是「这条是不是路径」，
                    # 碰上同名就可能误判（2026-10-21 第 10 轮复核问题 8）。
                    head = piece.split(" ", 1)[0]
                    if "/" in head and (REPOSITORY / head).exists():
                        piece = head
                    elif piece.startswith("docs/") and " " not in piece:
                        pass
                    else:
                        skipped_paths.append({"id": row["id"], "path": piece,
                                              "reason": "含空格且无法确定路径"})
                        continue
                checked_paths += 1
                if not (REPOSITORY / piece).exists():
                    missing_paths.append({"id": row["id"], "path": piece})
                else:
                    previous_directory = str(PurePosixPath(piece).parent)


    executed = [item for item in results if not item["placeholder"]]
    passed = sum(1 for item in executed if item["exit_code"] == 0)
    csv_path = Path(arguments.csv)
    summary = {
        "csv": arguments.csv,
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "rows": len(results),
        "executable_commands": len(executed),
        "placeholder_commands": len(results) - len(executed),
        "exit_zero": passed,
        "non_zero": len(executed) - passed,
        "timeouts": sum(1 for item in executed if item["timed_out"]),
        "evidence_paths_total": checked_paths + len(skipped_paths),
        "evidence_paths_checked": checked_paths,
        "evidence_paths_missing": missing_paths,
        "evidence_paths_skipped": skipped_paths,
        "results": results,
    }
    output_path = Path(arguments.out)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("共 %d 行（可执行 %d、占位 %d），exit0 = %d，非 0 = %d，超时 = %d；"
          "证据路径 %d 条（另有 %d 条非路径声明已逐条列出）、缺失 %d 条；明细写入 %s"
          % (summary["rows"], summary["executable_commands"], summary["placeholder_commands"],
             summary["exit_zero"], summary["non_zero"], summary["timeouts"],
             summary["evidence_paths_checked"], len(skipped_paths),
             len(summary["evidence_paths_missing"]), output_path))
    for item in skipped_paths:
        print("  未核对：%s → %s（%s）" % (item["id"], item["path"], item["reason"]))
    return 0 if summary["non_zero"] == 0 and summary["timeouts"] == 0 and not missing_paths else 1


if __name__ == "__main__":
    sys.exit(main())
