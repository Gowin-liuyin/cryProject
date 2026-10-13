#!/bin/bash
# 只验证窗口请求和恢复。不跑解封装。
set -u
run=/home/nss-marker/yhr/Cry/v4-confirmation-8709dfe
window="$run/source/build/cmake/v4_window"
mkdir -p "$run/dry-run" "$run/log"
"$window" run "$run/dry-run" -- /usr/bin/taskset -c 2 /bin/bash -c 'end=$((SECONDS+2)); while [ "$SECONDS" -lt "$end" ]; do :; done'
echo "window_exit=$?"
{
    echo "frequency_writes=restored_or_failed"
    for cpu_index in $(seq 0 31); do
        gov=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor
        min=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_min_freq
        max=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_max_freq
        if [ -r "$gov" ] && [ -r "$min" ] && [ -r "$max" ]; then
            printf 'cpu=%s governor=%s min=%s max=%s\n' "$cpu_index" "$(cat "$gov")" "$(cat "$min")" "$(cat "$max")"
        else
            echo "cpu=$cpu_index unreadable"
        fi
    done
} > "$run/log/frequency-machine-after-dry.txt"
if cmp -s <(grep '^cpu=' "$run/log/frequency-machine-before.txt") <(grep '^cpu=' "$run/log/frequency-machine-after-dry.txt"); then
    echo "machine_policy_restored=yes"
else
    echo "machine_policy_restored=no"
    diff -u <(grep '^cpu=' "$run/log/frequency-machine-before.txt") <(grep '^cpu=' "$run/log/frequency-machine-after-dry.txt") || true
fi
echo '---COVERAGE---'
cat "$run/dry-run/coverage.txt" || true
echo '---BASELINE---'
cat "$run/dry-run/frequency-baseline.txt" || true
