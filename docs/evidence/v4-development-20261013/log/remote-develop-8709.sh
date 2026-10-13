#!/bin/bash
# 开发采集不写频率。失败会话保留，不换种子重抽。
set -u
run=/home/nss-marker/yhr/Cry/v4-development-8709dfe
exec > "$run/log/develop-wrapper.txt" 2>&1
set -x
echo DEVELOP_START
export LC_ALL=C
export TMPDIR="$run/tmp"
export TMP="$run/tmp"
export TEMP="$run/tmp"
real_run=$(readlink -f "$run")
if [ "$real_run" != "$run" ]; then
    echo "PATH_ESCAPE $real_run"
    exit 1
fi
collector="$run/source/build/cmake/encoder_branch/v4_collect"
analyzer="$run/source/build/cmake/v4_analyze"
test -x "$collector"
test -x "$analyzer"
command -v taskset >/dev/null || exit 1
date -u +develop_start=%Y-%m-%dT%H:%M:%SZ > "$run/log/develop-time.txt"
{
    echo "frequency_writes=none"
    echo "affinity_request=cpu2"
    echo "governor_policy_boost_epp=not_modified"
    for name in scaling_governor scaling_min_freq scaling_max_freq scaling_cur_freq; do
        path="/sys/devices/system/cpu/cpu2/cpufreq/$name"
        if [ -r "$path" ]; then
            printf 'cpu2_%s=' "$name"
            cat "$path"
        else
            echo "cpu2_${name}=unreadable"
        fi
    done
} > "$run/log/frequency-observed-before.txt"
independent_sha=$(sha256sum "$collector" | awk '{print $1}')
recorded_sha=$(awk '{print $1}' "$run/log/binary-sha256.txt" | head -1)
if [ "$independent_sha" != "$recorded_sha" ]; then
    echo "BINARY_SHA_MISMATCH $independent_sha $recorded_sha"
    exit 1
fi
mkdir -p "$run/sessions"
: > "$run/sessions/manifest.txt"
: > "$run/log/session-exits.txt"
deadline=$((SECONDS + 90 * 60))
for session_index in 1 2 3 4 5 6 7 8; do
    if [ "$SECONDS" -ge "$deadline" ]; then
        echo "stopped_wall_clock session_index=$session_index" | tee -a "$run/log/session-exits.txt"
        break
    fi
    session_id=$(printf 's%02d' "$session_index")
    session_seed=$((20261013000 + session_index))
    session_dir="$run/sessions/$session_id"
    mkdir -p "$session_dir"
    set +e
    taskset -c 2 "$collector" dev-8709dfe "$session_id" "$session_seed" 2 \
        "$session_dir/calls.csv" "$session_dir/meta.txt" "$session_dir/empty.csv"
    session_status=$?
    set -e
    printf '%s\n' "$independent_sha" > "$session_dir/binary.sha256"
    echo "$session_id seed=$session_seed exit=$session_status" >> "$run/log/session-exits.txt"
    echo "$session_dir" >> "$run/sessions/manifest.txt"
done
{
    echo "frequency_writes=none"
    for name in scaling_governor scaling_min_freq scaling_max_freq scaling_cur_freq; do
        path="/sys/devices/system/cpu/cpu2/cpufreq/$name"
        if [ -r "$path" ]; then
            printf 'cpu2_%s=' "$name"
            cat "$path"
        else
            echo "cpu2_${name}=unreadable"
        fi
    done
} > "$run/log/frequency-observed-after.txt"
# 当前频率会自己变化。只核对本次没有写过的 governor 与 min/max。
before_policy=$(grep -E 'cpu2_scaling_(governor|min_freq|max_freq)=' "$run/log/frequency-observed-before.txt")
after_policy=$(grep -E 'cpu2_scaling_(governor|min_freq|max_freq)=' "$run/log/frequency-observed-after.txt")
if [ "$before_policy" = "$after_policy" ]; then
    echo "governor_min_max_unchanged=yes" >> "$run/log/frequency-observed-after.txt"
else
    echo "governor_min_max_unchanged=no" >> "$run/log/frequency-observed-after.txt"
fi
mkdir -p "$run/analysis/power-run1" "$run/analysis/power-run2"
set +e
"$analyzer" reduce-effects "$run/sessions/manifest.txt" "$run/analysis/effects.csv" development \
    > "$run/analysis/reduce-stdout.txt"
reduce_status=$?
set -e
echo "reduce_exit=$reduce_status" >> "$run/log/session-exits.txt"
if [ "$reduce_status" -ne 0 ]; then
    date -u +develop_end=%Y-%m-%dT%H:%M:%SZ >> "$run/log/develop-time.txt"
    echo DEVELOP_REDUCE_STOP
    exit 0
fi
"$analyzer" power "$run/analysis/effects.csv" "$run/analysis/power-run1" development \
    > "$run/analysis/power-run1/stdout.txt"
"$analyzer" power "$run/analysis/effects.csv" "$run/analysis/power-run2" development \
    > "$run/analysis/power-run2/stdout.txt"
cmp "$run/analysis/power-run1/conclusion.txt" "$run/analysis/power-run2/conclusion.txt"
cmp "$run/analysis/power-run1/stdout.txt" "$run/analysis/power-run2/stdout.txt"
date -u +develop_end=%Y-%m-%dT%H:%M:%SZ >> "$run/log/develop-time.txt"
echo DEVELOP_OK
