#!/bin/bash
# 修法 1/2：Pin 3.28 真实下载 + Microwalk 源码获取（tarball 备用路径）。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
mkdir -p "$PROBE/pin" "$PROBE/src"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache"

run_step() {
    step="$1"; shift
    log="$PROBE/$step.log"
    {
        printf '### step=%s\n### date=%s\n### cmd=%s\n### begin-output\n' "$step" "$(date -Is)" "$*"
    } > "$log"
    set +e
    "$@" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$PROBE/$step.exit"
    printf 'step=%-34s exit=%s\n' "$step" "$status"
}

PIN_URL=https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.28-98749-g6643ecee5-gcc-linux.tar.gz
run_step f1-pin-328-download curl -sSL --max-time 1800 -o "$PROBE/pin/pin-3.28-gcc-linux.tar.gz" "$PIN_URL"
run_step f2-pin-328-file file "$PROBE/pin/pin-3.28-gcc-linux.tar.gz"
sha256sum "$PROBE/pin/pin-3.28-gcc-linux.tar.gz" > "$PROBE/pin/pin-3.28.sha256" 2>&1
run_step f3-pin-328-extract tar -xzf "$PROBE/pin/pin-3.28-gcc-linux.tar.gz" -C "$PROBE/pin"
run_step f4-pin-328-list bash -c "ls -la $PROBE/pin/ && ls $PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux/ 2>/dev/null | head -30"
run_step f5-pin-328-version bash -c "cd $PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux 2>/dev/null && ./pin -version 2>&1 | head -20"
run_step f6-pin-328-license bash -c "find $PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux -maxdepth 2 -iname '*licen*' -o -maxdepth 2 -iname '*COPYING*' -o -maxdepth 2 -iname '*README*' 2>/dev/null | head -20"
run_step f7-pin-328-inspect-head bash -c "head -40 $PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux/Licensing/README* 2>/dev/null || find $PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux -maxdepth 3 -iname '*licen*' -exec head -30 {} \\;"

# Microwalk 源码备用路径：codeload tarball（不依赖 git 协议速度）
run_step f8-microwalk-tarball-download bash -c \
    "curl -sSL --max-time 900 -o $PROBE/src/Microwalk-master.tar.gz -w 'http_code=%{http_code} size=%{size_download}\\n' https://codeload.github.com/microwalk-project/Microwalk/tar.gz/refs/heads/master"
run_step f9-microwalk-tarball-file file "$PROBE/src/Microwalk-master.tar.gz"
sha256sum "$PROBE/src/Microwalk-master.tar.gz" > "$PROBE/src/Microwalk-master.sha256" 2>&1
run_step f10-microwalk-tarball-extract tar -xzf "$PROBE/src/Microwalk-master.tar.gz" -C "$PROBE/src"
run_step f11-microwalk-tarball-list bash -c "ls -la $PROBE/src/ && ls $PROBE/src/Microwalk-master/ 2>/dev/null"

printf 'pin_fix_complete\n'
