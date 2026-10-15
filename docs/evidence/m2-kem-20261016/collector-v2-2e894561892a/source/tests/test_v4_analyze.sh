#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: test_v4_analyze.sh BINARY SOURCE_ROOT" >&2
    exit 1
fi

binary=$1
source_root=$2

if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi

root="${A113_TEST_TMPDIR}/v4-analyze"
rm -rf "$root"
mkdir -p "$root/power1" "$root/power2" "$root/power-zero" "$root/confirm1" "$root/confirm2" \
    "$root/paired1" "$root/paired2" "$root/diagnose"

cat >"$root/effects.csv" <<'EOF'
effect_counts,empty_median_counts,window_coverage
10,20,1
10,21,1
10,22,1
10,23,1
10,24,1
10,25,1
10,26,1
10,27,1
EOF

cat >"$root/zeros.csv" <<'EOF'
effect_counts,empty_median_counts,window_coverage
0,1,1
0,1,1
0,1,1
0,1,1
0,1,1
0,1,1
0,1,1
0,1,1
EOF

cat >"$root/low-coverage.csv" <<'EOF'
effect_counts,empty_median_counts,window_coverage
10,20,0.5
10,21,1
10,22,1
10,23,1
EOF

cat >"$root/rounds.csv" <<'EOF'
branch_effect_counts,mask_effect_counts
10,1
10,1
10,1
10,1
10,1
EOF

printf '10\n11\n9\n10\n12\n8\n10\n11\n' >"$root/series.txt"

set +e
"$binary" power "$root/effects.csv" "$root/power1" development >"$root/power1/stdout.txt"
power_status=$?
"$binary" power "$root/effects.csv" "$root/power2" development >"$root/power2/stdout.txt"
power_status_2=$?
"$binary" power "$root/zeros.csv" "$root/power-zero" development >"$root/zero-stdout.txt"
zero_status=$?
"$binary" confirm "$root/effects.csv" "$root/confirm1" confirmation >"$root/confirm1/stdout.txt"
confirm_status=$?
"$binary" confirm "$root/effects.csv" "$root/confirm2" confirmation >"$root/confirm2/stdout.txt"
mkdir -p "$root/coverage"
"$binary" confirm "$root/low-coverage.csv" "$root/coverage" confirmation >"$root/coverage-stdout.txt"
coverage_status=$?
"$binary" paired "$root/rounds.csv" "$root/paired1" >"$root/paired1/stdout.txt"
paired_status=$?
"$binary" paired "$root/rounds.csv" "$root/paired2" >"$root/paired2/stdout.txt"
"$binary" order >"$root/order1.txt"
"$binary" order >"$root/order2.txt"
"$binary" label 1 >"$root/label1.txt"
"$binary" label 1 >"$root/label2.txt"
"$binary" diagnose "$root/effects.csv" "$root/series.txt" "$root/diagnose" >"$root/diagnose/stdout.txt"
diagnose_status=$?
set -e

if [ "$power_status" -ne 0 ] || [ "$power_status_2" -ne 0 ] || [ "$zero_status" -ne 0 ]; then
    echo "power command failed" >&2
    exit 1
fi
cmp -s "$root/power1/stdout.txt" "$root/power2/stdout.txt"
cmp -s "$root/power1/stdout.txt" "$root/power1/conclusion.txt"
grep -F -x -q "rule_id=v4_group_confirmation_20261013" "$root/power1/conclusion.txt"
grep -F -x -q "alpha_family=0.01" "$root/power1/conclusion.txt"
grep -F -x -q "power_target=0.9" "$root/power1/conclusion.txt"
grep -F -x -q "status=exported" "$root/power1/conclusion.txt"
grep -F -x -q "repeat_count=2" "$root/power1/conclusion.txt"
grep -F -x -q "session_count=4" "$root/power1/conclusion.txt"
grep -F -x -q "status=stopped_no_stable_group_effect" "$root/zero-stdout.txt"

if [ "$confirm_status" -ne 0 ] || [ "$coverage_status" -ne 0 ]; then
    echo "confirm command failed" >&2
    exit 1
