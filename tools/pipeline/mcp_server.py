#!/usr/bin/env python3
"""A1-13 流水线 MCP server（stdio，换行分隔 JSON-RPC 2.0，纯标准库）。

支持 initialize / tools/list / tools/call 与八个工具。只读 docs/ 与 tools/；
唯一写操作是 detect_submit 的 build/pipeline-runs/jobs.json；
report_generate 交给既有 pipeline.py report 写 run 目录；
repair_propose 只返回文本建议，绝不落盘应用；evidence_get 永远只读。

用法：python3 tools/pipeline/mcp_server.py（stdin/stdout 各一行一个 JSON）
"""

import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

TOOLS_DIRECTORY = Path(__file__).resolve().parent
REPOSITORY_ROOT = TOOLS_DIRECTORY.parents[1]
MANIFEST_DIRECTORY = REPOSITORY_ROOT / "docs" / "research" / "phase3-session-20261116" / "manifests"
RUNS_DIRECTORY = REPOSITORY_ROOT / "build" / "pipeline-runs"
JOBS_PATH = RUNS_DIRECTORY / "jobs.json"
PIPELINE_PATH = TOOLS_DIRECTORY / "pipeline.py"

sys.path.insert(0, str(TOOLS_DIRECTORY))
import repair_propose  # noqa: E402  (同目录模块，导入后再使用)

SERVER_NAME = "a113-pipeline-mcp"
SERVER_VERSION = "0.1.0"
PROTOCOL_VERSION = "2024-11-05"
SAFE_NAME_PATTERN = re.compile(r"^[A-Za-z0-9_.:+-]+$")
RUN_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*$")

TOOL_DEFINITIONS = [
    {
        "name": "registry_list",
        "description": "列出 P3 真实 manifest registry（docs/research/phase3-session-20261116/manifests/）",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "qualify_dry",
        "description": "汇编构建命令但不执行（dry-run）",
        "inputSchema": {
            "type": "object",
            "properties": {
                "target": {"type": "string"},
                "preset": {"type": "string"},
            },
            "required": ["target"],
            "additionalProperties": False,
        },
    },
    {
        "name": "detect_submit",
        "description": "把本地回放或 deferred_hardware 作业入队（写 build/pipeline-runs/jobs.json）",
        "inputSchema": {
            "type": "object",
            "properties": {
                "kind": {"type": "string", "enum": ["local_replay", "deferred_hardware"]},
                "manifest": {"type": "string"},
                "note": {"type": "string"},
            },
            "required": ["kind", "manifest"],
            "additionalProperties": False,
        },
    },
    {
        "name": "job_status",
        "description": "查询作业状态",
        "inputSchema": {
            "type": "object",
            "properties": {"job_id": {"type": "string"}},
            "required": ["job_id"],
            "additionalProperties": False,
        },
    },
    {
        "name": "findings_get",
        "description": "只读读取 build/pipeline-runs/<run_id>/findings.json",
        "inputSchema": {
            "type": "object",
            "properties": {"run_id": {"type": "string"}},
            "required": ["run_id"],
            "additionalProperties": False,
        },
    },
    {
        "name": "repair_propose",
        "description": "包 repair_propose：positive 定位项 × 反汇编文本 → 纯文本补丁建议（不落盘）",
        "inputSchema": {
            "type": "object",
            "properties": {
                "finding": {"type": "string"},
                "disasm": {"type": "string"},
            },
            "required": ["finding", "disasm"],
            "additionalProperties": False,
        },
    },
    {
        "name": "report_generate",
        "description": "包 pipeline.py report：为 build/pipeline-runs/<run_id> 生成 report.md",
        "inputSchema": {
            "type": "object",
            "properties": {"run_id": {"type": "string"}},
            "required": ["run_id"],
            "additionalProperties": False,
        },
    },
    {
        "name": "evidence_get",
        "description": "只读返回 docs/ 或 tools/ 内文件的路径与 SHA-256",
        "inputSchema": {
            "type": "object",
            "properties": {"path": {"type": "string"}},
            "required": ["path"],
            "additionalProperties": False,
        },
    },
]
TOOL_NAMES = tuple(tool["name"] for tool in TOOL_DEFINITIONS)


