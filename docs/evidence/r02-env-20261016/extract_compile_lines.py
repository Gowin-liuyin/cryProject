#!/usr/bin/env python3
# T07 远端辅助（只读）：从 compile_commands.json 里提取真实编译行与去重后的选项集。
# 用法（从本机把脚本经 stdin 送到远端 python3）：
#   ssh <host> python3 - <flags-regex> <path> [<path> ...] < extract_compile_lines.py
# 只读，不写远端任何文件。
import json
import os
import re
import sys

FLAG_PREFIXES = ("-O", "-f", "-m", "-std=", "-D", "-g", "-W", "-U", "-pthread", "-s")
SKIP_WITH_VALUE = ("-I", "-isystem", "-o", "-c", "-MF", "-MT", "-MD", "-MMD", "-MQ", "-x")


def flagset(tokens):
    keep = []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token in SKIP_WITH_VALUE:
            index += 2
            continue
        if token.startswith(("-I", "-isystem")):
            index += 1
            continue
        if token.startswith(FLAG_PREFIXES):
            keep.append(token)
        index += 1
    return " ".join(keep)


def main():
    raw = sys.argv[1:]
    if not raw:
        print("usage: python3 - <target-regex> <path> [path...]")
        return 2
    target_pattern = re.compile(raw[0])
    paths = raw[1:]
    print("### TARGET_REGEX %s" % raw[0])
    for path in paths:
        print("### BUILD %s" % path)
        if not os.path.isfile(path):
            print("### MISSING")
            continue
        with open(path) as handle:
            entries = json.load(handle)
        flagsets = {}
        for entry in entries:
            tokens = entry["arguments"] if "arguments" in entry else entry["command"].split()
            flagsets.setdefault(flagset(tokens), []).append(entry["file"])
        print("### ENTRY_COUNT %d  DISTINCT_FLAGSETS %d" % (len(entries), len(flagsets)))
        for flags, files in sorted(flagsets.items(), key=lambda item: (-len(item[1]), item[0])):
            sample = ", ".join(sorted({os.path.basename(name) for name in files})[:6])
            print("FLAGSET n=%d | %s | files: %s" % (len(files), flags, sample))
        print("### MATCHING_TARGETS")
        emitted = set()
        for entry in entries:
            tokens = entry["arguments"] if "arguments" in entry else entry["command"].split()
            target = ""
            for index, token in enumerate(tokens):
                if token == "-o" and index + 1 < len(tokens):
                    target = tokens[index + 1]
                elif token.startswith("-o") and len(token) > 2:
                    target = token[2:]
            if not target or not target_pattern.search(target):
                continue
            if target in emitted:
                continue
            emitted.add(target)
            print("TARGET %s" % target)
            print("  FILE %s" % entry["file"])
            print("  FLAGS %s" % flagset(tokens))
            print("  RAW   %s" % " ".join(tokens))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
