#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""为 T25 网络场景构建三套 network_client / network_server。

臂与来源（全部复用远端已冻结的构建，不重新编译 liboqs）：

  m5ref      mlkem-native 参考路径：仓库默认 CMake 目标（mlkem_reference）
  m1unfixed  liboqs 0.10.0 未修：冻结树 build/historical-clangover
  m1fixed    liboqs 0.10.0 + 官方修复 982c762：冻结树 build/historical-fixed-982c762

M1 两臂沿用 R09 的做法：从冻结树的 compile_commands.json 取编译参数，
按对象 sha256 把 liboqs.a 的归档成员映射回编译条目，再用同一组参数编译
network_client / network_server / network_frame / inputs / random / mlkem，
最后与 liboqs.a 一起链接。这样「判定的二进制」与「计时的二进制」来自同一次构建。

约束：
  * 只在 Cry 之下写文件；临时文件、缓存、日志都在输出根之下，不写 /tmp。
  * 不改写冻结树与 vendor 原件；每个臂的构建目录独立，产物不混用。
  * 每次构建都记录工具摘要、编译命令与产物摘要。

用法：
  build_network_arms.py --cry-root /home/nss-marker/yhr/Cry \
      --source-root <当前仓库源码根> \
      --output-root /home/nss-marker/yhr/Cry/r13-network-20261020/runs/arms
"""

import argparse
import hashlib
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

LINK_FLAGS = ["-fno-pie", "-no-pie"]


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(command, cwd=None, log_path=None, env=None):
    completed = subprocess.run(
        command, cwd=cwd, env=env, check=False,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    if log_path is not None:
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write("$ %s\n" % " ".join(shlex.quote(part) for part in command))
            handle.write(completed.stdout)
    if completed.returncode != 0:
        sys.stderr.write("command failed (%d): %s\n" % (completed.returncode, " ".join(command)))
        sys.stderr.write(completed.stdout[-4000:])
        raise SystemExit(completed.returncode)
    return completed.stdout


def archive_members(archive_path, scratch_directory):
    """按**成员顺序**读 ar 归档，返回 (成员名, 解出文件路径, sha256)。

    不用 `ar p <name>`：归档里 `kem.c.o` 这类同名成员会出现两次，`ar p` 只会
    取到第一个，第二份内容会被静默丢掉。`ar` 归档头是定长的，这里直接按字节解析，
    保证不重不漏（与 tools/platform_optlevel/build_liboqs_cell.py 同一实现）。
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
    scratch_root = Path(scratch_directory)
    scratch_root.mkdir(parents=True, exist_ok=True)
    for index, (member_name, body) in enumerate(raw_members):
        unique_path = str(scratch_root / ("member%03d_%s" % (index, member_name)))
        with open(unique_path, "wb") as member_file:
            member_file.write(body)
        extracted.append((member_name, unique_path, hashlib.sha256(body).hexdigest()))
    return extracted


def map_members_to_entries(members, compile_commands, liboqs_build_directory):
    """按对象 sha256 把归档成员映射回编译条目；映射不唯一即失败。"""
    entry_by_digest = {}
    for index, entry in enumerate(compile_commands):
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
            unresolved.append((member_name, len(candidates)))
            continue
        selected.append((member_name, member_path, candidates[0]))
    if unresolved:
        raise SystemExit("unresolved archive members: %r" % (unresolved,))
    return selected


def rewrite_object_flag(tokens, object_path):
    rewritten = []
    skip_next = False
    for token in tokens:
        if skip_next:
            rewritten.append(object_path)
            skip_next = False
            continue
        if token == "-o":
            rewritten.append(token)
            skip_next = True
            continue
        rewritten.append(token)
    return rewritten