fi
cmp -s "$root/confirm1/stdout.txt" "$root/confirm2/stdout.txt"
grep -F -x -q "primary_token=rejected_direction_consistent" "$root/confirm1/conclusion.txt"
grep -F -x -q "status=stopped_window_coverage" "$root/coverage-stdout.txt"
grep -F -x -q "primary_token=not_run" "$root/coverage-stdout.txt"

python3 - "$root/confirm1/conclusion.txt" "$root/confirm1/session-effects.csv" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read().splitlines()
values = {}
for line in text:
    if "=" in line:
        key, value = line.split("=", 1)
        values[key] = value
mean = float(values["unadjusted_mean_counts"])
intercept = float(values["covariate_intercept_counts"])
if abs(mean - intercept) > 1e-9:
    raise SystemExit("centered intercept moved the mean")
total = 0.0
count = 0
for line in open(sys.argv[2], encoding="utf-8"):
    if line.startswith("session_index"):
        continue
    total += float(line.split(",")[1])
    count += 1
if count != 8 or abs(total / count - mean) > 1e-9:
    raise SystemExit("session table does not match the printed mean")
PY

if [ "$paired_status" -ne 0 ]; then
    echo "paired command failed" >&2
    exit 1
fi
cmp -s "$root/paired1/stdout.txt" "$root/paired2/stdout.txt"
grep -F -x -q "verdict=protection_causality" "$root/paired1/conclusion.txt"
cmp -s "$root/order1.txt" "$root/order2.txt"
cmp -s "$root/label1.txt" "$root/label2.txt"
test "$(wc -l <"$root/label1.txt" | tr -d ' ')" = "24"
if [ "$diagnose_status" -ne 0 ]; then
    echo "diagnose command failed" >&2
    exit 1
fi
grep -F -q "shapiro_premise=" "$root/diagnose/conclusion.txt"
grep -F -q "acf_premise=" "$root/diagnose/conclusion.txt"
grep -F -q "qq_premise=" "$root/diagnose/conclusion.txt"
test -s "$root/diagnose/qq.svg"

# 功效不等式由程序自己的输出核对，不把某个手写 S 当成科学结论。
python3 - "$binary" "$root" <<'PY'
import math
import os
import subprocess
import sys

binary, root = sys.argv[1:]
path = os.path.join(root, "spread.csv")
with open(path, "w", encoding="utf-8") as handle:
    handle.write("effect_counts,empty_median_counts,window_coverage\n")
    for value in (1, 2, 0, 3, 1, 2, 0, 4):
        handle.write("%s,1,1\n" % value)
outdir = os.path.join(root, "spread")
os.makedirs(outdir)
subprocess.check_call([binary, "power", path, outdir, "fixture"], stdout=subprocess.DEVNULL)
text = open(os.path.join(outdir, "conclusion.txt"), encoding="utf-8").read().splitlines()
values = dict(line.split("=", 1) for line in text if "=" in line)
if values["alpha_family"] != "0.01" or values["power_target"] != "0.9":
    raise SystemExit("power header drifted")
if values["status"] == "exported":
    power = float(values["power_at_exported"])
    if power < 0.9:
        raise SystemExit("exported power is below the frozen target")
    if values["power_at_previous"] != "na":
        if float(values["power_at_previous"]) >= 0.9:
            raise SystemExit("a smaller session count already met the target")
elif values["status"] not in (
    "stopped_power_exceeds_cap",
    "stopped_no_stable_group_effect",
):
    raise SystemExit("unexpected power status %s" % values["status"])
PY

python3 - "$binary" "$root" <<'PY'
import hashlib
import os
import subprocess
import sys

binary, root = sys.argv[1:]
raw_root = os.path.join(root, "raw-sessions")
os.makedirs(raw_root)


