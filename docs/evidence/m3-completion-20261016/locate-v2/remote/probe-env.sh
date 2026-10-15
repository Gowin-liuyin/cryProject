#!/bin/bash
# M3 locate-v2 Microwalk/.NET/Pin/Docker 真实探测。所有落盘在 NEWROOT 内。
set -u
NEWROOT="$1"
LOGS="$NEWROOT/logs"
RAW="$NEWROOT/evidence/raw"
mkdir -p "$RAW"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home"
export XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$NEWROOT/home"
export NUGET_PACKAGES="$NEWROOT/cache/nuget"
export DOCKER_CONFIG="$NEWROOT/home/.docker"
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$DOTNET_CLI_HOME" "$NUGET_PACKAGES" "$DOCKER_CONFIG"

section() { printf '\n===== %s =====\n' "$1"; }

{
section "identity"
date -Is
hostname
uname -a
id
printf 'NEWROOT=%s\n' "$NEWROOT"
realpath "$NEWROOT"

section "tool-presence"
for t in dotnet pin docker podman nerdctl microwalk git curl wget unzip tar clang gcc cmake ninja java valgrind objdump; do
  printf '%-10s -> %s\n' "$t" "$(command -v "$t" 2>/dev/null || echo MISSING)"
done

section "dotnet"
dotnet --version 2>&1 || true
dotnet --info 2>&1 | head -40 || true
dotnet --list-sdks 2>&1 || true
dotnet --list-runtimes 2>&1 || true
ls -d /usr/share/dotnet /usr/lib/dotnet /opt/dotnet "$HOME/.dotnet" 2>&1 || true
( dpkg -l 2>/dev/null | grep -i -E 'dotnet|mono' || echo 'no dotnet/mono dpkg entries' )
( apt-cache policy dotnet-sdk-8.0 dotnet-sdk-9.0 dotnet-runtime-8.0 2>&1 | head -30 || true )

section "pin"
ls -d /opt/pin* /usr/local/pin* "$HOME"/pin* 2>&1 || true
( find /opt /usr/local -maxdepth 2 -iname 'pin*' 2>/dev/null | head -20 || true )
( dpkg -l 2>/dev/null | grep -i -E '\bpin\b' || echo 'no pin dpkg entries' )

section "docker"
docker version 2>&1 || true
docker info 2>&1 | head -40 || true
docker context ls 2>&1 || true
( systemctl is-active docker 2>&1 || true )
( systemctl status docker --no-pager 2>&1 | head -10 || true )
podman version 2>&1 || true

section "network-reachability"
for u in https://dotnet.microsoft.com https://dot.net https://builds.dotnet.com https://software.intel.com https://www.intel.com https://github.com https://raw.githubusercontent.com https://ghcr.io/v2/ https://registry-1.docker.io/v2/ https://pypi.org https://mirrors.tuna.tsinghua.edu.cn; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u" 2>/dev/null || echo CURLFAIL)
  printf '%-50s %s\n' "$u" "$code"
done

section "network-dns"
for h in dotnet.microsoft.com builds.dotnet.microsoft.com software.intel.com github.com ghcr.io registry-1.docker.io; do
  printf '%-40s ' "$h"
  getent hosts "$h" 2>&1 | head -2 | tr '\n' ' ' || true
  printf '\n'
done

section "proxy-env"
env | grep -i -E 'proxy|no_proxy' || echo 'no proxy env vars'

section "disk-and-boundary"
df -h "$NEWROOT"
printf 'docker root (if daemon readable): '
docker info --format '{{.DockerRootDir}}' 2>&1 || true
printf 'TMPDIR=%s\n' "$TMPDIR"
printf 'HOME=%s\n' "$HOME"
} > "$LOGS/env-probe.log" 2>&1
echo "env-probe done: $LOGS/env-probe.log"
