#!/bin/sh
# T25 网络场景的恢复合同验证：空任务，不采任何数据。
#
# 验证 PLAN.md 第 4 节的 6 条：
#   1. veth 建/删、netns 退出、qdisc 清理三条路径都能回到进入前状态；
#   2. 进入后没有残留 veth 与 qdisc 规则；
#   3. 命名空间进程全部回收，无孤儿进程；
#   4. 不写 /run/netns 具名句柄；
#   5. 临时文件、缓存、日志全部落在 Cry 之下，不写 /tmp；
#   6. 频率状态未被本任务改动（进入前后 scaling_cur_freq 一致）。
#
# 用法：verify_network_recovery.sh <OUT_DIR>
#   OUT_DIR  本次验证的输出目录（必须新建，且在 Cry 之下）
set -eu

if [ "$#" -ne 1 ]; then
    printf 'usage: %s OUT_DIR\n' "$0" >&2
    exit 2
fi

out_dir=$1
case "${out_dir}" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf 'Require output directory under Cry.\n' >&2; exit 2 ;;
esac
if [ -e "${out_dir}" ] || [ -L "${out_dir}" ]; then
    printf 'Output directory must be new.\n' >&2
    exit 2
fi
mkdir -p "${out_dir}"
out_dir=$(realpath "${out_dir}")
mkdir -p "${out_dir}/tmp" "${out_dir}/cache"
export TMPDIR="${out_dir}/tmp"
export TMP="${TMPDIR}"
export TEMP="${TMPDIR}"
export XDG_CACHE_HOME="${out_dir}/cache"

host_veth="cry13v"
peer_veth="cry13w"
holder_marker="${out_dir}/tmp/holder.pid"

# 建 veth / qdisc / 进入命名空间需要 root；口令文件由调用方准备并在使用后删除，
# 脚本本身不保存口令。
auth_file=${SUDO_AUTH_FILE:-}
sudo_run() {
    if [ -n "${auth_file}" ] && [ -f "${auth_file}" ]; then
        sudo -S -p '' "$@" < "${auth_file}"
    else
        sudo -n "$@"
    fi
}

cpufreq_root=/sys/devices/system/cpu/cpu0/cpufreq

# 频率「策略」快照：这些是静态设置项，本任务不写它们，必须逐字不变。
# scaling_cur_freq 是瞬时反馈读数，未锁频时本来就在波动，**不能**用作「未改动」的判据；
# 它只作为观测记录，不参与断言。
read_cpufreq_policy() {
    for policy_file in scaling_governor scaling_min_freq scaling_max_freq \
        energy_performance_preference; do
        printf '%s=%s\n' "${policy_file}" \
            "$(cat "${cpufreq_root}/${policy_file}" 2>/dev/null || printf 'unavailable')"
    done
    printf 'boost=%s\n' "$(cat "${cpufreq_root}/boost" 2>/dev/null || printf 'unavailable')"
}

before_links=$(sudo_run ip -o link show 2>/dev/null | wc -l)
before_qdisc=$(sudo_run tc qdisc show 2>/dev/null | wc -l)
before_freq=$(cat "${cpufreq_root}/scaling_cur_freq" 2>/dev/null || printf 'unavailable')
before_policy=$(read_cpufreq_policy)
{
    printf 'before_links=%s\nbefore_qdisc=%s\nbefore_cur_freq_khz=%s\n' \
        "${before_links}" "${before_qdisc}" "${before_freq}"
    printf '%s\n' "${before_policy}"
} > "${out_dir}/before.txt"

failures=0
check() {
    label=$1
    shift
    if "$@"; then
        printf 'check pass: %s\n' "${label}" >> "${out_dir}/checks.txt"
    else
        printf 'check FAIL: %s\n' "${label}" >> "${out_dir}/checks.txt"
        failures=$((failures + 1))
    fi
}

holder_pid=""
unshare_pid=""
no_orphan_process() {
    # 用记录的 PID 判定，不用 pgrep -f 模式匹配：后者会匹配到检查命令自身的
    # 命令行（模式串就在命令行里），产生假阴性。
    for candidate in "${holder_pid}" "${unshare_pid}"; do
        [ -n "${candidate}" ] || continue
        if kill -0 "${candidate}" 2>/dev/null; then
            return 1
        fi
    done
    return 0
}

link_absent() {
    ! sudo_run ip link show "${host_veth}" >/dev/null 2>&1
}

