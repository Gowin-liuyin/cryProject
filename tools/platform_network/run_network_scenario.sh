#!/bin/sh
# T25 同机网络场景三档采集（匿名 netns + 自有 veth + netem 抖动）。
#
# 用法：run_network_scenario.sh <BUILD_DIR> <OUT_DIR> <SEED> <REQUEST_COUNT> <PORT>
#   BUILD_DIR       含 network_client / network_server 的目录
#   OUT_DIR         本次运行的输出目录（必须新建）
#   SEED            公开测试种子
#   REQUEST_COUNT   请求数（取 5 的整数倍，保证五类输入等量）
#   PORT            服务端端口
#
# 约束（与 PLAN.md 一致）：
#   * 只在本机自有测试端点之间通信，不涉及第三方服务。
#   * 抖动用内核 netem，位于密码计算窗口之外；不在算法里加 sleep 或随机延迟。
#   * 用 unshare --net 建匿名进程网络命名空间，不在 /run/netns 建项目具名句柄。
#   * 不写 /tmp：临时文件、缓存、日志都在 OUT_DIR 之下。
#   * 不写任何 cpufreq 节点（不锁频、不改频率）。
#   * 绑核用 taskset -c 0,1,3，不占用 CPU2/CPU6。
#   * 退出时删除 veth、回收命名空间进程、清理 qdisc。
set -eu

if [ "$#" -ne 5 ]; then
    printf 'usage: %s BUILD_DIR OUT_DIR SEED REQUEST_COUNT PORT\n' "$0" >&2
    exit 2
fi

build_dir=$(realpath "$1")
out_dir=$2
test_seed=$3
request_count=$4
port=$5

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

client_program="${build_dir}/network_client"
server_program="${build_dir}/network_server"
# 本地直调工具：measure（完整解封装、不走 socket，五类输入）。
# 参考臂的 CMake 产物在 <build>/reference/benchmark，但那个变体只覆盖 3 类输入；
# 采集脚本用独立编译的 measure（与 M1 两臂同口径）。
# 参考臂的 arm 根比 M1 两臂多一层 cmake/，故两处都找。
measure_program=""
for candidate in "${build_dir}/measure" "${build_dir}/cmake/measure" \
    "${build_dir}/../measure"; do
    if [ -x "${candidate}" ]; then
        measure_program="${candidate}"
        break
    fi
done
for program in "${client_program}" "${server_program}"; do
    if [ ! -x "${program}" ]; then
        printf 'Missing program: %s\n' "${program}" >&2
        exit 1
    fi
done
if [ -z "${measure_program}" ]; then
    printf 'Missing local measure program under %s\n' "${build_dir}" >&2
    exit 1
fi

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

# 网络接口名取任务专用的短名，避免与宿主既有接口冲突。
host_veth="cry13a"
peer_veth="cry13b"
host_address="10.88.13.1"
peer_address="10.88.13.2"
peer_prefix=30

holder_pid=""
cleanup() {
    if [ -n "${holder_pid}" ]; then
        # 命名空间持有进程是 root 起的，回收也要 root。
        sudo_run kill "${holder_pid}" >/dev/null 2>&1 || true
        wait "${holder_pid}" >/dev/null 2>&1 || true
    fi
    sudo_run tc qdisc del dev "${host_veth}" root >/dev/null 2>&1 || true
    sudo_run ip link del "${host_veth}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

ip link del "${host_veth}" >/dev/null 2>&1 || true
sudo_run ip link add "${host_veth}" type veth peer name "${peer_veth}"
sudo_run ip addr add "${host_address}/${peer_prefix}" dev "${host_veth}"
sudo_run ip link set "${host_veth}" up

# 匿名进程网络命名空间：先在命名空间内起一个占位进程持有 veth 对端，
# 再把 peer 移进去。不使用 ip netns add，不在 /run/netns 建句柄。
# unshare --net 需要 root（本机禁止非特权用户命名空间），因此经 sudo_run 起。
holder_marker="${out_dir}/tmp/net-holder.pid"
sudo_run unshare --net sh -c "echo \$\$ > '${holder_marker}'; exec sleep 600" >/dev/null 2>&1 &
holder_pid=$!
waited=0
while [ ! -s "${holder_marker}" ] && [ "${waited}" -lt 40 ]; do
    sleep 0.25
    waited=$((waited + 1))
done
if [ ! -s "${holder_marker}" ]; then
    printf 'Anonymous network namespace did not start.\n' >&2
    exit 1
fi
holder_pid=$(cat "${holder_marker}")
sudo_run ip link set "${peer_veth}" netns "${holder_pid}"
sudo_run nsenter -t "${holder_pid}" --net ip link set lo up
sudo_run nsenter -t "${holder_pid}" --net ip addr add "${peer_address}/${peer_prefix}" dev "${peer_veth}"
sudo_run nsenter -t "${holder_pid}" --net ip link set "${peer_veth}" up

run_scenario() {
    scenario_name=$1
    delay=$2
    jitter=$3

    if [ "${delay}" != "none" ]; then
        sudo_run tc qdisc replace dev "${host_veth}" root netem delay "${delay}" "${jitter}"
    else
        sudo_run tc qdisc del dev "${host_veth}" root >/dev/null 2>&1 || true
    fi

    sudo_run nsenter -t "${holder_pid}" --net \
        taskset -c 0,1,3 "${server_program}" --bind "${peer_address}" --port "${port}" \
        --seed "${test_seed}" --request-count "${request_count}" \
        > "${out_dir}/${scenario_name}-server.txt" 2>&1 &
    server_pid=$!
    sleep 0.5

    taskset -c 0,1,3 "${client_program}" --connect "${peer_address}" --port "${port}" \
        --seed "${test_seed}" --request-count "${request_count}" \
        --rtt-path "${out_dir}/${scenario_name}-rtt.csv" \
        > "${out_dir}/${scenario_name}-client.txt" 2>&1
    client_status=$?

    wait "${server_pid}" || true
    server_status=$?

    printf 'scenario=%s delay=%s jitter=%s client_exit=%d server_exit=%d\n' \
        "${scenario_name}" "${delay}" "${jitter}" "${client_status}" "${server_status}" \
        >> "${out_dir}/scenarios.txt"
}

# 本地直调基线：完全不走 socket，直接在同一进程里做完整解封装。
# 这一档给出「本地差异的可分辨下界」——网络各档的结论都以它为参照。
# measure 自身按 sample_index % 5 轮转五类输入，**一次运行即产出全部五类**，
# 分组以 CSV 的 input_category 列为准（复算脚本按列分组）。
run_local_direct() {
    scenario_name=direct
    if [ ! -x "${measure_program}" ]; then
        printf 'Missing local measure program: %s\n' "${measure_program}" >&2
        return 1
    fi
    # 每类样本数取 request_count，使五类各 80 个样本，与网络端的每类样本数对齐。
    taskset -c 0,1,3 "${measure_program}" "${scenario_name}" \
        "${test_seed}" "${request_count}" \
        "${out_dir}/${scenario_name}.csv" \
        "${out_dir}/${scenario_name}.meta" \
        > "${out_dir}/${scenario_name}.stdout" 2>&1
    measure_status=$?
    printf 'scenario=%s mode=local_direct measure_exit=%d\n' "${scenario_name}" "${measure_status}" \
        >> "${out_dir}/scenarios.txt"
}

: > "${out_dir}/scenarios.txt"
run_local_direct
run_scenario loopback none none
run_scenario low 100us 20us
run_scenario mid 1ms 200us
run_scenario high 10ms 2ms

printf 'NETWORK_SCENARIOS_DONE\n'
