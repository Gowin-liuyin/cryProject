#!/bin/bash
# M3 D03：Microwalk 真实探测。每一步都保存原始命令、输出、退出码。落盘只在 NEWROOT 内。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
mkdir -p "$PROBE"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home"
export XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$NEWROOT/microwalk-probe/dotnet-home"
export NUGET_PACKAGES="$NEWROOT/microwalk-probe/nuget"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$NEWROOT/microwalk-probe/bundle-extract"
export DOCKER_CONFIG="$NEWROOT/home/.docker"
mkdir -p "$TMPDIR" "$HOME" "$XDG_CACHE_HOME" "$DOTNET_CLI_HOME" "$NUGET_PACKAGES" \
    "$DOTNET_BUNDLE_EXTRACT_BASE_DIR" "$DOCKER_CONFIG"

run_step() {
    step="$1"; shift
    log="$PROBE/$step.log"
    {
        printf '### step=%s\n' "$step"
        printf '### date=%s\n' "$(date -Is)"
        printf '### cwd=%s\n' "$(pwd)"
        printf '### cmd=%s\n' "$*"
        printf '### begin-output\n'
    } > "$log"
    set +e
    "$@" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$PROBE/$step.exit"
    printf 'step=%-28s exit=%s log=%s\n' "$step" "$status" "$log"
}

# ---------- A. .NET SDK 真实安装尝试 ----------
run_step a1-dotnet-install-script-download \
    curl -sSL --max-time 120 -o "$PROBE/dotnet-install.sh" https://dot.net/v1/dotnet-install.sh
if [ -s "$PROBE/dotnet-install.sh" ]; then
    head -5 "$PROBE/dotnet-install.sh" > "$PROBE/dotnet-install.head"
    sha256sum "$PROBE/dotnet-install.sh" >> "$PROBE/dotnet-install.head"
fi
run_step a2-dotnet-sdk-install-channel8 \
    bash "$PROBE/dotnet-install.sh" --channel 8.0 --install-dir "$PROBE/dotnet" --no-path --verbose
if [ -x "$PROBE/dotnet/dotnet" ]; then
    run_step a3-dotnet-info "$PROBE/dotnet/dotnet" --info
    run_step a4-dotnet-list-sdks "$PROBE/dotnet/dotnet" --list-sdks
fi

# ---------- B. Intel Pin 下载与许可 ----------
run_step b1-pin-known-url-head \
    curl -sSIL --max-time 60 \
    https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.31-98869-gfa6f126a8-gcc-linux.tar.gz
run_step b2-pin-3.28-url-head \
    curl -sSIL --max-time 60 \
    https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.28-98749-g6643ecee5-gcc-linux.tar.gz
run_step b3-pin-download-331 \
    curl -sSL --max-time 900 -o "$PROBE/pin-gcc-linux.tar.gz" \
    https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.31-98869-gfa6f126a8-gcc-linux.tar.gz
if [ -s "$PROBE/pin-gcc-linux.tar.gz" ]; then
    run_step b4-pin-archive-identify file "$PROBE/pin-gcc-linux.tar.gz"
    sha256sum "$PROBE/pin-gcc-linux.tar.gz" > "$PROBE/pin-archive.sha256"
    run_step b5-pin-extract tar -xzf "$PROBE/pin-gcc-linux.tar.gz" -C "$PROBE"
    run_step b6-pin-license-list bash -c "find $PROBE -maxdepth 3 -iname '*licen*' -o -maxdepth 3 -iname 'README*' | head -20"
fi

# ---------- C. Microwalk 源码/发行件可达性 ----------
run_step c1-github-api-release-latest \
    curl -sSL --max-time 60 -H 'Accept: application/vnd.github+json' \
    https://api.github.com/repos/microwalk-project/Microwalk/releases/latest
run_step c2-github-api-releases-list \
    curl -sSL --max-time 60 -H 'Accept: application/vnd.github+json' \
    'https://api.github.com/repos/microwalk-project/Microwalk/releases?per_page=20'
run_step c3-github-api-pin-action-repo \
    curl -sSL --max-time 60 -H 'Accept: application/vnd.github+json' \
    https://api.github.com/repos/microwalk-project/microwalk-pin-action
run_step c4-git-clone-microwalk \
    git clone --depth 1 https://github.com/microwalk-project/Microwalk.git "$PROBE/Microwalk"
if [ -d "$PROBE/Microwalk/.git" ]; then
    run_step c5-clone-head bash -c "cd $PROBE/Microwalk && git log -1 --format='%H %ad %s' && git status --porcelain | head"
    run_step c6-clone-tree bash -c "ls -la $PROBE/Microwalk && find $PROBE/Microwalk -maxdepth 2 -name '*.csproj' -o -maxdepth 2 -name 'global.json' -o -maxdepth 2 -name '*.sln' | head -20"
fi

# ---------- D. Docker / ghcr ----------
run_step d1-docker-info-rootdir docker info --format 'DockerRootDir={{.DockerRootDir}}'
run_step d2-dockerd-nonroot-custom-root bash -c \
    "timeout 40 dockerd --data-root=$PROBE/docker-data --exec-root=$PROBE/docker-exec --pidfile=$PROBE/dockerd.pid --host=unix://$PROBE/docker.sock --iptables=false --bridge=none 2>&1 | tail -25"
run_step d3-ghcr-token bash -c \
    "curl -sSL --max-time 60 'https://ghcr.io/token?scope=repository:microwalk-project/microwalk:pull&service=ghcr.io' -o $PROBE/ghcr-token.json && head -c 200 $PROBE/ghcr-token.json && echo && jq -r '.token|length' $PROBE/ghcr-token.json"
if [ -s "$PROBE/ghcr-token.json" ]; then
    GHCR_TOKEN="$(jq -r '.token // empty' "$PROBE/ghcr-token.json" 2>/dev/null)"
    if [ -n "$GHCR_TOKEN" ]; then
        run_step d4-ghcr-manifest-pin bash -c \
            "curl -sSL --max-time 120 -H 'Authorization: Bearer $GHCR_TOKEN' \
             -H 'Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json,application/vnd.oci.image.manifest.v1+json' \
             -o $PROBE/ghcr-manifest-pin.json -w 'http_code=%{http_code}\n' \
             https://ghcr.io/v2/microwalk-project/microwalk/manifests/pin && head -c 3000 $PROBE/ghcr-manifest-pin.json"
        run_step d5-ghcr-tags-list bash -c \
            "curl -sSL --max-time 60 -H 'Authorization: Bearer $GHCR_TOKEN' \
             'https://ghcr.io/v2/microwalk-project/microwalk/tags/list' | head -c 2000"
    fi
fi

printf 'microwalk_probe_complete\n'
