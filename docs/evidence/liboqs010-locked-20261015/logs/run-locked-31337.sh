#!/bin/bash
# 锁频后的历史解封装对比。口令只从环境变量 SUDO_PW 读取，不写入本文件。
set -eu
WORK=/home/nss-marker/yhr/Cry/liboqs010-historical-20261015-86131c2
cd "$WORK"
export LC_ALL=C
export TMPDIR="$WORK/tmp"
export TEMP="$WORK/tmp"
export TMP="$WORK/tmp"
mkdir -p "$TMPDIR" \
  runs/locked-31337-10k/vulnerable \
  runs/locked-31337-10k/fixed \
  runs/locked-31337-10k/micro \
  runs/locked-31337-10k/freq-before \
  logs

RUN=runs/locked-31337-10k
VULN=./build/historical-clangover/historical/measure
FIXED=./build/historical-fixed-982c762/historical/measure
VULN_LIB=./build/historical-clangover/liboqs010-install/lib/liboqs.a
FIXED_LIB=./build/historical-fixed-982c762/liboqs010-install/lib/liboqs.a
CPU=/sys/devices/system/cpu/cpu2/cpufreq
BOOST=/sys/devices/system/cpu/cpufreq/boost
TARGET_KHZ=4300000
restored=0

if [ -z "${SUDO_PW:-}" ]; then
  echo "missing SUDO_PW" >&2
  exit 2
fi

snapshot_freq() {
  local cpu id key
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    [ -d "$cpu/cpufreq" ] || continue
    id=$(basename "$cpu")
    for key in scaling_governor scaling_min_freq scaling_max_freq energy_performance_preference; do
      if [ -f "$cpu/cpufreq/$key" ]; then
        printf '%s %s %s\n' "$id" "$key" "$(cat "$cpu/cpufreq/$key")"
      fi
    done
  done
  if [ -f "$BOOST" ]; then
    printf 'global boost %s\n' "$(cat "$BOOST")"
  fi
}

cat > "$RUN/freq-before/restore_freq.py" << 'PY'
import pathlib, sys
snap = pathlib.Path(sys.argv[1]).read_text().splitlines()
rows = []
boost = None
for line in snap:
    parts = line.split()
    if len(parts) != 3:
        continue
    if parts[0] == "global" and parts[1] == "boost":
        boost = parts[2]
        continue
    rows.append(parts)
if boost is not None:
    pathlib.Path("/sys/devices/system/cpu/cpufreq/boost").write_text(boost + "\n")
for cpu, key, value in rows:
    if key != "scaling_max_freq":
        continue
    pathlib.Path(f"/sys/devices/system/cpu/{cpu}/cpufreq/{key}").write_text(value + "\n")
for cpu, key, value in rows:
    if key != "scaling_min_freq":
        continue
    pathlib.Path(f"/sys/devices/system/cpu/{cpu}/cpufreq/{key}").write_text(value + "\n")
for cpu, key, value in rows:
    if key in ("scaling_min_freq", "scaling_max_freq"):
        continue
    pathlib.Path(f"/sys/devices/system/cpu/{cpu}/cpufreq/{key}").write_text(value + "\n")
PY
restore_freq() {
  if [ "$restored" -eq 1 ]; then
    return 0
  fi
  restored=1
  printf '%s\n' "$SUDO_PW" | sudo -S -p '' python3 "$RUN/freq-before/restore_freq.py" "$RUN/freq-before/snapshot.txt"
}

trap restore_freq EXIT
snapshot_freq > "$RUN/freq-before/snapshot.txt"
echo "snapshot_lines=$(wc -l < "$RUN/freq-before/snapshot.txt")"

cat > logs/stage-d-protocol.txt << EOF
stage=D
declared_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
purpose=same-seed decapsulation comparison after a frequency request, then the linked 982c762 tree
seed=31337
samples_per_category=10000
categories=valid,bit-flipped,random,message-zero,message-ones
primary_pair=message-zero minus message-ones
affinity=taskset -c 2
binaries=historical-clangover/measure and historical-fixed-982c762/measure
fix=full liboqs commit 982c762 applied to a 0.10.0 copy and relinked
pinned_vendor=unmodified
avx2=forced off in both builds; OQS_DIST_BUILD=OFF alone is not sufficient
frequency_request=global boost 0; cpu2 governor performance; cpu2 epp performance; cpu2 scaling_min=scaling_max=4300000 kHz
lock_accept=20 samples of cpu2 scaling_cur_freq over about 1 s, all within 2 percent of the requested kHz; otherwise one retarget to the median of those samples and accept only if the new 20 samples span at most 50000 kHz
if_lock_rejected=restore and do not collect
interval=normal approximation, z=1.96, sample variance with divisor n-1, declared before the run
buried=vulnerable primary interval includes 0
if_buried=time poly_frommsg alone, 2000 batches of 1000 calls, messages 32 zero bytes and 32 0xff bytes, same taskset, same lock window, reported separately from decapsulation
statistical_test=not Holm
threshold_for_significance=not chosen beyond the predeclared interval
key_recovery=not_attempted
EOF