class ToolError(Exception):
    pass


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as file_handle:
        while True:
            block = file_handle.read(1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def resolve_repository_path(text):
    candidate = Path(text)
    resolved = candidate.resolve() if candidate.is_absolute() else (REPOSITORY_ROOT / candidate).resolve()
    if not resolved.is_relative_to(REPOSITORY_ROOT):
        raise ToolError("path escapes the repository: %s" % text)
    return resolved


def display_path(resolved):
    return resolved.relative_to(REPOSITORY_ROOT).as_posix()


def tool_registry_list(arguments):
    if arguments:
        raise ToolError("registry_list takes no arguments")
    manifests = []
    for manifest_path in sorted(MANIFEST_DIRECTORY.glob("*.json")):
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ToolError("cannot read manifest %s: %s" % (manifest_path, error))
        manifests.append(
            {
                "target_id": manifest.get("target_id"),
                "module": manifest.get("module"),
                "manifest_version": manifest.get("manifest_version"),
                "preregistration_sha256": manifest.get("preregistration_sha256"),
                "path": display_path(manifest_path),
            }
        )
    return {"count": len(manifests), "manifests": manifests}


def tool_qualify_dry(arguments):
    target = arguments.get("target")
    preset = arguments.get("preset", "baseline-wsl")
    if not isinstance(target, str) or SAFE_NAME_PATTERN.match(target) is None:
        raise ToolError("target must be a safe CMake target name")
    if not isinstance(preset, str) or SAFE_NAME_PATTERN.match(preset) is None:
        raise ToolError("preset must be a safe CMake preset name")
    commands = [
        "cmake --preset %s" % preset,
        "cmake --build --preset %s --target %s" % (preset, target),
    ]
    return {
        "executed": False,
        "commands": commands,
        "note": "dry-run：只汇编构建命令，不执行；qualify_dry 不写任何文件",
    }


def load_jobs_document():
    if not JOBS_PATH.is_file():
        return {"jobs": []}
    try:
        document = json.loads(JOBS_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ToolError("cannot read jobs file: %s" % error)
    if not isinstance(document, dict) or not isinstance(document.get("jobs"), list):
        raise ToolError("invalid jobs file")
    return document


def write_jobs_document(document):
    RUNS_DIRECTORY.mkdir(parents=True, exist_ok=True)
    temporary_path = JOBS_PATH.with_name(JOBS_PATH.name + ".tmp")
    temporary_path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    temporary_path.replace(JOBS_PATH)


def tool_detect_submit(arguments):
    kind = arguments.get("kind")
    manifest_id = arguments.get("manifest")
    note = arguments.get("note", "")
    if kind not in ("local_replay", "deferred_hardware"):
        raise ToolError("kind must be local_replay or deferred_hardware")
    if not isinstance(manifest_id, str) or manifest_id == "":
        raise ToolError("manifest must be a non-empty target_id")
    manifest_path = MANIFEST_DIRECTORY / (manifest_id + ".json")
    if not manifest_path.is_file():
        raise ToolError("unknown manifest target_id: %s" % manifest_id)
    if not isinstance(note, str):
        raise ToolError("note must be a string")
    document = load_jobs_document()
    job_id = "job-%04d" % (len(document["jobs"]) + 1)
    job = {
        "job_id": job_id,
        "kind": kind,
        "manifest": manifest_id,
        "status": "queued",
        "note": note,
        "submitted_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    document["jobs"].append(job)
    write_jobs_document(document)
    return {"job": job}


def tool_job_status(arguments):
    job_id = arguments.get("job_id")
    if not isinstance(job_id, str) or job_id == "":
        raise ToolError("job_id must be a non-empty string")
    document = load_jobs_document()
    for job in document["jobs"]:
        if job.get("job_id") == job_id:
            return {"job": job}
    raise ToolError("unknown job_id: %s" % job_id)


def tool_findings_get(arguments):
    run_id = arguments.get("run_id")
    if not isinstance(run_id, str) or RUN_ID_PATTERN.match(run_id) is None:
        raise ToolError("run_id must match ^[a-z0-9][a-z0-9-]*$")
    findings_path = RUNS_DIRECTORY / run_id / "findings.json"
    if not findings_path.is_file():
        raise ToolError("findings.json not found for run_id %s" % run_id)
    try:
        document = json.loads(findings_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ToolError("cannot read findings: %s" % error)
    findings = document.get("findings", [])
    return {
        "run_id": run_id,
        "path": display_path(findings_path),
        "sha256": sha256_file(findings_path),
        "finding_count": len(findings),
        "findings": findings,
    }


def tool_repair_propose(arguments):
    finding_argument = arguments.get("finding")
    disasm_argument = arguments.get("disasm")
    if not isinstance(finding_argument, str) or finding_argument == "":
        raise ToolError("finding must be a non-empty path")
    if not isinstance(disasm_argument, str) or disasm_argument == "":
        raise ToolError("disasm must be a non-empty path")
    findings_path = resolve_repository_path(finding_argument)
    disassembly_path = resolve_repository_path(disasm_argument)
    try:
        report_text = repair_propose.propose(findings_path, disassembly_path)
    except repair_propose.ProposalError as error:
        raise ToolError(str(error))
    return {"exit_code": 0, "text": report_text}


def tool_report_generate(arguments):
    run_id = arguments.get("run_id")
    if not isinstance(run_id, str) or RUN_ID_PATTERN.match(run_id) is None:
        raise ToolError("run_id must match ^[a-z0-9][a-z0-9-]*$")
    run_directory = RUNS_DIRECTORY / run_id
    if not (run_directory / "manifest.json").is_file():
        raise ToolError("run directory not found for run_id %s" % run_id)
    completed = subprocess.run(
        [sys.executable, str(PIPELINE_PATH), "report", str(run_directory)],
        capture_output=True,
        text=True,
        check=False,
    )
    report_path = run_directory / "report.md"
    if completed.returncode != 0 or not report_path.is_file():
        raise ToolError("pipeline report failed: %s" % completed.stderr.strip())
    return {
        "run_id": run_id,
        "returncode": completed.returncode,
        "report_path": display_path(report_path),
        "report_sha256": sha256_file(report_path),
        "stdout": completed.stdout.strip(),
    }


def tool_evidence_get(arguments):
    path_argument = arguments.get("path")
    if not isinstance(path_argument, str) or path_argument == "":
        raise ToolError("path must be a non-empty string")
    resolved = resolve_repository_path(path_argument)
    allowed_prefixes = (REPOSITORY_ROOT / "docs", REPOSITORY_ROOT / "tools")
    if not any(resolved.is_relative_to(prefix.resolve()) for prefix in allowed_prefixes):
        raise ToolError("evidence_get only reads docs/ or tools/")
    if not resolved.is_file():
        return {"path": display_path(resolved), "exists": False}
    return {
        "path": display_path(resolved),
        "exists": True,
        "bytes": resolved.stat().st_size,
        "sha256": sha256_file(resolved),
    }


TOOL_HANDLERS = {
    "registry_list": tool_registry_list,
    "qualify_dry": tool_qualify_dry,
    "detect_submit": tool_detect_submit,
    "job_status": tool_job_status,
    "findings_get": tool_findings_get,
    "repair_propose": tool_repair_propose,
    "report_generate": tool_report_generate,
    "evidence_get": tool_evidence_get,
}


def send_message(message):
    sys.stdout.write(json.dumps(message, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def error_response(request_id, code, message):
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def handle_initialize(request):
    requested_protocol = request.get("params", {}).get("protocolVersion", PROTOCOL_VERSION)
    if not isinstance(requested_protocol, str):
        requested_protocol = PROTOCOL_VERSION
    return {
        "protocolVersion": requested_protocol,
        "capabilities": {"tools": {}},
        "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
        "instructions": "只读 docs/ 与 tools/；写操作仅 build/pipeline-runs/；repair_propose 只给文本建议。",
    }


def handle_tools_call(request):
    params = request.get("params")
    if not isinstance(params, dict):
        raise ToolError("tools/call params must be an object")
    tool_name = params.get("name")
    arguments = params.get("arguments", {})
    if tool_name not in TOOL_HANDLERS:
        raise ToolError("unknown tool: %s" % tool_name)
    if not isinstance(arguments, dict):
        raise ToolError("tool arguments must be an object")
    payload = TOOL_HANDLERS[tool_name](arguments)
    return {
        "content": [{"type": "text", "text": json.dumps(payload, ensure_ascii=False, indent=2)}],
        "isError": False,
    }


def handle_request(request):
    if not isinstance(request, dict):
        return error_response(None, -32600, "invalid request")
    request_id = request.get("id")
    method = request.get("method")
    if not isinstance(method, str):
        return error_response(request_id, -32600, "missing method")
    if request_id is None and method.startswith("notifications/"):
        return None
    try:
        if method == "initialize":
            result = handle_initialize(request)
        elif method == "tools/list":
            result = {"tools": TOOL_DEFINITIONS}
        elif method == "tools/call":
            result = handle_tools_call(request)
        else:
            return error_response(request_id, -32601, "method not found: %s" % method)
    except ToolError as error:
        if method == "tools/call":
            result = {"content": [{"type": "text", "text": str(error)}], "isError": True}
        else:
            return error_response(request_id, -32602, str(error))
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def main():
    for raw_line in sys.stdin:
        line = raw_line.strip()
        if line == "":
            continue
        try:
            request = json.loads(line)
        except json.JSONDecodeError as error:
            send_message(error_response(None, -32700, "parse error: %s" % error))
            continue
        try:
            response = handle_request(request)
        except Exception as error:  # 单个请求失败不应拖垮 server，但必须报告
            send_message(error_response(request.get("id") if isinstance(request, dict) else None,
                -32603, "internal error: %s" % error))
            continue
        if response is not None:
            send_message(response)
    return 0


if __name__ == "__main__":
    sys.exit(main())
