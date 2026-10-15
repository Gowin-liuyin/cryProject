#!/bin/sh
set -eu

stats_program=$1
repository_root=$2
dudect_replay_program=$3
: "${A113_TEST_TMPDIR:?CTest must supply an in-build temporary directory}"
mkdir -p "$A113_TEST_TMPDIR"
work_directory=$(mktemp -d "$A113_TEST_TMPDIR/platform-stats.XXXXXXXX")
trap 'rm -rf -- "$work_directory"' EXIT HUP INT TERM
battery="$repository_root/scripts/run_stats_battery.sh"
fixtures="$repository_root/tests/fixtures/platform_stats"

"$battery" --input "$fixtures/shifted.csv" --output-dir "$work_directory/shifted" \
    --stats-bin "$stats_program" --no-external >/dev/null
cmp "$fixtures/shifted.csv" "$work_directory/shifted/input.csv"
# 独立手算：两组 1..5 与 11..15，差 -10、SE=1、t=-10、df=8。
awk '
/"mean_difference_class0_minus_class1_ns"/ {if ($2 != "-10,") exit 1; difference=1}
/"standard_error_ns"/ {if ($2 != "1,") exit 1; standard_error=1}
/"welch_t"/ {if ($2 != "-10,") exit 1; statistic=1}
/"welch_degrees_of_freedom"/ {if ($2 != "8,") exit 1; degrees=1}
END {if (!(difference && standard_error && statistic && degrees)) exit 1}
' "$work_directory/shifted/ci_welch.json"

"$battery" --input "$fixtures/measure.csv" --format measure \
    --output-dir "$work_directory/measure" --stats-bin "$stats_program" --no-external >/dev/null
cmp "$work_directory/shifted/ci_welch.json" "$work_directory/measure/ci_welch.json"
cmp "$work_directory/shifted/normalized.csv" "$work_directory/measure/normalized.csv"

"$battery" --input "$fixtures/equal.csv" --output-dir "$work_directory/equal" \
    --stats-bin "$stats_program" --no-external >/dev/null
awk '/"p_two_sided_normal_approximation"/ {if ($2 != "1,") exit 1; found=1}
END {if (!found) exit 1}' "$work_directory/equal/ci_welch.json"

# 截断、负数、额外列、混合运行、非 ns 与非有限数必须拒绝。
for invalid_kind in truncated negative extra mixed unit nan; do
    case "$invalid_kind" in
        truncated) printf 'class0_ns,class1_ns\n1,2\n3,4' > "$work_directory/invalid.csv" ;;
        negative) printf 'class0_ns,class1_ns\n-1,2\n3,4\n' > "$work_directory/invalid.csv" ;;
        extra) printf 'class0_ns,class1_ns\n1,2,3\n3,4\n' > "$work_directory/invalid.csv" ;;
        mixed) sed '3s/synthetic/other/' "$fixtures/measure.csv" > "$work_directory/invalid.csv" ;;
        unit) sed 's/,ns$/,cycles/' "$fixtures/measure.csv" > "$work_directory/invalid.csv" ;;
        nan) printf 'class0_ns,class1_ns\nNaN,2\n3,4\n' > "$work_directory/invalid.csv" ;;
    esac
    case "$invalid_kind" in
        mixed|unit) invalid_format=measure ;;
        *) invalid_format=wide ;;
    esac
    if "$battery" --input "$work_directory/invalid.csv" --format "$invalid_format" \
        --output-dir "$work_directory/$invalid_kind" --stats-bin "$stats_program" \
        --no-external >/dev/null 2>&1; then
        printf 'Accepted invalid fixture: %s\n' "$invalid_kind" >&2
        exit 1
    fi
done
if "$battery" --input "$fixtures/equal.csv" --output-dir "$work_directory/equal" \
    --stats-bin "$stats_program" --no-external >/dev/null 2>&1; then
    printf '%s\n' 'Overwrote existing result' >&2
    exit 1
fi

printf 'class0_ns,class1_ns\n0,1\n1,2\n' > "$work_directory/zero.csv"
"$battery" --input "$work_directory/zero.csv" --output-dir "$work_directory/zero" \
    --stats-bin "$stats_program" >/dev/null
# 该小样本先受 RTLF 的每类100条下限拦截；零值在主 CI 中仍保留。
awk '/"class0_count"/ {if ($2 != "2,") exit 1; found=1}
END {if (!found) exit 1}' "$work_directory/zero/ci_welch.json"
awk 'BEGIN {print "class0_ns,class1_ns"; for (row=0; row<100; row++) print row "," row+1}' \
    > "$work_directory/zero-large.csv"
"$battery" --input "$work_directory/zero-large.csv" --output-dir "$work_directory/zero-large" \
    --stats-bin "$stats_program" >/dev/null
if ! grep -q 'blocked_upstream_zero_filter' "$work_directory/zero-large/summary.json"; then
    printf '%s\n' 'RTLF would silently filter zero values' >&2
    exit 1
fi

if [ "$dudect_replay_program" != '-' ]; then
    "$dudect_replay_program" "$work_directory/shifted/normalized.csv" > "$work_directory/replay.log"
    if ! grep -q '^battery_dudect_status=insufficient_measurements$' "$work_directory/replay.log"; then
        printf '%s\n' 'Too-small dudect replay was not marked insufficient' >&2
        exit 1
    fi
fi
printf '%s\n' 'platform statistics synthetic and rejection checks passed'
