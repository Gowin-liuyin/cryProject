#!/bin/sh
# 驱动已入库的开发功效表和确认会话，核对冻结规则实际打出的令牌。
# macOS 的 libm 末位可以和 nss-m 档案不同，所以这里不把远端功效用十进制逐位钉死。
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: test_v4_sealed_decision.sh BINARY SOURCE_ROOT" >&2
    exit 1
fi

binary=$1
source_root=$2

if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi

root="${A113_TEST_TMPDIR}/v4-sealed-decision"
effects="$source_root/docs/evidence/v4-development-20261013/analysis/effects.csv"
session="$source_root/docs/evidence/v4-confirmation-20261013/sessions/s01"
archived="$source_root/docs/evidence/v4-confirmation-20261013/analysis/confirm-run1/conclusion.txt"
rm -rf "$root"
mkdir -p "$root/power1" "$root/power2" "$root/confirm1" "$root/confirm2"
printf '%s\n' "$session" >"$root/manifest.txt"

expect_line() {
    file=$1
    line=$2
    if ! grep -F -x -q -- "$line" "$file"; then
        echo "missing line: $line" >&2
        echo "in $file" >&2
        exit 1
    fi
}

"$binary" power "$effects" "$root/power1" development >"$root/power1/stdout.txt"
"$binary" power "$effects" "$root/power2" development >"$root/power2/stdout.txt"
cmp -s "$root/power1/stdout.txt" "$root/power1/conclusion.txt"
cmp -s "$root/power1/stdout.txt" "$root/power2/stdout.txt"
expect_line "$root/power1/conclusion.txt" "rule_id=v4_group_confirmation_20261013"
expect_line "$root/power1/conclusion.txt" "mode=power"
expect_line "$root/power1/conclusion.txt" "status=exported"
expect_line "$root/power1/conclusion.txt" "alpha_family=0.01"
expect_line "$root/power1/conclusion.txt" "power_target=0.9"
expect_line "$root/power1/conclusion.txt" "repeat_count=2"
expect_line "$root/power1/conclusion.txt" "session_count=40"
awk -F= '
    $1 == "power_at_exported" { exported = $2 }
    $1 == "power_at_previous" { previous = $2 }
    END {
        if (exported + 0 < 0.9) {
            exit 1
        }
        if (previous + 0 >= 0.9) {
            exit 1
        }
    }
' "$root/power1/conclusion.txt"

# 封存确认只有 s01，覆盖率是 0。会话数检查先停，主令牌必须保持 not_run。
"$binary" confirm-sessions "$root/manifest.txt" "$root/confirm1" confirmation \
    >"$root/confirm1/stdout.txt"
"$binary" confirm-sessions "$root/manifest.txt" "$root/confirm2" confirmation \
    >"$root/confirm2/stdout.txt"
cmp -s "$root/confirm1/stdout.txt" "$root/confirm1/conclusion.txt"
cmp -s "$root/confirm1/stdout.txt" "$root/confirm2/stdout.txt"
cmp -s "$root/confirm1/conclusion.txt" "$archived"
expect_line "$root/confirm1/conclusion.txt" "rule_id=v4_group_confirmation_20261013"
expect_line "$root/confirm1/conclusion.txt" "status=stopped_session_count"
expect_line "$root/confirm1/conclusion.txt" "primary_token=not_run"
expect_line "$root/confirm1/conclusion.txt" "session_count=1"
expect_line "$root/confirm1/conclusion.txt" "holm_rejected=no"
expect_line "$root/confirm1/conclusion.txt" "direction_consistent=no"
expect_line "$root/confirm1/conclusion.txt" "unadjusted_mean_counts=na"
