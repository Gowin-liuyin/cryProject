#!/usr/bin/env python3
"""在**不修改冻结树**的前提下，把 M1 两版与 M5 的普通采集件在 clang-18 的
`-O0 / -O2 / -O3 / -Os` 四个级别各重建一份，供 T22 反汇编判定与 T23 锁频计时使用。

口径（写进 r09-optlevel PLAN 的同一条）：
  * 每个格子里，**该臂的全部 C 源**（实现 + 封装层 + 采集件 + Memcheck 探针）
    都用同一个 `-O<级别>` 编译，其他标志逐字沿用冻结树
    `compile_commands.json` 里的那一条（含 `OQS_DIST_BUILD=OFF`、
    `OQS_OPT_TARGET=generic`、`OQS_USE_AVX2_INSTRUCTIONS=OFF` 等构建期条件，
    以及 historical 的 `-fno-vectorize`）。只有 `-O*` 一个 token 被替换。
  * `build_identity.h` 由本脚本在新根内重新生成，如实记录级别与完整命令；
    冻结树自带的旧 `build_identity.h` 只作为被覆盖的搜索路径，不参与本格。

M1 liboqs 对象由 `build_liboqs_cell.py` 按冻结归档的成员 sha256 反查编译命令重建。
"""

import argparse
import hashlib
import json
import os
import shlex
import shutil
import subprocess
import sys