cat > "$RUN/freq-before/apply_lock.py" << PY
import pathlib
boost = pathlib.Path("$BOOST")
cpu = pathlib.Path("$CPU")
boost.write_text("0\\n")
(cpu / "scaling_governor").write_text("performance\\n")
(cpu / "energy_performance_preference").write_text("performance\\n")
(cpu / "scaling_max_freq").write_text("$TARGET_KHZ\\n")
(cpu / "scaling_min_freq").write_text("$TARGET_KHZ\\n")
PY
printf '%s\n' "$SUDO_PW" | sudo -S -p '' python3 "$RUN/freq-before/apply_lock.py"

requested=$TARGET_KHZ
sample_cur() {
  local i
  : > "$1"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    cat "$CPU/scaling_cur_freq" >> "$1"
    sleep 0.05
  done
}

sample_cur "$RUN/freq-before/probe1.txt"
python3 - << PY > "$RUN/freq-before/probe1-summary.txt"
import pathlib, statistics
vals = [int(x) for x in pathlib.Path("$RUN/freq-before/probe1.txt").read_text().split()]
target = $TARGET_KHZ
lo, hi = target * 0.98, target * 1.02
ok = all(lo <= v <= hi for v in vals)
print(f"n={len(vals)} min={min(vals)} max={max(vals)} median={statistics.median(vals):.0f} within_2pct={ok}")
print(f"median_khz={statistics.median(vals):.0f}")
PY
cat "$RUN/freq-before/probe1-summary.txt"
within=$(awk -F= '/within_2pct/ {print $NF}' "$RUN/freq-before/probe1-summary.txt")
if [ "$within" != "True" ]; then
  median_khz=$(awk -F= '/^median_khz/ {printf "%.0f", $2}' "$RUN/freq-before/probe1-summary.txt")
  printf '%s\n' "$median_khz" > "$RUN/freq-before/retarget_khz.txt"
  printf '%s\n' "$SUDO_PW" | sudo -S -p '' python3 -c 'import pathlib,sys; k=pathlib.Path(sys.argv[1]).read_text().strip(); cpu=pathlib.Path(sys.argv[2]); cpu.joinpath("scaling_max_freq").write_text(k+"\n"); cpu.joinpath("scaling_min_freq").write_text(k+"\n")' "$RUN/freq-before/retarget_khz.txt" "$CPU"
  requested=$median_khz
  sample_cur "$RUN/freq-before/probe2.txt"
  python3 - << PY > "$RUN/freq-before/probe2-summary.txt"
import pathlib
vals = [int(x) for x in pathlib.Path("$RUN/freq-before/probe2.txt").read_text().split()]
span = max(vals) - min(vals)
print(f"n={len(vals)} min={min(vals)} max={max(vals)} span={span} accept={span <= 50000}")
PY
  cat "$RUN/freq-before/probe2-summary.txt"
  accept=$(awk -F= '/accept/ {print $NF}' "$RUN/freq-before/probe2-summary.txt")
  if [ "$accept" != "True" ]; then
    echo "lock_rejected=yes" | tee logs/stage-d-status.txt
    echo "requested_khz=$requested" >> logs/stage-d-status.txt
    exit 2
  fi
fi

{
  echo "lock_accepted=yes"
  echo "requested_khz=$requested"
  echo "boost=$(cat "$BOOST")"
  echo "governor=$(cat "$CPU/scaling_governor")"
  echo "epp=$(cat "$CPU/energy_performance_preference")"
  echo "min=$(cat "$CPU/scaling_min_freq")"
  echo "max=$(cat "$CPU/scaling_max_freq")"
} | tee logs/stage-d-lock.txt

