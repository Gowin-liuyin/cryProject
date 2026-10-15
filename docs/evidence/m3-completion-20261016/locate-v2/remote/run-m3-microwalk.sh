#!/bin/bash
# 在 Cry 内用 Microwalk(Pin) 真实追踪本项目的 M3 on/off 完整解封装夹具。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
REPO="$PROBE/src/Microwalk-master"
SRC="$NEWROOT/source"
B="$NEWROOT/build-ordinary"
PINROOT="$PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux"
LOGS="$NEWROOT/logs"
MW="$PROBE/m3mw"
export TMPDIR="$NEWROOT/tmp" TMP="$NEWROOT/tmp" TEMP="$NEWROOT/tmp"
export HOME="$NEWROOT/home" XDG_CACHE_HOME="$NEWROOT/cache"
export DOTNET_CLI_HOME="$PROBE/dotnet-home" NUGET_PACKAGES="$PROBE/nuget"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$PROBE/bundle-extract"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
export PATH="$PROBE/dotnet:$PATH"
mkdir -p "$MW"

MICROWALK_DIR="$REPO/Microwalk/bin/Release/net8.0"
PLUGIN_DIR="$REPO/Microwalk.Plugins.PinTracer/bin/Release/net8.0"
MAPGEN_DIR="$REPO/Tools/MapFileGenerator/bin/Release/net8.0"
PINTOOL="$REPO/PinTracer/obj-intel64/PinTracer.so"

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
    printf 'step=%-42s exit=%s\n' "$name" "$status"
}

# m1: 用与 CMake 相同的补丁 overlay 编译 on/off 共享库（-fPIC -g）
for mode in on off; do
    if [ "$mode" = on ]; then leak=1; else leak=0; fi
    OV="$B/platform-m3-${mode}-source/mlkem"
    run "m1-build-libm3${mode}" "clang -fPIC -shared -DMLK_CONFIG_FILE='\"baseline_config.h\"' -DPLATFORM_IMPLEMENTATION_NAME='\"platform-m3-lut-${mode}\"' -DPLATFORM_M3_LUT_LEAK=${leak} -I$OV -I$SRC/include -I$SRC/vendor/mlkem-native/mlkem -O2 -g -DNDEBUG -std=c11 -fno-inline -o $MW/libm3${mode}.so $OV/mlkem_native.c $SRC/src/mlkem.c $SRC/src/random.c $SRC/src/inputs.c && ls -la $MW/libm3${mode}.so && file $MW/libm3${mode}.so"
    run "m2-map-libm3${mode}" "cd $MAPGEN_DIR && dotnet MapFileGenerator.dll $MW/libm3${mode}.so $MW/libm3${mode}.map && wc -l $MW/libm3${mode}.map"
done

# m3: 编译两个目标可执行文件（同一份 target 源，链接不同 .so）
cp -a "$REPO/templates/c/microwalk/main.c" "$MW/main.c"
cp -a "$NEWROOT/m3mwtarget.c" "$MW/m3mwtarget.c"
run m2b-target-source "ls -la $MW/main.c $MW/m3mwtarget.c && sha256sum $MW/main.c $MW/m3mwtarget.c"
for mode in on off; do
    run "m3-build-target-m3-${mode}" "gcc $MW/main.c $MW/m3mwtarget.c -g -fno-inline -fno-split-stack -I$SRC/include -L$MW -Wl,-rpath,$MW -lm3${mode} -o $MW/target-m3-${mode} && ls -la $MW/target-m3-${mode}"
    run "m4-map-target-m3-${mode}" "cd $MAPGEN_DIR && dotnet MapFileGenerator.dll $MW/target-m3-${mode} $MW/target-m3-${mode}.map && wc -l $MW/target-m3-${mode}.map"
done

# m5: 测试用例（1 字节 = 输入类下标 0..4，对应 valid/bit-flipped/random/message-zero/message-ones）
mkdir -p "$MW/testcases"
for idx in 0 1 2 3 4; do
    printf "\\x%02x" "$idx" > "$MW/testcases/t${idx}.testcase"
