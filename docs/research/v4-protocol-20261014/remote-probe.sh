#!/bin/sh
# 频率保持探测。只空转，不解封装，不使用确认种子。
# 用法: remote-probe.sh RUN_ROOT WINDOW_BIN SPIN_BIN
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: remote-probe.sh RUN_ROOT WINDOW_BIN SPIN_BIN" >&2
    exit 2
fi

run=$(CDPATH= cd -- "$1" && pwd -P)
window=$2
spin=$3
cry_root=/home/nss-marker/yhr/Cry

case "$run" in
    "$cry_root"/*) ;;
    *)
        echo "status=outside_cry_root"
        exit 2
        ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "status=not_root"
    exit 2
fi

if [ ! -x "$window" ] || [ ! -x "$spin" ]; then
    echo "status=missing_binary"
    exit 2
fi

if [ -e "$run/probe" ]; then
    echo "status=probe_dir_exists"
    exit 2
fi

mkdir -p "$run/log" "$run/probe"

snapshot() {
    dest=$1
    boost_path=/sys/devices/system/cpu/cpufreq/boost
    cpu_index=0
    : >"$dest"
    printf 'boost=' >>"$dest"
    if [ -r "$boost_path" ]; then
        tr -d '\n' <"$boost_path" >>"$dest"
    else
        printf 'missing' >>"$dest"
    fi
    printf '\n' >>"$dest"
    while [ "$cpu_index" -le 31 ]; do
        cpu_base="/sys/devices/system/cpu/cpu${cpu_index}/cpufreq"
        printf 'cpu=%s\n' "$cpu_index" >>"$dest"
        for field in scaling_governor energy_performance_preference scaling_min_freq \
            scaling_max_freq; do
            printf '%s=' "$field" >>"$dest"
            if [ -r "$cpu_base/$field" ]; then
                tr -d '\n' <"$cpu_base/$field" >>"$dest"
            else
                printf 'missing' >>"$dest"
            fi
            printf '\n' >>"$dest"
        done
        cpu_index=$((cpu_index + 1))
    done
}

{
    echo "rule_id=v4_frequency_hold_20261014"
    date -u +"probe_start=%Y-%m-%dT%H:%M:%SZ"
    hostname
    uname -a
    systemd-detect-virt || true
    sha256sum "$window" "$spin"
} >"$run/log/environment.txt"

snapshot "$run/log/policy-before.txt"
: >"$run/log/probe-exits.txt"
completed=0
stop_reason=none
trial_index=0

# 冻结的 12 次：8 次 40 ms，随后 4 次 2000 ms。
for duration_ms in 40 40 40 40 40 40 40 40 2000 2000 2000 2000; do
    trial_index=$((trial_index + 1))
    trial_dir=$(printf '%s/probe/t%02d' "$run" "$trial_index")
    mkdir -p "$trial_dir"
    window_exit=0
    "$window" run-held "$trial_dir" -- "$spin" "$duration_ms" \
        >"$trial_dir/window-stdout.txt" 2>"$trial_dir/window-stderr.txt" || window_exit=$?
    coverage_text=$(sed -n 's/^coverage_fraction=//p' "$trial_dir/coverage.txt" 2>/dev/null || true)
    printf 'trial=%02d duration_ms=%s window_exit=%s coverage_fraction=%s\n' \
        "$trial_index" "$duration_ms" "$window_exit" "${coverage_text:-missing}" \
        >>"$run/log/probe-exits.txt"
    if [ "$window_exit" -ne 0 ]; then
        stop_reason=window_exit
        break
    fi
    if ! awk -v value="$coverage_text" 'BEGIN {
        if (value == "" || value == "na" || value == "missing") {
            exit 1
        }
        if (value + 0 >= 0.99) {
            exit 0
        }
        exit 1
    }'; then
        stop_reason=coverage
        break
    fi
    completed=$((completed + 1))
done

snapshot "$run/log/policy-after.txt"
if cmp -s "$run/log/policy-before.txt" "$run/log/policy-after.txt"; then
    policy_match=yes
else
    policy_match=no
fi

{
    echo "completed_coverage_pass=$completed"
    echo "stop_reason=$stop_reason"
    echo "policy_match=$policy_match"
    if [ "$completed" -eq 12 ] && [ "$policy_match" = "yes" ]; then
        echo "probe_pass=yes"
    else
        echo "probe_pass=no"
    fi
    date -u +"probe_end=%Y-%m-%dT%H:%M:%SZ"
} >>"$run/log/probe-exits.txt"

if [ "$completed" -eq 12 ] && [ "$policy_match" = "yes" ]; then
    exit 0
fi
exit 1
