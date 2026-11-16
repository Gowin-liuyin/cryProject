#!/usr/bin/env python3
"""P3 编排器 MVP：freeze / verify / run-local / report。

只做编排、SHA-256 复算与报告渲染：统计量一律来自既有 C 件
（platform_shape_stats / platform_holm），本脚本不实现任何统计公式。
输出目录默认 build/pipeline-runs/（gitignored），不进 git、不进 docs/evidence。

退出码：0 成功；1 用法；2 配置/数据错误；4 校验不符（manifest/artifact SHA-256）。
"""

import argparse
import csv
import glob
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNS_DIRECTORY = REPOSITORY_ROOT / "build" / "pipeline-runs"
DEFAULT_PLATFORM_STATS = REPOSITORY_ROOT / "build" / "cmake-platform" / "platform_shape_stats"

EXIT_OK = 0
EXIT_USAGE = 1
EXIT_DATA = 2
EXIT_VERIFY = 4

MANIFEST_VERSION = 1
MODULES = ("M1", "M2", "M3", "M4", "M5", "R17")
LAYERS = ("localize", "microbench", "end_to_end")
MECHANISMS = (
    "early_return",
    "variable_time_compare",
    "data_dependent_loop",
    "data_dependent_memory",
    "failure_path",
    "exception_path",
    "variable_latency_instruction",
    "exploratory_shape_replay",
    "not_assessed",
)
VERDICTS = ("positive", "negative", "not_run", "budget_insufficient")
STAGE_TOOLS = ("platform_shape_stats", "external_evidence")
SHAPE_OUTPUT_COLUMNS = ("test_name", "statistic", "p_value", "n0", "n1", "verdict_exploratory")

SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
TARGET_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]{2,63}$")
FINDING_ID_PATTERN = re.compile(r"^f-[0-9]{4}$")


class PipelineError(Exception):
    def __init__(self, message, exit_code=EXIT_DATA):
        super().__init__(message)
        self.exit_code = exit_code


class PipelineArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        raise PipelineError("usage: " + message, EXIT_USAGE)


