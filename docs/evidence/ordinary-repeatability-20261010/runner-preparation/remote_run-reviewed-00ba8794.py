#!/usr/bin/env python3
"""固定普通参考完整调用的两批部署管理；统计只由固定C程序计算。"""

import datetime
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import resource
import shlex
import shutil
import signal
import stat
import subprocess
import sys
import tarfile
import time
import xml.etree.ElementTree as ElementTree

BASE = Path("/home/nss-marker/yhr/Cry")
STUDY = Path("docs/research/aris-ordinary-repeatability-20261010")
SOURCE_MANIFEST_SHA256 = "c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552"
SOURCE_MANIFEST_NAME = str(STUDY / "SOURCE_MANIFEST.json")
RUNNER_NAME = str(STUDY / "remote_run.py")
SOURCE_FILE_COUNT = 140
TOTAL_BYTES = 256 * 1024 * 1024
MIN_FREE_BYTES = 1024 * 1024 * 1024
TOOLS = ("reference_repeatability", "analyze_reference_repeatability", "reference_repeatability_kat")
TEST_NAMES = ("reference_repeatability_selfcheck", "reference_repeatability_analysis_selfcheck",
              "reference_repeatability_fixture_check", "reference_repeatability_nist_kat",
              "reference_repeatability_process_safety")
TEMP_NAMES = ("TMPDIR", "TMP", "TEMP", "XDG_CACHE_HOME", "CCACHE_DIR", "CLANG_MODULE_CACHE_PATH")
FIXTURE_PROMPT_SHA256 = "998e22dfb12efb14ce9fdff911ca634b13612819a1806f25da69adba7e16db91"
FIXTURE_EXPECTED_SHA256 = "9089ec6ff2424da9f2782b89b2f831a329a3e28d6e5e24b802b78ff36ac61cdf"
CSV_HEADER = ("phase,series,count,zero_count,sum_ns,min_ns,min_positive_ns,p50_ns,p90_ns,"
              "p99_ns,max_ns,mad_ns")
SIGNALS = {signal.SIGALRM, signal.SIGTERM, signal.SIGINT, signal.SIGHUP}


def check_argv(root_text, source_commit, batch):
    match = re.fullmatch(str(BASE) + r"/reference-repeatability-([0-9a-f]{7,40})-([0-9a-f]{8,32})", root_text)
    if not match or not re.fullmatch(r"[0-9a-f]{40}", source_commit) or batch not in ("e1", "e2"):
        raise ValueError("invalid fixed root, source commit or batch")
    if not source_commit.startswith(match.group(1)):
        raise ValueError("root commit prefix mismatch")


def check_relative_path(text):
    path = PurePosixPath(text)
    if not text or path.is_absolute() or str(path) != text or any(part in ("", ".", "..") for part in text.split("/")):
        raise ValueError("noncanonical source path")
    return text


def manifest_pins(value):
    if not isinstance(value, dict) or value.get("schema") != "reference-repeatability-source-manifest-v1":
        raise ValueError("invalid source manifest schema")
    entries = value.get("files")
    if not isinstance(entries, list) or len(entries) != SOURCE_FILE_COUNT:
        raise ValueError("source manifest must bind exactly 140 files")
    pins = {}
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"path", "bytes", "sha256"}:
            raise ValueError("invalid source manifest entry")
        name = check_relative_path(entry["path"])
        if name in pins or name in (SOURCE_MANIFEST_NAME, RUNNER_NAME):
            raise ValueError("duplicate or self-referential source pin")
        if type(entry["bytes"]) is not int or entry["bytes"] <= 0 or not isinstance(entry["sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", entry["sha256"]):
            raise ValueError("invalid source byte count or digest")
        pins[name] = dict(entry)
    return pins


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for block in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def tree_files(root):
    files = []
    for directory, child_directories, child_files in os.walk(root, followlinks=False):
        for name in child_directories + child_files:
            path = Path(directory) / name
            mode = path.lstat().st_mode
            if not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)):
                raise ValueError("nonregular or symlink project path: " + str(path))
            if stat.S_ISREG(mode):
                files.append(path)
    return sorted(files)


def physical_path(path):
    for component in (path, *path.parents):
        if component.is_symlink() or component.resolve(strict=True) != component:
            raise ValueError("project ancestor is not physical: " + str(component))
    if path != BASE and BASE not in path.parents:
        raise ValueError("project path escaped Cry")


def source_layout(source, pins):
    expected_files = set(pins) | {SOURCE_MANIFEST_NAME, RUNNER_NAME}
    actual_files = {str(path.relative_to(source)) for path in tree_files(source)}
    expected_directories = {str(parent) for name in expected_files for parent in PurePosixPath(name).parents
                            if str(parent) != "."}
    actual_directories = {str(Path(directory, name).relative_to(source))
                          for directory, children, _ in os.walk(source, followlinks=False) for name in children}
    if actual_files != expected_files or actual_directories != expected_directories:
        raise ValueError("source layout contains extra, missing or nonregular entries")


def save_json(path, value):
    with path.open("x", encoding="utf-8") as output_file:
        json.dump(value, output_file, ensure_ascii=True, indent=2)
        output_file.write("\n")


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def process_start_ticks(process_id):
    return int(Path(f"/proc/{process_id}/stat").read_text().rsplit(")", 1)[1].split()[19])


def deadline_interrupt(signum, frame):
    raise TimeoutError("administrative deadline or signal " + str(signum))


def cleanup_is_confirmed(leader_reaped, group_gone):
    return leader_reaped is True and group_gone is True


def export_is_safe(state, commands):
    return state.get("cleanup_unconfirmed") is False and all(
        record.get("supervisor_pid") is None or cleanup_is_confirmed(
            record.get("leader_reaped"), record.get("process_group_gone")) for record in commands)


def ownership_allows_freeze(batch_directory_owned, state, commands):
    return batch_directory_owned is True and export_is_safe(state, commands)


OUTPUT_NAMES = ("csv", "metadata", "analysis", "summary")


