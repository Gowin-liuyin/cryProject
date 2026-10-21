#!/usr/bin/env bash
# T25 网络场景采集驱动：在平台锁频控制器下跑本地直调基线 + 三档网络场景。
#
# 用法：run_network_controlled.sh <ARM_BUILD_DIR> <OUT_DIR> <SEED> <DIRECT_PER_CLASS> <NET_PER_CLASS> <PORT> <CPU> <CONTROL_ROOT>
#   ARM_BUILD_DIR  该臂的构建目录（须含 network_client / network_server / measure）
#   OUT_DIR        本次运行的输出目录（必须新建，且在 Cry 之下）
#   SEED           公开测试种子
#   DIRECT_PER_CLASS  本地直调档每类输入的样本数
#   NET_PER_CLASS     网络各档每类输入的样本数；网络端总请求数 = 5 × NET_PER_CLASS
#   PORT           服务端端口
#   CPU            锁频目标 CPU（2 或 6）
#   CONTROL_ROOT   控制器根（新建，名称须为 platform-control-20261016-<12 位小写十六进制>）
#
# 频率口径：与 R02/R08/R09 同一控制器口径（boost=0、governor/EPP=performance、
# min=max=4300000 kHz、taskset 绑核、进入/采中/退出快照与 restore_match 核对）。
# 这样网络各档与「本地直调」基线处在同一频率条件下，可与 R09 的可分辨性结论对照——
# 未锁频的试跑里本地几十纳秒量级效应完全被噪声淹没，不能作为对照基准。
#
# 拓扑：匿名进程网络命名空间 + 自有 veth（10.88.13.1/30 ↔ 10.88.13.2/30）。
# 抖动由内核 netem 挂在 veth **两端**（单向 100 µs/20 µs、1 ms/200 µs、10 ms/2 ms），
# 位于密码计算窗口之外；不在算法里加 sleep 或随机延迟。
#
# 角色分配：
#   服务端 = 控制器 worker（原生 ELF，在 Cry 之内，taskset 绑到锁频 CPU，在匿名 netns 内）
#   客户端 = 宿主网络命名空间内的普通进程，绑核到 0,1,3（不占 CPU2/CPU6）
#
# 约束：口令只经临时文件传入、用完删除；不写 /tmp；不建 /run/netns 具名句柄；
# 拓扑与采集都在 Cry 之下；失败即停并保留原件。
set -eu

if [ "$#" -ne 8 ]; then
    printf 'usage: %s ARM_BUILD_DIR OUT_DIR SEED DIRECT_PER_CLASS NET_PER_CLASS PORT CPU CONTROL_ROOT\n' "$0" >&2
    exit 2
fi

arm_build_dir=$(realpath "$1")
out_dir=$2
test_seed=$3
direct_per_class=$4
net_per_class=$5
port=$6
cpu=$7
control_root=$8

case "${out_dir}" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf 'Require output directory under Cry.\n' >&2; exit 2 ;;
esac
case "${control_root}" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf 'Require control root under Cry.\n' >&2; exit 2 ;;
esac
if [ -e "${out_dir}" ] || [ -L "${out_dir}" ]; then
    printf 'Output directory must be new.\n' >&2
    exit 2
fi
if [ -e "${control_root}" ] || [ -L "${control_root}" ]; then
    printf 'Control root must be new.\n' >&2
    exit 2
fi
mkdir -p "${out_dir}"
out_dir=$(realpath "${out_dir}")
mkdir -p "${out_dir}/tmp" "${out_dir}/cache"

client_program=""
server_program=""
# 参考臂的 CMake 产物在 <arm>/cmake/ 下，M1 两臂直接在 <arm>/ 下；
# 查找顺序与 measure 一致，两处都找。
for candidate in "${arm_build_dir}/network_client" "${arm_build_dir}/cmake/network_client"; do
    if [ -x "${candidate}" ]; then
        client_program="${candidate}"
        break
    fi
done
for candidate in "${arm_build_dir}/network_server" "${arm_build_dir}/cmake/network_server"; do
    if [ -x "${candidate}" ]; then
        server_program="${candidate}"
        break
    fi
done
# 本地直调工具：measure（完整解封装、不走 socket，五类输入）。
# 参考臂的 CMake 产物在 <build>/reference/benchmark，但那个变体只覆盖 3 类输入；
# 采集脚本用独立编译的 measure（与 M1 两臂同口径）。
# 参考臂的 arm 根比 M1 两臂多一层 cmake/ 目录，故两处都找。
measure_program=""
for candidate in "${arm_build_dir}/measure" "${arm_build_dir}/cmake/measure" \
    "${arm_build_dir}/../measure"; do
    if [ -x "${candidate}" ]; then
        measure_program="${candidate}"
        break
    fi
