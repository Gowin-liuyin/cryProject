#!/usr/bin/env bash
set -euo pipefail
cd /home/cryrepro
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy
proxy=$(cat /home/cryrepro/cry-wsl-proxy.txt)
if [ -n "$proxy" ]; then
  export http_proxy="$proxy" https_proxy="$proxy" HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy"
fi
export GIT_TERMINAL_PROMPT=0 TZ=Asia/Shanghai
mode=${1:?quick or full}
stage=${2:-all}
case "$mode" in
  quick) export QUICK=1 WORK=/home/cryrepro/cry-wsl-quick;;
  full) export QUICK=0 WORK=/home/cryrepro/cry-wsl;;
  *) exit 2;;
esac
exec bash /home/cryrepro/wsl_repro.sh "$stage"
