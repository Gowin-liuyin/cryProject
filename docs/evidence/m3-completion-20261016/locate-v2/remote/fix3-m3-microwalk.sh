#!/bin/bash
# 修正轮 3：给内存访问泄漏模块补 output-format，重跑两臂并导出报告。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"; REPO="$PROBE/src/Microwalk-master"
PINROOT="$PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux"
LOGS="$NEWROOT/logs"; MW="$PROBE/m3mw"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$PROBE/dotnet-home" NUGET_PACKAGES="$PROBE/nuget"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$PROBE/bundle-extract"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
export PATH="$PROBE/dotnet:$PATH"

MICROWALK_DIR="$REPO/Microwalk/bin/Release/net8.0"
PLUGIN_DIR="$REPO/Microwalk.Plugins.PinTracer/bin/Release/net8.0"
PINTOOL="$REPO/PinTracer/obj-intel64/PinTracer.so"

run() {
    name="$1"; shift
    log="$LOGS/$name.log"
    printf '### step=%s\n### date=%s\n### cmd=%s\n### begin-output\n' "$name" "$(date -Is)" "$*" > "$log"
    set +e
    bash -o pipefail -c "$*" >> "$log" 2>&1
    status=$?
    set -e
    printf '### end-output\n### exit=%s\n' "$status" >> "$log"
    printf '%s\n' "$status" > "$LOGS/$name.exit"
    printf 'step=%-44s exit=%s\n' "$name" "$status"
}

for mode in on off; do
    D="$MW/$mode"
    python3 - "$D/config2.yml" "$D/config3.yml" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
old = "        output-directory: $$PERSIST_DIR$$/results-memory\n"
new = old + "        output-format: txt\n"
assert old in text, "anchor not found"
open(dst, "w", encoding="utf-8").write(text.replace(old, new, 1))
PY
    run "o1-config3-m3-${mode}" "grep -n 'output-format\|results-memory\|module:' $D/config3.yml"
done

for mode in on off; do
    D="$MW/$mode"; W="$MW/work3-${mode}"
    rm -rf "$W"; mkdir -p "$W/work/target-m3-${mode}" "$W/persist/target-m3-${mode}"
    run "o2-microwalk3-m3-${mode}" "cd $D && TESTCASE_DIRECTORY=$MW/testcases TARGET_NAME=target-m3-${mode} WORK_DIR=$W PIN_PATH='$PINROOT' PINTOOL='$PINTOOL' dotnet '$MICROWALK_DIR/Microwalk.dll' $D/config3.yml -p '$PLUGIN_DIR'"
done

for mode in on off; do
    W="$MW/work3-${mode}"
    run "o3-callstacks-m3-${mode}" "cat $W/persist/target-m3-${mode}/results/call-stacks.txt"
    run "o4-memory-report-m3-${mode}" "ls -la $W/persist/target-m3-${mode}/results-memory/; echo '=== mutual-information.txt (top 25) ==='; sort -t, -k2 -gr $W/persist/target-m3-${mode}/results-memory/mutual-information.txt 2>/dev/null | head -25; echo '=== conditional-guessing-entropy head ==='; head -20 $W/persist/target-m3-${mode}/results-memory/conditional-guessing-entropy.txt 2>/dev/null"
done

printf 'm3_microwalk_fix3_complete\n'
