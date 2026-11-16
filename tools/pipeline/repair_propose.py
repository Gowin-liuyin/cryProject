#!/usr/bin/env python3
"""R0a/M3 修复建议器：把 positive 定位项与反汇编文本做模式匹配，输出纯文本补丁建议。

只读输入文件（findings.json、objdump 文本、repair_patterns/*.json），
不调用 objdump、不写任何文件、不应用补丁；结果必须人工审阅后按新提交落盘。

用法：
    python3 tools/pipeline/repair_propose.py --finding <findings.json> --disasm <objdump.txt>
    [--patterns-dir tools/pipeline/repair_patterns]

退出码：0 成功（含零候选）；1 用法；2 配置/数据错误。
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PATTERNS_DIR = Path(__file__).resolve().parent / "repair_patterns"
PATTERN_ORDER = (
    "secret_branch_to_mask",
    "secret_div_to_mulshift",
    "secret_index_to_ctselect",
    "early_exit_compare_to_or",
)
PATTERN_REQUIRED_FIELDS = (
    "id",
    "disasm_pattern",
    "mechanism",
    "patch_template",
    "known_example",
    "known_counterexample",
    "risk_note",
)
DISCLAIMER = "免责声明：不自动应用，人工审阅后按新提交落盘。"

EXIT_OK = 0
EXIT_USAGE = 1
EXIT_DATA = 2

SYMBOL_HEADER = re.compile(r"^([0-9a-fA-F]+) <([^>]+)>:\s*$")


class ProposalError(Exception):
    def __init__(self, message, exit_code=EXIT_DATA):
        super().__init__(message)
        self.exit_code = exit_code


class ProposalArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        raise ProposalError("usage: " + message, EXIT_USAGE)


def load_patterns(patterns_directory):
    patterns_directory = Path(patterns_directory)
    prepare_error = None
    patterns = []
    for pattern_id in PATTERN_ORDER:
        pattern_path = patterns_directory / (pattern_id + ".json")
        if not pattern_path.is_file():
            raise ProposalError("missing repair pattern: %s" % pattern_path)
        try:
            pattern = json.loads(pattern_path.read_text(encoding="utf-8"))
        except OSError as error:
            raise ProposalError("cannot read %s: %s" % (pattern_path, error))
        except json.JSONDecodeError as error:
            raise ProposalError("invalid JSON in %s: %s" % (pattern_path, error))
        for required_field in PATTERN_REQUIRED_FIELDS:
            if required_field not in pattern:
                raise ProposalError("%s misses field %s" % (pattern_path, required_field))
        if pattern["id"] != pattern_id:
            raise ProposalError("%s declares id %r, expected %r" % (pattern_path, pattern["id"], pattern_id))
        try:
            compiled_pattern = re.compile(pattern["disasm_pattern"])
        except re.error as error:
            raise ProposalError("invalid disasm_pattern in %s: %s" % (pattern_path, error))
        pattern["compiled_pattern"] = compiled_pattern
        pattern["pattern_path"] = pattern_path.as_posix()
        patterns.append(pattern)
    if prepare_error is not None:
        raise ProposalError(prepare_error)
    return patterns


def load_findings(findings_path):
    findings_path = Path(findings_path)
    try:
        document = json.loads(findings_path.read_text(encoding="utf-8"))
    except OSError as error:
        raise ProposalError("cannot read findings %s: %s" % (findings_path, error))
    except json.JSONDecodeError as error:
        raise ProposalError("invalid findings JSON %s: %s" % (findings_path, error))
    if isinstance(document, dict):
        findings = document.get("findings")
    else:
        findings = document
    if not isinstance(findings, list):
        raise ProposalError("findings file must be a JSON array or an object with findings[]")
    for finding_index, finding in enumerate(findings):
        if not isinstance(finding, dict):
            raise ProposalError("findings[%d] is not an object" % finding_index)
        if "verdict" not in finding or "layer" not in finding:
            raise ProposalError("findings[%d] needs verdict and layer" % finding_index)
    return findings


def select_positive_localize_findings(findings):
    return [
        finding
        for finding in findings
        if finding.get("verdict") == "positive" and finding.get("layer") == "localize"
    ]


def locate_functions(disassembly_lines):
    functions = []
    for line_number, line in enumerate(disassembly_lines, start=1):
        match = SYMBOL_HEADER.match(line.strip())
        if match is not None:
            functions.append((line_number, match.group(2)))
    return functions


def enclosing_function(functions, line_number):
    current_name = "(unknown)"
    for start_line, name in functions:
        if start_line <= line_number:
            current_name = name
        else:
            break
    return current_name


def match_line_number(disassembly_text, character_offset):
    return disassembly_text.count("\n", 0, character_offset) + 1


def render_proposal(proposal_index, pattern, finding, disassembly_path_display, disassembly_lines,
    match_start_line, match_line_count, function_name):
    template = pattern["patch_template"].replace("%FUNCTION%", function_name)
    excerpt_lines = disassembly_lines[
        match_start_line - 1 : min(match_start_line - 1 + match_line_count, len(disassembly_lines))
    ]
    excerpt = "\n".join("    " + line.strip() for line in excerpt_lines if line.strip() != "")
    finding_label = finding.get("finding_id", "f-????")
    lines = []
    lines.append("## 候选 %d：%s" % (proposal_index, pattern["id"]))
    lines.append("")
    lines.append("- pattern_id: `%s`" % pattern["id"])
    lines.append("- mechanism: `%s`" % pattern["mechanism"])
    lines.append("- known_example: %s" % pattern["known_example"])
    lines.append("- risk_note: %s" % pattern["risk_note"])
    lines.append(
        "- matched_finding: %s（module=%s arm=%s layer=%s verdict=%s mechanism=%s）"
        % (
            finding_label,
            finding.get("module", "?"),
            finding.get("arm", "?"),
            finding.get("layer", "?"),
            finding.get("verdict", "?"),
            finding.get("mechanism", "?"),
        )
    )
    lines.append(
        "- disasm 位置: `%s` 第 %d 行（函数 `%s`）"
        % (disassembly_path_display, match_start_line, function_name)
    )
    lines.append("- 命中指令：")
    lines.append("")
    lines.append("```text")
    lines.append(excerpt)
    lines.append("```")
    lines.append("")
    lines.append("- 建议补丁（模板渲染，仅供人工审阅）：")
    lines.append("")
    lines.append("```diff")
    lines.append(template.rstrip("\n"))
    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def propose(findings_path, disassembly_path, patterns_directory=None):
    patterns = load_patterns(patterns_directory or DEFAULT_PATTERNS_DIR)
    findings = load_findings(findings_path)
    positive_findings = select_positive_localize_findings(findings)
    disassembly_path = Path(disassembly_path)
    try:
        disassembly_text = disassembly_path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        raise ProposalError("cannot read disassembly %s: %s" % (disassembly_path, error))
    disassembly_lines = disassembly_text.splitlines()
    functions = locate_functions(disassembly_lines)
    try:
        disassembly_display = disassembly_path.resolve().relative_to(REPOSITORY_ROOT).as_posix()
    except ValueError:
        disassembly_display = disassembly_path.resolve().as_posix()

    proposals = []
    seen_keys = set()
    for finding in positive_findings:
        for pattern in patterns:
            for match in pattern["compiled_pattern"].finditer(disassembly_text):
                match_start_line = match_line_number(disassembly_text, match.start())
                match_line_count = match.group(0).count("\n") + 1
                function_name = enclosing_function(functions, match_start_line)
                dedupe_key = (pattern["id"], function_name, match_start_line)
                if dedupe_key in seen_keys:
                    continue
                seen_keys.add(dedupe_key)
                proposals.append(
                    render_proposal(
                        len(proposals) + 1,
                        pattern,
                        finding,
                        disassembly_display,
                        disassembly_lines,
                        match_start_line,
                        match_line_count,
                        function_name,
                    )
                )

    lines = []
    lines.append("# repair_propose：修复候选（dry-run，纯文本，不落盘）")
    lines.append("")
    lines.append("- findings: `%s`（positive 定位项 %d 个）" % (Path(findings_path).as_posix(), len(positive_findings)))
    lines.append("- disasm: `%s`" % disassembly_display)
    lines.append("- 模式库: `%s`（%d 条）" % (Path(patterns_directory or DEFAULT_PATTERNS_DIR).as_posix(), len(patterns)))
    lines.append("")
    if not proposals:
        lines.append("本次 positive 定位项在给定反汇编中 **未命中任何模式（零候选）**。")
        lines.append("")
    for proposal_text in proposals:
        lines.append(proposal_text)
    lines.append("## 汇总")
    lines.append("")
    lines.append("- positive 定位项: %d" % len(positive_findings))
    lines.append("- 命中候选: %d" % len(proposals))
    lines.append("- 模式数: %d" % len(patterns))
    lines.append("")
    lines.append(DISCLAIMER)
    lines.append("")
    return "\n".join(lines)


def build_argument_parser():
    parser = ProposalArgumentParser(
        description="Match positive localize findings against repair patterns and print dry-run diffs"
    )
    parser.add_argument("--finding", required=True, help="findings.json or a hand-written JSON array")
    parser.add_argument("--disasm", required=True, help="saved objdump text file")
    parser.add_argument("--patterns-dir", default=None)
    return parser


def main(argument_values=None):
    parser = build_argument_parser()
    try:
        arguments = parser.parse_args(argument_values)
        report = propose(arguments.finding, arguments.disasm, arguments.patterns_dir)
    except ProposalError as error:
        print("repair_propose error: %s" % error, file=sys.stderr)
        return error.exit_code
    sys.stdout.write(report)
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
