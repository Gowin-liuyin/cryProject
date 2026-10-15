#!/usr/bin/env python3
"""R06 审计：静态分类"可泄露可观察面"的调用点。

判定目标只有两类：
  1) 秘密：共享密钥 ss、私钥 sk/z、内部消息 m'、种子等；
  2) "验证是否通过"这一内部结果：重加密比较位、接受/拒绝分支、mismatch 计数。

输入：待扫描的 C 文件列表（stdin，每行一个路径）。
输出：TSV，一行一个调用点：
  file:line | 语句（多行折叠成单行）| touches_secret | reason
"""

import os
import re
import sys

# 可能把内容送出进程边界的调用点。
CALL_NAMES = [
    "printf", "fprintf", "sprintf", "snprintf", "vsnprintf", "vfprintf",
    "puts", "fputs", "putchar", "fputc", "fwrite", "perror", "syslog",
    "write", "dprintf", "assert", "abort", "exit", "_exit", "errno",
]

CALL_RE = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(CALL_NAMES) + r")\s*\(")

# 会产生秘密/秘密派生物的标识符（含显式秘密标记宏的参数）。
SECRET_HINT_RE = re.compile(
    r"(?:^|_)(?:ss|sk|z|m_prime|message_prime|secret|secrets|secret_key|private_key|"
    r"shared_secret|decapsulation_key|decapsulated|expected_secret|row_secrets|"
    r"key_seed|seed_bytes|indcpa_dec|verify|verification|is_equal|equal|mismatch|"
    r"reject(?:ion)?|accept|chosen_message|failed_decapsulation|compare|memcmp|ct_memcmp)(?:_|$)",
    re.IGNORECASE,
)

# 明确"不接触秘密"的公开量，用于给出理由。
PUBLIC_HINT_RE = re.compile(
    r"(?:^|_)(?:count|index|idx|bytes|nanoseconds|ns|seconds|seed|path|name|status|"
    r"resolution|digest|sha|sha3|hash|header|format|version|label|category|class|"
    r"sample|row|column|budget|checksum|capacity|offset|size|length|rows|attempted|"
    r"completed|consumed|zero|minimum|maximum|mean|total)(?:_|$)",
    re.IGNORECASE,
)


def strip_comments(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if ch == "/" and nxt == "/":
            j = text.find("\n", i)
            if j < 0:
                break
            out.append("\n")
            i = j + 1
        elif ch == "/" and nxt == "*":
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("\n" * text.count("\n", i, j))
            i = j
        elif ch == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    j += 1
                    break
                j += 1
            # 把字符串字面量折成占位串，避免分号/逗号干扰语句切分。
            out.append('"' + text[i + 1:j - 1].replace("\n", " ") + '"' if j - i > 1 else '""')
            i = j
        elif ch == "'":
            j = text.find("'", i + 1)
            j = n if j < 0 else j + 1
            out.append(text[i:j])
            i = j
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def function_bodies(clean: str):
    """定位函数体（顶层 {...} 区间），避免把 #include/宏定义当成语句。"""
    bodies = []
    i = 0
    n = len(clean)
    while i < n:
        if clean[i] == "{":
            depth = 0
            j = i
            while j < n:
                if clean[j] == "{":
                    depth += 1
                elif clean[j] == "}":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            bodies.append((i, j + 1))
            i = j + 1
        else:
            i += 1
    return bodies


def split_statements(clean: str, raw_lines):
    """在函数体内部按 ; 切分（已去注释、字符串占位），返回 (起行, 语句文本)。"""
    result = []
    for body_start, body_end in function_bodies(clean):
        depth = 0
        start = body_start
        for i in range(body_start, body_end):
            ch = clean[i]
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
                if depth == 0 and ch == "}":
                    segment = clean[start:i + 1]
                    if segment.strip():
                        line = clean.count("\n", 0, start) + 1
                        result.append((line, segment))
                    start = i + 1
            elif ch == ";" and depth == 1:
                segment = clean[start:i + 1]
                if segment.strip():
                    line = clean.count("\n", 0, start) + 1
                    result.append((line, segment))
                start = i + 1
    return result


def collect_secret_names(all_texts):
    names = set()
    for text in all_texts:
        for match in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\b", text):
            token = match.group(1)
            if len(token) < 2:
                continue
            if SECRET_HINT_RE.search(token):
                names.add(token)
    return names


def main():
    # 路径以仓库根为基准；扫描命令在任意工作目录下都可重跑。
    repo_root = os.environ.get("R06_REPO", os.getcwd())
    paths = [line.strip() for line in sys.stdin if line.strip()]
    sources = {}
    for path in paths:
        resolved = path if os.path.isabs(path) else os.path.join(repo_root, path)
        with open(resolved, "r", encoding="utf-8", errors="replace") as handle:
            sources[path] = handle.read()
    secret_names = collect_secret_names(sources.values())

    rows = []
    for path in paths:
        raw = sources[path]
        clean = strip_comments(raw)
        statements = split_statements(clean, raw)
        for line, text in statements:
            collapsed = " ".join(text.split())
            calls = sorted(set(m.group(1) for m in CALL_RE.finditer(text)))
            if not calls:
                continue
            identifiers = set(
                t for t in re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)\b", text)
            )
            secret_hits = sorted(identifiers & secret_names)
            reason = ""
            if secret_hits:
                touches = "yes"
                reason = "实参/控制流引用秘密相关标识符: " + ",".join(secret_hits[:8])
            else:
                touches = "no"
                call_text = ",".join(calls)
                public_hits = sorted(
                    t for t in identifiers if PUBLIC_HINT_RE.search(t)
                )
                if public_hits:
                    detail = "公开量: " + ",".join(public_hits[:6])
                else:
                    detail = "仅字面量/公开控制量"
                reason = "不含秘密标识符（%s；调用=%s）" % (detail, call_text)
            rows.append((path, line, collapsed, touches, reason, ",".join(calls)))

    header = ["file", "line", "call", "statement", "touches_secret", "reason"]
    print("\t".join(header))
    for path, line, statement, touches, reason, calls in rows:
        print(
            "\t".join(
                [path, str(line), calls, statement.replace("\t", " "), touches, reason]
            )
        )
    yes = sum(1 for r in rows if r[3] == "yes")
    sys.stderr.write(
        "TOTAL_CALL_SITES=%d\nTOUCHES_SECRET=%d\nOTHER=%d\n"
        % (len(rows), yes, len(rows) - yes)
    )
    # 机读汇总，供 audit.sh 固化。
    print(
        "#SUMMARY\tTOTAL=%d\tTOUCHES_SECRET=%d\tOTHER=%d"
        % (len(rows), yes, len(rows) - yes)
    )


if __name__ == "__main__":
    main()