run_measure() {
  local name=$1 binary=$2
  rm -f "$RUN/$name/done"
  (
    while [ ! -f "$RUN/$name/done" ]; do
      cat "$CPU/scaling_cur_freq"
      sleep 0.05
    done
  ) > "$RUN/$name/cpu2_cur_freq_khz.txt" &
  local sampler=$!
  set +e
  taskset -c 2 "$binary" "hist010-$name" 31337 10000 \
    "$RUN/$name/samples.csv" "$RUN/$name/meta.txt" \
    > "$RUN/$name/stdout.txt" 2> "$RUN/$name/stderr.txt"
  local status=$?
  set -e
  touch "$RUN/$name/done"
  wait "$sampler" || true
  echo "$name measure_exit=$status"
  return "$status"
}

run_measure vulnerable "$VULN"
run_measure fixed "$FIXED"

python3 - << 'PY' | tee logs/stage-d-decaps.txt
import math, pathlib, statistics
def welch(left, right):
    n1, n2 = len(left), len(right)
    diff = statistics.fmean(left) - statistics.fmean(right)
    se = math.sqrt(statistics.variance(left) / n1 + statistics.variance(right) / n2)
    return diff, se, diff - 1.96 * se, diff + 1.96 * se

def load(path):
    rows = {}
    for line in pathlib.Path(path).read_text().splitlines()[1:]:
        parts = line.split(",")
        rows.setdefault(parts[2], []).append(int(parts[4]))
    return rows

for name in ("vulnerable", "fixed"):
    rows = load(f"runs/locked-31337-10k/{name}/samples.csv")
    print(f"[{name}] rows={sum(len(v) for v in rows.values())}")
    for category in ("valid", "bit-flipped", "random", "message-zero", "message-ones"):
        values = rows[category]
        print(f"{name} {category} n={len(values)} mean={statistics.fmean(values):.3f} median={statistics.median(values):.3f} stdev={statistics.pstdev(values):.3f}")
    diff, se, low, high = welch(rows["message-zero"], rows["message-ones"])
    includes0 = low <= 0 <= high
    print(f"{name} mean_zero_minus_ones_ns={diff:.3f} se={se:.3f} ci95_low={low:.3f} ci95_high={high:.3f} includes0={includes0}")
    freq = [int(x) for x in pathlib.Path(f"runs/locked-31337-10k/{name}/cpu2_cur_freq_khz.txt").read_text().split()]
    if freq:
        print(f"{name} cpu2_cur n={len(freq)} min={min(freq)} max={max(freq)} median={statistics.median(freq):.0f}")
    vuln_includes = includes0 if name == "vulnerable" else None
print("buried=" + ("yes" if open("runs/locked-31337-10k/vulnerable/samples.csv") and True else "no"))
PY

buried=$(awk -F= '/^vulnerable mean_zero_minus_ones/ {print $NF}' logs/stage-d-decaps.txt)
# The includes0 flag is on the vulnerable summary line.
buried=$(python3 - << 'PY'
import pathlib
text = pathlib.Path("logs/stage-d-decaps.txt").read_text().splitlines()
for line in text:
    if line.startswith("vulnerable mean_zero_minus_ones"):
        print("yes" if line.endswith("includes0=True") else "no")
PY
)
echo "decaps_buried=$buried" | tee -a logs/stage-d-decaps.txt

if [ "$buried" = "yes" ]; then
  cat > "$RUN/micro/poly_frommsg_bench.c" << 'EOF'
#define _POSIX_C_SOURCE 200809L
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

typedef struct {
    int16_t coeffs[256];
} poly;

extern void pqcrystals_ml_kem_768_ipd_ref_poly_frommsg(poly *out, const uint8_t message[32]);

static uint64_t monotonic_nanoseconds(void)
{
    struct timespec stamp;
    clock_gettime(CLOCK_MONOTONIC, &stamp);
    return (uint64_t)stamp.tv_sec * 1000000000ull + (uint64_t)stamp.tv_nsec;
}

static int expect_coefficient(const uint8_t message_byte, int16_t coefficient)
{
    int16_t expected = (message_byte & 1u) ? 1665 : 0;
    return coefficient == expected ? 0 : 1;
}

