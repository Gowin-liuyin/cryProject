#!/bin/sh
set -eu

project_directory=/Users/yin/code/cryProject
stage_directory="$project_directory/build/aris-core-rehearsal-20261009/stage"
reference=$(cat "$stage_directory/PREPARATION_REF")
case "$reference" in
    ''|*[!0-9a-f]*)
        exit 2
        ;;
esac
if [ "${#reference}" -ne 40 ]; then
    exit 2
fi
short_reference=$(printf '%s' "$reference" | cut -c 1-12)
remote_directory="/home/nss-marker/yhr/Cry/core-rehearsal-20261009-$short_reference"
local_output="$project_directory/build/aris-core-rehearsal-20261009/execution-$short_reference"
if [ -e "$local_output" ]; then
    printf '已有本次输出，停止重复运行。\n' >&2
    exit 2
fi
(
    cd "$stage_directory"
    shasum -a 256 -c SHA256SUMS
)

connection_directory=$(mktemp -d /tmp/cryproject-rehearsal.XXXXXX)
control_socket="$connection_directory/session.sock"
cleanup()
{
    trap - 0
    ssh -S "$control_socket" -O exit nss-marker@10.144.144.5 >/dev/null 2>&1 || :
    rmdir "$connection_directory" || :
}
trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

printf '按SSH和sudo的系统提示输入密码；脚本不读取或保存口令。\n'
ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=8 -o ControlMaster=yes \
    -o ControlPersist=600 -o ControlPath="$control_socket" nss-marker@10.144.144.5 true
ssh -S "$control_socket" -o BatchMode=yes nss-marker@10.144.144.5 \
    "mkdir -m 700 '$remote_directory'"
scp -o ControlPath="$control_socket" -o BatchMode=yes -r "$stage_directory/source" \
    "nss-marker@10.144.144.5:$remote_directory/"
scp -o ControlPath="$control_socket" -o BatchMode=yes "$stage_directory/SHA256SUMS" \
    "nss-marker@10.144.144.5:$remote_directory/SHA256SUMS"
ssh -S "$control_socket" -o BatchMode=yes nss-marker@10.144.144.5 \
    "cd '$remote_directory' && sha256sum -c SHA256SUMS"

remote_exit_status=0
if ssh -tt -S "$control_socket" -o BatchMode=yes -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=4 nss-marker@10.144.144.5 \
    "sudo /usr/bin/python3 '$remote_directory/source/rehearse.py' launch '$remote_directory'"; then
    remote_exit_status=0
else
    remote_exit_status=$?
fi
mkdir -m 700 "$local_output"
copy_exit_status=0
if scp -o ControlPath="$control_socket" -o BatchMode=yes -r \
    "nss-marker@10.144.144.5:$remote_directory/results" "$local_output/"; then
    copy_exit_status=0
else
    copy_exit_status=$?
fi
printf '{"preparation_commit":"%s","remote_exit_status":%s,"copy_exit_status":%s}\n' \
    "$reference" "$remote_exit_status" "$copy_exit_status" > "$local_output/receipt.json"
printf '回执目录：%s\n' "$local_output"
if [ "$remote_exit_status" -ne 0 ] || [ "$copy_exit_status" -ne 0 ]; then
    exit 1
fi