def write_session(directory, zero_elapsed, ones_elapsed, empty_median, coverage, binary_digest):
    os.makedirs(directory)
    rows = []
    hashes = []
    for key_index in range(16):
        for repeat_index in range(2):
            even_sum = (key_index + repeat_index) % 2 == 0
            if even_sum:
                categories = ("message-zero", "message-ones", "message-ones", "message-zero")
            else:
                categories = ("message-ones", "message-zero", "message-zero", "message-ones")
            for slot_index, category in enumerate(categories):
                elapsed = zero_elapsed if category == "message-zero" else ones_elapsed
                identity = key_index if category == "message-zero" else key_index + 16
                digest = "%064x" % identity
                hashes.append(digest)
                rows.append(
                    "v4_group_session_v1,run,session,%u,%u,%u,%s,%u,CLOCK_MONOTONIC,%s"
                    % (key_index, repeat_index, slot_index, category, elapsed, digest)
                )
    with open(os.path.join(directory, "calls.csv"), "w", encoding="utf-8") as handle:
        handle.write(
            "schema,run_id,session_id,key_index,repeat_index,slot_index,category,"
            "elapsed_clock_counts,clock_path,ciphertext_sha256_hex\n"
        )
        handle.write("\n".join(rows) + "\n")
    with open(os.path.join(directory, "empty.csv"), "w", encoding="utf-8") as handle:
        handle.write("window_index,elapsed_clock_counts,clock_path\n")
        for index in range(256):
            handle.write("%u,%u,CLOCK_MONOTONIC\n" % (index, empty_median))
    input_sha256 = hashlib.sha256("".join(hashes).encode("ascii")).hexdigest()
    with open(os.path.join(directory, "meta.txt"), "w", encoding="utf-8") as handle:
        handle.write(
            "schema=v4_group_session_v1\nrepeat_count=2\nkey_count=16\n"
            "input_sha256=%s\nexecutable_sha256=%s\n" % (input_sha256, binary_digest)
        )
    with open(os.path.join(directory, "coverage.txt"), "w", encoding="utf-8") as handle:
        handle.write("coverage_fraction=%s\n" % coverage)
    with open(os.path.join(directory, "binary.sha256"), "w", encoding="utf-8") as handle:
        handle.write(binary_digest + "\n")
    return rows


def session_effect(path):
    zero_total = 0.0
    ones_total = 0.0
    zero_count = 0
    ones_count = 0
    for line in open(path, encoding="utf-8"):
        if line.startswith("schema,") or not line.strip():
            continue
        fields = line.rstrip("\n").split(",")
        elapsed = float(fields[7])
        if fields[6] == "message-zero":
            zero_total += elapsed
            zero_count += 1
        elif fields[6] == "message-ones":
            ones_total += elapsed
            ones_count += 1
    return zero_total / zero_count - ones_total / ones_count


binary_digest = "ab" * 32
manifest_lines = []
expected_effects = []
for session_index in range(4):
    directory = os.path.join(raw_root, "session-%u" % (session_index + 1))
    write_session(directory, 100 + session_index, 40, 7 + session_index, "1", binary_digest)
    manifest_lines.append(directory)
    expected_effects.append(session_effect(os.path.join(directory, "calls.csv")))
manifest = os.path.join(raw_root, "manifest.txt")
with open(manifest, "w", encoding="utf-8") as handle:
    handle.write("\n".join(manifest_lines) + "\n")

conclusions = []
for run_index in (1, 2):
    outdir = os.path.join(raw_root, "confirm-%u" % run_index)
    os.makedirs(outdir)
    stdout = subprocess.check_output(
        [binary, "confirm-sessions", manifest, outdir, "confirmation"], text=True
    )
    recorded = open(os.path.join(outdir, "conclusion.txt"), encoding="utf-8").read()
    if stdout != recorded:
        raise SystemExit("confirm-sessions stdout differed from conclusion.txt")
    conclusions.append(recorded)
if conclusions[0] != conclusions[1]:
    raise SystemExit("confirm-sessions was not byte-stable")
values = dict(line.split("=", 1) for line in conclusions[0].splitlines() if "=" in line)
expected_mean = sum(expected_effects) / len(expected_effects)
if abs(float(values["unadjusted_mean_counts"]) - expected_mean) > 1e-9:
    raise SystemExit("session mean was not recomputed from the raw elapsed column")
if abs(float(values["covariate_intercept_counts"]) - expected_mean) > 1e-9:
    raise SystemExit("centered empty-window intercept moved the raw mean")
