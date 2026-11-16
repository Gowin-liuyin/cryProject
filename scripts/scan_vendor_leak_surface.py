#!/usr/bin/env python3
"""R0b vendor 防护链泄露面扫描器。

只扫描 --config 固定清单列出的文件，不扫全树；正则逐行命中后登记
“文件:行号:行文本:所在函数”，输出 HITS.md 与 hits.json 供人工复核，
不做自动定性、不修改 vendor 任何文件。

退出码：0 成功；1 用法；2 配置/数据错误；3 vendor 缺件（需先取件）。
"""

import argparse
import hashlib
import json
import re
import sys
from datetime import date
from pathlib import Path

EXIT_OK = 0
EXIT_USAGE = 1
EXIT_DATA = 2
EXIT_MISSING_VENDOR = 3

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
CONTROL_KEYWORDS = {
    "if",
    "for",
    "while",
    "switch",
    "do",
    "else",
    "return",
    "sizeof",
    "case",
    "goto",
    "typedef",
    "_Static_assert",
    "static_assert",
}
IDENTIFIER_BEFORE_PAREN = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\s*$")


def fail(message, exit_code):
    print("error: " + message, file=sys.stderr)
    return exit_code


def strip_comments_and_literals(text):
    """把注释与字符串/字符字面量替换为空格，保留换行以便行号对齐。"""
    cleaned = []
    index = 0
    text_length = len(text)
    while index < text_length:
        character = text[index]
        next_character = text[index + 1] if index + 1 < text_length else ""
        if character == "/" and next_character == "*":
            cleaned.append("  ")
            index += 2
            while index < text_length and not (text[index] == "*" and index + 1 < text_length
                                               and text[index + 1] == "/"):
                cleaned.append("\n" if text[index] == "\n" else " ")
                index += 1
            if index < text_length:
                cleaned.append("  ")
                index += 2
        elif character == "/" and next_character == "/":
            while index < text_length and text[index] != "\n":
                cleaned.append(" ")
                index += 1
        elif character in ("\"", "'"):
            quote = character
            cleaned.append(" ")
            index += 1
            while index < text_length:
                if text[index] == "\\" and index + 1 < text_length:
                    cleaned.append(" ")
                    index += 1
                    cleaned.append(" " if text[index] != "\n" else "\n")
                    index += 1
                    continue
                if text[index] == quote:
                    cleaned.append(" ")
                    index += 1
                    break
                cleaned.append("\n" if text[index] == "\n" else " ")
                index += 1
        else:
            cleaned.append(character)
            index += 1
    return "".join(cleaned)


def collect_function_starts(cleaned_text):
    """按“顶层括号 + 后随 {”启发式登记函数定义起始行与函数名。"""
    functions = []
    brace_depth = 0
    paren_depth = 0
    candidate_name = None
    candidate_line = 0
    line_number = 1
    index = 0
    text_length = len(cleaned_text)
    while index < text_length:
        character = cleaned_text[index]
        if character == "\n":
            line_number += 1
            index += 1
            continue
        if brace_depth == 0 and character == "(" and paren_depth == 0:
            match = IDENTIFIER_BEFORE_PAREN.search(cleaned_text[max(0, index - 200):index])
            if match is not None and match.group(1) not in CONTROL_KEYWORDS:
                candidate_name = match.group(1)
                candidate_line = line_number
                paren_depth = 1
                index += 1
                continue
        if candidate_name is not None and brace_depth == 0:
            if character == "(":
                paren_depth += 1
            elif character == ")":
                paren_depth -= 1
                if paren_depth == 0:
                    lookahead = index + 1
                    while lookahead < text_length and cleaned_text[lookahead] in " \t":
                        lookahead += 1
                    is_function = lookahead < text_length and cleaned_text[lookahead] == "{"
                    if is_function:
                        functions.append((candidate_line, candidate_name))
                    candidate_name = None
        if character == "{":
            brace_depth += 1
        elif character == "}":
            brace_depth = max(0, brace_depth - 1)
        index += 1
    return functions