def accepted_pins_match(case, observed):
    if case.get("status") != "accepted" or not isinstance(observed, dict) or set(observed) != set(OUTPUT_NAMES):
        return False
    for name in OUTPUT_NAMES:
        record = observed[name]
        expected_bytes = case.get(name + "_bytes")
        expected_sha256 = case.get(name + "_sha256")
        if (not isinstance(record, dict) or record.get("regular_physical") is not True
                or type(expected_bytes) is not int or expected_bytes < 0
                or not isinstance(expected_sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", expected_sha256)
                or type(record.get("bytes")) is not int or record["bytes"] != expected_bytes
                or record.get("sha256") != expected_sha256):
            return False
    return True


def current_output_pin(path):
    try:
        physical_path(path)
        if not stat.S_ISREG(path.lstat().st_mode):
            raise ValueError("output is not regular")
        byte_count = path.stat().st_size
        digest = sha256(path)
        if path.stat().st_size != byte_count:
            raise ValueError("output length changed during hash")
        return {"regular_physical": True, "bytes": byte_count, "sha256": digest}
    except (OSError, ValueError) as error:
        return {"regular_physical": False, "bytes": None, "sha256": None,
                "observation_error": {"type": type(error).__name__, "message": str(error)}}


def frequency_paths():
    return [Path("/sys/devices/system/cpu/cpufreq/boost")] + [
        Path(f"/sys/devices/system/cpu/cpufreq/policy{cpu_index}/{field}")
        for cpu_index in range(32) for field in ("scaling_governor", "scaling_min_freq", "scaling_max_freq",
                                               "energy_performance_preference")]


def read_context():
    values = {"utc": utc(), "uname": list(os.uname()), "uid": os.getuid(),
              "effective_uid": os.geteuid(), "affinity": sorted(os.sched_getaffinity(0)),
              "free_bytes": shutil.disk_usage(BASE).free, "read_only_files": {}}
    paths = [Path("/proc/sys/kernel/random/boot_id"), Path("/proc/cpuinfo"), Path("/proc/loadavg"),
             Path("/proc/stat"), Path("/sys/devices/system/clocksource/clocksource0/current_clocksource")]
    for path in paths + frequency_paths():
        try:
            values["read_only_files"][str(path)] = {"text": path.read_text(), "errno": 0}
        except OSError as error:
            values["read_only_files"][str(path)] = {"text": None, "errno": error.errno}
    boot = values["read_only_files"]["/proc/sys/kernel/random/boot_id"]
    values["boot_id"] = boot["text"].strip() if boot["errno"] == 0 else None
    return values


def accept_context(value, user_id):
    if (not isinstance(value, dict) or type(value.get("uid")) is not int or type(value.get("effective_uid")) is not int
            or value["uid"] != user_id or value["effective_uid"] != user_id or type(user_id) is not int or user_id <= 0):
        raise ValueError("ordinary context user rejected")
    if (not isinstance(value.get("boot_id"), str) or not re.fullmatch(
            r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", value["boot_id"])):
        raise ValueError("boot identity unavailable")
    if not isinstance(value.get("uname"), list) or len(value["uname"]) != 5 or value["uname"][0] != "Linux" or value["uname"][4] != "x86_64":
        raise ValueError("context platform rejected")
    if not isinstance(value.get("affinity"), list) or 2 not in value["affinity"]:
        raise ValueError("CPU2 unavailable in caller context")
    if type(value.get("free_bytes")) is not int or value["free_bytes"] < MIN_FREE_BYTES:
        raise ValueError("context free-space budget rejected")
    return value["boot_id"]


def accept_metadata(value, user_id):
    expected = {"record_count": 50000, "valid_warmup_calls": 25000, "valid_main_calls": 25000,
                "planned_warmup_calls": 25000, "planned_main_calls": 25000,
                "attempted_call_count": 50000, "verified_output_call_count": 50000,
                "setup_call_count": 1, "setup_operation_status": 0, "uid": user_id, "effective_uid": user_id,
                "target_cpu": 2, "stop_errno": 0, "configuration_writes": 0, "uname_errno": 0,
                "original_affinity_errno": 0, "set_affinity_errno": 0, "dumpable_set_errno": 0,
                "dumpable_read_errno": 0, "dumpable_readback": 0, "fixture_group_id": 5, "fixture_case_id": 86}
    if not isinstance(value, dict) or any(type(value.get(key)) is not int or value[key] != expected_value
           for key, expected_value in expected.items()):
        raise ValueError("collector integer metadata rejected")
    if (value.get("contract") != "ordinary-reference-repeatability-v1" or value.get("clock") != "CLOCK_MONOTONIC_RAW"
            or value.get("stop_reason") != "completed" or value.get("partial_unknown") is not False
            or any(value.get(key) is not True for key in ("self_affinity_set", "reference_identity_verified",
                                                        "setup_verified", "dumpable_set_attempted", "dumpable_set_succeeded"))
            or value.get("fixture_source_commit") != "975de31eb83d87039ec88934fdc47d8c312b892d"
            or value.get("fixture_prompt_sha256") != FIXTURE_PROMPT_SHA256
            or value.get("fixture_expected_sha256") != FIXTURE_EXPECTED_SHA256
            or type(value.get("pid")) is not int or value["pid"] <= 0):
        raise ValueError("collector completion metadata rejected")
    system = value.get("uname")
    if not isinstance(system, dict) or system.get("sysname") != "Linux" or system.get("machine") != "x86_64":
        raise ValueError("collector kernel identity rejected")
    original = value.get("original_affinity")
    if (not isinstance(original, list) or not original or 2 not in original
            or any(type(cpu) is not int or cpu < 0 for cpu in original) or original != sorted(set(original))):
        raise ValueError("collector original affinity rejected")
    before, after = value.get("before"), value.get("after")
    for snapshot in (before, after):
        if (not isinstance(snapshot, dict) or snapshot.get("affinity") != [2]
                or type(snapshot["affinity"][0]) is not int):
            raise ValueError("collector CPU mask rejected")
        if snapshot.get("cpu2_check") is not True or type(snapshot.get("observed_cpu")) is not int or snapshot["observed_cpu"] != 2:
            raise ValueError("collector CPU observation rejected")
        if any(type(snapshot.get(key)) is not int or snapshot[key] != 0
               for key in ("clocksource_errno", "resolution_errno", "affinity_errno", "cpu_errno")):
            raise ValueError("collector environment errno rejected")
        if (snapshot.get("resolution_has_timespec") is not True
                or not isinstance(snapshot.get("clocksource"), str) or not snapshot["clocksource"]
                or any(type(snapshot.get(key)) is not int or snapshot[key] < 0
                       for key in ("resolution_seconds", "resolution_fractional_ns", "resolution_ns"))):
            raise ValueError("collector resolution or clocksource rejected")
        if (snapshot["resolution_fractional_ns"] >= 1000000000 or snapshot["resolution_ns"] !=
                snapshot["resolution_seconds"] * 1000000000 + snapshot["resolution_fractional_ns"]):
            raise ValueError("collector resolution arithmetic rejected")
    if any(before[key] != after[key] for key in
           ("clocksource", "resolution_seconds", "resolution_fractional_ns", "resolution_ns")):
        raise ValueError("collector environment changed")
    return value["pid"]


def accept_summary(value, table_text):
    if not isinstance(value, dict) or value.get("schema") != "reference-repeatability-analysis-v1" or value.get("status") != "descriptive_only" or value.get("units") != "ns":
        raise ValueError("C summary schema rejected")
    for key, expected in (("record_count", 50000), ("warmup_call_count", 25000), ("main_call_count", 25000)):
        if type(value.get(key)) is not int or value[key] != expected:
            raise ValueError("C summary count rejected")
    for key in ("phase_conservation_valid", "cross_phase_conservation_valid"):
        if value.get(key) is not True:
            raise ValueError("C conservation assertion rejected")
    for key in ("clock_precision_certified", "iid_claimed", "collector_stderr_checked", "collector_exit_checked",
                "complete_metadata_acceptance", "r02_signed_off", "r04_signed_off"):
        if value.get(key) is not False:
            raise ValueError("C scope flag rejected")
    for key in ("phase_boundary_gap_ns", "warmup_wall_ns", "main_wall_ns", "warmup_pair_sum_ns",
                "warmup_between_sum_ns", "main_pair_sum_ns", "main_between_sum_ns"):
        if type(value.get(key)) is not int or value[key] < 0:
            raise ValueError("C geometry value rejected")
    if (value["warmup_wall_ns"] != value["warmup_pair_sum_ns"] + value["warmup_between_sum_ns"]
            or value["main_wall_ns"] != value["main_pair_sum_ns"] + value["main_between_sum_ns"]):
        raise ValueError("C geometry accounting rejected")
    lines = table_text.splitlines()
    if not table_text.endswith("\n") or len(lines) != 7 or lines[0] != CSV_HEADER:
        raise ValueError("C six-row output rejected")
    names = ("within_pair_ns", "between_pairs_ns", "combined_ordered_read_increment_ns")
    for row_index, row in enumerate(lines[1:]):
        fields = row.split(",")
        if len(fields) != 12 or fields[0] != ("warmup" if row_index < 3 else "main") or fields[1] != names[row_index % 3]:
            raise ValueError("C table row layout rejected")
        for field_index, text in enumerate(fields[2:], 2):
            if field_index == 6 and text == "null":
                continue
            if not re.fullmatch(r"[0-9]+", text):
                raise ValueError("C table number rejected")
        count = int(fields[2])
        if count != (25000, 24999, 49999)[row_index % 3]:
            raise ValueError("C table count rejected")
        if (int(fields[3]) > count or any(int(fields[index]) > (1 << 64) - 1
                for index in (4, 5, 7, 8, 9, 10, 11))
                or not int(fields[5]) <= int(fields[7]) <= int(fields[8]) <= int(fields[9]) <= int(fields[10])):
            raise ValueError("C table integer range rejected")
        if fields[6] != "null" and not 0 < int(fields[6]) <= int(fields[10]):
            raise ValueError("C table positive minimum rejected")
        phase = "warmup" if row_index < 3 else "main"
        expected_sum = (value[phase + "_pair_sum_ns"], value[phase + "_between_sum_ns"], value[phase + "_wall_ns"])[row_index % 3]
        if int(fields[4]) != expected_sum:
            raise ValueError("C table/summary geometry mismatch")
    return True


def accept_prior_state(value, source_commit, runner_sha256, binaries, boot_id):
    expected_binaries = {f"build-{configuration}/{tool}" for configuration in ("ordinary", "sanitize") for tool in TOOLS}
    if (not isinstance(value, dict) or value.get("schema") != "reference-repeatability-remote-v1"
            or value.get("batch") != "e1" or value.get("source_commit") != source_commit
            or value.get("source_manifest_sha256") != SOURCE_MANIFEST_SHA256 or value.get("runner_sha256") != runner_sha256
            or value.get("status") != "completed" or value.get("boot_id") != boot_id
            or value.get("cleanup_unconfirmed") is not False or value.get("all_child_work_stopped") is not True
            or type(value.get("accepted_processes")) is not int or value["accepted_processes"] != 3
            or type(value.get("accepted_timed_calls")) is not int or value["accepted_timed_calls"] != 150000
            or type(value.get("completed_processes")) is not int or value["completed_processes"] != 3
            or not isinstance(value.get("binary_sha256"), dict) or set(value["binary_sha256"]) != expected_binaries
            or value["binary_sha256"] != binaries):
        raise ValueError("E2 requires completed E1 with identical source, runner, boot and six ELF files")
    cases = value.get("cases")
    if (not isinstance(cases, list) or len(cases) != 3 or [case.get("name") for case in cases] != ["P1", "P2", "P3"]
            or any(case.get("status") != "accepted" or case.get("partial_unknown") is not False
                   or case.get("collector_started") is not True or case.get("collector_completed") is not True
                   or case.get("management_complete_metadata_acceptance") is not True for case in cases)):
        raise ValueError("E1 case acceptance incomplete")
    qualification = value.get("functional_qualification_accounting")
    if (not isinstance(qualification, dict) or qualification.get("status") != "completed"
            or qualification.get("completed_configurations") != ["ordinary", "sanitize"]
            or type(qualification.get("exact_completed_full_algorithm_calls")) is not int
            or qualification["exact_completed_full_algorithm_calls"] != 132
            or any(type(qualification.get(key)) is not int or qualification[key] != count
                   for key, count in (("decapsulation_calls", 24), ("key_generation_calls", 54), ("encapsulation_calls", 54)))):
        raise ValueError("E1 full qualification accounting incomplete")
    return True


def check_compile_flags(commands, configuration):
    if not isinstance(commands, list) or not commands:
        raise ValueError("empty compile commands")
    for entry in commands:
        arguments = entry.get("arguments") or shlex.split(entry.get("command", ""))
        if not arguments or arguments[0] != "/usr/bin/gcc" or "-std=c11" not in arguments or "-Werror" not in arguments:
            raise ValueError("unexpected compiler or language flags")
        if any("-flto" in argument or "BASELINE_VULNERABLE" in argument or "BASELINE_HARDENED" in argument
               or "BASELINE_DEPLOYABLE" in argument for argument in arguments):
            raise ValueError("LTO or variant macro prohibited")
        sanitizers = [argument for argument in arguments if "-fsanitize" in argument]
        if (configuration == "ordinary" and sanitizers) or (configuration == "sanitize" and "-fsanitize=address,undefined" not in sanitizers):
            raise ValueError("sanitizer configuration mismatch")
    return True


def verify_frozen_tree(root, manifest_file):
    value = json.loads(manifest_file.read_text())
    if not isinstance(value, dict) or not value:
        raise ValueError("empty frozen E1 manifest")
    expected = set(value) | {str(manifest_file.relative_to(root))}
    if {str(path.relative_to(root)) for path in tree_files(root)} != expected:
        raise ValueError("E1 frozen file membership changed")
    for name, record in value.items():
        check_relative_path(name)
        if not isinstance(record, dict) or set(record) != {"bytes", "sha256"}:
            raise ValueError("invalid frozen E1 manifest record")
        path = root / name
        if path.stat().st_size != record["bytes"] or sha256(path) != record["sha256"]:
            raise ValueError("E1 frozen bytes changed: " + name)
    return sha256(manifest_file)


def run_once(root, source_commit, batch):
    check_argv(str(root), source_commit, batch)
    physical_path(BASE)
    physical_path(root)
    physical_path(root / "source")
    if os.uname().sysname != "Linux" or os.uname().machine != "x86_64" or os.getuid() <= 0 or os.geteuid() != os.getuid():
        raise ValueError("requires ordinary Linux/x86_64 user")
    source = root / "source"
    manifest_file = source / SOURCE_MANIFEST_NAME
    if sha256(manifest_file) != SOURCE_MANIFEST_SHA256:
        raise ValueError("fixed source manifest digest mismatch")
    source_pins = manifest_pins(json.loads(manifest_file.read_text()))
    source_layout(source, source_pins)
    if Path(__file__).resolve(strict=True) != source / RUNNER_NAME:
        raise ValueError("runner is not the uploaded physical source file")
    runner_sha256 = sha256(Path(__file__))
    for name, record in source_pins.items():
        path = source / name
        if path.stat().st_size != record["bytes"] or sha256(path) != record["sha256"]:
            raise ValueError("frozen source digest or length mismatch: " + name)
    if 2 not in os.sched_getaffinity(0) or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
        raise ValueError("CPU2 or free-space preflight rejected")
    for tool in ("gcc", "cmake", "ctest", "timeout", "objdump", "readelf", "nm"):
        if not os.access("/usr/bin/" + tool, os.X_OK):
            raise ValueError("required tool unavailable: " + tool)
    tree_files(root)
    batch_root = root / "batches" / batch
    archive = Path(str(root) + "." + batch + ".tar.gz")
    if batch_root.exists() or batch_root.is_symlink() or archive.exists() or archive.is_symlink():
        raise ValueError("batch or archive already exists; automatic retry is prohibited")
    before_context = read_context()
    boot_id = accept_context(before_context, os.getuid())
    prior = None
    prior_manifest_sha256 = None
    binary_pins = {}
    if batch == "e1":
        if set(path.name for path in root.iterdir()) != {"source"}:
            raise ValueError("E1 new root must contain only source")
    else:
        prior_manifest = root / "batches/e1/manifest.json"
        prior_manifest_sha256 = verify_frozen_tree(root, prior_manifest)
        prior = json.loads((root / "batches/e1/run-state.json").read_text())
        binary_pins = {f"build-{configuration}/{tool}": sha256(root / f"build-{configuration}" / tool)
                       for configuration in ("ordinary", "sanitize") for tool in TOOLS}
        accept_prior_state(prior, source_commit, runner_sha256, binary_pins, boot_id)
        prior_commands = json.loads((root / "batches/e1/commands.json").read_text())
        if not export_is_safe(prior, prior_commands):
            raise ValueError("E1 cleanup gate not confirmed")
        prior_archive = Path(str(root) + ".e1.tar.gz")
        if not prior_archive.is_file() or prior_archive.is_symlink():
            raise ValueError("E1 original archive unavailable")
        physical_path(prior_archive)
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    started = time.monotonic()
    work_deadline = started + 300
    commands, cases = [], []
    qualification = {"status": "not_repeated" if batch == "e2" else "unknown",
                     "completed_configurations": [], "exact_completed_full_algorithm_calls": 0 if batch == "e2" else None,
                     "proven_completed_full_algorithm_calls_lower_bound": 0,
                     "decapsulation_calls": 0 if batch == "e2" else None,
                     "key_generation_calls": 0 if batch == "e2" else None,
                     "encapsulation_calls": 0 if batch == "e2" else None,
                     "incomplete_execution_calls_unknown": batch == "e1"}
    state = {"schema": "reference-repeatability-remote-v1", "batch": batch, "source_commit": source_commit,
             "source_manifest_sha256": SOURCE_MANIFEST_SHA256, "runner_sha256": runner_sha256,
             "source_file_count": 142, "source_pins": source_pins, "boot_id": boot_id,
             "started_utc": utc(), "supervisor_pid": os.getpid(), "supervisor_start_ticks": process_start_ticks(os.getpid()),
             "planned_processes": 3, "planned_timed_calls_per_process": 50000,
             "planned_setup_calls_per_process": 1, "launched_supervisors": 0,
             "confirmed_collector_starts": 0, "completed_processes": 0, "accepted_processes": 0,
             "accepted_timed_calls": 0, "confirmed_complete_collector_full_calls": 0,
             "cleanup_unconfirmed": False, "status": "failed", "cases": cases,
             "binary_sha256": binary_pins, "functional_qualification_accounting": qualification,
             "archive_status": "see_supervisor_stdout"}
    if prior is not None:
        state["e1_dependency"] = {"state_sha256": sha256(root / "batches/e1/run-state.json"),
                                  "manifest_sha256": prior_manifest_sha256,
                                  "archive_sha256": sha256(Path(str(root) + ".e1.tar.gz")),
                                  "binary_sha256": dict(binary_pins), "boot_id": boot_id,
                                  "completed_qualification_full_calls": 132}
    environment = {"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8",
                   "ASAN_OPTIONS": "detect_leaks=0:halt_on_error=1", "UBSAN_OPTIONS": "halt_on_error=1"}
    if "HOME" in os.environ:
        environment["HOME"] = os.environ["HOME"]
    for name in TEMP_NAMES:
        environment[name] = str(batch_root / "environment" / name.lower())

    def boundary():
        physical_path(root)
        size = sum(path.stat().st_size for path in tree_files(root))
        if time.monotonic() >= work_deadline or size > TOTAL_BYTES or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
            raise RuntimeError("work time, tree payload or free-space budget exhausted")
        source_layout(source, source_pins)
        pins = {"source/" + name: record["sha256"] for name, record in source_pins.items()}
        pins["source/" + SOURCE_MANIFEST_NAME] = SOURCE_MANIFEST_SHA256
        pins["source/" + RUNNER_NAME] = runner_sha256
        pins.update(state["binary_sha256"])
        if any(sha256(root / name) != digest for name, digest in pins.items()):
            raise ValueError("source, manifest, runner or ELF changed during execution")

    def child_limits():
        signal.pthread_sigmask(signal.SIG_SETMASK, [])
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        resource.setrlimit(resource.RLIMIT_FSIZE, (64 * 1024 * 1024, 64 * 1024 * 1024))

    def confirm_cleanup(process, record, terminate):
        previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, SIGNALS)
        deadline = time.monotonic() + 5
        record.update(cleanup_pid=process.pid, cleanup_pgid=process.pid,
                      leader_reaped=False, process_group_gone=False)
        try:
            if terminate and process.poll() is None:
                if type(record.get("supervisor_start_ticks")) is not int or process_start_ticks(process.pid) != record["supervisor_start_ticks"]:
                    raise RuntimeError("owned live leader identity unavailable; group signal withheld")
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                    record["terminated_by_supervisor"] = True
                except ProcessLookupError:
                    pass
            if process.poll() is None:
                process.wait(timeout=max(0, deadline - time.monotonic()))
            record["exit_code"] = process.returncode
            record["leader_reaped"] = process.poll() is not None
            while record["leader_reaped"]:
                try:
                    os.killpg(process.pid, 0)
                except ProcessLookupError:
                    record["process_group_gone"] = True
                    break
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                time.sleep(min(0.05, remaining))
        except BaseException as error:
            record["cleanup_error"] = {"type": type(error).__name__, "message": str(error)}
        finally:
            confirmed = cleanup_is_confirmed(record["leader_reaped"], record["process_group_gone"])
            record["cleanup_unconfirmed"] = not confirmed
            state["cleanup_unconfirmed"] = state["cleanup_unconfirmed"] or not confirmed
            signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
        return confirmed

    def command(label, arguments, seconds, output=None, errors=None, case=None):
        boundary()
        remaining_seconds = min(seconds, work_deadline - time.monotonic())
        if remaining_seconds <= 0:
            raise TimeoutError("remaining work budget exhausted before command launch")
        output = output or batch_root / "logs" / (label + ".stdout")
        errors = errors or batch_root / "logs" / (label + ".stderr")
        record = {"label": label, "argv": [str(argument) for argument in arguments],
                  "environment": environment, "started_utc": utc(), "stdout": str(output.relative_to(root)),
                  "stderr": str(errors.relative_to(root)), "manager_wait_limit_seconds": remaining_seconds,
                  "exit_code": None, "supervisor_pid": None, "supervisor_start_ticks": None}
        commands.append(record)
        with output.open("xb") as stdout_file, errors.open("xb") as stderr_file:
            process = None
            previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, SIGNALS)
            try:
                try:
                    process = subprocess.Popen(record["argv"], cwd=batch_root, env=environment, stdin=subprocess.DEVNULL,
                                               stdout=stdout_file, stderr=stderr_file, start_new_session=True,
                                               preexec_fn=child_limits)
                    record["supervisor_pid"] = process.pid
                    if case is not None:
                        case.update(status="supervisor_started", supervisor_pid=process.pid,
                                    supervisor_start_ticks=None)
                        state["launched_supervisors"] += 1
                    record["supervisor_start_ticks"] = process_start_ticks(process.pid)
                    if case is not None:
                        case["supervisor_start_ticks"] = record["supervisor_start_ticks"]
                finally:
                    signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
                record["exit_code"] = process.wait(timeout=max(0, min(remaining_seconds, work_deadline - time.monotonic())))
            except BaseException:
                if process is not None:
                    confirm_cleanup(process, record, True)
                raise
            else:
                if not confirm_cleanup(process, record, False):
                    raise RuntimeError("cleanup_unconfirmed: own leader or group remains unknown")
            finally:
                record["ended_utc"] = utc()
        record["stdout_sha256"], record["stderr_sha256"] = sha256(output), sha256(errors)
        record["stdout_bytes"], record["stderr_bytes"] = output.stat().st_size, errors.stat().st_size
        boundary()
        if record["exit_code"] != 0:
            raise RuntimeError(label + " exited " + str(record["exit_code"]))
        return output

    def qualify_configuration(configuration):
        stage_end = min(work_deadline, time.monotonic() + 60)
        build = root / ("build-" + configuration)
        if build.exists() or build.is_symlink():
            raise ValueError("build tree exists; rebuilding is prohibited")
        command(configuration + "-configure", ["/usr/bin/cmake", "-G", "Unix Makefiles", "-S", source / STUDY, "-B", build,
                "-DCMAKE_C_COMPILER=/usr/bin/gcc", "-DCMAKE_BUILD_TYPE=RelWithDebInfo", "-DBUILD_TESTING=ON",
                "-DREFERENCE_REPEATABILITY_SANITIZERS=" + ("ON" if configuration == "sanitize" else "OFF")],
                stage_end - time.monotonic())
        command(configuration + "-build", ["/usr/bin/cmake", "--build", build, "--parallel", "2"],
                stage_end - time.monotonic())
        check_compile_flags(json.loads((build / "compile_commands.json").read_text()), configuration)
        for tool in TOOLS:
            arguments = shlex.split((build / "CMakeFiles" / (tool + ".dir") / "link.txt").read_text())
            if not arguments or arguments[0] != "/usr/bin/gcc" or any("-flto" in argument or "BASELINE_" in argument for argument in arguments):
                raise ValueError("unexpected link command")
            sanitizers = [argument for argument in arguments if "-fsanitize" in argument]
            if (configuration == "ordinary" and sanitizers) or (configuration == "sanitize" and "-fsanitize=address,undefined" not in sanitizers):
                raise ValueError("link sanitizer configuration mismatch")
            if tool != "analyze_reference_repeatability" and not any(argument.endswith("librepeatability_reference.a") for argument in arguments):
                raise ValueError("collector or KAT not linked to fixed reference archive")
            binary = build / tool
            with binary.open("rb") as binary_file:
                if binary_file.read(4) != b"\x7fELF":
                    raise ValueError("Linux artifact is not ELF")
            state["binary_sha256"][str(binary.relative_to(root))] = sha256(binary)
        inventory = command(configuration + "-test-inventory", ["/usr/bin/ctest", "--test-dir", build,
                            "--show-only=json-v1"], 5)
        if [test["name"] for test in json.loads(inventory.read_text())["tests"]] != list(TEST_NAMES):
            raise ValueError("CTest inventory is not exactly the five frozen checks")
        tests = command(configuration + "-ctest", ["/usr/bin/ctest", "--test-dir", build, "--verbose",
                        "--output-on-failure", "--output-junit", build / "tests.xml"], 30)
        suite = ElementTree.parse(build / "tests.xml").getroot()
        testcases = suite.findall("testcase")
        if (suite.get("tests") != "5" or suite.get("failures") != "0" or suite.get("disabled", "0") != "0"
                or suite.get("skipped", "0") != "0" or [test.get("name") for test in testcases] != list(TEST_NAMES)
                or any(test.find("failure") is not None or test.find("skipped") is not None for test in testcases)
                or "100% tests passed, 0 tests failed out of 5" not in tests.read_text()):
            raise ValueError("actual verbose CTest 5/5 receipt rejected")
        qualification["completed_configurations"].append(configuration)
        qualification["proven_completed_full_algorithm_calls_lower_bound"] += 66
        if qualification["completed_configurations"] == ["ordinary", "sanitize"]:
            qualification.update(status="completed", exact_completed_full_algorithm_calls=132,
                                 decapsulation_calls=24, key_generation_calls=54, encapsulation_calls=54,
                                 incomplete_execution_calls_unknown=False)
        for tool in TOOLS:
            binary = build / tool
            for inspector, flags in (("objdump", ["-d"]), ("readelf", ["-h", "-d", "-Ws"]), ("nm", ["-an"])):
                command(configuration + "-" + tool + "-" + inspector,
                        ["/usr/bin/" + inspector, *flags, binary], 5)

    export = {"root": str(root), "batch": batch, "archive": None, "archive_sha256": None, "archive_status": "not_archived"}
    batch_directory_owned = False
    for termination_signal in SIGNALS:
        signal.signal(termination_signal, deadline_interrupt)
    signal.setitimer(signal.ITIMER_REAL, 300)
    try:
        previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, SIGNALS)
        try:
            batch_root.mkdir(parents=True, exist_ok=False)
            batch_directory_owned = True
            state["batch_directory_owned"] = True
        finally:
            signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
        claim = {"event": "supervisor_started", "root": str(root), "batch": batch,
                 "source_commit": source_commit, "pid": os.getpid(), "start_ticks": state["supervisor_start_ticks"],
                 "collector_processes_started": None, "actual_accepted_timed_calls": 0}
        save_json(batch_root / "run-claim.json", claim)
        print(json.dumps(claim, separators=(",", ":")), flush=True)
        for name in ("logs", "output", *("environment/" + name.lower() for name in TEMP_NAMES)):
            (batch_root / name).mkdir(parents=True, exist_ok=False)
        save_json(batch_root / "before-environment.json", before_context)
        for tool in ("gcc", "cmake", "timeout"):
            version = command(tool + "-version", ["/usr/bin/" + tool, "--version"], 5)
            if tool == "timeout" and "GNU coreutils" not in version.read_text():
                raise ValueError("GNU timeout required")
        if batch == "e1":
            for configuration in ("ordinary", "sanitize"):
                qualify_configuration(configuration)
        else:
            state["e1_dependency"]["reused_qualified_ordinary_binaries"] = True
        state["binary_sha256_before_sampling"] = dict(state["binary_sha256"])
        collector_pids = {case["pid"] for case in prior["cases"]} if prior is not None else set()
        for process_index in range(1, 4):
            label = "P" + str(process_index)
            case = {"name": label, "status": "supervisor_not_started", "partial_unknown": True,
                    "collector_started": None, "collector_completed": None}
            cases.append(case)
            csv_file = batch_root / "output" / (label + ".csv")
            metadata_file = batch_root / "output" / (label + ".json")
            command(label, ["/usr/bin/timeout", "--signal=TERM", "--kill-after=2s", "15s",
                    root / "build-ordinary/reference_repeatability", "--collect"], 20, csv_file, metadata_file, case)
            metadata_text = metadata_file.read_text()
            if not metadata_text.endswith("\n") or metadata_text.count("\n") != 1:
                raise ValueError("collector metadata is not one complete line")
            metadata = json.loads(metadata_text)
            collector_pid = accept_metadata(metadata, os.getuid())
            if (collector_pid in collector_pids or metadata["uname"]["release"] != os.uname().release
                    or metadata["uname"]["nodename"] != os.uname().nodename
                    or metadata["original_affinity"] != before_context["affinity"]):
                raise ValueError("collector PID, kernel or original caller affinity rejected")
            collector_pids.add(collector_pid)
            case.update(status="collector_metadata_completed", collector_started=True, collector_completed=True,
                        pid=collector_pid, csv_sha256=sha256(csv_file), metadata_sha256=sha256(metadata_file),
                        collector_exit_checked=True, collector_stderr_checked=True)
            state["confirmed_collector_starts"] += 1
            state["completed_processes"] += 1
            state["confirmed_complete_collector_full_calls"] += 50001
            analysis = batch_root / "output" / (label + "-analysis.csv")
            summary = batch_root / "output" / (label + "-summary.json")
            command(label + "-analysis", [root / "build-ordinary/analyze_reference_repeatability", csv_file],
                    30, analysis, summary)
            summary_text = summary.read_text()
            if not summary_text.endswith("\n") or summary_text.count("\n") != 1:
                raise ValueError("C summary is not one complete line")
            accept_summary(json.loads(summary_text), analysis.read_text())
            if sha256(csv_file) != case["csv_sha256"] or sha256(metadata_file) != case["metadata_sha256"]:
                raise ValueError("collector originals changed during analysis")
            case.update(status="accepted", partial_unknown=False,
                        management_complete_metadata_acceptance=True,
                        analysis_sha256=sha256(analysis), summary_sha256=sha256(summary),
                        csv_bytes=csv_file.stat().st_size, metadata_bytes=metadata_file.stat().st_size,
                        analysis_bytes=analysis.stat().st_size, summary_bytes=summary.stat().st_size)
            state["accepted_processes"] += 1
            state["accepted_timed_calls"] += 50000
        boundary()
        state["binary_sha256_after_sampling"] = dict(state["binary_sha256"])
        state["status"] = "completed"
    except BaseException as error:
        state["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        if not batch_directory_owned:
            signal.setitimer(signal.ITIMER_REAL, 0)
            export.update(status="failed", batch_directory_owned=False,
                          archive_status="withheld_no_batch_ownership", failure=state.get("failure"))
            print(json.dumps(export, separators=(",", ":")), flush=True)
            return 1
        safe_to_freeze = ownership_allows_freeze(batch_directory_owned, state, commands)
        state["supervisor_work_stopped_utc"] = utc()
        state["all_child_work_stopped"] = True if safe_to_freeze else None
        state["collector_calls_unknown"] = state["launched_supervisors"] > state["completed_processes"]
        state["proven_completed_full_algorithm_calls_lower_bound"] = (
            qualification["proven_completed_full_algorithm_calls_lower_bound"] + state["confirmed_complete_collector_full_calls"])
        exact_known = not state["collector_calls_unknown"] and not qualification["incomplete_execution_calls_unknown"]
        state["exact_completed_full_algorithm_calls"] = state["proven_completed_full_algorithm_calls_lower_bound"] if exact_known else None
        if not safe_to_freeze:
            state["status"] = "unknown"
            state["cleanup_unconfirmed"] = True
            state["unconfirmed_processes"] = [{key: record.get(key) for key in
                ("supervisor_pid", "supervisor_start_ticks", "cleanup_pid", "cleanup_pgid", "leader_reaped", "process_group_gone")}
                for record in commands if record.get("supervisor_pid") is not None and not
                cleanup_is_confirmed(record.get("leader_reaped"), record.get("process_group_gone"))]
            export["cleanup_unconfirmed"] = True
            export["unconfirmed_processes"] = state["unconfirmed_processes"]
        state["work_elapsed_seconds"] = time.monotonic() - started
        signal.setitimer(signal.ITIMER_REAL, 30)
        try:
            after_context = read_context()
            save_json(batch_root / "after-environment.json", after_context)
            try:
                if accept_context(after_context, os.getuid()) != boot_id:
                    raise ValueError("boot identity changed")
            except ValueError as error:
                state["status"] = "failed" if safe_to_freeze else "unknown"
                state["after_context_failure"] = str(error)
            state["frequency_snapshot_comparison"] = {
                "file_count": 129,
                "all_available_and_equal": all(before_context["read_only_files"][str(path)]["errno"] == 0
                    and after_context["read_only_files"][str(path)]["errno"] == 0
                    and before_context["read_only_files"][str(path)]["text"] == after_context["read_only_files"][str(path)]["text"]
                    for path in frequency_paths()),
                "scope": "two visible snapshots only; no frequency control or physical constancy claim"}
            export_pin_failure = None
            if safe_to_freeze:
                try:
                    for case in cases:
                        visible = {name: current_output_pin(batch_root / "output" / (case["name"] + suffix))
                                   for name, suffix in (("csv", ".csv"), ("metadata", ".json"),
                                                        ("analysis", "-analysis.csv"), ("summary", "-summary.json"))}
                        if case["status"] == "accepted":
                            case["accepted_output_pins_unchanged"] = accepted_pins_match(case, visible)
                            if not case["accepted_output_pins_unchanged"]:
                                raise ValueError("accepted output missing or changed: " + case["name"])
                        else:
                            case["current_visible_outputs"] = visible
                    physical_path(root)
                    tree_files(root)
                    final_pins = {"source/" + name: record["sha256"] for name, record in source_pins.items()}
                    final_pins.update({"source/" + SOURCE_MANIFEST_NAME: SOURCE_MANIFEST_SHA256,
                                       "source/" + RUNNER_NAME: runner_sha256})
                    final_pins.update(state["binary_sha256"])
                    if any(sha256(root / name) != digest for name, digest in final_pins.items()):
                        state["status"] = "failed"
                        raise ValueError("frozen source or ELF changed before export")
                    state["source_and_binary_final_pins"] = final_pins
                    if batch == "e2":
                        if sha256(root / "batches/e1/manifest.json") != prior_manifest_sha256:
                            raise ValueError("old E1 manifest changed")
                        old_manifest = json.loads((root / "batches/e1/manifest.json").read_text())
                        if any((root / name).stat().st_size != record["bytes"] or sha256(root / name) != record["sha256"]
                               for name, record in old_manifest.items()):
                            raise ValueError("old E1 original bytes changed")
                        if sha256(Path(str(root) + ".e1.tar.gz")) != state["e1_dependency"]["archive_sha256"]:
                            raise ValueError("old E1 archive changed")
                except BaseException as error:
                    state["status"] = "failed"
                    export_pin_failure = {"type": type(error).__name__, "message": str(error)}
                    state["final_pin_failure"] = export_pin_failure
            save_json(batch_root / "commands.json", commands)
            save_json(batch_root / "run-state.json", state)
            if not safe_to_freeze:
                raise RuntimeError("cleanup_unconfirmed: frozen manifest and archive withheld")
            if export_pin_failure is not None:
                raise RuntimeError("source/ELF/E1 pin failure: manifest and archive withheld")
            current_files = tree_files(root)
            if sum(path.stat().st_size for path in current_files) > TOTAL_BYTES or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
                raise RuntimeError("tree or free-space export budget exhausted")
            save_json(batch_root / "manifest.json", {str(path.relative_to(root)): {"bytes": path.stat().st_size,
                       "sha256": sha256(path)} for path in current_files})
            remaining = TOTAL_BYTES - sum(path.stat().st_size for path in tree_files(root))
            if remaining <= 0 or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
                raise RuntimeError("no export payload or free-space budget")
            with archive.open("xb") as archive_file:
                class LimitedArchive:
                    def write(self, data):
                        if archive_file.tell() + len(data) > remaining:
                            raise RuntimeError("combined tree/archive payload budget exhausted")
                        return archive_file.write(data)

                    def __getattr__(self, name):
                        return getattr(archive_file, name)

                with tarfile.open(fileobj=LimitedArchive(), mode="w:gz") as archive_stream:
                    def regular_member(member):
                        if not member.isfile():
                            raise ValueError("archive member is not a regular file")
                        return member

                    for path in tree_files(root):
                        archive_stream.add(path, arcname=str(path.relative_to(root)), recursive=False, filter=regular_member)
            export.update(archive=str(archive), archive_sha256=sha256(archive), archive_status="archived",
                          manifest=str((batch_root / "manifest.json").relative_to(root)),
                          manifest_sha256=sha256(batch_root / "manifest.json"))
        except BaseException as error:
            export["export_failure"] = {"type": type(error).__name__, "message": str(error)}
            if archive.exists():
                export["partial_archive"] = str(archive)
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
        export["status"] = state["status"]
        print(json.dumps(export, separators=(",", ":")), flush=True)
    return 0 if state["status"] == "completed" and export["archive_status"] == "archived" else 1


def selfcheck():
    commit = "a" * 40
    check_argv(str(BASE) + "/reference-repeatability-aaaaaaa-01234567", commit, "e1")
    check_argv(str(BASE) + "/reference-repeatability-aaaaaaa-01234567", commit, "e2")
    for bad_root, bad_commit, bad_batch in (("/tmp/reference-repeatability-aaaaaaa-01234567", commit, "e1"),
            (str(BASE) + "/reference-repeatability-bbbbbbb-01234567", commit, "e1"),
            (str(BASE) + "/reference-repeatability-aaaaaaa-../x", commit, "e1"),
            (str(BASE) + "/reference-repeatability-aaaaaaa-01234567", "a" * 39, "e1"),
            (str(BASE) + "/reference-repeatability-aaaaaaa-01234567", commit, "e3")):
        try:
            check_argv(bad_root, bad_commit, bad_batch)
        except ValueError:
            continue
        raise AssertionError("invalid path/commit/batch accepted")
    for text in ("/absolute", "x/../y", "x//y", "x/./y", ""):
        try:
            check_relative_path(text)
        except ValueError:
            continue
        raise AssertionError("noncanonical relative path accepted")
    source_fixture = {"schema": "reference-repeatability-source-manifest-v1", "files": [
        {"path": "fixture/file-" + str(index), "bytes": 1, "sha256": "b" * 64}
        for index in range(140)]}
    assert len(manifest_pins(source_fixture)) == 140
    for entries in (source_fixture["files"][:-1], source_fixture["files"] + [source_fixture["files"][0]],
                    source_fixture["files"][:-1] + [source_fixture["files"][0]]):
        try:
            manifest_pins(dict(source_fixture, files=entries))
        except ValueError:
            continue
        raise AssertionError("extra, short or duplicate source manifest accepted")
    snapshot = {"affinity": [2], "cpu2_check": True, "observed_cpu": 2, "clocksource": "tsc",
                "clocksource_errno": 0, "resolution_errno": 0, "affinity_errno": 0, "cpu_errno": 0,
                "resolution_has_timespec": True, "resolution_seconds": 0,
                "resolution_fractional_ns": 1, "resolution_ns": 1}
    metadata = {"record_count": 50000, "valid_warmup_calls": 25000, "valid_main_calls": 25000,
                "planned_warmup_calls": 25000, "planned_main_calls": 25000, "attempted_call_count": 50000,
                "verified_output_call_count": 50000, "setup_call_count": 1, "setup_operation_status": 0,
                "uid": 1000, "effective_uid": 1000, "target_cpu": 2, "stop_errno": 0,
                "configuration_writes": 0, "uname_errno": 0, "original_affinity_errno": 0, "set_affinity_errno": 0,
                "dumpable_set_errno": 0, "dumpable_read_errno": 0, "dumpable_readback": 0,
                "fixture_group_id": 5, "fixture_case_id": 86, "fixture_source_commit": "975de31eb83d87039ec88934fdc47d8c312b892d",
                "fixture_prompt_sha256": FIXTURE_PROMPT_SHA256, "fixture_expected_sha256": FIXTURE_EXPECTED_SHA256,
                "contract": "ordinary-reference-repeatability-v1", "clock": "CLOCK_MONOTONIC_RAW", "stop_reason": "completed",
                "partial_unknown": False, "self_affinity_set": True, "reference_identity_verified": True,
                "setup_verified": True, "dumpable_set_attempted": True, "dumpable_set_succeeded": True, "pid": 17,
                "uname": {"sysname": "Linux", "machine": "x86_64"}, "original_affinity": [0, 1, 2, 3],
                "before": dict(snapshot), "after": dict(snapshot)}
    assert accept_metadata(metadata, 1000) == 17
    for key, value in (("record_count", True), ("partial_unknown", True), ("after", None), ("pid", 0),
            ("setup_call_count", 0), ("setup_verified", None), ("dumpable_readback", 1),
            ("attempted_call_count", 49999), ("verified_output_call_count", 49999), ("fixture_case_id", 87),
            ("reference_identity_verified", 1), ("before", dict(snapshot, affinity=[2.0])),
            ("before", dict(snapshot, resolution_ns=2)),
            ("after", dict(snapshot, clocksource="other"))):
        malformed = dict(metadata, **{key: value})
        try:
            accept_metadata(malformed, 1000)
        except ValueError:
            continue
        raise AssertionError("invalid metadata accepted")
    summary = {"schema": "reference-repeatability-analysis-v1", "status": "descriptive_only", "units": "ns",
               "record_count": 50000, "warmup_call_count": 25000, "main_call_count": 25000,
               "phase_conservation_valid": True, "cross_phase_conservation_valid": True,
               "clock_precision_certified": False, "iid_claimed": False, "collector_stderr_checked": False,
               "collector_exit_checked": False, "complete_metadata_acceptance": False, "r02_signed_off": False,
               "r04_signed_off": False, "phase_boundary_gap_ns": 0, "warmup_wall_ns": 2, "main_wall_ns": 2,
               "warmup_pair_sum_ns": 1, "warmup_between_sum_ns": 1, "main_pair_sum_ns": 1, "main_between_sum_ns": 1}
    table = CSV_HEADER + "\n" + "".join(
        f"{phase},{series},{count},{count - total}, {total},0,1,0,0,0,1,0\n".replace(", ", ",")
        for phase in ("warmup", "main")
        for series, count, total in zip(("within_pair_ns", "between_pairs_ns", "combined_ordered_read_increment_ns"),
                                       (25000, 24999, 49999), (1, 1, 2)))
    assert accept_summary(summary, table)
    for key, value in (("schema", "raw-clock-analysis-v1"), ("record_count", 50001),
                       ("collector_exit_checked", True), ("warmup_wall_ns", 3), ("phase_conservation_valid", None)):
        try:
            accept_summary(dict(summary, **{key: value}), table)
        except ValueError:
            continue
        raise AssertionError("invalid C summary accepted")
    confirmed = {"supervisor_pid": 17, "leader_reaped": True, "process_group_gone": True}
    assert export_is_safe({"cleanup_unconfirmed": False}, [confirmed])
    for leader_reaped, group_gone in ((False, True), (True, False), (None, True), (True, None), (1, True)):
        assert not export_is_safe({"cleanup_unconfirmed": False}, [dict(confirmed, leader_reaped=leader_reaped, process_group_gone=group_gone)])
    assert not export_is_safe({"cleanup_unconfirmed": True}, [confirmed])
    assert not export_is_safe({}, [confirmed])
    assert ownership_allows_freeze(True, {"cleanup_unconfirmed": False}, [confirmed])
    for ownership in (False, None, 1):
        assert not ownership_allows_freeze(ownership, {"cleanup_unconfirmed": False}, [confirmed])
    accepted = {"status": "accepted"}
    visible = {}
    for index, name in enumerate(OUTPUT_NAMES):
        accepted[name + "_bytes"] = index + 10
        accepted[name + "_sha256"] = "b" * 64
        visible[name] = {"regular_physical": True, "bytes": index + 10, "sha256": "b" * 64}
    assert accepted_pins_match(accepted, visible)
    for name in OUTPUT_NAMES:
        missing = dict(visible)
        del missing[name]
        assert not accepted_pins_match(accepted, missing)
        for key, value in (("regular_physical", False), ("bytes", None), ("bytes", 99),
                           ("sha256", None), ("sha256", "c" * 64)):
            changed = dict(visible, **{name: dict(visible[name], **{key: value})})
            assert not accepted_pins_match(accepted, changed)
    assert not accepted_pins_match(dict(accepted, status="collector_metadata_completed"), visible)
    unknown_case = {"collector_started": None, "collector_completed": None, "partial_unknown": True}
    assert unknown_case["collector_started"] is None and unknown_case["partial_unknown"] is True
    binaries = {f"build-{configuration}/{tool}": "b" * 64 for configuration in ("ordinary", "sanitize") for tool in TOOLS}
    prior = {"schema": "reference-repeatability-remote-v1", "batch": "e1", "source_commit": commit,
             "source_manifest_sha256": SOURCE_MANIFEST_SHA256, "runner_sha256": "c" * 64,
             "status": "completed", "boot_id": "boot", "cleanup_unconfirmed": False, "all_child_work_stopped": True,
             "accepted_processes": 3, "accepted_timed_calls": 150000, "completed_processes": 3, "binary_sha256": binaries,
             "cases": [dict(name=name, status="accepted", partial_unknown=False, collector_started=True,
                            collector_completed=True, management_complete_metadata_acceptance=True) for name in ("P1", "P2", "P3")],
             "functional_qualification_accounting": {"status": "completed", "completed_configurations": ["ordinary", "sanitize"],
                 "exact_completed_full_algorithm_calls": 132, "decapsulation_calls": 24, "key_generation_calls": 54, "encapsulation_calls": 54}}
    assert accept_prior_state(prior, commit, "c" * 64, binaries, "boot")
    for key, value in (("status", "failed"), ("boot_id", "other"), ("accepted_processes", 2),
                       ("source_manifest_sha256", "d" * 64), ("runner_sha256", "d" * 64), ("binary_sha256", {})):
        try:
            accept_prior_state(dict(prior, **{key: value}), commit, "c" * 64, binaries, "boot")
        except ValueError:
            continue
        raise AssertionError("invalid E2 dependency accepted")
    assert check_compile_flags([{"arguments": ["/usr/bin/gcc", "-std=c11", "-Werror", "-O2"]}], "ordinary")
    assert check_compile_flags([{"arguments": ["/usr/bin/gcc", "-std=c11", "-Werror", "-fsanitize=address,undefined"]}], "sanitize")
    for flags, configuration in ((["-flto"], "ordinary"), (["-DBASELINE_VULNERABLE=1"], "ordinary"),
                                  (["-fsanitize=address,undefined"], "ordinary"), ([], "sanitize")):
        try:
            check_compile_flags([{"arguments": ["/usr/bin/gcc", "-std=c11", "-Werror", *flags]}], configuration)
        except ValueError:
            continue
        raise AssertionError("invalid compile flags accepted")
    assert 3 * (25000 + 25000) == 150000 and 2 * (132 // 2) == 132
    assert 3 * (50000 + 1) + 132 == 150135 and 6 * (50000 + 1) + 132 == 300138
    return True


if __name__ == "__main__":
    if sys.argv[1:] == ["--selfcheck"]:
        print(json.dumps({"selfcheck": selfcheck(), "real_clock_reads": 0, "file_reads": 0,
                          "ssh_calls": 0, "crypto_calls": 0}))
    elif len(sys.argv) == 4:
        sys.exit(run_once(Path(sys.argv[1]), sys.argv[2], sys.argv[3]))
    else:
        raise SystemExit("usage: remote_run.py ROOT SOURCE_COMMIT e1|e2 | --selfcheck")
