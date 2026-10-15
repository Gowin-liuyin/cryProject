#!/usr/bin/env python3
"""按冻结的 liboqs 0.10.0 构建配置，只替换优化级别，重建 M1 两版的最小 liboqs 归档。

输入是冻结树里 ExternalProject 已经生成的 `compile_commands.json` 与 `liboqs.a`。
先用对象文件 sha256 把归档成员唯一映射回编译命令（同一 basename 会出现多次，
不能按名字猜），然后逐条把 `-O<级别>` 换成目标级别、把 `-o` 指向新根内的新对象，
其余标志逐字保留。这样"只有优化级别变化"是可核对的，而不是口头声明。

不写冻结树：输出对象、归档、日志全部落在调用方给出的新根路径下。
"""

import argparse
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile


OPTIMIZATION_FLAG_PATTERN = ("-O0", "-O1", "-O2", "-O3", "-Os", "-Oz", "-Og", "-Ofast")


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as source:
        for chunk in iter(lambda: source.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def archive_members(archive_path, scratch_directory):
    """按**成员顺序**读归档，返回 (成员名, 解出文件路径, sha256)。

    不用 `ar p <name>`：归档里 `kem.c.o` 这类同名成员会出现两次，`ar p` 只会
    取到第一个，第二份内容会被静默丢掉（本脚本第一版就是这么错的）。
    `ar` 归档头是定长的，这里直接按字节解析，保证不重不漏。
    """
    with open(archive_path, "rb") as archive_file:
        payload = archive_file.read()
    if not payload.startswith(b"!<arch>\n"):
        raise SystemExit("%s is not an ar archive" % archive_path)
    offset = 8
    long_names = b""
    raw_members = []
    while offset + 60 <= len(payload):
        header = payload[offset : offset + 60]
        name_field = header[0:16].decode("ascii", "replace").strip()
        size_field = header[48:58].decode("ascii", "replace").strip()
        if header[58:60] != b"`\n" or not size_field.isdigit():
            raise SystemExit("malformed ar header at offset %d" % offset)
        member_size = int(size_field)
        body_start = offset + 60
        body = payload[body_start : body_start + member_size]
        offset = body_start + member_size + (member_size % 2)
        if name_field == "//":
            long_names = body
            continue
        if name_field == "/":
            # GNU 归档符号索引；不是编译对象，跳过。
            continue
        if name_field.startswith("/") and name_field[1:].isdigit():
            name_offset = int(name_field[1:])
            terminator = long_names.find(b"/\n", name_offset)
            member_name = long_names[name_offset:terminator].decode("ascii", "replace")
        else:
            member_name = name_field.rstrip("/")
        raw_members.append((member_name, body))
    extracted = []
    for index, (member_name, body) in enumerate(raw_members):
        unique_path = os.path.join(
            scratch_directory, "member%03d_%s" % (index, member_name)
        )
        with open(unique_path, "wb") as member_file:
            member_file.write(body)
        extracted.append((member_name, unique_path, hashlib.sha256(body).hexdigest()))
    return extracted


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--frozen-build-dir", required=True)
    parser.add_argument("--level", required=True, choices=OPTIMIZATION_FLAG_PATTERN)
    parser.add_argument("--object-dir", required=True)
    parser.add_argument("--output-archive", required=True)
    parser.add_argument("--log", required=True)
    arguments = parser.parse_args()

    liboqs_build_directory = os.path.join(arguments.frozen_build_dir, "liboqs010-build")
    frozen_archive = os.path.join(
        arguments.frozen_build_dir, "liboqs010-install", "lib", "liboqs.a"
    )
    compile_commands_path = os.path.join(liboqs_build_directory, "compile_commands.json")
    entries = json.load(open(compile_commands_path))

    os.makedirs(arguments.object_dir, exist_ok=True)
    os.makedirs(os.path.dirname(arguments.output_archive), exist_ok=True)
    log_lines = []

    with tempfile.TemporaryDirectory(prefix="liboqs-members-", dir=arguments.object_dir) as scratch:
        members = archive_members(frozen_archive, scratch)
        # 归档成员 -> compile_commands 条目：按对象 sha256 唯一匹配。
        entry_by_digest = {}
        for index, entry in enumerate(entries):
            # CMake 生成的 output 是相对 **liboqs 顶层构建目录** 的路径，
            # 而不是相对 entry["directory"]（后者是子目录）。这里按顶层目录解析。
            output_path = entry["output"]
            if not os.path.isabs(output_path):
                output_path = os.path.join(liboqs_build_directory, output_path)
            if os.path.isfile(output_path):
                entry_by_digest.setdefault(sha256_file(output_path), []).append(index)
        selected = []
        unresolved = []
        for member_name, member_path, member_digest in members:
            candidates = entry_by_digest.get(member_digest, [])
            if len(candidates) != 1:
                unresolved.append((member_name, member_digest, len(candidates)))
                continue
            selected.append((member_name, candidates[0]))
        if unresolved:
            sys.stderr.write("unresolved archive members: %r\n" % (unresolved,))
            return 1

        object_paths = []
        for order, (member_name, entry_index) in enumerate(selected):
            entry = entries[entry_index]
            tokens = shlex.split(entry["command"])
            rewritten = []
            skip_next = False
            object_path = os.path.join(
                arguments.object_dir, "member%03d_%s" % (order, member_name)
            )
            for token in tokens:
                if skip_next:
                    rewritten.append(object_path)
                    skip_next = False
                    continue
                if token == "-o":
                    rewritten.append(token)
                    skip_next = True
                    continue
                if token in OPTIMIZATION_FLAG_PATTERN:
                    rewritten.append(arguments.level)
                    continue
                rewritten.append(token)
            if skip_next:
                sys.stderr.write("dangling -o in entry %d\n" % entry_index)
                return 1
            command_text = " ".join(shlex.quote(token) for token in rewritten)
            completed = subprocess.run(
                rewritten, cwd=liboqs_build_directory, capture_output=True, text=True
            )
            log_lines.append("member=%s" % member_name)
            log_lines.append("compile_command=%s" % command_text)
            log_lines.append("exit_code=%d" % completed.returncode)
            if completed.stdout:
                log_lines.append("stdout=%s" % completed.stdout.strip())
            if completed.stderr:
                log_lines.append("stderr=%s" % completed.stderr.strip())
            if completed.returncode != 0:
                open(arguments.log, "w").write("\n".join(log_lines) + "\n")
                return completed.returncode
            object_paths.append(object_path)

        if os.path.exists(arguments.output_archive):
            os.remove(arguments.output_archive)
        subprocess.run(
            ["/usr/bin/ar", "rcs", arguments.output_archive] + object_paths, check=True
        )
        log_lines.append("archive=%s" % arguments.output_archive)
        log_lines.append("archive_sha256=%s" % sha256_file(arguments.output_archive))
        log_lines.append("member_count=%d" % len(object_paths))

    open(arguments.log, "w").write("\n".join(log_lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
