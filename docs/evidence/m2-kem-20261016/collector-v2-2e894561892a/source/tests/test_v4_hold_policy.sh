#!/bin/sh
# 核对 20261014 频率保持规则：阈值和频带不变，默认窗口子命令仍是 run。
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: test_v4_hold_policy.sh WINDOW ANALYZE SOURCE_ROOT" >&2
    exit 1
fi

window=$1
analyze=$2
source_root=$3
protocol="$source_root/docs/research/v4-protocol-20261014/PROTOCOL.md"
old_protocol="$source_root/docs/research/v4-protocol-20261013/PROTOCOL.md"
probe="$source_root/docs/research/v4-protocol-20261014/remote-probe.sh"

if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi

root="${A113_TEST_TMPDIR}/v4-hold-policy"
rm -rf "$root"
mkdir -p "$root"

"$window" --hold-policy-self-check
"$analyze" order >"$root/order.txt"
"$analyze" order-held >"$root/order-held.txt"

cmp -s "$root/order-held.txt" - <<'EOF'
round=1
order=branch_then_mask
seed=20261017001
round=2
order=branch_then_mask
seed=20261017002
round=3
order=branch_then_mask
seed=20261017003
round=4
order=branch_then_mask
seed=20261017004
round=5
order=mask_then_branch
seed=20261017005
EOF

grep -F -x -q 'round=1' "$root/order.txt"
grep -F -x -q 'order=mask_then_branch' "$root/order.txt"
grep -F -x -q 'seed=20261015001' "$root/order.txt"
if grep -F -q '20261017001' "$root/order.txt"; then
    echo "old order printed a hold seed" >&2
    exit 1
fi

for line in \
    'rule_id=`v4_frequency_hold_20261014`' \
    '4257000..4343000' \
    '覆盖率阈值仍是 `0.99`' \
    'scaling_governor` 写成 `performance`' \
    'energy_performance_preference` 写成 `performance`' \
    '把 boost 写成 `0`' \
    '前 8 次每次 40 ms' \
    '后 4 次每次 2000 ms' \
    '20261016000+s' \
    '2026101707' \
    '20261017000+r' \
    '不修改 `docs/research/v4-protocol-20261013/PROTOCOL.md`'; do
    if ! grep -F -q -- "$line" "$protocol"; then
        echo "missing protocol line: $line" >&2
        exit 1
    fi
done

if ! grep -F -q '不改 governor、boost、EPP' "$old_protocol"; then
    echo "20261013 protocol no longer keeps the min/max-only rule" >&2
    exit 1
fi

if ! grep -F -q 'for duration_ms in 40 40 40 40 40 40 40 40 2000 2000 2000 2000; do' "$probe"; then
    echo "probe durations drifted" >&2
    exit 1
fi
if ! grep -F -q '"$window" run-held' "$probe"; then
    echo "probe does not call run-held" >&2
    exit 1
fi
if grep -F -q '2026101400' "$probe"; then
    echo "probe names an old confirmation seed" >&2
    exit 1
fi