CLANG18 = "/usr/bin/clang-18"
OPTIMIZATION_LEVELS = {"O0": "-O0", "O2": "-O2", "O3": "-O3", "Os": "-Os"}
OPTIMIZATION_FLAG_PATTERN = ("-O0", "-O1", "-O2", "-O3", "-Os", "-Oz", "-Og", "-Ofast")


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as source:
        for chunk in iter(lambda: source.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


class BuildLog:
    def __init__(self, path):
        self.path = path
        self.lines = []

    def record(self, label, command_text, completed):
        self.lines.append("%s_compile_command=%s" % (label, command_text))
        self.lines.append("%s_exit_code=%d" % (label, completed.returncode))
        if completed.stdout.strip():
            self.lines.append("%s_stdout=%s" % (label, completed.stdout.strip()))
        if completed.stderr.strip():
            self.lines.append("%s_stderr=%s" % (label, completed.stderr.strip()))

    def note(self, text):
        self.lines.append(text)

    def flush(self):
        with open(self.path, "w") as output:
            output.write("\n".join(self.lines) + "\n")


def load_compile_commands(tree_root, relative_path):
    path = os.path.join(tree_root, relative_path)
    with open(path) as source:
        entries = json.load(source)
    return path, entries


def find_entry(entries, absolute_source_path, object_suffix):
    """按**目标对象路径**唯一匹配编译命令。

    同一个 `src/random.c` 会被多个 CMake 目标各编译一次，只按源文件名或绝对路径
    都会撞车；`CMakeFiles/<target>.dir/<source>.o` 才能唯一确定"哪一个目标的哪一份"。
    """
    matches = [
        entry
        for entry in entries
        if entry["file"] == absolute_source_path and entry["output"].endswith(object_suffix)
    ]
    if len(matches) != 1:
        raise SystemExit(
            "expected exactly one compile command for %s via %s, found %d"
            % (absolute_source_path, object_suffix, len(matches))
        )
    return matches[0]


def rewrite_command(entry, level_flag, output_path, leading_includes):
    tokens = shlex.split(entry["command"])
    rewritten = [tokens[0]]
    for include_directory in leading_includes:
        rewritten.extend(["-I", include_directory])
    index = 1
    replaced_output = False
    while index < len(tokens):
        token = tokens[index]
        if token == "-o" and index + 1 < len(tokens):
            rewritten.extend(["-o", output_path])
            replaced_output = True
            index += 2
            continue
        if token in OPTIMIZATION_FLAG_PATTERN:
            rewritten.append(level_flag)
            index += 1
            continue
        rewritten.append(token)
        index += 1
    if not replaced_output:
        raise SystemExit("compile command without -o: %s" % entry["command"])
    return rewritten


def run_command(command, working_directory, log, label):
    command_text = " ".join(shlex.quote(token) for token in command)
    completed = subprocess.run(
        command, cwd=working_directory, capture_output=True, text=True
    )
    log.record(label, command_text, completed)
    if completed.returncode != 0:
        log.flush()
        raise SystemExit("%s failed with %d" % (label, completed.returncode))
    return command_text


def write_build_identity(path, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as output:
        output.write("#ifndef BASELINE_BUILD_IDENTITY_H\n#define BASELINE_BUILD_IDENTITY_H\n")
        output.write("static const char *const build_identity_lines[] = {\n")
        for line in lines:
            escaped = line.replace("\\", "\\\\").replace('"', '\\"')
            output.write('"%s\\n",\n' % escaped)
        output.write("};\n#endif\n")


def arm_definitions(cry_root):
    m1_root = os.path.join(cry_root, "liboqs010-historical-20261015-86131c2")
    m5_root = os.path.join(cry_root, "platform-m5-20261016-30efdf66eb26")
    return {
        "m1unfixed": {
            "kind": "liboqs010",
            "tree": m1_root,
            "frozen_build_dir": os.path.join(m1_root, "build", "historical-clangover"),
            "source_export": os.path.join(m1_root, "SOURCE_EXPORT.sha256"),
            "implementation": "liboqs-0.10.0-historical-clangover-unfixed",
            "symbol": "pqcrystals_ml_kem_768_ipd_ref_poly_frommsg",
            "poison_source": os.path.join(m1_root, "tools", "historical_poison.c"),
            "poison_probe_name": "historical_poison_cell",
        },
        "m1fixed": {
            "kind": "liboqs010",
            "tree": m1_root,
            "frozen_build_dir": os.path.join(
                m1_root, "build", "historical-fixed-982c762"
            ),
            "source_export": os.path.join(m1_root, "SOURCE_EXPORT.sha256"),
            "implementation": "liboqs-0.10.0-plus-982c762-fixed",
            "symbol": "pqcrystals_ml_kem_768_ipd_ref_poly_frommsg",
            "poison_source": os.path.join(m1_root, "tools", "historical_poison.c"),
            "poison_probe_name": "historical_poison_cell",
        },
        "m5ref": {
            "kind": "mlkem_native",
            "tree": m5_root,
            "source_tree": os.path.join(m5_root, "source-v2"),
            "frozen_build_dir": os.path.join(m5_root, "build-v2-ordinary"),
            "source_export": os.path.join(
                m5_root, "source-v2", "SOURCE_EXPORT.sha256"
            ),
            "implementation": "mlkem-native-b3ba7b3-portable-reference",
            "symbol": "baseline_native_poly_frommsg",
            "poison_source": os.path.join(
                m5_root, "source-v2", "tools", "platform_m5", "poison.c"
            ),
            "poison_probe_name": "platform_m5_poison_cell",
        },
    }


def build_liboqs_arm(arguments, arm, level_name, level_flag, cell_root, log):
    frozen_build_dir = arm["frozen_build_dir"]
    object_directory = os.path.join(cell_root, "liboqs-objects")
    archive_path = os.path.join(cell_root, "liboqs.a")
    liboqs_log = os.path.join(cell_root, "liboqs-build.log")
    completed = subprocess.run(
        [
            sys.executable,
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_liboqs_cell.py"),
            "--frozen-build-dir",
            frozen_build_dir,
            "--level=%s" % level_flag,
            "--object-dir",
            object_directory,
            "--output-archive",
            archive_path,
            "--log",
            liboqs_log,
        ],
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        log.note("liboqs_rebuild_failed=%s" % completed.stderr.strip())
        log.flush()
        raise SystemExit("liboqs rebuild failed for %s" % cell_root)
    log.note("liboqs_archive=%s" % archive_path)
    log.note("liboqs_archive_sha256=%s" % sha256_file(archive_path))
    with open(liboqs_log) as source:
        command_count = sum(1 for line in source if line.startswith("compile_command="))
    log.note("liboqs_translation_units=%d" % command_count)

    tree = arm["tree"]
    compile_commands_path, entries = load_compile_commands(
        os.path.join(frozen_build_dir), "compile_commands.json"
    )
    if not os.path.isabs(compile_commands_path):
        compile_commands_path = os.path.join(frozen_build_dir, compile_commands_path)
    log.note("compile_commands=%s" % compile_commands_path)
    log.note("compile_commands_sha256=%s" % sha256_file(compile_commands_path))

    include_install = os.path.join(frozen_build_dir, "liboqs010-install", "include")
    generated_directory = os.path.join(cell_root, "generated")
    write_build_identity(
        os.path.join(generated_directory, "build_identity.h"),
        [
            "cell=%s" % os.path.basename(cell_root),
            "arm=%s" % arm["implementation"],
            "optimization_level=%s" % level_flag,
            "source_identity_kind=verified_source_export_of_frozen_tree",
            "frozen_tree=%s" % tree,
            "frozen_source_export_manifest_sha256=%s" % sha256_file(arm["source_export"]),
            "compiler_command=%s" % CLANG18,
            "cell_build_script=%s" % os.path.abspath(__file__),
            "cell_build_script_sha256=%s" % sha256_file(os.path.abspath(__file__)),
            "cell_scope=implementation_plus_wrapper_plus_harness_all_at_same_level",
            "project_cmake_configuration=not_used_cell_built_from_frozen_compile_commands",
            "note=frozen tree read-only; only the -O token was replaced",
        ],
    )

    wrapper_objects = []
    for order, source_suffix in enumerate(
        ["src/mlkem_liboqs010.c", "src/random.c", "src/inputs_liboqs010.c"]
    ):
        entry = find_entry(
            entries,
            os.path.join(tree, source_suffix),
            "CMakeFiles/mlkem_historical.dir/" + source_suffix + ".o",
        )
        output_path = os.path.join(cell_root, "obj", "wrapper%02d.o" % order)
        command = rewrite_command(entry, level_flag, output_path, [generated_directory])
        run_command(command, entry["directory"], log, "wrapper_%d" % order)
        wrapper_objects.append(output_path)

    measure_entry = find_entry(
        entries,
        os.path.join(tree, "src/measure.c"),
        "CMakeFiles/historical_measure.dir/src/measure.c.o",
    )
    measure_object = os.path.join(cell_root, "obj", "measure.o")
    measure_command = rewrite_command(
        measure_entry, level_flag, measure_object, [generated_directory]
    )
    run_command(measure_command, measure_entry["directory"], log, "measure")

    measure_elf = os.path.join(cell_root, "measure")
    link_command = [
        CLANG18,
        level_flag,
        "-g",
        "-DNDEBUG",
        "-o",
        measure_elf,
        measure_object,
    ] + wrapper_objects + [archive_path, "-lpthread", "-lm"]
    run_command(link_command, cell_root, log, "link_measure")

    # Memcheck 探针沿用与 measure 完全相同的包含路径、宏和级别，只把被编译的
    # 翻译单元换成冻结树既有的探针源（tools/historical_poison.c）。
    poison_object = os.path.join(cell_root, "obj", "poison_probe.o")
    poison_command = [CLANG18, "-I", generated_directory]
    measure_tokens = shlex.split(measure_entry["command"])
    index = 1
    while index < len(measure_tokens):
        token = measure_tokens[index]
        if token == "-o":
            index += 2
            continue
        if token == "-c":
            index += 2
            continue
        if token in OPTIMIZATION_FLAG_PATTERN:
            poison_command.append(level_flag)
            index += 1
            continue
        poison_command.append(token)
        index += 1
    poison_command.extend(["-c", arm["poison_source"], "-o", poison_object])
    run_command(poison_command, cell_root, log, "poison_probe")
    poison_elf = os.path.join(cell_root, arm["poison_probe_name"])
    run_command(
        [CLANG18, level_flag, "-g", "-DNDEBUG", "-o", poison_elf, poison_object]
        + wrapper_objects
        + [archive_path, "-lpthread", "-lm"],
        cell_root,
        log,
        "link_poison_probe",
    )
    return measure_elf, poison_elf


def build_mlkem_native_arm(arguments, arm, level_name, level_flag, cell_root, log):
    tree = arm["source_tree"]
    frozen_build_dir = arm["frozen_build_dir"]
    compile_commands_path, entries = load_compile_commands(
        frozen_build_dir, "compile_commands.json"
    )
    log.note("compile_commands=%s" % compile_commands_path)
    log.note("compile_commands_sha256=%s" % sha256_file(compile_commands_path))
    generated_directory = os.path.join(cell_root, "generated")
    write_build_identity(
        os.path.join(generated_directory, "build_identity.h"),
        [
            "cell=%s" % os.path.basename(cell_root),
            "arm=%s" % arm["implementation"],
            "optimization_level=%s" % level_flag,
            "source_identity_kind=verified_source_export_of_frozen_tree",
            "frozen_tree=%s" % tree,
            "frozen_source_export_manifest_sha256=%s" % sha256_file(arm["source_export"]),
            "compiler_command=%s" % CLANG18,
            "cell_build_script=%s" % os.path.abspath(__file__),
            "cell_build_script_sha256=%s" % sha256_file(os.path.abspath(__file__)),
            "cell_scope=implementation_plus_wrapper_plus_harness_all_at_same_level",
            "project_cmake_configuration=not_used_cell_built_from_frozen_compile_commands",
            "note=frozen tree read-only; only the -O token was replaced",
        ],
    )

    library_objects = []
    for order, source_suffix in enumerate(
        ["src/kernel.c", "src/mlkem.c", "src/random.c", "src/inputs.c"]
    ):
        entry = find_entry(
            entries,
            os.path.join(tree, source_suffix),
            "CMakeFiles/mlkem_reference.dir/" + source_suffix + ".o",
        )
        output_path = os.path.join(cell_root, "obj", "library%02d.o" % order)
        command = rewrite_command(entry, level_flag, output_path, [generated_directory])
        run_command(command, entry["directory"], log, "library_%d" % order)
        library_objects.append(output_path)
    library_path = os.path.join(cell_root, "libmlkem_cell.a")
    run_command(["/usr/bin/ar", "rcs", library_path] + library_objects, cell_root, log, "ar_library")

    measure_entry = find_entry(
        entries,
        os.path.join(tree, "src/measure.c"),
        "CMakeFiles/reference_measure.dir/src/measure.c.o",
    )
    measure_object = os.path.join(cell_root, "obj", "measure.o")
    command = rewrite_command(
        measure_entry, level_flag, measure_object, [generated_directory]
    )
    run_command(command, measure_entry["directory"], log, "measure")
    measure_elf = os.path.join(cell_root, "measure")
    run_command(
        [CLANG18, level_flag, "-g", "-DNDEBUG", "-o", measure_elf, measure_object, library_path],
        cell_root,
        log,
        "link_measure",
    )

    poison_command = [
        CLANG18,
        '-DMLK_CONFIG_FILE="baseline_config.h"',
        "-DPLATFORM_M5_HAVE_VALGRIND=1",
        "-I",
        os.path.join(tree, "include"),
        "-I",
        os.path.join(tree, "vendor", "mlkem-native", "mlkem"),
        "-isystem",
        "/usr/include",
        level_flag,
        "-g",
        "-DNDEBUG",
        "-std=c11",
        "-c",
        arm["poison_source"],
        "-o",
        os.path.join(cell_root, "obj", "poison_probe.o"),
    ]
    run_command(poison_command, cell_root, log, "poison_probe")
    poison_elf = os.path.join(cell_root, arm["poison_probe_name"])
    run_command(
        [
            CLANG18,
            level_flag,
            "-g",
            "-DNDEBUG",
            "-o",
            poison_elf,
            os.path.join(cell_root, "obj", "poison_probe.o"),
            library_path,
        ],
        cell_root,
        log,
        "link_poison_probe",
    )
    return measure_elf, poison_elf


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--cry-root", default="/home/nss-marker/yhr/Cry")
    parser.add_argument("--arms", default="m1unfixed,m1fixed,m5ref")
    parser.add_argument("--levels", default="O0,O2,O3,Os")
    arguments = parser.parse_args()

    os.makedirs(arguments.root, exist_ok=True)
    os.makedirs(os.path.join(arguments.root, "tmp"), exist_ok=True)
    os.environ["TMPDIR"] = os.path.join(arguments.root, "tmp")
    os.environ["TMP"] = os.environ["TMPDIR"]
    os.environ["TEMP"] = os.environ["TMPDIR"]
    os.environ["XDG_CACHE_HOME"] = os.path.join(arguments.root, "cache")

    definitions = arm_definitions(arguments.cry_root)
    summary = []
    for arm_name in arguments.arms.split(","):
        arm = definitions[arm_name]
        for level_name in arguments.levels.split(","):
            level_flag = OPTIMIZATION_LEVELS[level_name]
            cell_name = "%s-%s" % (arm_name, level_name)
            cell_root = os.path.join(arguments.root, "build", cell_name)
            os.makedirs(os.path.join(cell_root, "obj"), exist_ok=True)
            log = BuildLog(os.path.join(cell_root, "build.log"))
            log.note("cell=%s" % cell_name)
            log.note("level=%s" % level_flag)
            log.note("compiler=%s" % CLANG18)
            if arm["kind"] == "liboqs010":
                measure_elf, poison_elf = build_liboqs_arm(
                    arguments, arm, level_name, level_flag, cell_root, log
                )
            else:
                measure_elf, poison_elf = build_mlkem_native_arm(
                    arguments, arm, level_name, level_flag, cell_root, log
                )
            log.note("measure_elf=%s" % measure_elf)
            log.note("measure_elf_sha256=%s" % sha256_file(measure_elf))
            log.note("poison_probe_elf=%s" % poison_elf)
            log.note("poison_probe_elf_sha256=%s" % sha256_file(poison_elf))
            log.flush()
            summary.append(
                "%s measure=%s poison=%s"
                % (cell_name, sha256_file(measure_elf), sha256_file(poison_elf))
            )
            print("built %s" % cell_name, flush=True)

    with open(os.path.join(arguments.root, "CELLS.sha256"), "w") as output:
        output.write("\n".join(summary) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