def build_m1_arm(arm_name, frozen_root, build_directory_name, source_root, output_root, log):
    """按 R09 的做法，从冻结的 liboqs 构建产物编译并链接该臂的客户端/服务端。"""
    frozen_tree = Path(frozen_root)
    build_directory = frozen_tree / "build" / build_directory_name
    # liboqs 是 ExternalProject：真正的对象与 compile_commands 在 liboqs010-build 子目录下，
    # 归档安装件在 liboqs010-install 下。
    liboqs_build_directory = build_directory / "liboqs010-build"
    compile_commands_path = liboqs_build_directory / "compile_commands.json"
    archive_path = build_directory / "liboqs010-install" / "lib" / "liboqs.a"
    for required in (compile_commands_path, archive_path):
        if not required.is_file():
            raise SystemExit("missing frozen artifact: %s" % required)
    compile_commands = json.load(open(compile_commands_path, encoding="utf-8"))

    arm_root = output_root / ("build-" + arm_name)
    arm_root.mkdir(parents=True, exist_ok=True)
    object_directory = arm_root / "obj"
    object_directory.mkdir(exist_ok=True)

    # 归档成员解到独立 scratch 目录，再按 sha256 映射回编译条目。
    members = archive_members(archive_path, str(arm_root / "scratch"))
    selected = map_members_to_entries(members, compile_commands, str(liboqs_build_directory))
    shutil.rmtree(arm_root / "scratch", ignore_errors=True)

    environment = dict(os.environ)
    environment["TMPDIR"] = str(arm_root / "tmp")
    Path(environment["TMPDIR"]).mkdir(exist_ok=True)

    object_paths = []
    for order, (member_name, _member_path, entry_index) in enumerate(selected):
        entry = compile_commands[entry_index]
        tokens = shlex.split(entry["command"])
        object_path = str(object_directory / ("member%03d_%s" % (order, member_name)))
        tokens = rewrite_object_flag(tokens, object_path)
        run(tokens, cwd=entry["directory"], log_path=log, env=environment)
        object_paths.append(object_path)

    # 客户端与服务端共用同一臂的实现：mlkem_liboqs010.c（解封装）+ inputs_liboqs010.c（输入生成）。
    arm_sources = {
        "network_client": [source_root / "src/network_client.c", source_root / "src/network_frame.c"],
        "network_server": [source_root / "src/network_server.c", source_root / "src/network_frame.c"],
    }
    common_sources = [
        source_root / "src/mlkem_liboqs010.c",
        source_root / "src/inputs_liboqs010.c",
        source_root / "src/random.c",
    ]
    include_flags = [
        "-I" + str(source_root / "include"),
        "-I" + str(frozen_tree / "include"),
        "-I" + str(frozen_tree / "vendor/liboqs-0.10.0" / "src/common"),
        "-I" + str(build_directory / "liboqs010-install" / "include"),
        # measure.c 需要构建身份头（由 CMake 的 build_identity 目标生成）。
        "-I" + str(build_directory / "generated" / "RelWithDebInfo"),
    ]
    binaries = {}
    for program, sources in arm_sources.items():
        binary_path = str(arm_root / program)
        objects = []
        for source in list(sources) + common_sources:
            object_path = str(object_directory / (program + "_" + source.name + ".o"))
            command = [
                "/usr/bin/clang", "-std=c11", "-O2", "-g", "-DNDEBUG",
                "-DBASELINE_HISTORICAL=1",
                "-Wall", "-Wextra", "-Wpedantic",
            ] + include_flags + ["-c", str(source), "-o", object_path]
            run(command, cwd=str(source_root), log_path=log, env=environment)
            objects.append(object_path)
        link_command = [
            "/usr/bin/clang", "-o", binary_path,
        ] + objects + object_paths + [
            str(build_directory / "liboqs010-install" / "lib" / "liboqs.a"),
            "-lm", "-lpthread",
        ] + LINK_FLAGS
        run(link_command, cwd=str(source_root), log_path=log, env=environment)
        binaries[program] = binary_path

    # 本地直调基线：measure.c（完整解封装，不走 socket），与网络端同一臂、同一实现。
    measure_path = str(arm_root / "measure")
    measure_objects = []
    for source in (source_root / "src/measure.c",) + tuple(common_sources):
        object_path = str(object_directory / ("measure_" + source.name + ".o"))
        command = [
            "/usr/bin/clang", "-std=c11", "-O2", "-g", "-DNDEBUG",
            "-DBASELINE_HISTORICAL=1",
            "-Wall", "-Wextra", "-Wpedantic",
        ] + include_flags + ["-c", str(source), "-o", object_path]
        run(command, cwd=str(source_root), log_path=log, env=environment)
        measure_objects.append(object_path)
    run([
        "/usr/bin/clang", "-o", measure_path,
    ] + measure_objects + object_paths + [
        str(build_directory / "liboqs010-install" / "lib" / "liboqs.a"),
        "-lm", "-lpthread",
    ] + LINK_FLAGS, cwd=str(source_root), log_path=log, env=environment)
    binaries["measure"] = measure_path

    identity = {
        "arm": arm_name,
        "frozen_tree": str(frozen_tree),
        "frozen_build": str(build_directory),
        "liboqs_archive_sha256": sha256_file(archive_path),
        "liboqs_build_directory": str(liboqs_build_directory),
        "compile_commands_sha256": sha256_file(compile_commands_path),
        "member_objects": len(object_paths),
        "binaries": {
            program: {"path": path, "sha256": sha256_file(path)}
            for program, path in binaries.items()
        },
    }
    identity_path = arm_root / "identity.json"
    identity_path.write_text(json.dumps(identity, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return binaries


def build_reference_arm(source_root, output_root, log):
    """m5ref：仓库默认 CMake 目标，不依赖 liboqs。"""
    arm_root = output_root / "build-m5ref"
    arm_root.mkdir(parents=True, exist_ok=True)
    build_directory = arm_root / "cmake"
    environment = dict(os.environ)
    environment["TMPDIR"] = str(arm_root / "tmp")
    Path(environment["TMPDIR"]).mkdir(exist_ok=True)
    run(["cmake", "-S", str(source_root), "-B", str(build_directory),
         "-DCMAKE_BUILD_TYPE=RelWithDebInfo", "-DBUILD_TESTING=ON"],
        log_path=log, env=environment)
    run(["cmake", "--build", str(build_directory),
         "--target", "network_client", "network_server", "reference_benchmark",
         "--parallel", "4"],
        log_path=log, env=environment)
    binaries = {}
    for program in ("network_client", "network_server"):
        candidate = build_directory / program
        if not candidate.is_file():
            raise SystemExit("missing built program: %s" % candidate)
        binaries[program] = str(candidate)
    # 本地直调基线：完全不走 socket 的完整解封装测量（measure.c）。
    # 参考臂的 reference_benchmark 带 BASELINE_ORDINARY_WORKLOAD，只覆盖 3 类输入
    # （valid / bit-flipped / random）；本地直调基线要与网络端一样覆盖 5 类
    # （含 message-zero / message-ones），因此这里单独编译一个不带该宏的 measure，
    # 与 M1 两臂同口径。SHA3 走 mlkem-native 的 fips202（measure.c 的默认分支）。
    measure_path = str(arm_root / "measure")
    identity_include = str(build_directory / "generated" / "RelWithDebInfo")
    fips202_sources = sorted(
        (source_root / "vendor/mlkem-native/mlkem/src/fips202").rglob("*.c")
    )
    if not fips202_sources:
        raise SystemExit("missing mlkem-native fips202 sources")
    measure_objects = []
    for source in [source_root / "src/measure.c"] + fips202_sources:
        object_path = str(arm_root / ("measure_" + source.name + ".o"))
        run([
            "/usr/bin/clang", "-std=c11", "-O2", "-g", "-DNDEBUG",
            "-Wall", "-Wextra", "-Wpedantic",
            "-I" + str(source_root / "include"),
            "-I" + identity_include,
            "-I" + str(source_root / "vendor/mlkem-native/mlkem"),
            "-I" + str(source_root / "vendor/mlkem-native/mlkem/src/fips202"),
            "-c", str(source), "-o", object_path,
        ], cwd=str(source_root), log_path=log, env=environment)
        measure_objects.append(object_path)
    reference_library = build_directory / "reference" / "libmlkem.a"
    if not reference_library.is_file():
        raise SystemExit("missing reference library: %s" % reference_library)
    run([
        "/usr/bin/clang", "-o", measure_path,
    ] + measure_objects + [
        str(reference_library),
        "-lm", "-lpthread",
    ], cwd=str(source_root), log_path=log, env=environment)
    binaries["measure"] = measure_path
    identity = {
        "arm": "m5ref",
        "source_root": str(source_root),
        "binaries": {
            program: {"path": path, "sha256": sha256_file(path)}
            for program, path in binaries.items()
        },
    }
    (arm_root / "identity.json").write_text(
        json.dumps(identity, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return binaries


def main():
    parser = argparse.ArgumentParser(description="构建 T25 网络场景的三套臂")
    parser.add_argument("--cry-root", required=True)
    parser.add_argument("--source-root", required=True)
    parser.add_argument("--output-root", required=True)
    arguments = parser.parse_args()

    cry_root = Path(arguments.cry_root)
    source_root = Path(arguments.source_root).resolve()
    output_root = Path(arguments.output_root)
    if not str(output_root).startswith(str(cry_root) + "/"):
        raise SystemExit("output root must be under the Cry root")
    if output_root.exists():
        raise SystemExit("output root must be new")
    output_root.mkdir(parents=True)
    output_root = output_root.resolve()

    frozen_root = cry_root / "liboqs010-historical-20261015-86131c2"
    log_path = output_root / "build.log"

    arms = {}
    arms["m5ref"] = build_reference_arm(source_root, output_root, log_path)
    arms["m1unfixed"] = build_m1_arm(
        "m1unfixed", frozen_root, "historical-clangover", source_root, output_root, log_path)
    arms["m1fixed"] = build_m1_arm(
        "m1fixed", frozen_root, "historical-fixed-982c762", source_root, output_root, log_path)

    summary = {
        "source_root": str(source_root),
        "output_root": str(output_root),
        "arms": {
            arm: {
                program: {"path": path, "sha256": sha256_file(path)}
                for program, path in programs.items()
            }
            for arm, programs in arms.items()
        },
    }
    (output_root / "arms.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"arms": sorted(arms), "output_root": str(output_root)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
