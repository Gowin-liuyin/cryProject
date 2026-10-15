#!/bin/bash
# 修法：① 建 obj-intel64 后重编 Pin 工具；② config 必须在 -p 之前；③ 用 pipefail 保留真实退出码。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
REPO="$PROBE/src/Microwalk-master"
PINROOT="$PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux"
LOGS="$NEWROOT/logs"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$PROBE/dotnet-home" NUGET_PACKAGES="$PROBE/nuget"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$PROBE/bundle-extract"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
export PATH="$PROBE/dotnet:$PATH"

MICROWALK_DIR="$REPO/Microwalk/bin/Release/net8.0"
PLUGIN_DIR="$REPO/Microwalk.Plugins.PinTracer/bin/Release/net8.0"
MAPGEN_DIR="$REPO/Tools/MapFileGenerator/bin/Release/net8.0"
PINTOOL="$REPO/PinTracer/obj-intel64/PinTracer.so"

step=0
run() {
    name="$1"; shift
    log="$LOGS/$name.log"
    {
        printf '### step=%s\n### date=%s\n### cmd=%s\n### begin-output\n' "$name" "$(date -Is)" "$*"
    } > "$log"
    set +e
    bash -o pipefail -c "$*" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$LOGS/$name.exit"
    printf 'step=%-40s exit=%s\n' "$name" "$status"
}

run h1-mkdir-objdir-and-build-pin "mkdir -p $REPO/PinTracer/obj-intel64 && cd $REPO/PinTracer && make PIN_ROOT='$PINROOT' obj-intel64/PinTracer.so && ls -la obj-intel64/PinTracer.so && file obj-intel64/PinTracer.so"

TPL="$PROBE/template-run"
WORK_DIR="$TPL/run"
run h2-template-library-and-target-present "ls -la $TPL/libexample.so $TPL/microwalk/target-example $TPL/microwalk/libexample.map $TPL/microwalk/target-example.map"
run h3-template-microwalk-run "cd $TPL/microwalk && TESTCASE_DIRECTORY=$TPL/microwalk/testcases/target-example TARGET_NAME=target-example WORK_DIR=$WORK_DIR PIN_PATH='$PINROOT' PINTOOL='$PINTOOL' dotnet '$MICROWALK_DIR/Microwalk.dll' '$TPL/microwalk/config.yml' -p '$PLUGIN_DIR'"
run h4-template-artifacts "find $WORK_DIR -type f | head -60; echo '--- sizes ---'; du -sh $WORK_DIR/* 2>/dev/null"
run h5-template-results "find $WORK_DIR/persist -type f | while read f; do echo \"== \$f\"; head -c 2000 \"\$f\"; echo; done"

printf 'microwalk_fix_run_complete\n'
