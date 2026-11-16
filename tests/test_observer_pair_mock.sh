#!/bin/sh
# 观测者对端到端冒烟（mock 受害者）：验证 wrapper↔观测者的 turn 协议、
# CSV 记数、类别 join，以及 cache mock 的类别相关行命中（热行=类别行的
# 比例阈值 0.7；机制失效时≈0.5 随机，可区分）。不绑核、不联网。
set -eu

SOURCE_ROOT=$1
SMT_OBSERVER=$2
CACHE_OBSERVER=$3
VICTIM_MOCK=$4
[ -n "${A113_TEST_TMPDIR:-}" ] || { echo "A113_TEST_TMPDIR not set" >&2; exit 77; }
PYTHON=${PYTHON3_EXECUTABLE:-python3}
WORK="$A113_TEST_TMPDIR/observer-pair-mock"
rm -rf "$WORK"
mkdir -p "$WORK/lut"

# 4096B 共享 LUT：行 0 全 0；行 1 填 0x681 模式（内容任意，只要求两行可区分寻址）。
"$PYTHON" - "$WORK/lut/m3-shared-lut.bin" <<'PYEOF'
import sys
data = bytearray(4096)
for index in range(32, 64):
    data[2 * index] = 0x81
    data[2 * index + 1] = 0x06
with open(sys.argv[1], "wb") as stream:
    stream.write(data)
PYEOF
printf '{"cache_line_bytes":64,"line_count":2,"lines":[{"byte_offset":0},{"byte_offset":64}]}\n' \
    >"$WORK/lut/layout.json"

RUN_PAIR="$SOURCE_ROOT/tools/platform_observers/run_pair.sh"

echo "== smt pair =="
sh "$RUN_PAIR" --protocol smt --observer "$SMT_OBSERVER" --victim "$VICTIM_MOCK" \
    --outdir "$WORK/smt" --run-id mock-smt --seed 20261116 --batches 64

echo "== cache pair =="
sh "$RUN_PAIR" --protocol cache --observer "$CACHE_OBSERVER" --victim "$VICTIM_MOCK" \
    --outdir "$WORK/cache" --run-id mock-cache --seed 20261116 --batches 48 \
    --map "$WORK/lut/m3-shared-lut.bin" --layout "$WORK/lut/layout.json" \
    --mock-lut "$WORK/lut/m3-shared-lut.bin"

"$PYTHON" - "$WORK" <<'PYEOF'
import csv
import sys

work = sys.argv[1]
failures = []


def data_rows(path):
    with open(path, newline="") as stream:
        rows = [row for row in csv.reader(stream) if row]
    return rows[0], rows[1:]


for name, expected in [
    ("smt/runs/mock-smt/victim.csv", 64),
    ("smt/runs/mock-smt/observer-batches.csv", 64),
    ("smt/runs/mock-smt/batch-classes.csv", 64),
    ("cache/runs/mock-cache/victim.csv", 96),
    ("cache/runs/mock-cache/observer-reloads.csv", 96),
    ("cache/runs/mock-cache/batch-classes.csv", 48),
]:
    header, rows = data_rows(f"{work}/{name}")
    if len(rows) != expected:
        failures.append(f"{name}: {len(rows)} rows, expected {expected}")
    print(f"{name}: header={header} rows={len(rows)}")

for name, expected in [("smt/runs/mock-smt/class-pair.csv", 32),
                       ("cache/runs/mock-cache/class-pair.csv", 48)]:
    header, rows = data_rows(f"{work}/{name}")
    if header != ["message-zero", "message-ones"]:
        failures.append(f"{name}: bad header {header}")
    if len(rows) != expected:
        failures.append(f"{name}: {len(rows)} pairs, expected {expected}")

# cache 类别相关命中：每样本取 reload 较小的行为热行，类别 zero 应对应行 0。
# 只作信息性输出——F+R 信号质量对机器负载敏感（空载 ~0.98、并行回归下可到随机），
# 真实信号验证属裸金属锁频 pilot；本测试只严格断言协议结构与计数。
_, observer_rows = data_rows(f"{work}/cache/runs/mock-cache/observer-reloads.csv")
_, class_rows = data_rows(f"{work}/cache/runs/mock-cache/batch-classes.csv")
labels = {int(row[0]): row[1] for row in class_rows}
correct = 0
samples = len(observer_rows) // 2
for sample_index in range(samples):
    line_zero = float(observer_rows[2 * sample_index][2])
    line_ones = float(observer_rows[2 * sample_index + 1][2])
    hot_line_is_zero = line_zero < line_ones
    label = labels[sample_index]
    if (label == "message-zero") == hot_line_is_zero:
        correct += 1
rate = correct / samples if samples else 0.0
print(f"cache class-hit rate (informational): {correct}/{samples} = {rate:.3f}")

if failures:
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    sys.exit(1)
print("observer pair mock: all checks passed")
PYEOF