def sha256_bytes(content):
    return hashlib.sha256(content).hexdigest()


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as file_handle:
        while True:
            block = file_handle.read(1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def canonical_json(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode(
        "utf-8"
    )


def load_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except OSError as error:
        raise PipelineError("cannot read %s: %s" % (path, error))
    except json.JSONDecodeError as error:
        raise PipelineError("invalid JSON in %s: %s" % (path, error))


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def require(condition, message, exit_code=EXIT_DATA):
    if not condition:
        raise PipelineError(message, exit_code)


def is_sha256(text):
    return isinstance(text, str) and SHA256_PATTERN.match(text) is not None


def require_sha256(text, label):
    require(is_sha256(text), "%s must be a 64-hex SHA-256, got %r" % (label, text))


def manifest_rules(manifest):
    """规则段 = 除 preregistration_sha256 外的整个 manifest。"""
    rules = dict(manifest)
    rules.pop("preregistration_sha256", None)
    return rules


def compute_preregistration_sha256(manifest):
    return sha256_bytes(canonical_json(manifest_rules(manifest)))


def require_exact_keys(value, label, required_keys):
    require(isinstance(value, dict), "%s must be an object" % label)
    actual_keys = set(value.keys())
    required = set(required_keys)
    missing = sorted(required - actual_keys)
    unexpected = sorted(actual_keys - required)
    require(not missing, "%s misses keys: %s" % (label, ", ".join(missing)))
    require(not unexpected, "%s has unexpected keys: %s" % (label, ", ".join(unexpected)))


def require_nonempty_string(value, label):
    require(isinstance(value, str) and value.strip() != "", "%s must be a non-empty string" % label)


def validate_manifest(manifest, require_preregistration):
    manifest_keys = (
        "manifest_version",
        "target_id",
        "module",
        "source_commit",
        "build_preset",
        "elf_sha256",
        "arms",
        "class_pairs",
        "stages",
        "preregistration_sha256",
    )
    require_exact_keys(manifest, "manifest", manifest_keys)
    require(
        manifest["manifest_version"] == MANIFEST_VERSION and isinstance(manifest["manifest_version"], int),
        "manifest_version must be %d" % MANIFEST_VERSION,
    )
    target_id = manifest["target_id"]
    require(
        isinstance(target_id, str) and TARGET_ID_PATTERN.match(target_id) is not None,
        "target_id must match ^[a-z0-9][a-z0-9-]{2,63}$",
    )
    require(manifest["module"] in MODULES, "module must be one of %s" % (MODULES,))
    require_nonempty_string(manifest["source_commit"], "source_commit")
    require_nonempty_string(manifest["build_preset"], "build_preset")
    require_sha256(manifest["elf_sha256"], "elf_sha256")

    arms = manifest["arms"]
    require(isinstance(arms, list) and len(arms) >= 1, "arms must be a non-empty list")
    for arm_index, arm in enumerate(arms):
        arm_label = "arms[%d]" % arm_index
        require_exact_keys(arm, arm_label, ("name", "build_cmd", "digest"))
        require_nonempty_string(arm["name"], arm_label + ".name")
        require_nonempty_string(arm["build_cmd"], arm_label + ".build_cmd")
        require_sha256(arm["digest"], arm_label + ".digest")

    class_pairs = manifest["class_pairs"]
    require(isinstance(class_pairs, list) and len(class_pairs) >= 1, "class_pairs must be a non-empty list")
    for pair_index, class_pair in enumerate(class_pairs):
        pair_label = "class_pairs[%d]" % pair_index
        require_exact_keys(class_pair, pair_label, ("name", "class_zero", "class_one"))
        require_nonempty_string(class_pair["name"], pair_label + ".name")
        require_nonempty_string(class_pair["class_zero"], pair_label + ".class_zero")
        require_nonempty_string(class_pair["class_one"], pair_label + ".class_one")

    stages = manifest["stages"]
    require(isinstance(stages, list) and len(stages) >= 1, "stages must be a non-empty list")
    for stage_index, stage in enumerate(stages):
        stage_label = "stages[%d]" % stage_index
        require_exact_keys(stage, stage_label, ("name", "tool", "args", "artifact_glob"))
        require_nonempty_string(stage["name"], stage_label + ".name")
        require(stage["tool"] in STAGE_TOOLS, stage_label + ".tool must be one of %s" % (STAGE_TOOLS,))
        require(isinstance(stage["args"], dict), stage_label + ".args must be an object")
        require(isinstance(stage["artifact_glob"], str), stage_label + ".artifact_glob must be a string")
        validate_stage_args(stage, stage_label)

    preregistration = manifest["preregistration_sha256"]
    if require_preregistration:
        require_sha256(preregistration, "preregistration_sha256")
    else:
        require(
            preregistration == "" or is_sha256(preregistration),
            "preregistration_sha256 must be empty or a 64-hex SHA-256",
        )


def validate_stage_args(stage, stage_label):
    args = stage["args"]
    if stage["tool"] == "platform_shape_stats":
        allowed_keys = {"format", "inputs", "inputs_glob"}
        unexpected = sorted(set(args.keys()) - allowed_keys)
        require(not unexpected, stage_label + ".args has unexpected keys: " + ", ".join(unexpected))
        require(args.get("format") in ("wide", "long"), stage_label + ".args.format must be wide or long")
        has_inputs = "inputs" in args
        has_glob = "inputs_glob" in args
        require(has_inputs != has_glob, stage_label + ".args needs exactly one of inputs / inputs_glob")
        if has_inputs:
            require(
                isinstance(args["inputs"], list) and len(args["inputs"]) >= 1,
                stage_label + ".args.inputs must be a non-empty list",
            )
            for input_index, input_path in enumerate(args["inputs"]):
                require_nonempty_string(input_path, "%s.args.inputs[%d]" % (stage_label, input_index))
        else:
            require_nonempty_string(args["inputs_glob"], stage_label + ".args.inputs_glob")
    else:
        require("artifacts" in args, stage_label + ".args.artifacts is required")
        require(
            isinstance(args["artifacts"], list) and len(args["artifacts"]) >= 1,
            stage_label + ".args.artifacts must be a non-empty list",
        )
        for artifact_index, artifact_path in enumerate(args["artifacts"]):
            require_nonempty_string(
                artifact_path, "%s.args.artifacts[%d]" % (stage_label, artifact_index)
            )
        require_nonempty_string(args.get("reason", ""), stage_label + ".args.reason")
        if "layer" in args:
            require(args["layer"] in LAYERS, stage_label + ".args.layer must be one of %s" % (LAYERS,))
        if "mechanism" in args:
            require(
                args["mechanism"] in MECHANISMS,
                stage_label + ".args.mechanism must be one of %s" % (MECHANISMS,),
            )


def validate_findings_document(document):
    require_exact_keys(document, "findings document", ("run_id", "manifest_sha256", "findings"))
    require_nonempty_string(document["run_id"], "findings.run_id")
    require_sha256(document["manifest_sha256"], "findings.manifest_sha256")
    findings = document["findings"]
    require(isinstance(findings, list), "findings must be a list")
    finding_keys = (
        "finding_id",
        "module",
        "arm",
        "layer",
        "mechanism",
        "verdict",
        "evidence_path",
        "evidence_sha256",
        "notes",
    )
    seen_ids = set()
    for finding_index, finding in enumerate(findings):
        finding_label = "findings[%d]" % finding_index
        require_exact_keys(finding, finding_label, finding_keys)
        require(
            isinstance(finding["finding_id"], str)
            and FINDING_ID_PATTERN.match(finding["finding_id"]) is not None,
            finding_label + ".finding_id must match ^f-[0-9]{4}$",
        )
        require(finding["finding_id"] not in seen_ids, "duplicate finding_id " + finding["finding_id"])
        seen_ids.add(finding["finding_id"])
        require(finding["module"] in MODULES, finding_label + ".module must be one of %s" % (MODULES,))
        require_nonempty_string(finding["arm"], finding_label + ".arm")
        require(finding["layer"] in LAYERS, finding_label + ".layer must be one of %s" % (LAYERS,))
        require(
            finding["mechanism"] in MECHANISMS,
            finding_label + ".mechanism must be one of %s" % (MECHANISMS,),
        )
        require(finding["verdict"] in VERDICTS, finding_label + ".verdict must be one of %s" % (VERDICTS,))
        require_nonempty_string(finding["evidence_path"], finding_label + ".evidence_path")
        require(
            finding["evidence_sha256"] == "" or is_sha256(finding["evidence_sha256"]),
            finding_label + ".evidence_sha256 must be empty or 64-hex SHA-256",
        )
        require_nonempty_string(finding["notes"], finding_label + ".notes")
        if finding["verdict"] == "not_run":
            require(
                finding["mechanism"] == "not_assessed"
                or finding["mechanism"] in MECHANISMS,
                finding_label + ".mechanism invalid for not_run",
            )


def resolve_input_path(text, manifest_directory):
    """相对路径先按仓库根解析；仓库根下不存在时再按 manifest 所在目录解析。"""
    candidate = Path(text)
    if candidate.is_absolute():
        return candidate
    repository_candidate = REPOSITORY_ROOT / text
    if repository_candidate.exists():
        return repository_candidate
    return Path(manifest_directory) / text


def display_path(resolved_path):
    resolved_path = Path(resolved_path)
    try:
        return resolved_path.resolve().relative_to(REPOSITORY_ROOT).as_posix()
    except ValueError:
        return resolved_path.resolve().as_posix()


def expand_stage_inputs(stage, manifest_directory):
    args = stage["args"]
    if "inputs" in args:
        return [text for text in args["inputs"]]
    pattern = args["inputs_glob"]
    if Path(pattern).is_absolute():
        matches = sorted(glob.glob(pattern))
        require(len(matches) >= 1, "inputs_glob matched no files: " + pattern)
        return [Path(match).as_posix() for match in matches]
    matches = sorted(glob.glob(str(REPOSITORY_ROOT / pattern)))
    require(len(matches) >= 1, "inputs_glob matched no files: " + pattern)
    return [display_path(Path(match)) for match in matches]


def stage_input_records(manifest, manifest_directory):
    records = []
    for stage in manifest["stages"]:
        if stage["tool"] == "platform_shape_stats":
            paths = expand_stage_inputs(stage, manifest_directory)
        else:
            paths = list(stage["args"]["artifacts"])
        for path_text in paths:
            resolved = resolve_input_path(path_text, manifest_directory)
            require(
                resolved.is_file(),
                "stage %s references a missing artifact: %s" % (stage["name"], path_text),
            )
            display = display_path(resolved) if not Path(path_text).is_absolute() else Path(
                path_text
            ).as_posix()
            records.append((display, resolved, sha256_file(resolved)))
    return records


def read_artifacts_file(run_directory):
    artifacts_path = run_directory / "artifacts.sha256"
    require(artifacts_path.is_file(), "missing %s" % artifacts_path, EXIT_VERIFY)
    records = []
    for line_number, line in enumerate(
        artifacts_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if line.strip() == "":
            continue
        parts = line.split("  ", 1)
        require(len(parts) == 2, "invalid artifacts.sha256 line %d" % line_number, EXIT_VERIFY)
        records.append((parts[0], parts[1]))
    return records


def verify_artifact_records(records, manifest_directory):
    for expected_digest, path_text in records:
        resolved = resolve_input_path(path_text, manifest_directory)
        require(resolved.is_file(), "artifact is missing: %s" % path_text, EXIT_VERIFY)
        actual_digest = sha256_file(resolved)
        require(
            actual_digest == expected_digest,
            "artifact SHA-256 mismatch: %s (expected %s, got %s)"
            % (path_text, expected_digest, actual_digest),
            EXIT_VERIFY,
        )


def verify_run_directory(run_directory):
    run_directory = Path(run_directory)
    manifest_path = run_directory / "manifest.json"
    require(manifest_path.is_file(), "missing %s" % manifest_path, EXIT_VERIFY)
    manifest = load_json(manifest_path)
    validate_manifest(manifest, require_preregistration=True)
    manifest_directory = run_directory
    computed_preregistration = compute_preregistration_sha256(manifest)
    require(
        computed_preregistration == manifest["preregistration_sha256"],
        "preregistration_sha256 mismatch (expected %s, got %s)"
        % (manifest["preregistration_sha256"], computed_preregistration),
        EXIT_VERIFY,
    )
    freeze_document = load_json(run_directory / "freeze.json")
    require(
        freeze_document.get("preregistration_sha256") == computed_preregistration,
        "freeze.json preregistration_sha256 mismatch",
        EXIT_VERIFY,
    )
    require(
        freeze_document.get("manifest_sha256") == sha256_file(manifest_path),
        "frozen manifest SHA-256 mismatch",
        EXIT_VERIFY,
    )
    verify_artifact_records(read_artifacts_file(run_directory), manifest_directory)
    journal_path = run_directory / "journal.json"
    if journal_path.is_file():
        journal = load_json(journal_path)
        for stage_record in journal.get("stages", []):
            for output in stage_record.get("outputs", []):
                resolved = resolve_input_path(output["path"], manifest_directory)
                require(resolved.is_file(), "stage output is missing: %s" % output["path"], EXIT_VERIFY)
                require(
                    sha256_file(resolved) == output["sha256"],
                    "stage output SHA-256 mismatch: %s" % output["path"],
                    EXIT_VERIFY,
                )
    findings_path = run_directory / "findings.json"
    if findings_path.is_file():
        findings_document = load_json(findings_path)
        validate_findings_document(findings_document)
        for finding in findings_document["findings"]:
            if finding["evidence_sha256"] == "":
                continue
            resolved = resolve_input_path(finding["evidence_path"], manifest_directory)
            require(
                resolved.is_file(),
                "finding evidence is missing: %s" % finding["evidence_path"],
                EXIT_VERIFY,
            )
            require(
                sha256_file(resolved) == finding["evidence_sha256"],
                "finding evidence SHA-256 mismatch: %s" % finding["evidence_path"],
                EXIT_VERIFY,
            )
    return manifest


def relpath_for_display(resolved_path):
    try:
        return Path(resolved_path).resolve().relative_to(REPOSITORY_ROOT).as_posix()
    except ValueError:
        return Path(resolved_path).resolve().as_posix()


def command_freeze(arguments):
    manifest_path = Path(arguments.manifest).resolve()
    require(manifest_path.is_file(), "manifest not found: %s" % arguments.manifest)
    manifest = load_json(manifest_path)
    validate_manifest(manifest, require_preregistration=False)
    manifest["preregistration_sha256"] = compute_preregistration_sha256(manifest)
    validate_manifest(manifest, require_preregistration=True)

    runs_directory = (
        Path(arguments.runs_dir).resolve()
        if arguments.runs_dir is not None
        else DEFAULT_RUNS_DIRECTORY
    )
    run_directory = runs_directory / manifest["target_id"]
    if run_directory.exists() and any(run_directory.iterdir()):
        if arguments.force:
            for stale_entry in sorted(run_directory.iterdir()):
                if stale_entry.is_dir():
                    for child_entry in sorted(stale_entry.rglob("*"), reverse=True):
                        child_entry.unlink() if child_entry.is_file() else child_entry.rmdir()
                    stale_entry.rmdir()
                else:
                    stale_entry.unlink()
        else:
            raise PipelineError(
                "run directory already exists: %s (pass --force or choose another --runs-dir)"
                % run_directory
            )
    run_directory.mkdir(parents=True, exist_ok=True)

    artifact_records = stage_input_records(manifest, manifest_path.parent)
    write_json(run_directory / "manifest.json", manifest)
    manifest_digest = sha256_file(run_directory / "manifest.json")
    freeze_document = {
        "run_id": manifest["target_id"],
        "source_manifest_path": manifest_path.as_posix(),
        "target_id": manifest["target_id"],
        "module": manifest["module"],
        "preregistration_sha256": manifest["preregistration_sha256"],
        "manifest_sha256": manifest_digest,
        "artifact_count": len(artifact_records),
        "frozen_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "pipeline_script_sha256": sha256_file(Path(__file__).resolve()),
    }
    write_json(run_directory / "freeze.json", freeze_document)
    artifact_lines = ["%s  %s" % (digest, display) for display, _, digest in artifact_records]
    (run_directory / "artifacts.sha256").write_text(
        "\n".join(artifact_lines) + "\n", encoding="utf-8"
    )
    print(
        "freeze: run_id=%s artifacts=%d preregistration=%s"
        % (manifest["target_id"], len(artifact_records), manifest["preregistration_sha256"])
    )
    print("freeze: run directory %s" % run_directory)
    return EXIT_OK


def command_verify(arguments):
    run_directory = Path(arguments.run_dir).resolve()
    require(run_directory.is_dir(), "run directory not found: %s" % arguments.run_dir, EXIT_VERIFY)
    try:
        verify_run_directory(run_directory)
    except PipelineError as error:
        if error.exit_code is None:
            raise
        raise PipelineError("verify failed: %s" % error, EXIT_VERIFY)
    print("verify ok: %s" % run_directory)
    return EXIT_OK


def select_arm_name(manifest, input_display):
    arms = manifest["arms"]
    if len(arms) == 1:
        return arms[0]["name"]
    lowered = input_display.lower()
    if "vulnerable" in lowered:
        return arms[0]["name"]
    if "fixed" in lowered:
        return arms[1]["name"]
    return arms[0]["name"]


def slugify(text):
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "input"


def read_shape_output(output_path):
    with open(output_path, "r", encoding="utf-8", newline="") as output_file:
        reader = csv.reader(output_file)
        header = next(reader, None)
        require(
            header == list(SHAPE_OUTPUT_COLUMNS),
            "unexpected platform_shape_stats header in %s: %r" % (output_path, header),
        )
        rows = []
        for row in reader:
            require(len(row) == len(SHAPE_OUTPUT_COLUMNS), "malformed stats row in %s" % output_path)
            rows.append(
                {
                    "test_name": row[0],
                    "statistic": float(row[1]),
                    "p_value": float(row[2]),
                    "n0": int(row[3]),
                    "n1": int(row[4]),
                    "verdict_exploratory": row[5],
                }
            )
    require(len(rows) >= 1, "platform_shape_stats wrote no rows: %s" % output_path)
    for row in rows:
        require(
            row["verdict_exploratory"] in ("flag", "clear"),
            "unexpected verdict in %s: %r" % (output_path, row["verdict_exploratory"]),
        )
    return rows


def append_finding(findings, manifest, arm_name, layer, mechanism, verdict, evidence_path,
    evidence_sha256, notes):
    findings.append(
        {
            "finding_id": "f-%04d" % (len(findings) + 1),
            "module": manifest["module"],
            "arm": arm_name,
            "layer": layer,
            "mechanism": mechanism,
            "verdict": verdict,
            "evidence_path": evidence_path,
            "evidence_sha256": evidence_sha256,
            "notes": notes,
        }
    )


def execute_shape_stage(stage, manifest, run_directory, platform_stats_path, findings,
    journal_outputs):
    args = stage["args"]
    require(
        platform_stats_path.is_file(),
        "platform_shape_stats executable not found: %s" % platform_stats_path,
    )
    require(
        platform_stats_path.stat().st_mode & 0o111 != 0,
        "platform_shape_stats is not executable: %s" % platform_stats_path,
    )
    inputs = expand_stage_inputs(stage, run_directory)
    stage_output_directory = run_directory / "shape"
    stage_output_directory.mkdir(parents=True, exist_ok=True)
    for input_text in inputs:
        resolved_input = resolve_input_path(input_text, run_directory)
        require(resolved_input.is_file(), "shape replay input missing: %s" % input_text)
        input_display = input_text if Path(input_text).is_absolute() else display_path(resolved_input)
        stem = slugify(input_display)
        output_csv = stage_output_directory / (stem + ".csv")
        output_meta = stage_output_directory / (stem + ".meta.txt")
        command = [
            str(platform_stats_path),
            "--input",
            str(resolved_input),
            "--format",
            args["format"],
            "--output",
            str(output_csv),
            "--meta",
            str(output_meta),
            "--label",
            input_display,
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        require(
            completed.returncode == 0,
            "platform_shape_stats failed for %s (exit %d): %s"
            % (input_display, completed.returncode, completed.stderr.strip()),
        )
        require(output_csv.is_file() and output_meta.is_file(), "shape replay wrote no output")
        arm_name = select_arm_name(manifest, input_display)
        output_display = display_path(output_csv)
        output_digest = sha256_file(output_csv)
        for row in read_shape_output(output_csv):
            verdict = "positive" if row["verdict_exploratory"] == "flag" else "negative"
            notes = (
                "exploratory replay only; not in any Holm family; test=%s; statistic=%s; "
                "p_value=%s; alpha=0.05"
                % (row["test_name"], row["statistic"], row["p_value"])
            )
            append_finding(
                findings,
                manifest,
                arm_name,
                "end_to_end",
                "exploratory_shape_replay",
                verdict,
                output_display,
                output_digest,
                notes,
            )
        journal_outputs.append(output_csv)
        journal_outputs.append(output_meta)


def execute_evidence_stage(stage, manifest, run_directory, findings, journal_outputs):
    del journal_outputs
    args = stage["args"]
    layer = args.get("layer", "end_to_end")
    mechanism = args.get("mechanism", "not_assessed")
    artifact_display = None
    artifact_digest = ""
    for artifact_text in args["artifacts"]:
        resolved = resolve_input_path(artifact_text, run_directory)
        require(resolved.is_file(), "evidence artifact missing: %s" % artifact_text)
        if artifact_display is None:
            artifact_display = (
                artifact_text if Path(artifact_text).is_absolute() else display_path(resolved)
            )
            artifact_digest = sha256_file(resolved)
    append_finding(
        findings,
        manifest,
        manifest["arms"][0]["name"],
        layer,
        mechanism,
        "not_run",
        artifact_display,
        artifact_digest,
        "deferred_hardware: " + args["reason"],
    )
    return {
        "evidence_path": artifact_display,
        "evidence_sha256": artifact_digest,
        "reason": args["reason"],
    }


def command_run_local(arguments):
    run_directory = Path(arguments.run_dir).resolve()
    require(run_directory.is_dir(), "run directory not found: %s" % arguments.run_dir, EXIT_VERIFY)
    try:
        manifest = verify_run_directory(run_directory)
    except PipelineError as error:
        if error.exit_code is None:
            raise
        raise PipelineError("verify failed: %s" % error, EXIT_VERIFY)
    platform_stats_path = (
        Path(arguments.platform_stats).resolve()
        if arguments.platform_stats is not None
        else DEFAULT_PLATFORM_STATS
    )
    findings = []
    journal_stages = []
    for stage in manifest["stages"]:
        journal_outputs = []
        if stage["tool"] == "platform_shape_stats":
            execute_shape_stage(
                stage, manifest, run_directory, platform_stats_path, findings, journal_outputs
            )
            journal_stages.append(
                {
                    "name": stage["name"],
                    "tool": stage["tool"],
                    "status": "executed",
                    "outputs": [
                        {
                            "path": display_path(output_path),
                            "sha256": sha256_file(output_path),
                        }
                        for output_path in journal_outputs
                    ],
                }
            )
        else:
            deferred_record = execute_evidence_stage(
                stage, manifest, run_directory, findings, journal_outputs
            )
            journal_stages.append(
                {
                    "name": stage["name"],
                    "tool": stage["tool"],
                    "status": "deferred",
                    "outputs": [],
                    "evidence_path": deferred_record["evidence_path"],
                    "evidence_sha256": deferred_record["evidence_sha256"],
                    "reason": deferred_record["reason"],
                }
            )
    findings_document = {
        "run_id": manifest["target_id"],
        "manifest_sha256": sha256_file(run_directory / "manifest.json"),
        "findings": findings,
    }
    validate_findings_document(findings_document)
    write_json(run_directory / "findings.json", findings_document)
    journal = {
        "run_id": manifest["target_id"],
        "manifest_sha256": sha256_file(run_directory / "manifest.json"),
        "platform_stats_executable": platform_stats_path.as_posix(),
        "platform_stats_sha256": sha256_file(platform_stats_path)
        if platform_stats_path.is_file()
        else "",
        "stages": journal_stages,
        "completed_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    write_json(run_directory / "journal.json", journal)
    verdict_counts = {}
    for finding in findings:
        verdict_counts[finding["verdict"]] = verdict_counts.get(finding["verdict"], 0) + 1
    print(
        "run-local: run_id=%s findings=%d verdicts=%s"
        % (manifest["target_id"], len(findings), json.dumps(verdict_counts, sort_keys=True))
    )
    print("run-local: findings %s" % (run_directory / "findings.json"))
    return EXIT_OK


def markdown_cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def command_report(arguments):
    run_directory = Path(arguments.run_dir).resolve()
    require(run_directory.is_dir(), "run directory not found: %s" % arguments.run_dir, EXIT_VERIFY)
    try:
        manifest = verify_run_directory(run_directory)
    except PipelineError as error:
        if error.exit_code is None:
            raise
        raise PipelineError("verify failed: %s" % error, EXIT_VERIFY)
    findings_path = run_directory / "findings.json"
    require(findings_path.is_file(), "missing findings.json; run run-local first")
    findings_document = load_json(findings_path)
    validate_findings_document(findings_document)
    journal = load_json(run_directory / "journal.json")
    freeze_document = load_json(run_directory / "freeze.json")

    lines = []
    lines.append("# Pipeline report: %s" % manifest["target_id"])
    lines.append("")
    lines.append("本报告由 `tools/pipeline/pipeline.py report` 渲染；统计量全部来自既有 C 件")
    lines.append("（`platform_shape_stats` / `platform_holm`），编排器只做编排、SHA-256 复算与渲染。")
    lines.append("")
    lines.append("## manifest 摘要")
    lines.append("")
    lines.append("| 项 | 值 |")
    lines.append("|---|---|")
    lines.append("| target_id | `%s` |" % manifest["target_id"])
    lines.append("| module | `%s` |" % manifest["module"])
    lines.append("| source_commit | `%s` |" % markdown_cell(manifest["source_commit"]))
    lines.append("| build_preset | `%s` |" % markdown_cell(manifest["build_preset"]))
    lines.append("| elf_sha256 | `%s` |" % manifest["elf_sha256"])
    lines.append("| preregistration_sha256 | `%s` |" % manifest["preregistration_sha256"])
    lines.append("| manifest_sha256 | `%s` |" % freeze_document["manifest_sha256"])
    lines.append("")
    lines.append("## arms")
    lines.append("")
    lines.append("| name | build_cmd | digest |")
    lines.append("|---|---|---|")
    for arm in manifest["arms"]:
        lines.append(
            "| `%s` | `%s` | `%s` |"
            % (arm["name"], markdown_cell(arm["build_cmd"]), arm["digest"])
        )
    lines.append("")
    lines.append("## class_pairs")
    lines.append("")
    lines.append("| name | class_zero | class_one |")
    lines.append("|---|---|---|")
    for class_pair in manifest["class_pairs"]:
        lines.append(
            "| `%s` | `%s` | `%s` |"
            % (class_pair["name"], class_pair["class_zero"], class_pair["class_one"])
        )
    lines.append("")
    lines.append("## stages")
    lines.append("")
    lines.append("| name | tool | artifact_glob | status |")
    lines.append("|---|---|---|---|")
    stage_status = {record["name"]: record["status"] for record in journal["stages"]}
    for stage in manifest["stages"]:
        lines.append(
            "| `%s` | `%s` | `%s` | `%s` |"
            % (
                stage["name"],
                stage["tool"],
                markdown_cell(stage["artifact_glob"]),
                stage_status.get(stage["name"], "unknown"),
            )
        )
    lines.append("")
    lines.append("## findings")
    lines.append("")
    lines.append("| finding_id | arm | layer | mechanism | verdict | evidence_path | notes |")
    lines.append("|---|---|---|---|---|---|---|")
    for finding in findings_document["findings"]:
        lines.append(
            "| %s | `%s` | `%s` | `%s` | %s | `%s` | %s |"
            % (
                finding["finding_id"],
                finding["arm"],
                finding["layer"],
                finding["mechanism"],
                finding["verdict"],
                markdown_cell(finding["evidence_path"]),
                markdown_cell(finding["notes"]),
            )
        )
    lines.append("")
    lines.append("## deferred 清单")
    lines.append("")
    deferred_records = [
        record for record in journal["stages"] if record["status"] == "deferred"
    ]
    if not deferred_records:
        lines.append("（无 deferred stage）")
    else:
        for record in deferred_records:
            evidence_text = record.get("evidence_path", "（无）")
            reason_text = record.get("reason", "（未记录原因）")
            lines.append(
                "- `%s`: deferred_hardware（%s；evidence: `%s`）"
                % (record["name"], markdown_cell(reason_text), markdown_cell(evidence_text))
            )
    lines.append("")
    lines.append("## 校验")
    lines.append("")
    lines.append(
        "`python3 tools/pipeline/pipeline.py verify %s` 通过；冻结 manifest、"
        "`artifacts.sha256` 与 run-local 输出均按 SHA-256 复核。"
        % run_directory.as_posix()
    )
    lines.append("")
    report_path = run_directory / "report.md"
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("report: %s" % report_path)
    return EXIT_OK


def build_argument_parser():
    parser = PipelineArgumentParser(
        description="A1-13 pipeline MVP: freeze/verify/run-local/report (no statistics here)"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    freeze_parser = subparsers.add_parser("freeze", help="validate manifest and write frozen copy")
    freeze_parser.add_argument("manifest")
    freeze_parser.add_argument("--runs-dir", default=None)
    freeze_parser.add_argument("--force", action="store_true")
    freeze_parser.set_defaults(handler=command_freeze)

    verify_parser = subparsers.add_parser("verify", help="recompute all recorded SHA-256")
    verify_parser.add_argument("run_dir")
    verify_parser.set_defaults(handler=command_verify)

    run_parser = subparsers.add_parser("run-local", help="execute locally runnable stages")
    run_parser.add_argument("run_dir")
    run_parser.add_argument("--platform-stats", default=None)
    run_parser.set_defaults(handler=command_run_local)

    report_parser = subparsers.add_parser("report", help="render report.md from findings")
    report_parser.add_argument("run_dir")
    report_parser.set_defaults(handler=command_report)
    return parser


def main(argument_values=None):
    parser = build_argument_parser()
    try:
        arguments = parser.parse_args(argument_values)
        return arguments.handler(arguments)
    except PipelineError as error:
        print("pipeline error: %s" % error, file=sys.stderr)
        return error.exit_code


if __name__ == "__main__":
    sys.exit(main())
