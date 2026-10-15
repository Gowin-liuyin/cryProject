#!/bin/bash
# Docker / ghcr 边界合规探测：不向 Docker 默认存储写入任何内容。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
LOGS="$NEWROOT/logs"
mkdir -p "$PROBE/ghcr"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" DOCKER_CONFIG="$NEWROOT/home/.docker" XDG_CACHE_HOME="$NEWROOT/cache"
mkdir -p "$DOCKER_CONFIG"

run_step() {
    step="$1"; shift
    log="$LOGS/$step.log"
    {
        printf '### step=%s\n### date=%s\n### cmd=%s\n### begin-output\n' "$step" "$(date -Is)" "$*"
    } > "$log"
    set +e
    "$@" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$LOGS/$step.exit"
    printf 'step=%-34s exit=%s\n' "$step" "$status"
}

run_step d1-docker-info-rootdir bash -c \
    "docker info --format 'DockerRootDir={{.DockerRootDir}}'; docker info --format 'Driver={{.Driver}}'; docker info --format 'ServerVersion={{.ServerVersion}}'"
run_step d2-docker-images-readonly docker images --digests
run_step d3-dockerd-nonroot-cry-dataroot bash -c \
    "timeout 45 dockerd --data-root=$PROBE/docker-data --exec-root=$PROBE/docker-exec --pidfile=$PROBE/dockerd.pid --host=unix://$PROBE/docker.sock --iptables=false --bridge=none 2>&1 | tail -20"
run_step d4-ghcr-token bash -c \
    "curl -sSL --max-time 60 'https://ghcr.io/token?scope=repository:microwalk-project/microwalk:pull&service=ghcr.io' -o $PROBE/ghcr/token.json -w 'http_code=%{http_code}\\n' && jq -r '\"token_length=\\(.token|length)\"' $PROBE/ghcr/token.json"
GHCR_TOKEN="$(jq -r '.token // empty' "$PROBE/ghcr/token.json" 2>/dev/null)"
if [ -n "${GHCR_TOKEN:-}" ]; then
    run_step d5-ghcr-manifest-index bash -c \
        "curl -sSL --max-time 120 -H 'Authorization: Bearer $GHCR_TOKEN' \
         -H 'Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json,application/vnd.oci.image.manifest.v1+json' \
         -o $PROBE/ghcr/manifest-index.json -D $PROBE/ghcr/manifest-index.headers -w 'http_code=%{http_code}\\n' \
         https://ghcr.io/v2/microwalk-project/microwalk/manifests/pin && head -c 4000 $PROBE/ghcr/manifest-index.json"
    run_step d6-ghcr-tags bash -c \
        "curl -sSL --max-time 60 -H 'Authorization: Bearer $GHCR_TOKEN' \
         'https://ghcr.io/v2/microwalk-project/microwalk/tags/list' -o $PROBE/ghcr/tags.json -w 'http_code=%{http_code}\\n' && head -c 3000 $PROBE/ghcr/tags.json"
    # 若是 manifest list，取第一个 linux/amd64 子 manifest 的摘要
    SUB_DIGEST="$(jq -r '[.manifests[]? | select(.platform.os=="linux" and .platform.architecture=="amd64")][0].digest // empty' "$PROBE/ghcr/manifest-index.json" 2>/dev/null)"
    if [ -n "${SUB_DIGEST:-}" ]; then
        printf '%s\n' "$SUB_DIGEST" > "$PROBE/ghcr/amd64-subdigest.txt"
        run_step d7-ghcr-manifest-amd64 bash -c \
            "curl -sSL --max-time 120 -H 'Authorization: Bearer $GHCR_TOKEN' \
             -H 'Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json' \
             -o $PROBE/ghcr/manifest-amd64.json -D $PROBE/ghcr/manifest-amd64.headers -w 'http_code=%{http_code}\\n' \
             'https://ghcr.io/v2/microwalk-project/microwalk/manifests/$SUB_DIGEST' && cat $PROBE/ghcr/manifest-amd64.json"
        run_step d8-ghcr-layer-size-summary bash -c \
            "jq -r '\"config_size=\\(.config.size)\", (.layers[] | \"layer \\(.size) \\(.digest)\")' $PROBE/ghcr/manifest-amd64.json; \
             jq -r '[.layers[].size] | add' $PROBE/ghcr/manifest-amd64.json | sed 's/^/layers_total_bytes=/'"
        CONFIG_DIGEST="$(jq -r '.config.digest // empty' "$PROBE/ghcr/manifest-amd64.json" 2>/dev/null)"
        if [ -n "${CONFIG_DIGEST:-}" ]; then
            run_step d9-ghcr-config-blob bash -c \
                "curl -sSL --max-time 120 -H 'Authorization: Bearer $GHCR_TOKEN' \
                 -o $PROBE/ghcr/config-blob.json -w 'http_code=%{http_code}\\n' \
                 'https://ghcr.io/v2/microwalk-project/microwalk/blobs/$CONFIG_DIGEST' && jq -r '.config.Env[]?,.config.Cmd[]?,.config.WorkingDir,.created' $PROBE/ghcr/config-blob.json"
        fi
    fi
fi
printf 'docker_ghcr_probe_complete\n'