done
if [ -z "${client_program}" ] || [ -z "${server_program}" ] || [ -z "${measure_program}" ]; then
    printf 'Missing program under %s\n' "${arm_build_dir}" >&2
    exit 1
fi

auth_file=${SUDO_AUTH_FILE:-}
sudo_run() {
    if [ -n "${auth_file}" ] && [ -f "${auth_file}" ]; then
        sudo -S -p '' "$@" < "${auth_file}"
    else
        sudo -n "$@"
    fi
}

# 控制器源码与冻结计划放在控制根内；控制器自己核对计划摘要。
controller_source="/home/nss-marker/yhr/Cry/r13-network-20261020/source-3f94f228/tools/platform_control/controller.py"
if [ ! -f "${controller_source}" ]; then
    printf 'Missing controller source: %s\n' "${controller_source}" >&2
    exit 1
fi
mkdir -p "${control_root}"
control_root=$(realpath "${control_root}")
if ! printf '%s' "${control_root##*/}" | grep -Eq '^platform-control-20261016-[0-9a-f]{12}$'; then
    printf 'Control root name must be platform-control-20261016-<12 hex>\n' >&2
    exit 2
fi
cp "${controller_source}" "${control_root}/controller.py"
controller_plan="${control_root}/PLAN.md"
cat > "${controller_plan}" <<'PLAN_EOF'
# T25 网络场景采集计划（冻结）

本计划随控制根一同冻结，控制器在 run 时核对其 SHA-256。

- 目的：在锁频条件下量化本地解封装耗时差异经真实两端网络传输后是否还能被客户端分辨。
- 锁频口径：与 R02/R08/R09 同一控制器口径（boost=0、governor/EPP=performance、
  min=max=4300000 kHz、taskset 绑核、进入/采中/退出快照、restore_match 核对）。
- 拓扑：匿名进程网络命名空间 + 自有 veth（10.88.13.1/30 ↔ 10.88.13.2/30），
  抖动由内核 netem 挂在 veth 两端，位于密码计算窗口之外；不在算法里加 sleep 或随机延迟。
- 档位：direct（本地直调，不走 socket）/ loopback（veth+TCP 无抖动）/ low（单向 100us/20us）/
  mid（单向 1ms/200us）/ high（单向 10ms/2ms）。
- 角色：服务端是控制器 worker（taskset 绑到锁频 CPU，在匿名 netns 内）；客户端在宿主
  网络命名空间内，绑核 0,1,3。
- 输入：客户端按 request_index % 5 轮转五类（valid / bit-flipped / random / message-zero /
  message-ones）；主类对为 message-zero vs message-ones。
- 统计：客户端 RTT 的 Welch + 正态近似 95% CI，族外不做 Holm；超时与丢失单列为删失。
- 结论上限：只写「本预算下未检出」或「可分辨」，不写「没有远程泄露」。
- 不做：不涉及密钥恢复、不做攻击程序、不涉及第三方服务与公网。
PLAN_EOF
plan_digest=$(sha256sum "${controller_plan}" | cut -d ' ' -f 1)

host_veth="cry13a"
peer_veth="cry13b"
host_address="10.88.13.1"
peer_address="10.88.13.2"
peer_prefix=30
network_request_count=$((net_per_class * 5))

# 控制器相邻两次 run 之间的固定冷却：上一次 run 结束时会恢复频率策略，
# CPU 需要时间回到稳定工作点，否则下一次 run 的 20 次频率探针跨度会超过
# 控制器自带的 50000 kHz 上限（第一轮实跑：direct 跨度 0、loopback 19800、
# low 53823 被拒）。冷却是**排程间隔**，不改变控制器的任何判据。
cool_down_seconds=20
# 单档最大尝试次数。只有在控制器**根本没启动 worker**（terminal.json 里没有
# worker_exit_code）时才允许重来；已经采到数的档一律不重跑、不择优。
max_attempts=3

holder_pid=""
cleanup_topology() {
    if [ -n "${holder_pid}" ]; then
        sudo_run kill "${holder_pid}" >/dev/null 2>&1 || true
        wait "${holder_pid}" >/dev/null 2>&1 || true
        holder_pid=""
    fi
    sudo_run tc qdisc del dev "${host_veth}" root >/dev/null 2>&1 || true
    sudo_run ip link del "${host_veth}" >/dev/null 2>&1 || true
}
trap cleanup_topology EXIT INT TERM

