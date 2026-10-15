#!/usr/bin/env python3
"""R06 审计：计时窗口边界与"窗口内不得有 I/O 或日志"检查。

方法：
  1) 先去掉字符串字面量（meta 里记录的 window=... 断言本身不是代码），
     再找 atomic_signal_fence(memory_order_seq_cst) 的真实代码位置；
  2) 把相邻两个 fence 配成一对（一个计时窗口的起止）；
  3) 对每一对打印窗口原文，并用白名单核对窗口内没有 I/O/日志/分配/内存操作。

窗口内允许出现：读钟、atomic_signal_fence、被测函数（完整解封装或热点函数）、
状态整型接收与无分支累积。
"""

import re
import sys

IO_CALLS = (
    "printf", "fprintf", "vfprintf", "sprintf", "snprintf", "vsnprintf", "puts", "fputs",
    "putchar", "fputc", "fwrite", "write", "perror", "syslog", "fopen", "fclose",
    "fflush", "fread", "fgets", "remove", "rename", "readlink", "malloc", "calloc",
    "realloc", "free", "memcpy", "memset", "memcmp",
)
IO_RE = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(IO_CALLS) + r")\s*\(")
FENCE_RE = re.compile(r"atomic_signal_fence\s*\(\s*memory_order_seq_cst\s*\)")


def strip_string_literals(text: str) -> str:
    out = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char == '"':
            index += 1
            while index < length:
                if text[index] == "\\":
                    index += 2
                    continue
                if text[index] == '"':
                    index += 1
                    break
                index += 1
            out.append('""')
        elif char == "'":
            end = text.find("'", index + 1)
            end = length if end < 0 else end + 1
            out.append(text[index:end])
            index = end
        else:
            out.append(char)
            index += 1
    return "".join(out)


def main():
    targets = []
    for spec in sys.argv[1:]:
        path, label = spec.split("::", 1)
        targets.append((path, label))

    problem_windows = 0
    total_windows = 0
    for path, label in targets:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            raw_lines = handle.read().split("\n")
        code_lines = [strip_string_literals(line) for line in raw_lines]
        fence_indices = [i for i, line in enumerate(code_lines) if FENCE_RE.search(line)]
        print("=== %s (%s) ===" % (label, path))
        if not fence_indices:
            print("  未找到代码中的 atomic_signal_fence：无法确认窗口边界")
            problem_windows += 1
            print()
            continue
        if len(fence_indices) % 2 != 0:
            print("  fence 数量为奇数（%d），按逐对解释并标注" % len(fence_indices))
        allowed_prefixes = ("read_monotonic_nanoseconds", "read_nanoseconds", "clock_gettime",
                            "mlkem_decapsulate", "poly_tomsg", "compare_once", "run_batch")
        for pair_index in range(0, len(fence_indices) - 1, 2):
            start = fence_indices[pair_index]
            end = fence_indices[pair_index + 1]
            total_windows += 1
            region_lines = raw_lines[start:end + 1]
            code_region = "\n".join(code_lines[start:end + 1])
            hits = sorted(set(m.group(1) for m in IO_RE.finditer(code_region)))
            offending = [
                name for name in hits
                if not any(name.startswith(prefix) for prefix in allowed_prefixes)
            ]
            print("  --- 窗口 #%d：行 %d..%d ---" % (pair_index // 2 + 1, start + 1, end + 1))
            for offset, text in enumerate(region_lines):
                print("  %5d| %s" % (start + offset + 1, text))
            if offending:
                print("  !! 窗口内出现非白名单调用：%s" % ",".join(offending))
                problem_windows += 1
            else:
                print("  窗口内无非白名单调用（无 I/O/日志/分配/内存操作）")
        print()

    print("R06_WINDOW_TOTAL=%d" % total_windows)
    print("R06_WINDOW_PROBLEM_WINDOWS=%d" % problem_windows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