netns_handle_absent() {
    if [ -d /run/netns ]; then
        ! ls /run/netns 2>/dev/null | grep -q 'cry13'
    else
        return 0
    fi
}

tmp_clean() {
    ! ls -A "${out_dir}/tmp" 2>/dev/null | grep -qv '^holder.pid$'
}

# —— 路径 1：建 veth + 匿名 netns + qdisc，然后按合同清理 ——
sudo_run ip link del "${host_veth}" >/dev/null 2>&1 || true
sudo_run ip link add "${host_veth}" type veth peer name "${peer_veth}"
sudo_run ip addr add 10.88.13.1/30 dev "${host_veth}"
sudo_run ip link set "${host_veth}" up
sudo_run unshare --net sh -c "echo \$\$ > '${holder_marker}'; exec sleep 600" >/dev/null 2>&1 &
unshare_pid=$!
waited=0
while [ ! -s "${holder_marker}" ] && [ "${waited}" -lt 40 ]; do
    sleep 0.25
    waited=$((waited + 1))
done
holder_pid=$(cat "${holder_marker}" 2>/dev/null || printf '')
if [ -n "${holder_pid}" ]; then
    sudo_run ip link set "${peer_veth}" netns "${holder_pid}"
    sudo_run nsenter -t "${holder_pid}" --net ip link set lo up
    sudo_run nsenter -t "${holder_pid}" --net ip addr add 10.88.13.2/30 dev "${peer_veth}"
    sudo_run nsenter -t "${holder_pid}" --net ip link set "${peer_veth}" up
    sudo_run tc qdisc replace dev "${host_veth}" root netem delay 100us 20us
    printf 'holder_pid=%s\nqdisc_applied=yes\n' "${holder_pid}" > "${out_dir}/during.txt"
fi

# —— 清理（与 run_network_scenario.sh 相同的路径）——
# 命名空间持有进程是 root 起的，回收也要 root。
if [ -n "${holder_pid}" ]; then
    sudo_run kill "${holder_pid}" >/dev/null 2>&1 || true
    wait "${holder_pid}" >/dev/null 2>&1 || true
fi
wait "${unshare_pid}" >/dev/null 2>&1 || true
sudo_run tc qdisc del dev "${host_veth}" root >/dev/null 2>&1 || true
sudo_run ip link del "${host_veth}" >/dev/null 2>&1 || true

after_links=$(sudo_run ip -o link show 2>/dev/null | wc -l)
after_qdisc=$(sudo_run tc qdisc show 2>/dev/null | wc -l)
after_freq=$(cat "${cpufreq_root}/scaling_cur_freq" 2>/dev/null || printf 'unavailable')
after_policy=$(read_cpufreq_policy)
{
    printf 'after_links=%s\nafter_qdisc=%s\nafter_cur_freq_khz=%s\n' \
        "${after_links}" "${after_qdisc}" "${after_freq}"
    printf '%s\n' "${after_policy}"
} > "${out_dir}/after.txt"

check 'veth removed after cleanup' link_absent
check 'no project handle under /run/netns' netns_handle_absent
check 'no orphan namespace process' no_orphan_process
check 'link count restored' test "${after_links}" -eq "${before_links}"
check 'qdisc count restored' test "${after_qdisc}" -eq "${before_qdisc}"
check 'cpufreq policy unchanged (governor/min/max/EPP/boost)' \
    test "${after_policy}" = "${before_policy}"
check 'temporary files stayed under Cry' tmp_clean
# 按本任务自己的根名匹配，不能只匹配接口名——本任务的产物前缀是
# r13-network-20261020，只查 cry13 会漏掉本任务留在 /tmp 的副本。
# 用 find 覆盖隐藏项与二层子目录；ls 不带 -A 看不见以点开头的条目。
check 'no /tmp write by this task (top level and 2 levels deep, hidden included)' \
    sh -c "! find /tmp -maxdepth 2 \( -name '*cry13*' -o -name '*r13-network*' \) -print 2>/dev/null | grep -q ."

printf 'failures=%s\n' "${failures}" > "${out_dir}/summary.txt"
cat "${out_dir}/before.txt" "${out_dir}/after.txt" "${out_dir}/checks.txt" "${out_dir}/summary.txt"
if [ "${failures}" -ne 0 ]; then
    printf 'Network recovery verification FAILED with %s failing check(s).\n' "${failures}" >&2
    exit 1
fi
printf 'Network recovery verification passed.\n'