int main(int argc, char **argv)
{
    poly out;
    uint8_t message[32];
    volatile int16_t sink;
    const int batch_calls = 1000;
    const int sample_count = 2000;
    int sample_index;
    int call_index;
    uint64_t start_ns;
    uint64_t end_ns;
    if (argc != 2) {
        return 2;
    }
    memset(message, 0, sizeof(message));
    pqcrystals_ml_kem_768_ipd_ref_poly_frommsg(&out, message);
    if (expect_coefficient(0, out.coeffs[0]) != 0) {
        return 3;
    }
    memset(message, 255, sizeof(message));
    pqcrystals_ml_kem_768_ipd_ref_poly_frommsg(&out, message);
    if (expect_coefficient(255, out.coeffs[0]) != 0) {
        return 4;
    }
    printf("variant,message,sample_index,batch_calls,elapsed_nanoseconds\n");
    for (sample_index = 0; sample_index < sample_count; ++sample_index) {
        memset(message, 0, sizeof(message));
        start_ns = monotonic_nanoseconds();
        for (call_index = 0; call_index < batch_calls; ++call_index) {
            pqcrystals_ml_kem_768_ipd_ref_poly_frommsg(&out, message);
            sink = out.coeffs[0];
        }
        end_ns = monotonic_nanoseconds();
        printf("%s,message-zero,%d,%d,%llu\n", argv[1], sample_index, batch_calls,
            (unsigned long long)(end_ns - start_ns));
        memset(message, 255, sizeof(message));
        start_ns = monotonic_nanoseconds();
        for (call_index = 0; call_index < batch_calls; ++call_index) {
            pqcrystals_ml_kem_768_ipd_ref_poly_frommsg(&out, message);
            sink = out.coeffs[0];
        }
        end_ns = monotonic_nanoseconds();
        printf("%s,message-ones,%d,%d,%llu\n", argv[1], sample_index, batch_calls,
            (unsigned long long)(end_ns - start_ns));
        (void)sink;
    }
    return 0;
}
EOF
  clang -O2 -o "$RUN/micro/bench-vulnerable" "$RUN/micro/poly_frommsg_bench.c" "$VULN_LIB" -pthread
  clang -O2 -o "$RUN/micro/bench-fixed" "$RUN/micro/poly_frommsg_bench.c" "$FIXED_LIB" -pthread
  taskset -c 2 "$RUN/micro/bench-vulnerable" vulnerable > "$RUN/micro/vulnerable.csv"
  taskset -c 2 "$RUN/micro/bench-fixed" fixed > "$RUN/micro/fixed.csv"
  python3 - << 'PY' | tee logs/stage-d-micro.txt
import math, pathlib, statistics
def welch(left, right):
    diff = statistics.fmean(left) - statistics.fmean(right)
    se = math.sqrt(statistics.variance(left) / len(left) + statistics.variance(right) / len(right))
    return diff, se, diff - 1.96 * se, diff + 1.96 * se
for name in ("vulnerable", "fixed"):
    rows = {}
    for line in pathlib.Path(f"runs/locked-31337-10k/micro/{name}.csv").read_text().splitlines()[1:]:
        parts = line.split(",")
        rows.setdefault(parts[1], []).append(int(parts[4]))
    diff, se, low, high = welch(rows["message-zero"], rows["message-ones"])
    print(f"{name} batches={len(rows['message-zero'])} batch_calls=1000")
    print(f"{name} mean_batch_zero_ns={statistics.fmean(rows['message-zero']):.3f}")
    print(f"{name} mean_batch_ones_ns={statistics.fmean(rows['message-ones']):.3f}")
    print(f"{name} mean_zero_minus_ones_ns={diff:.3f} se={se:.3f} ci95_low={low:.3f} ci95_high={high:.3f} includes0={low <= 0 <= high}")
    print(f"{name} mean_per_call_zero_minus_ones_ns={diff / 1000:.6f}")
PY
else
  echo "microbenchmark=not_run" | tee logs/stage-d-micro.txt
fi

restore_freq
snapshot_freq > "$RUN/freq-before/snapshot-after.txt"
python3 - << 'PY' | tee -a logs/stage-d-status.txt
import pathlib
before = pathlib.Path("runs/locked-31337-10k/freq-before/snapshot.txt").read_text().splitlines()
after = pathlib.Path("runs/locked-31337-10k/freq-before/snapshot-after.txt").read_text().splitlines()
print("restore_match=" + ("yes" if before == after else "no"))
if before != after:
    b, a = set(before), set(after)
    for line in sorted(b - a)[:20]:
        print("missing_after", line)
    for line in sorted(a - b)[:20]:
        print("extra_after", line)
PY
unset SUDO_PW
echo "finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a logs/stage-d-status.txt
