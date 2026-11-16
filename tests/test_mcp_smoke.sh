#!/bin/sh
# T4.2 MCP server 冒烟：向 stdin 逐行写三条 JSON-RPC（initialize / tools/list /
# tools/call registry_list），断言三条响应、工具数=8、registry_list 返回两个真实 manifest。
# 只读 registry；不触发 detect_submit 等写操作。
set -eu

repository_root=${1:?usage: test_mcp_smoke.sh <repository_root>}
server_program="$repository_root/tools/pipeline/mcp_server.py"
: "${A113_TEST_TMPDIR:?CTest must supply an in-build temporary directory}"
python3 --version >/dev/null 2>&1 || {
    printf 'python3 is required for the MCP smoke test\n' >&2
    exit 1
}
test -f "$server_program"

mkdir -p "$A113_TEST_TMPDIR"
work_directory=$(mktemp -d "$A113_TEST_TMPDIR/mcp-smoke.XXXXXXXX")
trap 'rm -rf -- "$work_directory"' EXIT HUP INT TERM
response_file="$work_directory/responses.jsonl"

{
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke-test","version":"0.0.1"}}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"registry_list","arguments":{}}}'
} | python3 "$server_program" > "$response_file"

test "$(wc -l < "$response_file")" -eq 3

python3 - "$response_file" <<'CHECK_RESPONSES'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as response_handle:
    responses = [json.loads(line) for line in response_handle if line.strip()]
assert len(responses) == 3, responses
assert [response.get("id") for response in responses] == [1, 2, 3], responses
assert all(response.get("jsonrpc") == "2.0" for response in responses), responses

initialize_result = responses[0]["result"]
assert initialize_result["serverInfo"]["name"] == "a113-pipeline-mcp", initialize_result
assert initialize_result["protocolVersion"] == "2024-11-05", initialize_result
assert "tools" in initialize_result["capabilities"], initialize_result

tool_list = responses[1]["result"]["tools"]
assert len(tool_list) == 8, [tool["name"] for tool in tool_list]
expected_names = {
    "registry_list",
    "qualify_dry",
    "detect_submit",
    "job_status",
    "findings_get",
    "repair_propose",
    "report_generate",
    "evidence_get",
}
assert {tool["name"] for tool in tool_list} == expected_names, tool_list

registry_result = responses[2]["result"]
assert registry_result["isError"] is False, registry_result
content = registry_result["content"]
assert len(content) == 1 and content[0]["type"] == "text", content
registry = json.loads(content[0]["text"])
assert registry["count"] == 2, registry
manifest_ids = {manifest["target_id"] for manifest in registry["manifests"]}
assert manifest_ids == {"m1-r0204-replay", "m5-reference"}, registry
for manifest in registry["manifests"]:
    assert manifest["module"] in ("M1", "M5"), manifest
    assert manifest["path"].endswith(".json"), manifest
CHECK_RESPONSES

printf '%s\n' 'mcp smoke: 3 JSON-RPC responses, 8 tools, 2 manifests'
