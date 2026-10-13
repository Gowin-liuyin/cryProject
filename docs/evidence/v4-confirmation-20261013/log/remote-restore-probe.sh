#!/bin/bash
# 读回写回的瞬间差异。结束时必须回到进入时的 min/max。
set -u
run=/home/nss-marker/yhr/Cry/v4-confirmation-8709dfe
probe=$run/log/restore-probe.txt
exec > "$probe" 2>&1
restore_one() {
    local cpu="$1"
    local min_path="/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq"
    local max_path="/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq"
    printf '%s\n' "$2" > "$min_path"
    printf '%s\n' "$3" > "$max_path"
}
echo PROBE_START
for cpu in 2 18; do
    min_path="/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq"
    max_path="/sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq"
    orig_min=$(tr -d '\n' < "$min_path")
    orig_max=$(tr -d '\n' < "$max_path")
    echo "cpu=$cpu orig_min=$(printf %q "$orig_min") orig_max=$(printf %q "$orig_max")"
    printf '4300000\n' > "$min_path" || echo "write_min_failed cpu=$cpu"
    printf '4300000\n' > "$max_path" || echo "write_max_failed cpu=$cpu"
    sleep 2
    printf '%s\n' "$orig_min" > "$min_path" || echo "restore_min_failed cpu=$cpu"
    printf '%s\n' "$orig_max" > "$max_path" || echo "restore_max_failed cpu=$cpu"
    now_min=$(tr -d '\n' < "$min_path")
    now_max=$(tr -d '\n' < "$max_path")
    echo "cpu=$cpu immediate_min=$(printf %q "$now_min") immediate_max=$(printf %q "$now_max")"
    if [ "$now_min" != "$orig_min" ] || [ "$now_max" != "$orig_max" ]; then
        echo "cpu=$cpu immediate_match=no"
    else
        echo "cpu=$cpu immediate_match=yes"
    fi
    sleep 0.05
    later_min=$(tr -d '\n' < "$min_path")
    later_max=$(tr -d '\n' < "$max_path")
    echo "cpu=$cpu later_min=$(printf %q "$later_min") later_max=$(printf %q "$later_max")"
    # 无论中间读到什么，再写一次原值。
    restore_one "$cpu" "$orig_min" "$orig_max"
done
echo PROBE_END
