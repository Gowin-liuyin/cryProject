#!/bin/bash
# 真实尝试：在 Cry 边界内编译并运行 Microwalk（Pin 后端）。
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
export HOME="$NEWROOT/home"
export XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$PROBE/dotnet-home"
export NUGET_PACKAGES="$PROBE/nuget"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$PROBE/bundle-extract"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export PATH="$PROBE/dotnet:$PATH"
mkdir -p "$TMPDIR" "$HOME" "$XDG_CACHE_HOME" "$DOTNET_CLI_HOME" "$NUGET_PACKAGES" \
    "$DOTNET_BUNDLE_EXTRACT_BASE_DIR"

run_step() {
    step="$1"; shift
    log="$LOGS/$step.log"
    {
        printf '### step=%s\n### date=%s\n### cwd=%s\n### cmd=%s\n### env=%s\n### begin-output\n' \
            "$step" "$(date -Is)" "$(pwd)" "$*" \
            "TMPDIR=$TMPDIR HOME=$HOME DOTNET_CLI_HOME=$DOTNET_CLI_HOME NUGET_PACKAGES=$NUGET_PACKAGES"
    } > "$log"
    set +e
    "$@" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$LOGS/$step.exit"
    printf 'step=%-38s exit=%s\n' "$step" "$status"
}

# g1: .NET 构建 Microwalk 主程序与 Pin 插件、MAP 生成器
run_step g1-dotnet-build-microwalk bash -c \
    "cd $REPO && dotnet build Microwalk/Microwalk.csproj -c Release 2>&1 | tail -25"
run_step g2-dotnet-build-pintracer-plugin bash -c \
    "cd $REPO && dotnet build Microwalk.Plugins.PinTracer/Microwalk.Plugins.PinTracer.csproj -c Release 2>&1 | tail -25"
run_step g3-dotnet-build-mapfilegenerator bash -c \
    "cd $REPO && dotnet build Tools/MapFileGenerator/MapFileGenerator.csproj -c Release 2>&1 | tail -25"
run_step g4-dotnet-build-frameworkbase bash -c \
    "cd $REPO && dotnet build Microwalk.FrameworkBase/Microwalk.FrameworkBase.csproj -c Release 2>&1 | tail -15"

# g5: 编译 Pin 工具
run_step g5-make-pin-tool bash -c \
    "cd $REPO/PinTracer && make PIN_ROOT='$PINROOT' obj-intel64/PinTracer.so 2>&1 | tail -30"
run_step g6-pin-tool-artifact bash -c \
    "ls -la $REPO/PinTracer/obj-intel64/ 2>&1; file $REPO/PinTracer/obj-intel64/PinTracer.so 2>&1"

# g7: 定位 .NET 产物
run_step g7-locate-dotnet-outputs bash -c \
    "find $REPO -name 'Microwalk.dll' -o -name 'Microwalk.Plugins.PinTracer.dll' -o -name 'MapFileGenerator.dll' | sort"

MICROWALK_DIR="$REPO/Microwalk/bin/Release/net8.0"
PLUGIN_DIR="$REPO/Microwalk.Plugins.PinTracer/bin/Release/net8.0"
MAPGEN_DIR="$REPO/Tools/MapFileGenerator/bin/Release/net8.0"
PINTOOL="$REPO/PinTracer/obj-intel64/PinTracer.so"
run_step g8-check-required-paths bash -c \
    "for p in '$MICROWALK_DIR/Microwalk.dll' '$PLUGIN_DIR/Microwalk.Plugins.PinTracer.dll' '$MAPGEN_DIR/MapFileGenerator.dll' '$PINTOOL'; do if [ -e \$p ]; then echo \"OK \$p\"; else echo \"MISSING \$p\"; fi; done"

# g9: 用 Microwalk 自带 c 模板做端到端跑通验证
TPL="$PROBE/template-run"
rm -rf "$TPL"
cp -a "$REPO/templates/c" "$TPL"
mkdir -p "$TPL/work" "$TPL/persist"
run_step g9a-template-build-library bash -c "cd $TPL && make -j4 all 2>&1 | tail -10"
run_step g9b-template-map-library bash -c \
    "cd $MAPGEN_DIR && dotnet MapFileGenerator.dll $TPL/libexample.so $TPL/microwalk/libexample.map 2>&1 | tail -5"
run_step g9c-template-build-target bash -c \
    "cd $TPL/microwalk && gcc main.c target-example.c -g -fno-inline -fno-split-stack -L $TPL -lexample -I $TPL/src -o target-example 2>&1 | tail -10 && ls -la target-example"
run_step g9d-template-map-target bash -c \
    "cd $MAPGEN_DIR && dotnet MapFileGenerator.dll $TPL/microwalk/target-example $TPL/microwalk/target-example.map 2>&1 | tail -5"
run_step g9e-template-testcases bash -c "ls -la $TPL/microwalk/testcases/*/ | head -20"

WORK_DIR="$TPL/run"
mkdir -p "$WORK_DIR/work/target-example" "$WORK_DIR/persist/target-example"
run_step g10-template-microwalk-run bash -c \
    "cd $TPL/microwalk && TESTCASE_DIRECTORY=$TPL/microwalk/testcases/target-example TARGET_NAME=target-example WORK_DIR=$WORK_DIR PIN_PATH='$PINROOT' PINTOOL='$PINTOOL' dotnet '$MICROWALK_DIR/Microwalk.dll' -p '$PLUGIN_DIR' $TPL/microwalk/config.yml 2>&1 | tail -60"
run_step g11-template-results bash -c \
    "find $WORK_DIR -maxdepth 4 -type f | head -40; echo '--- results ---'; find $WORK_DIR/persist -type f -exec ls -la {} \\; 2>/dev/null | head -20"

printf 'microwalk_build_and_template_run_complete\n'