done
run m5-testcases "ls -la $MW/testcases/ && for f in $MW/testcases/*.testcase; do printf '%s=' \$f; od -An -tu1 \$f; done"

# m6: 不在 Pin 下干跑 wrapper，确认目标本身可用
for mode in on off; do
    run "m6-dryrun-target-m3-${mode}" "printf 't 0 $MW/testcases/t0.testcase\\nt 4 $MW/testcases/t4.testcase\\ne 0\\n' | LD_LIBRARY_PATH=$MW $MW/target-m3-${mode}"
done

# m7: 生成每个臂的 Microwalk 配置
for mode in on off; do
    D="$MW/$mode"
    mkdir -p "$D"
    cat > "$D/config.yml" <<YAML
constants:
  TARGET_PATH: \$\$CONFIG_PATH\$\$/target-m3-${mode}
  LIBRARY_PATH: $MW
  WORK_DIR: \$\$\$WORK_DIR\$\$\$/work/target-m3-${mode}
  PERSIST_DIR: \$\$\$WORK_DIR\$\$\$/persist/target-m3-${mode}
---

general:
  logger:
    log-level: info
    file: \$\$WORK_DIR\$\$/log.txt

testcase:
  module: load
  module-options:
    input-directory: \$\$\$TESTCASE_DIRECTORY\$\$\$

trace:
  module: pin
  module-options:
    output-directory: \$\$WORK_DIR\$\$/traces
    pin-tool-path: \$\$\$PINTOOL\$\$\$
    pin-path: \$\$\$PIN_PATH\$\$/pin
    wrapper-path: \$\$TARGET_PATH\$\$
    environment:
      LD_LIBRARY_PATH: \$\$LIBRARY_PATH\$\$
    images:
      - target-m3-${mode}
      - libm3${mode}.so
  options:
    input-buffer-size: 4

preprocess:
  module: pin
  module-options:
    output-directory: \$\$WORK_DIR\$\$/traces
    store-traces: true
    keep-raw-traces: false
  options:
    input-buffer-size: 2
    max-parallel-threads: 4

analysis:
  modules:
    - module: control-flow-leakage
      module-options:
        output-directory: \$\$PERSIST_DIR\$\$/results
        map-files:
          - \$\$TARGET_PATH\$\$.map
          - $MW/libm3${mode}.map
        dump-call-tree: true
        include-testcases-in-call-stacks: true

  options:
    input-buffer-size: 1
    max-parallel-threads: 1
YAML
    cp "$MW/target-m3-${mode}" "$D/target-m3-${mode}"
    cp "$MW/target-m3-${mode}.map" "$D/target-m3-${mode}.map"
    run "m7-config-m3-${mode}" "cat $D/config.yml"
done

# m8: 真实运行 Microwalk（on 臂）
for mode in on off; do
    D="$MW/$mode"
    W="$MW/work-${mode}"
    mkdir -p "$W/work/target-m3-${mode}" "$W/persist/target-m3-${mode}"
    run "m8-microwalk-run-m3-${mode}" "cd $D && TESTCASE_DIRECTORY=$MW/testcases TARGET_NAME=target-m3-${mode} WORK_DIR=$W PIN_PATH='$PINROOT' PINTOOL='$PINTOOL' dotnet '$MICROWALK_DIR/Microwalk.dll' $D/config.yml -p '$PLUGIN_DIR'"
done

# m9: 原始报告与轨迹站点
for mode in on off; do
    W="$MW/work-${mode}"
    run "m9-report-m3-${mode}" "find $W -type f | sort | head -40; echo '--- report txt ---'; cat $W/persist/target-m3-${mode}/results/call-stacks.txt 2>/dev/null | head -80; echo '--- report json head ---'; head -c 3000 $W/persist/target-m3-${mode}/results/call-stacks.json 2>/dev/null"
done

printf 'm3_microwalk_run_complete\n'
