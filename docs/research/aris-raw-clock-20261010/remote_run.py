#!/usr/bin/env python3
"""固定RAW两工具的单次普通用户部署管理，不计算统计量。"""

import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import shutil
import signal
import stat
import subprocess
import sys
import tarfile
import time

BASE = Path("/home/nss-marker/yhr/Cry")
TOTAL_BYTES = 256 * 1024 * 1024
MIN_FREE_BYTES = 1024 * 1024 * 1024
PLAN_SHA256 = "7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a"
SOURCE_SHA256 = {
    "raw_clock_calibration.c": "ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd",
    "analyze_raw_clock.c": "c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0",
    "CMakeLists.txt": "28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e",
}
TOOLS = ("raw_clock_calibration", "analyze_raw_clock")


def check_argv(root_text, source_commit):
    match = re.fullmatch(str(BASE) + r"/raw-clock-([0-9a-f]{7,40})-([0-9a-f]{8,32})", root_text)
    if not match or not re.fullmatch(r"[0-9a-f]{40}", source_commit):
        raise ValueError("invalid fixed root or source commit")
    if not source_commit.startswith(match.group(1)):
        raise ValueError("root commit prefix mismatch")


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


def save_json(path, value):
    with path.open("x", encoding="utf-8") as output_file:
        json.dump(value, output_file, ensure_ascii=True, indent=2)
        output_file.write("\n")


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def deadline_interrupt(signum, frame):
    raise TimeoutError("administrative deadline or signal " + str(signum))


def cleanup_is_confirmed(leader_reaped, group_gone):
    return leader_reaped is True and group_gone is True


def export_is_safe(state, commands):
    return state.get("cleanup_unconfirmed") is False and all(
        record.get("supervisor_pid") is None or cleanup_is_confirmed(
            record.get("leader_reaped"), record.get("process_group_gone")) for record in commands)


def read_context():
    values = {"utc": utc(), "uname": list(os.uname()), "uid": os.getuid(),
              "effective_uid": os.geteuid(), "affinity": sorted(os.sched_getaffinity(0)),
              "free_bytes": shutil.disk_usage(BASE).free, "read_only_files": {}}
    paths = [Path("/proc/cpuinfo"), Path("/proc/loadavg"), Path("/proc/stat"),
             Path("/sys/devices/system/clocksource/clocksource0/current_clocksource"),
             Path("/sys/devices/system/cpu/cpufreq/boost")]
    paths += [Path(f"/sys/devices/system/cpu/cpufreq/policy{cpu_index}/{field}")
              for cpu_index in range(32)
              for field in ("scaling_governor", "scaling_min_freq", "scaling_max_freq",
                            "energy_performance_preference")]
    for path in paths:
        try:
            values["read_only_files"][str(path)] = {"text": path.read_text(), "errno": 0}
        except OSError as error:
            values["read_only_files"][str(path)] = {"text": None, "errno": error.errno}
    return values


def accept_metadata(value, user_id):
    expected = {"record_count": 101000, "valid_warmup_pairs": 1000,
                "valid_main_pairs": 100000, "planned_warmup_pairs": 1000,
                "planned_main_pairs": 100000, "uid": user_id, "effective_uid": user_id,
                "target_cpu": 2, "stop_errno": 0, "configuration_writes": 0,
                "uname_errno": 0, "original_affinity_errno": 0, "set_affinity_errno": 0}
    if any(type(value.get(key)) is not int or value[key] != expected_value
           for key, expected_value in expected.items()):
        raise ValueError("collector integer metadata rejected")
    if (value.get("contract") != "raw-empty-pair-v1" or value.get("clock") != "CLOCK_MONOTONIC_RAW"
            or value.get("stop_reason") != "completed" or value.get("partial_unknown") is not False
            or value.get("self_affinity_set") is not True
            or type(value.get("pid")) is not int or value["pid"] <= 0):
        raise ValueError("collector completion metadata rejected")
    before, after = value.get("before"), value.get("after")
    for snapshot in (before, after):
        if not isinstance(snapshot, dict) or snapshot.get("affinity") != [2]:
            raise ValueError("collector CPU mask rejected")
        if snapshot.get("cpu2_check") is not True or snapshot.get("observed_cpu") != 2:
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