def function_for_line(functions, line_number):
    current_name = "(file_scope)"
    for start_line, name in functions:
        if start_line <= line_number:
            current_name = name
        else:
            break
    return current_name


def load_config(config_path):
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError("cannot load config %s: %s" % (config_path, error))
    if not isinstance(config, dict):
        raise ValueError("config must be a JSON object")
    for required_key in ("scan_id", "rule_regex", "rule_tokens", "targets"):
        if required_key not in config:
            raise ValueError("config misses %s" % required_key)
    tokens = config["rule_tokens"]
    if not isinstance(tokens, list) or not tokens:
        raise ValueError("rule_tokens must be a non-empty list")
    combined_rule = "|".join(token["regex"] for token in tokens)
    if combined_rule != config["rule_regex"]:
        raise ValueError("rule_regex does not equal the combined rule_tokens")
    try:
        re.compile(config["rule_regex"])
    except re.error as error:
        raise ValueError("invalid rule_regex: %s" % error)
    return config


def collect_scan_files(config):
    missing = []
    scan_entries = []
    for target in config["targets"]:
        tree_root = REPOSITORY_ROOT / target["tree"]
        directory = tree_root / target["directory"]
        if not directory.is_dir():
            missing.append(str(directory.relative_to(REPOSITORY_ROOT)))
            continue
        target_entries = []
        for file_name in target["files"]:
            file_path = directory / file_name
            if not file_path.is_file():
                missing.append(str(file_path.relative_to(REPOSITORY_ROOT)))
                continue
            target_entries.append(
                {
                    "tree": target["tree"],
                    "path": file_path.relative_to(REPOSITORY_ROOT).as_posix(),
                }
            )
        scan_entries.extend(target_entries)
    return scan_entries, missing


def scan_file(entry, token_regexes, combined_rule):
    file_path = REPOSITORY_ROOT / entry["path"]
    file_bytes = file_path.read_bytes()
    text = file_bytes.decode("utf-8", errors="replace")
    lines = text.splitlines()
    functions = collect_function_starts(strip_comments_and_literals(text))
    hits = []
    for line_index, line_text in enumerate(lines, start=1):
        if combined_rule.search(line_text) is None:
            continue
        matched_patterns = [
            token["name"] for token in token_regexes if token["regex"].search(line_text) is not None
        ]
        hits.append(
            {
                "path": entry["path"],
                "line": line_index,
                "function": function_for_line(functions, line_index),
                "patterns": matched_patterns,
                "text": line_text,
            }
        )
    return {
        "path": entry["path"],
        "tree": entry["tree"],
        "sha256": hashlib.sha256(file_bytes).hexdigest(),
        "line_count": len(lines),
        "hit_count": len(hits),
        "hits": hits,
    }


def markdown_escape(text):
    escaped = text.replace("\\", "\\\\").replace("|", "\\|").replace("`", "\\`")
    return escaped.strip()


