#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: test_v4_schedule.sh COLLECTOR ANALYZER" >&2
    exit 1
fi

if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi

collector=$1
analyzer=$2
root="${A113_TEST_TMPDIR}/v4-schedule"
rm -rf "$root"
mkdir -p "$root"

"$collector" --print-schedule 20261013001 2 "$root/first.txt"
"$collector" --print-schedule 20261013001 2 "$root/second.txt"
cmp -s "$root/first.txt" "$root/second.txt"
python3 - "$root/first.txt" "$root/schedule.csv" <<'PY'
import sys

rows = [line.strip() for line in open(sys.argv[1], encoding="utf-8") if line.strip()]
with open(sys.argv[2], "w", encoding="utf-8") as handle:
    handle.write("schema,ciphertext_sha256_hex\n")
    for digest in rows:
        handle.write("v4_group_session_v1,%s\n" % digest)
PY
"$collector" --check-schedule 20261013001 2 "$root/schedule.csv"
"$collector" --print-schedule 20261013002 2 "$root/other-seed.txt"
if cmp -s "$root/first.txt" "$root/other-seed.txt"; then
    echo "two development seeds produced the same ciphertext schedule" >&2
    exit 1
fi

python3 - "$root/first.txt" <<'PY'
import collections
import sys

rows = [line.strip() for line in open(sys.argv[1], encoding="utf-8") if line.strip()]
if len(rows) != 16 * 2 * 4:
    raise SystemExit("schedule row count is not 16 keys * R=2 * 4 slots")
counts = collections.Counter(rows)
if len(counts) != 32:
    raise SystemExit("expected 32 distinct ciphertexts, found %s" % len(counts))
if any(count != 4 or len(digest) != 64 for digest, count in counts.items()):
    raise SystemExit("each ciphertext must appear twice per class across R=2")
PY

mkdir -p "$root/live"
"$collector" schedule-live session-live 20261013001 1 "$root/live/calls.csv" "$root/live/meta.txt" \
    "$root/live/empty.csv"
grep -F -x -q "unique_ciphertext_check=passed" "$root/live/meta.txt"
grep -F -x -q "status=ok" "$root/live/meta.txt"
printf '%s\n' "$root/live" >"$root/live-manifest.txt"
"$analyzer" reduce-effects "$root/live-manifest.txt" "$root/live-effects.csv" development \
    >"$root/live-reduce.txt"
grep -F -x -q "status=ok" "$root/live-reduce.txt"

python3 - "$root/live/calls.csv" "$root/live/meta.txt" "$root/live-effects.csv" <<'PY'
import hashlib
import sys

calls_path, meta_path, effects_path = sys.argv[1:]
hashes = []
zero_sum = 0.0
ones_sum = 0.0
zero_count = 0
ones_count = 0
for line in open(calls_path, encoding="utf-8"):
    if line.startswith("schema,") or not line.strip():
        continue
    fields = line.rstrip("\n").split(",")
    hashes.append(fields[9])
    elapsed = float(fields[7])
    if fields[6] == "message-zero":
        zero_sum += elapsed
        zero_count += 1
    elif fields[6] == "message-ones":
        ones_sum += elapsed
        ones_count += 1
digest = hashlib.sha256("".join(hashes).encode("ascii")).hexdigest()
recorded = None
for line in open(meta_path, encoding="utf-8"):
    if line.startswith("input_sha256="):
        recorded = line.strip().split("=", 1)[1]
if recorded != digest:
    raise SystemExit("collector input digest does not match the ciphertext column")
effect = zero_sum / zero_count - ones_sum / ones_count
reduced = float(open(effects_path, encoding="utf-8").read().splitlines()[1].split(",")[0])
if abs(reduced - effect) > 1e-6:
    raise SystemExit("reduced effect does not match the raw elapsed means")
PY