# 建拓扑：匿名进程网络命名空间持有 veth 对端。不使用 ip netns add，
# 不在 /run/netns 建项目具名句柄。
setup_topology() {
    local marker="${out_dir}/tmp/holder.pid"
    rm -f "${marker}"
    sudo_run unshare --net sh -c "echo \$\$ > '${marker}'; exec sleep 3600" >/dev/null 2>&1 &
    local waited=0
    while [ ! -s "${marker}" ] && [ "${waited}" -lt 60 ]; do
        sleep 0.25
        waited=$((waited + 1))
    done
    if [ ! -s "${marker}" ]; then
        printf 'Anonymous network namespace did not start.\n' >&2
        return 1
    fi
    holder_pid=$(cat "${marker}")
    sudo_run ip link del "${host_veth}" >/dev/null 2>&1 || true
    sudo_run ip link add "${host_veth}" type veth peer name "${peer_veth}"
    sudo_run ip addr add "${host_address}/${peer_prefix}" dev "${host_veth}"
    sudo_run ip link set "${host_veth}" up
    sudo_run ip link set "${peer_veth}" netns "${holder_pid}"
    sudo_run nsenter -t "${holder_pid}" --net ip link set lo up
    sudo_run nsenter -t "${holder_pid}" --net ip addr add "${peer_address}/${peer_prefix}" dev "${peer_veth}"
    sudo_run nsenter -t "${holder_pid}" --net ip link set "${peer_veth}" up
}

apply_netem() {
    local delay=$1
    local jitter=$2
    if [ "${delay}" = "none" ]; then
        sudo_run tc qdisc del dev "${host_veth}" root >/dev/null 2>&1 || true
        sudo_run nsenter -t "${holder_pid}" --net \
            tc qdisc del dev "${peer_veth}" root >/dev/null 2>&1 || true
    else
        sudo_run tc qdisc replace dev "${host_veth}" root netem delay "${delay}" "${jitter}"
        sudo_run nsenter -t "${holder_pid}" --net \
            tc qdisc replace dev "${peer_veth}" root netem delay "${delay}" "${jitter}"
    fi
}

# 等待服务端在命名空间内开始监听。只读查看监听套接字，不建立连接——
# 服务端只接受一次连接，探测连接会把它消耗掉。
wait_for_listener() {
    local waited=0
    while [ "${waited}" -lt 240 ]; do
        if sudo_run nsenter -t "${holder_pid}" --net ss -ltn 2>/dev/null | grep -q ":${port}"; then
            return 0
        fi
        sleep 0.5
        waited=$((waited + 1))
    done
    printf 'Server did not start listening on port %s.\n' "${port}" >&2
    return 1
}

# 本地直调基线：同一锁频条件下给出「本地差异的可分辨下界」。
run_local_direct_controlled() {
    local attempt=1
    while [ "${attempt}" -le "${max_attempts}" ]; do
        local run_name="r13-direct-$(date +%s%N | tail -c 7)-a${attempt}"
        if [ "${attempt}" -gt 1 ]; then
            sleep "${cool_down_seconds}"
        fi
        set +e
        sudo_run /usr/bin/python3 -I -B "${control_root}/controller.py" run \
            --control-root "${control_root}" --run-name "${run_name}" --cpu "${cpu}" \
            --timeout-seconds 1800 \
            --plan "${controller_plan}" --plan-sha256 "${plan_digest}" \
            -- "${measure_program}" direct "${test_seed}" "${direct_per_class}" \
                "${out_dir}/direct.csv" "${out_dir}/direct.meta" \
            > "${out_dir}/direct-controller.log" 2>&1
        local controller_status=$?
        set -e
        printf 'scenario=direct attempt=%d controller_run=%s controller_exit=%d\n' \
            "${attempt}" "${run_name}" "${controller_status}" >> "${out_dir}/controller-runs.txt"
        # 种子写进台账：两次运行用不同种子，这一项必须在仓库内可核。
        # measure 的退出码在控制器终态的 worker_exit_code 里（直调档的 worker 就是
        # measure 本身），台账里的 measure_exit 取自该字段，不复用 controller_exit。
        measure_exit=unavailable
        if grep -q '"worker_exit_code"' "${control_root}/runs/${run_name}/terminal.json" 2>/dev/null; then
            measure_exit=$(sed -n 's/.*"worker_exit_code": *\([0-9-]*\).*/\1/p' \
                "${control_root}/runs/${run_name}/terminal.json" | head -n 1)
        fi
        printf 'scenario=direct attempt=%d seed=%s measure_exit=%s controller_exit=%d\n' \
            "${attempt}" "${test_seed}" "${measure_exit}" "${controller_status}" \
            >> "${out_dir}/scenarios.txt"
        cp "${control_root}/runs/${run_name}/terminal.json" \
           "${out_dir}/direct-terminal.json" 2>/dev/null || true
        cp "${control_root}/runs/${run_name}/during.json" \
           "${out_dir}/direct-during.json" 2>/dev/null || true
        if [ "${controller_status}" -eq 0 ] && \
           grep -q '"worker_exit_code"' "${control_root}/runs/${run_name}/terminal.json"; then
            return 0
        fi
        attempt=$((attempt + 1))
    done
    printf 'Local direct tier failed after %d attempts.\n' "${max_attempts}" >&2
    return 1
}