def write_hits_markdown(output_path, scan_id, config_path, rule_regex, tree_count, file_reports, hits):
    lines = []
    lines.append("# R0b vendor 防护链泄露面扫描（%s）" % scan_id)
    lines.append("")
    lines.append("本表只登记固定清单内文件的逐行正则命中，供人工复核；**不做自动定性**，")
    lines.append("不表示命中即泄露，也不修改 vendor 任何文件。")
    lines.append("")
    lines.append("- 日期：%s" % date.today().isoformat())
    lines.append("- 配置：`%s`" % config_path)
    lines.append("- 规则：`%s`" % rule_regex.replace("|", "\\|"))
    lines.append("- 清单：%d 棵 vendor 树 / %d 个文件（不扫全树）" % (tree_count, len(file_reports)))
    lines.append("")
    lines.append("## 1. 扫描范围与文件摘要")
    lines.append("")
    lines.append("| 文件 | 行数 | 命中行数 | 文件 SHA-256 |")
    lines.append("|---|---:|---:|---|")
    total_hits = 0
    for report in file_reports:
        total_hits += report["hit_count"]
        lines.append(
            "| `%s` | %d | %d | `%s` |"
            % (report["path"], report["line_count"], report["hit_count"], report["sha256"])
        )
    lines.append("")
    lines.append("合计命中行 **%d** 行。" % total_hits)
    lines.append("")
    lines.append("## 2. 逐行命中")
    lines.append("")
    if not hits:
        lines.append("（无命中）")
    else:
        lines.append("| # | 文件:行号 | 所在函数 | 命中规则 | 行文本 |")
        lines.append("|---:|---|---|---|---|")
        for hit_index, hit in enumerate(hits, start=1):
            lines.append(
                "| %d | `%s:%d` | `%s` | `%s` | `%s` |"
                % (
                    hit_index,
                    hit["path"],
                    hit["line"],
                    markdown_escape(hit["function"]),
                    ",".join(hit["patterns"]),
                    markdown_escape(hit["text"]),
                )
            )
    lines.append("")
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    argument_parser = argparse.ArgumentParser(
        description="Scan fixed vendor files for defensive-chain leak surface hits"
    )
    argument_parser.add_argument("--config", required=True, help="scan config JSON")
    argument_parser.add_argument(
        "--output-dir",
        default=None,
        help="output directory (default: directory of --config)",
    )
    arguments = argument_parser.parse_args()
    config_path = Path(arguments.config).resolve()
    output_directory = (
        Path(arguments.output_dir).resolve()
        if arguments.output_dir is not None
        else config_path.parent
    )
    try:
        config = load_config(config_path)
    except ValueError as error:
        return fail(str(error), EXIT_DATA)

    scan_entries, missing = collect_scan_files(config)
    if missing:
        print("error: vendor tree or file missing:", file=sys.stderr)
        for missing_path in missing:
            print("  " + missing_path, file=sys.stderr)
        print("run: sh tools/fetch_all_vendors.sh", file=sys.stderr)
        return EXIT_MISSING_VENDOR

    token_regexes = [
        {"name": token["name"], "regex": re.compile(token["regex"])}
        for token in config["rule_tokens"]
    ]
    combined_rule = re.compile(config["rule_regex"])
    tree_count = len({target["tree"] for target in config["targets"]})
    file_reports = []
    all_hits = []
    for entry in scan_entries:
        report = scan_file(entry, token_regexes, combined_rule)
        file_reports.append(report)
        all_hits.extend(report["hits"])
    all_hits.sort(key=lambda hit: (hit["path"], hit["line"]))

    output_directory.mkdir(parents=True, exist_ok=True)
    hits_json = {
        "scan_id": config["scan_id"],
        "generated_on": date.today().isoformat(),
        "config_path": str(config_path.relative_to(REPOSITORY_ROOT)),
        "rule_regex": config["rule_regex"],
        "rule_tokens": config["rule_tokens"],
        "scanned_file_count": len(file_reports),
        "scanned_line_count": sum(report["line_count"] for report in file_reports),
        "hit_count": len(all_hits),
        "files": [
            {key: report[key] for key in ("path", "tree", "sha256", "line_count", "hit_count")}
            for report in file_reports
        ],
        "hits": all_hits,
    }
    hits_json_path = output_directory / "hits.json"
    hits_json_path.write_text(
        json.dumps(hits_json, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    hits_markdown_path = output_directory / "HITS.md"
    write_hits_markdown(
        hits_markdown_path,
        config["scan_id"],
        str(config_path.relative_to(REPOSITORY_ROOT)),
        config["rule_regex"],
        tree_count,
        file_reports,
        all_hits,
    )
    print(
        "vendor surface scan: files=%d lines=%d hits=%d"
        % (len(file_reports), hits_json["scanned_line_count"], len(all_hits))
    )
    for report in file_reports:
        print("  %s: %d" % (report["path"], report["hit_count"]))
    print("outputs: %s %s" % (hits_markdown_path, hits_json_path))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
