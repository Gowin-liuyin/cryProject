#!/usr/bin/env bash
# T07 环境总表采集脚本（远端只读）。
# 用法：bash docs/evidence/r02-env-20261016/collect_env.sh > docs/evidence/r02-env-20261016/raw/remote-env.txt 2>&1
# 约束：全部命令只读；不写远端任何文件；不 sudo；不装包；不 pin CPU2/CPU6。
set -u

SSH_TARGET="nss-marker@10.144.144.5"
SSH_OPTS=(-o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock -o ConnectTimeout=15 -o BatchMode=yes)

run_remote() {
  printf '\n===== CMD: %s\n' "$1"
  printf -- '----- OUTPUT BEGIN\n'
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$1" 2>&1
  printf -- '----- OUTPUT END (exit=%s)\n' "$?"
}

printf '===== LOCAL: date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ (本机时间戳)\n'
date -u +%Y-%m-%dT%H:%M:%SZ

run_remote 'hostname; echo "---"; uname -a'
run_remote 'cat /etc/os-release'
run_remote 'cat /proc/cmdline'
run_remote 'nproc; echo "---"; getconf _NPROCESSORS_ONLN; echo "---"; free -k; echo "---"; head -3 /proc/meminfo'
run_remote 'lscpu'
run_remote 'cat /sys/devices/system/cpu/smt/active; echo "---"; cat /sys/devices/system/cpu/smt/control'
run_remote 'for t in clang clang-18 gcc g++ cmake ninja valgrind binsec z3 python3 openssl taskset; do p=$(command -v "$t" 2>/dev/null || true); if [ -n "$p" ]; then printf "%s\t%s\n" "$t" "$p"; else printf "%s\tNOT-INSTALLED\n" "$t"; fi; done'
run_remote 'clang --version; echo "---"; clang-18 --version; echo "---"; gcc --version | head -1; echo "---"; cmake --version | head -1; echo "---"; ninja --version'
run_remote 'valgrind --version 2>&1 | head -2; echo "---"; binsec -version 2>&1 | head -5; echo "---"; z3 --version 2>&1 | head -2'
run_remote 'cat /sys/devices/system/cpu/cpufreq/boost 2>&1; echo "--- amd_pstate"; cat /sys/devices/system/cpu/amd_pstate/status 2>&1; echo "--- policy2"; for f in scaling_driver scaling_governor scaling_min_freq scaling_max_freq scaling_cur_freq energy_performance_preference; do printf "%s=%s\n" "$f" "$(cat /sys/devices/system/cpu/cpufreq/policy2/$f 2>&1)"; done; echo "--- policy6"; for f in scaling_driver scaling_governor scaling_min_freq scaling_max_freq scaling_cur_freq energy_performance_preference; do printf "%s=%s\n" "$f" "$(cat /sys/devices/system/cpu/cpufreq/policy6/$f 2>&1)"; done'
run_remote 'head -40 /proc/interrupts; echo "--- grep cpu2/6 columns already in header above"; echo "--- irqbalance"; systemctl is-active irqbalance 2>&1; echo "--- default_smp_affinity"; cat /proc/irq/default_smp_affinity 2>&1'
run_remote 'systemctl list-units --type=service --state=running --no-pager --no-legend 2>&1 | head -60; echo "--- unit count"; systemctl list-units --type=service --state=running --no-pager --no-legend 2>&1 | wc -l'
run_remote 'cat /sys/devices/system/clocksource/clocksource0/current_clocksource 2>&1; echo "--- available"; cat /sys/devices/system/clocksource/clocksource0/available_clocksource 2>&1; echo "--- uptime"; cat /proc/uptime; echo "--- boot_id"; cat /proc/sys/kernel/random/boot_id'
run_remote 'nvidia-smi -L 2>&1 | head -3; echo "--- lspci net"; lspci 2>/dev/null | grep -i -E "ethernet|network" | head -5'