def run_once(root, source_commit):
    check_argv(str(root), source_commit)
    for component in (BASE, *BASE.parents, root, root / "source"):
        if component.is_symlink() or component.resolve(strict=True) != component:
            raise ValueError("project root is not physical")
    if os.uname().sysname != "Linux" or os.uname().machine != "x86_64" or os.geteuid() == 0:
        raise ValueError("requires ordinary Linux/x86_64 user")
    if (set(path.name for path in root.iterdir()) != {"source"}
            or set(path.name for path in (root / "source").iterdir()) != set(SOURCE_SHA256) | {"remote_run.py"}
            or Path(__file__).resolve() != root / "source/remote_run.py"):
        raise ValueError("new root must contain only four uploaded source files")
    tree_files(root)
    if 2 not in os.sched_getaffinity(0) or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
        raise ValueError("CPU2 or free-space preflight rejected")
    for filename, expected in SOURCE_SHA256.items():
        if sha256(root / "source" / filename) != expected:
            raise ValueError("frozen source digest mismatch: " + filename)
    archive = Path(str(root) + ".tar.gz")
    if archive.exists() or archive.is_symlink():
        raise ValueError("archive path already exists")
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    started = time.monotonic()
    commands, cases = [], []
    state = {"schema": "raw-clock-remote-v1", "source_commit": source_commit,
             "source_sha256": SOURCE_SHA256, "runner_sha256": sha256(Path(__file__)),
             "frozen_plan_sha256": PLAN_SHA256, "started_utc": utc(), "supervisor_pid": os.getpid(),
             "planned_processes": 3, "planned_pairs_per_process": 101000,
             "launched_supervisors": 0, "completed_processes": 0, "accepted_pairs": 0,
             "cleanup_unconfirmed": False,
             "status": "failed", "cases": cases, "archive_status": "see_supervisor_stdout"}
    environment = {"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8",
                   "ASAN_OPTIONS": "detect_leaks=1:halt_on_error=1",
                   "UBSAN_OPTIONS": "halt_on_error=1:print_stacktrace=1"}
    if "HOME" in os.environ:
        environment["HOME"] = os.environ["HOME"]
    for name in ("TMPDIR", "TMP", "TEMP", "XDG_CACHE_HOME", "CCACHE_DIR", "CLANG_MODULE_CACHE_PATH"):
        destination = root / "environment" / name.lower()
        environment[name] = str(destination)

    def boundary():
        if root.is_symlink() or root.resolve(strict=True) != root:
            raise ValueError("project root changed")
        size = sum(path.stat().st_size for path in tree_files(root))
        if time.monotonic() - started >= 300 or size > TOTAL_BYTES or shutil.disk_usage(BASE).free < MIN_FREE_BYTES:
            raise RuntimeError("work time, payload, or free-space budget exhausted")
        pins = {"source/" + name: digest for name, digest in SOURCE_SHA256.items()}
        pins["source/remote_run.py"] = state["runner_sha256"]
        pins.update(state.get("binary_sha256", {}))
        if any(sha256(root / name) != digest for name, digest in pins.items()):
            raise ValueError("source or ELF changed during execution")

    def child_limits():
        signal.pthread_sigmask(signal.SIG_SETMASK, [])
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        resource.setrlimit(resource.RLIMIT_FSIZE, (64 * 1024 * 1024, 64 * 1024 * 1024))

    def confirm_cleanup(process, record, terminate):
        previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK,
            {signal.SIGALRM, signal.SIGTERM, signal.SIGINT, signal.SIGHUP})
        deadline = time.monotonic() + 5
        record.update(cleanup_pid=process.pid, cleanup_pgid=process.pid,
                      leader_reaped=False, process_group_gone=False)
        try:
            if terminate and process.poll() is None:
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
        output = output or root / "logs" / (label + ".stdout")
        errors = errors or root / "logs" / (label + ".stderr")
        record = {"label": label, "argv": [str(argument) for argument in arguments],
                  "environment": environment, "started_utc": utc(), "stdout": str(output.relative_to(root)),
                  "stderr": str(errors.relative_to(root)), "exit_code": None, "supervisor_pid": None}
        commands.append(record)
        with output.open("xb") as stdout_file, errors.open("xb") as stderr_file:
            process = None
            previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK,
                {signal.SIGALRM, signal.SIGTERM, signal.SIGINT, signal.SIGHUP})
            try:
                try:
                    process = subprocess.Popen(record["argv"], cwd=root, env=environment, stdin=subprocess.DEVNULL,
                                               stdout=stdout_file, stderr=stderr_file, start_new_session=True,
                                               preexec_fn=child_limits)
                    record["supervisor_pid"] = process.pid
                    if case is not None:
                        case["status"] = "supervisor_started"
                        case["supervisor_pid"] = process.pid
                        state["launched_supervisors"] += 1
                finally:
                    signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
                record["exit_code"] = process.wait(timeout=min(seconds, 300 - (time.monotonic() - started)))
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
        boundary()
        if record["exit_code"] != 0:
            raise RuntimeError(label + " exited " + str(record["exit_code"]))
        return output

    export = {"root": str(root), "archive": None, "archive_sha256": None, "archive_status": "not_archived"}
    for termination_signal in (signal.SIGALRM, signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(termination_signal, deadline_interrupt)
    signal.setitimer(signal.ITIMER_REAL, 300)
    try:
        start_ticks = int(Path("/proc/self/stat").read_text().rsplit(")", 1)[1].split()[19])
        state["supervisor_start_ticks"] = start_ticks
        claim = {"event": "supervisor_started", "root": str(root),
                 "source_commit": source_commit, "pid": os.getpid(), "start_ticks": start_ticks,
                 "collector_processes_started": None, "actual_accepted_pairs": 0}
        save_json(root / "run-claim.json", claim)
        print(json.dumps(claim, separators=(",", ":")), flush=True)
        for name in ("logs", "output", *("environment/" + name.lower() for name in environment if name.endswith("DIR")
                                       or name in ("TMP", "TEMP", "XDG_CACHE_HOME", "CLANG_MODULE_CACHE_PATH"))):
            (root / name).mkdir(parents=True)
        save_json(root / "before-environment.json", read_context())
        for tool in ("gcc", "cmake", "timeout"):
            version = command(tool + "-version", ["/usr/bin/" + tool, "--version"], 5)
            if tool == "timeout" and "GNU coreutils" not in version.read_text():
                raise ValueError("GNU timeout required")
        state["binary_sha256"] = {}
        for configuration in ("ordinary", "sanitize"):
            stage_end = time.monotonic() + 60
            build = root / ("build-" + configuration)
            command(configuration + "-configure", ["/usr/bin/cmake", "-S", root / "source", "-B", build,
                    "-DCMAKE_C_COMPILER=/usr/bin/gcc", "-DBUILD_TESTING=ON",
                    "-DRAW_CLOCK_SANITIZERS=" + ("ON" if configuration == "sanitize" else "OFF")], 60)
            build_seconds = stage_end - time.monotonic()
            if build_seconds <= 0:
                raise TimeoutError("configuration build budget exhausted")
            command(configuration + "-build", ["/usr/bin/cmake", "--build", build, "--parallel", "2"], build_seconds)
            inventory = command(configuration + "-test-inventory", ["/usr/bin/ctest", "--test-dir", build,
                                "--show-only=json-v1"], 5)
            if [test["name"] for test in json.loads(inventory.read_text())["tests"]] != [
                    "raw_clock_calibration_selfcheck", "raw_clock_analysis_selfcheck"]:
                raise ValueError("CTest inventory is not exactly the two frozen selfchecks")
            command(configuration + "-ctest", ["/usr/bin/ctest", "--test-dir", build, "--output-on-failure",
                    "--output-junit", build / "tests.xml"], 30)
            for tool in TOOLS:
                binary = build / tool
                with binary.open("rb") as binary_file:
                    if binary_file.read(4) != b"\x7fELF":
                        raise ValueError("Linux artifact is not ELF")
                state["binary_sha256"][str(binary.relative_to(root))] = sha256(binary)
                for inspector, flags in (("objdump", ["-d"]), ("readelf", ["-h", "-d", "-Ws"]), ("nm", ["-an"])):
                    command(configuration + "-" + tool + "-" + inspector, ["/usr/bin/" + inspector, *flags, binary], 5)
        collector_pids = set()
        for process_index in range(1, 4):
            label = "P" + str(process_index)
            case = {"name": label, "status": "supervisor_not_started", "partial_unknown": True,
                    "collector_started": None, "collector_completed": None}
            cases.append(case)
            csv_file, metadata_file = root / "output" / (label + ".csv"), root / "output" / (label + ".json")
            command(label, ["/usr/bin/timeout", "--signal=TERM", "--kill-after=2s", "10s",
                    root / "build-ordinary/raw_clock_calibration", "--collect"], 15, csv_file, metadata_file, case)
            metadata_text = metadata_file.read_text()
            if not metadata_text.endswith("\n") or metadata_text.count("\n") != 1:
                raise ValueError("collector metadata is not one complete line")
            metadata = json.loads(metadata_text)
            collector_pid = accept_metadata(metadata, os.getuid())
            if collector_pid in collector_pids or metadata["uname"]["release"] != os.uname().release:
                raise ValueError("collector PID or kernel identity rejected")
            collector_pids.add(collector_pid)
            case.update(status="collector_metadata_completed", collector_started=True,
                        collector_completed=True, pid=collector_pid,
                        csv_sha256=sha256(csv_file), metadata_sha256=sha256(metadata_file),
                        collector_exit_checked=True, collector_stderr_checked=True)
            state["completed_processes"] += 1
            analysis = root / "output" / (label + "-analysis.csv")
            summary = root / "output" / (label + "-summary.json")
            command(label + "-analysis", [root / "build-ordinary/analyze_raw_clock", csv_file], 30, analysis, summary)
            result = json.loads(summary.read_text())
            if len(analysis.read_text().splitlines()) != 7 or result.get("schema") != "raw-clock-analysis-v1":
                raise ValueError("analysis six-row output rejected")
            if (sha256(csv_file) != case["csv_sha256"] or
                    sha256(metadata_file) != case["metadata_sha256"]):
                raise ValueError("collector originals changed during analysis")
            case["management_complete_metadata_acceptance"] = True
            case.update(status="accepted", partial_unknown=False)
            state["accepted_pairs"] += 101000
        for filename, expected in SOURCE_SHA256.items():
            if sha256(root / "source" / filename) != expected:
                raise ValueError("source changed during execution")
        state["status"] = "completed"
    except BaseException as error:
        state["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        safe_to_freeze = export_is_safe(state, commands)
        state["supervisor_work_stopped_utc"] = utc()
        state["all_child_work_stopped"] = True if safe_to_freeze else None
        if not safe_to_freeze:
            state["status"] = "failed"
            state["cleanup_unconfirmed"] = True
            state["unconfirmed_processes"] = [{key: record.get(key) for key in
                ("supervisor_pid", "cleanup_pid", "cleanup_pgid", "leader_reaped", "process_group_gone")}
                for record in commands if record.get("supervisor_pid") is not None and not
                cleanup_is_confirmed(record.get("leader_reaped"), record.get("process_group_gone"))]
            export["cleanup_unconfirmed"] = True
            export["unconfirmed_processes"] = state["unconfirmed_processes"]
        state["work_elapsed_seconds"] = time.monotonic() - started
        signal.setitimer(signal.ITIMER_REAL, 30)
        try:
            if safe_to_freeze:
                for case in cases:
                    for suffix, field in ((".csv", "csv_sha256"), (".json", "metadata_sha256")):
                        original = root / "output" / (case["name"] + suffix)
                        case[field] = sha256(original) if original.is_file() and not original.is_symlink() else None
            save_json(root / "after-environment.json", read_context())
            save_json(root / "commands.json", commands)
            save_json(root / "run-state.json", state)
            if not safe_to_freeze:
                raise RuntimeError("cleanup_unconfirmed: frozen manifest and archive withheld")
            save_json(root / "manifest.json", {str(path.relative_to(root)): {"bytes": path.stat().st_size,
                       "sha256": sha256(path)} for path in tree_files(root)})
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
            export.update(archive=str(archive), archive_sha256=sha256(archive), archive_status="archived")
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
    check_argv(str(BASE) + "/raw-clock-aaaaaaa-01234567", commit)
    for bad_root, bad_commit in (("/tmp/raw-clock-aaaaaaa-01234567", commit),
                                  (str(BASE) + "/raw-clock-bbbbbbb-01234567", commit),
                                  (str(BASE) + "/raw-clock-aaaaaaa-../x", commit),
                                  (str(BASE) + "/raw-clock-aaaaaaa-01234567", "a" * 39)):
        try:
            check_argv(bad_root, bad_commit)
        except ValueError:
            continue
        raise AssertionError("invalid path/commit accepted")
    snapshot = {"affinity": [2], "cpu2_check": True, "observed_cpu": 2, "clocksource": "tsc",
                "clocksource_errno": 0, "resolution_errno": 0, "affinity_errno": 0, "cpu_errno": 0,
                "resolution_has_timespec": True, "resolution_seconds": 0,
                "resolution_fractional_ns": 1, "resolution_ns": 1}
    metadata = {"record_count": 101000, "valid_warmup_pairs": 1000, "valid_main_pairs": 100000,
                "planned_warmup_pairs": 1000, "planned_main_pairs": 100000, "uid": 1000,
                "effective_uid": 1000, "target_cpu": 2, "stop_errno": 0, "configuration_writes": 0,
                "uname_errno": 0, "original_affinity_errno": 0, "set_affinity_errno": 0,
                "contract": "raw-empty-pair-v1", "clock": "CLOCK_MONOTONIC_RAW", "stop_reason": "completed",
                "partial_unknown": False, "self_affinity_set": True, "pid": 17,
                "before": dict(snapshot), "after": dict(snapshot)}
    assert accept_metadata(metadata, 1000) == 17
    for key, value in (("record_count", True), ("partial_unknown", True), ("after", None), ("pid", 0),
                       ("before", dict(snapshot, resolution_ns=2)), ("after", dict(snapshot, clocksource="other"))):
        malformed = dict(metadata, **{key: value})
        try:
            accept_metadata(malformed, 1000)
        except ValueError:
            continue
        raise AssertionError("invalid metadata accepted")
    confirmed = {"supervisor_pid": 17, "leader_reaped": True, "process_group_gone": True}
    assert export_is_safe({"cleanup_unconfirmed": False}, [confirmed])
    for leader_reaped, group_gone in ((False, True), (True, False), (None, True), (True, None), (1, True)):
        unknown = dict(confirmed, leader_reaped=leader_reaped, process_group_gone=group_gone)
        assert not export_is_safe({"cleanup_unconfirmed": False}, [unknown])
    assert not export_is_safe({"cleanup_unconfirmed": True}, [confirmed])
    assert not export_is_safe({}, [confirmed])
    return True


if __name__ == "__main__":
    if sys.argv[1:] == ["--selfcheck"]:
        print(json.dumps({"selfcheck": selfcheck()}))
    elif len(sys.argv) == 3:
        sys.exit(run_once(Path(sys.argv[1]), sys.argv[2]))
    else:
        raise SystemExit("usage: remote_run.py ROOT SOURCE_COMMIT | --selfcheck")
