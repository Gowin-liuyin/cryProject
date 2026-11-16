#!/bin/sh
# P3 编排器端到端回放：用合成 20 行 CSV 的微型 fixture manifest 跑
# freeze -> verify -> run-local -> verify -> report，断言 findings 行与 deferred 行。
# 统计量由被调用工具（fixture 内为 mock）给出；pipeline.py 只做编排与 SHA-256 复算。
# 临时目录固定走 CTest 的 A113_TEST_TMPDIR。
set -eu

repository_root=${1:?usage: test_pipeline_replay.sh <repository_root>}
pipeline_program="$repository_root/tools/pipeline/pipeline.py"
: "${A113_TEST_TMPDIR:?CTest must supply an in-build temporary directory}"
python3 --version >/dev/null 2>&1 || {
    printf 'python3 is required for the pipeline replay test\n' >&2
    exit 1
}
test -f "$pipeline_program"

mkdir -p "$A113_TEST_TMPDIR"
work_directory=$(mktemp -d "$A113_TEST_TMPDIR/pipeline-replay.XXXXXXXX")
trap 'rm -rf -- "$work_directory"' EXIT HUP INT TERM
runs_directory="$work_directory/runs"

# 1. 合成 20 行宽表（两列整数纳秒）。
fixture_csv="$work_directory/synthetic-20.csv"
{
    printf 'message-zero,message-ones\n'
    row_index=0
    while [ "$row_index" -lt 20 ]; do
        printf '%s,%s\n' "$((1000 + row_index))" "$((1001 + row_index))"
        row_index=$((row_index + 1))
    done
} > "$fixture_csv"
test "$(wc -l < "$fixture_csv")" -eq 21

# 2. 微型工具：只按 platform_shape_stats 的 CLI 写固定内容，不实现任何统计量。
mock_tool="$work_directory/mock_shape_stats.sh"
cat > "$mock_tool" <<'MOCK_TOOL'
#!/bin/sh
set -eu
input_path=
format=
output_path=
meta_path=
label=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --input) input_path=$2; shift 2 ;;
        --format) format=$2; shift 2 ;;
        --output) output_path=$2; shift 2 ;;
        --meta) meta_path=$2; shift 2 ;;
        --label) label=$2; shift 2 ;;
        *) printf 'mock: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
done
test -f "$input_path"
test "$format" = wide
test "$(wc -l < "$input_path")" -eq 21
cat > "$output_path" <<'MOCK_CSV'
test_name,statistic,p_value,n0,n1,verdict_exploratory
brown_forsythe,0.52,0.48,20,20,clear
ks_two_sample,0.11,0.90,20,20,clear
within_class_second_order_zero,2.10,0.04,10,10,flag
within_class_second_order_ones,-0.50,0.62,10,10,clear
MOCK_CSV
{
    printf 'input_path=%s\n' "$input_path"
    printf 'format=%s\n' "$format"
    printf 'label=%s\n' "$label"
    printf 'family=none_exploratory_only\n'
} > "$meta_path"
MOCK_TOOL
chmod +x "$mock_tool"
mock_digest=$(sha256sum "$mock_tool" | cut -d' ' -f1)

# 3. 微型 fixture manifest：一个可本地执行的 shape stage + 一个必 deferred 的 stage。
fixture_manifest="$work_directory/fixture-manifest.json"
cat > "$fixture_manifest" <<FIXTURE_JSON
{
  "manifest_version": 1,
  "target_id": "fixture-pipeline-replay",
  "module": "M1",
  "source_commit": "synthetic-fixture-no-source-commit",
  "build_preset": "synthetic fixture (no build)",
  "elf_sha256": "$mock_digest",
  "arms": [
    {
      "name": "fixture-arm",
      "build_cmd": "sh mock_shape_stats.sh (synthetic fixture)",
      "digest": "$mock_digest"
    }
  ],
  "class_pairs": [
    { "name": "fixture-main", "class_zero": "message-zero", "class_one": "message-ones" }
  ],
  "stages": [
    {
      "name": "fixture-shape-replay",
      "tool": "platform_shape_stats",
      "args": { "format": "wide", "inputs": ["$fixture_csv"] },
      "artifact_glob": "shape/*.csv"
    },
    {
      "name": "fixture-deferred",
      "tool": "external_evidence",
      "args": {
        "artifacts": ["$fixture_csv"],
        "reason": "synthetic fixture stage cannot run locally",
        "layer": "localize"
      },
      "artifact_glob": "deferred/*"
    }
  ],
  "preregistration_sha256": ""
}
FIXTURE_JSON

# 4. freeze -> verify -> run-local -> verify -> report。
python3 "$pipeline_program" freeze "$fixture_manifest" --runs-dir "$runs_directory"
run_directory="$runs_directory/fixture-pipeline-replay"
test -f "$run_directory/manifest.json"
test -f "$run_directory/artifacts.sha256"
python3 "$pipeline_program" verify "$run_directory"
python3 "$pipeline_program" run-local "$run_directory" --platform-stats "$mock_tool"
python3 "$pipeline_program" verify "$run_directory"
python3 "$pipeline_program" report "$run_directory"

report_path="$run_directory/report.md"
findings_path="$run_directory/findings.json"
test -f "$report_path"
test -f "$findings_path"
grep -q '^| f-0001 |' "$report_path"
grep -q '^| f-0005 |' "$report_path"
grep -q 'deferred_hardware' "$report_path"

python3 - "$findings_path" <<'CHECK_FINDINGS'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as findings_file:
    document = json.load(findings_file)
findings = document["findings"]
assert len(findings) == 5, findings
verdicts = [finding["verdict"] for finding in findings]
assert verdicts.count("positive") == 1, verdicts
assert verdicts.count("negative") == 3, verdicts
assert verdicts.count("not_run") == 1, verdicts
assert findings[-1]["notes"].startswith("deferred_hardware"), findings[-1]
assert findings[-1]["mechanism"] == "not_assessed", findings[-1]
CHECK_FINDINGS

# 5. 篡改一个 run-local 输出 artifact 后 verify 必须退 4，改回后恢复通过。
tampered_artifact=$(find "$run_directory/shape" -type f -name '*.csv' | LC_ALL=C sort | head -n 1)
test -n "$tampered_artifact"
cp "$tampered_artifact" "$work_directory/tamper-backup.bin"
printf 'tampered-byte' >> "$tampered_artifact"
tamper_status=0
python3 "$pipeline_program" verify "$run_directory" >/dev/null 2>&1 || tamper_status=$?
test "$tamper_status" -eq 4
mv "$work_directory/tamper-backup.bin" "$tampered_artifact"
python3 "$pipeline_program" verify "$run_directory" >/dev/null

printf '%s\n' 'pipeline replay: freeze/verify/run-local/report and tamper detection pass'