if values["holm_rejected"] == "yes" and values["direction_consistent"] == "yes":
    if values["primary_token"] != "rejected_direction_consistent":
        raise SystemExit("direction gate did not follow the Holm result")
elif values["holm_rejected"] == "no":
    if values["primary_token"] != "not_rejected":
        raise SystemExit("a non-rejection was labeled as a rejection")
else:
    raise SystemExit("unexpected Holm and direction combination")

collision = os.path.join(raw_root, "collision")
write_session(collision, 100, 40, 7, "1", binary_digest)
calls_path = os.path.join(collision, "calls.csv")
rewritten = []
seen_zero = None
for line in open(calls_path, encoding="utf-8"):
    fields = line.rstrip("\n").split(",")
    if len(fields) == 10 and fields[3] == "0" and fields[6] == "message-zero":
        seen_zero = fields[9]
    if (
        len(fields) == 10
        and fields[3] == "1"
        and fields[6] == "message-zero"
        and seen_zero is not None
    ):
        fields[9] = seen_zero
        line = ",".join(fields) + "\n"
    rewritten.append(line if line.endswith("\n") else line + "\n")
with open(calls_path, "w", encoding="utf-8") as handle:
    handle.writelines(rewritten)
hashes = []
for line in rewritten:
    fields = line.rstrip("\n").split(",")
    if len(fields) == 10 and fields[0] == "v4_group_session_v1":
        hashes.append(fields[9])
replacement = hashlib.sha256("".join(hashes).encode("ascii")).hexdigest()
meta_lines = open(os.path.join(collision, "meta.txt"), encoding="utf-8").read().splitlines()
with open(os.path.join(collision, "meta.txt"), "w", encoding="utf-8") as handle:
    for line in meta_lines:
        if line.startswith("input_sha256="):
            handle.write("input_sha256=%s\n" % replacement)
        else:
            handle.write(line + "\n")
collision_manifest = os.path.join(raw_root, "collision-manifest.txt")
with open(collision_manifest, "w", encoding="utf-8") as handle:
    handle.write(collision + "\n")
collision_out = os.path.join(raw_root, "collision-out")
os.makedirs(collision_out)
subprocess.check_call(
    [binary, "confirm-sessions", collision_manifest, collision_out, "confirmation"],
    stdout=subprocess.DEVNULL,
)
collision_values = dict(
    line.split("=", 1)
    for line in open(os.path.join(collision_out, "conclusion.txt"), encoding="utf-8")
    if "=" in line.strip()
)
collision_values = {key.strip(): value.strip() for key, value in collision_values.items()}
if (
    collision_values["status"] != "stopped_ciphertext_collision"
    or collision_values["primary_token"] != "not_run"
):
    raise SystemExit("a collided ciphertext group was not stopped")

digest_manifest = os.path.join(raw_root, "digest-manifest.txt")
digest_session = os.path.join(raw_root, "bad-digest")
write_session(digest_session, 100, 40, 7, "1", binary_digest)
meta_path = os.path.join(digest_session, "meta.txt")
meta_lines = []
for line in open(meta_path, encoding="utf-8"):
    if line.startswith("input_sha256="):
        meta_lines.append("input_sha256=%s\n" % ("0" * 64))
    else:
        meta_lines.append(line if line.endswith("\n") else line + "\n")
with open(meta_path, "w", encoding="utf-8") as handle:
    handle.writelines(meta_lines)
with open(digest_manifest, "w", encoding="utf-8") as handle:
    handle.write(digest_session + "\n")
digest_out = os.path.join(raw_root, "digest-out")
os.makedirs(digest_out)
subprocess.check_call(
    [binary, "confirm-sessions", digest_manifest, digest_out, "confirmation"],
    stdout=subprocess.DEVNULL,
)
digest_values = dict(
    line.split("=", 1)
    for line in open(os.path.join(digest_out, "conclusion.txt"), encoding="utf-8")
    if "=" in line.strip()
)
digest_values = {key.strip(): value.strip() for key, value in digest_values.items()}
if digest_values["status"] != "stopped_input_digest" or digest_values["primary_token"] != "not_run":
    raise SystemExit("an input digest mismatch was accepted")
PY