# 网络档：服务端是控制器 worker（必须在命名空间内），客户端在宿主命名空间。
run_network_tier() {
    local scenario_name=$1
    local delay=$2
    local jitter=$3
    local attempt=1
    local client_status=1
    local controller_status=1
    local run_name=""

    while [ "${attempt}" -le "${max_attempts}" ]; do
        run_name="r13-${scenario_name}-$(date +%s%N | tail -c 7)-a${attempt}"
        if [ "${attempt}" -gt 1 ]; then
            sleep "${cool_down_seconds}"
        fi

        setup_topology
        apply_netem "${delay}" "${jitter}"

        set +e
        sudo_run nsenter -t "${holder_pid}" --net \
            /usr/bin/python3 -I -B "${control_root}/controller.py" run \
            --control-root "${control_root}" --run-name "${run_name}" --cpu "${cpu}" \
            --timeout-seconds 1800 \
            --plan "${controller_plan}" --plan-sha256 "${plan_digest}" \
            -- "${server_program}" --bind "${peer_address}" --port "${port}" \
                --seed "${test_seed}" --request-count "${network_request_count}" \
            > "${out_dir}/${scenario_name}-controller.log" 2>&1 &
        local controller_job=$!
        set -e

        client_status=1
        if wait_for_listener; then
            set +e
            taskset -c 0,1,3 "${client_program}" --connect "${peer_address}" --port "${port}" \
                --seed "${test_seed}" --request-count "${network_request_count}" \
                --rtt-path "${out_dir}/${scenario_name}-rtt.csv" \
                > "${out_dir}/${scenario_name}-client.txt" 2>&1
            client_status=$?
            set -e
        else
            printf 'listener wait failed for %s (attempt %d)\n' "${scenario_name}" "${attempt}" \
                >> "${out_dir}/${scenario_name}-client.txt"
        fi

        set +e
        wait "${controller_job}"
        controller_status=$?
        set -e

        cp "${control_root}/runs/${run_name}/terminal.json" \
           "${out_dir}/${scenario_name}-terminal.json" 2>/dev/null || true
        cp "${control_root}/runs/${run_name}/during.json" \
           "${out_dir}/${scenario_name}-during.json" 2>/dev/null || true
        cp "${control_root}/runs/${run_name}/worker.stdout" \
           "${out_dir}/${scenario_name}-server.txt" 2>/dev/null || true
        cp "${control_root}/runs/${run_name}/entry-probes.json" \
           "${out_dir}/${scenario_name}-entry-probes.json" 2>/dev/null || true

        cleanup_topology

        printf 'scenario=%s attempt=%d seed=%s delay=%s jitter=%s client_exit=%d controller_exit=%d\n' \
            "${scenario_name}" "${attempt}" "${test_seed}" "${delay}" "${jitter}" \
            "${client_status}" "${controller_status}" >> "${out_dir}/scenarios.txt"
        printf 'scenario=%s attempt=%d controller_run=%s controller_exit=%d client_exit=%d\n' \
            "${scenario_name}" "${attempt}" "${run_name}" "${controller_status}" "${client_status}" \
            >> "${out_dir}/controller-runs.txt"

        if [ "${controller_status}" -eq 0 ] && [ "${client_status}" -eq 0 ] && \
           grep -q '"worker_exit_code"' "${control_root}/runs/${run_name}/terminal.json"; then
            return 0
        fi
        attempt=$((attempt + 1))
    done
    printf 'Network tier %s failed after %d attempts.\n' "${scenario_name}" "${max_attempts}" >&2
    return 1
}

: > "${out_dir}/scenarios.txt"
: > "${out_dir}/controller-runs.txt"

run_local_direct_controlled
sleep "${cool_down_seconds}"
run_network_tier loopback none none
sleep "${cool_down_seconds}"
run_network_tier low 100us 20us
sleep "${cool_down_seconds}"
run_network_tier mid 1ms 200us
sleep "${cool_down_seconds}"
run_network_tier high 10ms 2ms

printf 'NETWORK_SCENARIOS_DONE\n'
