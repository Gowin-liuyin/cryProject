"""M02仅负责进程编排、文件摘要和环境记录；统计与核验由C产物执行。"""

import hashlib
import json
import pathlib
import shutil
import subprocess
import sys
from datetime import datetime, timezone


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def publish(path, value):
    with path.open("x", encoding="utf-8") as output:
        json.dump(value, output, ensure_ascii=False, indent=2)
        output.write("\n")


def snapshot(source, inputs, observer, auditor, manifest, artifacts):
    source_records = {r["path"]: digest(source / r["path"]) for r in manifest["source_hashes"]}
    input_records = {r["path"]: digest(inputs / r["path"]) for r in manifest["fixed_input_hashes"]}
    expected_source = {r["path"]: r["sha256"] for r in manifest["source_hashes"]}
    expected_inputs = {r["path"]: r["sha256"] for r in manifest["fixed_input_hashes"]}
    actual_artifacts = {"normal": digest(observer), "audit": digest(auditor)}
    expected_artifacts = {r["variant"]: r["sha256"] for r in artifacts["artifacts"]}
    valid = source_records == expected_source and input_records == expected_inputs
    valid = valid and all(actual_artifacts[k] == expected_artifacts[k] for k in actual_artifacts)
    return {"utc": datetime.now(timezone.utc).isoformat(), "valid": valid,
            "source": source_records, "inputs": input_records, "artifacts": actual_artifacts}


def recorded_process(arguments, record_root, prefix, cwd):
    with (record_root / (prefix + "-stdout.log")).open("xb") as output:
        with (record_root / (prefix + "-stderr.log")).open("xb") as error:
            process = subprocess.Popen(arguments, cwd=cwd, stdout=output, stderr=error)
            process_record = {"arguments": arguments, "cwd": str(cwd), "pid": process.pid,
                              "utc_start": datetime.now(timezone.utc).isoformat()}
            try:
                publish(record_root / (prefix + "-start.json"), process_record)
                process_record["returncode"] = process.wait()
                process_record["utc_finish"] = datetime.now(timezone.utc).isoformat()
                publish(record_root / (prefix + "-finish.json"), process_record)
            except BaseException:
                if process.poll() is None:
                    try:
                        process.terminate()
                    except ProcessLookupError:
                        pass
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                raise
    return process_record["returncode"]


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: collect_runs.py REPOSITORY_ROOT")
    repository = pathlib.Path(sys.argv[1]).resolve()
    evidence = repository / "docs/evidence/aris-replication-20261009"
    work = repository / "build/aris-replication-20261009"
    execution = evidence / "execution"
    execution.mkdir()
    shutil.copyfile(__file__, execution / "collect_runs.py")
    inputs = evidence / "preparation/fixed-inputs"
    observer = work / "normal/update_cost"
    auditor = work / "audit/update_cost_result_review"
    manifest = json.loads((evidence / "preparation/source-input-manifest.json").read_text())
    artifacts = json.loads((evidence / "preparation/new-artifacts.json").read_text())
    environment = {"orchestration_runtime": {"executable": sys.executable, "version": sys.version}}
    for label, arguments in {
        "platform": ["uname", "-a"], "os": ["sw_vers"],
        "power": ["pmset", "-g", "ps"],
        "machine": ["sysctl", "hw.model", "hw.machine", "hw.ncpu", "hw.memsize", "machdep.cpu.brand_string"],
        "git_status": ["git", "status", "--short", "--branch"],
        "git_commit": ["git", "rev-parse", "HEAD"],
        "git_uncommitted_stat": ["git", "diff", "--stat"],
    }.items():
        result = subprocess.run(arguments, cwd=repository, capture_output=True, text=True)
        environment[label] = {"arguments": arguments, "returncode": result.returncode,
                              "stdout": result.stdout, "stderr": result.stderr}
        if result.returncode:
            publish(execution / "environment.json", environment)
            raise SystemExit("Environment recording failed; no formal launch")
    publish(execution / "environment.json", environment)
    if "AC Power" not in environment["power"]["stdout"]:
        raise SystemExit("Frozen AC condition unavailable; no formal launch")
    if subprocess.check_output(["git", "branch", "--show-current"], cwd=repository, text=True).strip() != "main":
        raise SystemExit("Expected main; no formal launch")
    for number in range(1, 4):
        if (evidence / f"run-{number}").exists():
            raise SystemExit("Formal directory already exists; no formal launch")
    view_root = work / "audit-views"
    view_root.mkdir()
    audits = evidence / "independent-audits"
    audits.mkdir()
    for number in range(1, 4):
        before = snapshot(work / "source", inputs, observer, auditor, manifest, artifacts)
        publish(execution / f"process-{number}-before.json", before)
        if not before["valid"]:
            raise SystemExit("Source/input/artifact mismatch; remaining launches stopped")
        run = evidence / f"run-{number}"
        status = recorded_process([str(observer), str(inputs), str(run)], execution,
                                  f"process-{number}-observer", repository)
        after = snapshot(work / "source", inputs, observer, auditor, manifest, artifacts)
        publish(execution / f"process-{number}-after.json", after)
        if status or not after["valid"]:
            raise SystemExit("Observer or digest failure; remaining launches stopped")
        view = view_root / f"process-{number}"
        view.mkdir()
        (view / "run").symlink_to(run, target_is_directory=True)
        status = recorded_process([str(auditor), str(view), str(inputs),
                                   str(audits / f"process-{number}.json")], execution,
                                  f"process-{number}-audit", repository)
        if status:
            raise SystemExit("C audit failed; remaining launches stopped")
    publish(execution / "completed.json", {"new_observer_processes": 3,
            "per_process_c_audits": 3, "retries": 0, "statistics_language": "C11",
            "scope": "one_clean_build_three_sequential_processes_macos_arm64_fixed_integer_tasks"})
    print("Three formal processes and three independent C audits completed")


if __name__ == "__main__":
    main()
