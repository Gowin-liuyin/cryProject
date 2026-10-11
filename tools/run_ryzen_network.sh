#!/bin/sh
# 在 Cry 内用 veth 和 netem 采集三档客户端 RTT。不创建 /run/netns 具名句柄。
set -eu

root=/home/nss-marker/yhr/Cry/seven-capabilities-20261011
build=${root}/build-positive
out=${root}/run-network
auth_file=${SUDO_AUTH_FILE:-}
mkdir -p "${out}" "${root}/tmp"
export TMPDIR=${root}/tmp

sudo_run() {
    if [ -n "${auth_file}" ] && [ -f "${auth_file}" ]; then
        sudo -S -p '' "$@" < "${auth_file}"
    else
        sudo -n "$@"
    fi
}

host_pid=""
holder_sudo=""
cleanup() {
    if [ -n "${host_pid}" ]; then
        sudo_run kill "${host_pid}" >/dev/null 2>&1 || true
    fi
    if [ -n "${holder_sudo}" ]; then
        wait "${holder_sudo}" 2>/dev/null || true
    fi
    sudo_run ip link del cry7a >/dev/null 2>&1 || true
    if [ -n "${auth_file}" ]; then
        rm -f "${auth_file}"
    fi
}
trap cleanup EXIT

pidfile=${root}/tmp/net-holder.pid
rm -f "${pidfile}"
sudo_run ip link del cry7a >/dev/null 2>&1 || true
sudo_run ip link add cry7a type veth peer name cry7b
sudo_run ip addr add 10.88.11.1/30 dev cry7a
sudo_run ip link set cry7a up
sudo_run unshare --net sh -c "echo \$\$ > '${pidfile}'; exec sleep 600" >/dev/null 2>&1 &
holder_sudo=$!
waited=0
while [ ! -s "${pidfile}" ] && [ "${waited}" -lt 20 ]; do
    sleep 0.2
    waited=$((waited + 1))
done
host_pid=$(cat "${pidfile}")
sudo_run ip link set cry7b netns "${host_pid}"
sudo_run nsenter -t "${host_pid}" --net ip link set lo up
sudo_run nsenter -t "${host_pid}" --net ip addr add 10.88.11.2/30 dev cry7b
sudo_run nsenter -t "${host_pid}" --net ip link set cry7b up

run_level() {
    level=$1
    delay=$2
    jitter=$3
    sudo_run tc qdisc replace dev cry7a root netem delay "${delay}" "${jitter}"
    sudo_run nsenter -t "${host_pid}" --net \
        "${build}/network_server" --bind 10.88.11.2 --port 18011 --seed 20261111 \
        --request-count 80 > "${out}/${level}-server.txt" 2>&1 &
    server_pid=$!
    sleep 0.5
    "${build}/network_client" --connect 10.88.11.2 --port 18011 --seed 20261111 \
        --request-count 80 --rtt-path "${out}/${level}-rtt.csv" \
        > "${out}/${level}-client.txt" 2>&1
    wait "${server_pid}"
    printf 'level=%s delay=%s jitter=%s client_exit=0\n' "${level}" "${delay}" "${jitter}" \
        >> "${out}/levels.txt"
}

run_level low 100us 20us
run_level mid 1ms 200us
run_level high 10ms 2ms
echo NETWORK_JITTER_DONE
