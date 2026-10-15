#!/bin/bash
# 修正轮：测试用例字节、PLT 惰性绑定、并同时启用内存访问轨迹泄漏模块。
set -u
NEWROOT="$1"
case "$NEWROOT" in
    /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-*) ;;
    *) echo "bad root" >&2; exit 2 ;;
esac
PROBE="$NEWROOT/microwalk-probe"
REPO="$PROBE/src/Microwalk-master"
SRC="$NEWROOT/source"
PINROOT="$PROBE/pin/pin-3.28-98749-g6643ecee5-gcc-linux"
LOGS="$NEWROOT/logs"
MW="$PROBE/m3mw"
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
    printf 'step=%-44s exit=%s\n' "$name" "$status"
}

# n1: 修正测试用例（每个文件恰好 1 字节，值为输入类下标 0..4）
rm -f "$MW/testcases"/*.testcase
for idx in 0 1 2 3 4; do
    python3 -c "import sys; sys.stdout.buffer.write(bytes([$idx]))" > "$MW/testcases/t${idx}.testcase"
done
run n1-testcases-fixed "ls -la $MW/testcases/; for f in $MW/testcases/*.testcase; do printf '%s =' \"\$f\"; od -An -tu1 \"\$f\"; done"

# n2: 关闭 PLT 惰性绑定并重新链接目标
for mode in on off; do
    run "n2-relink-target-m3-${mode}" "gcc $MW/main.c $MW/m3mwtarget.c -g -fno-inline -fno-split-stack -I$SRC/include -L$MW -Wl,-rpath,$MW -Wl,-z,now -lm3${mode} -o $MW/target-m3-${mode} && cd $MAPGEN_DIR && dotnet MapFileGenerator.dll $MW/target-m3-${mode} $MW/target-m3-${mode}.map && wc -l $MW/target-m3-${mode}.map"
    cp "$MW/target-m3-${mode}" "$MW/${mode}/target-m3-${mode}"
    cp "$MW/target-m3-${mode}.map" "$MW/${mode}/target-m3-${mode}.map"
done

# n3: 干跑 wrapper（协议：'t <id>' 行 + 下一行文件路径；'e 0' 退出）
for mode in on off; do
    run "n3-dryrun-target-m3-${mode}" "printf 't 0\\n$MW/testcases/t0.testcase\\nt 4\\n$MW/testcases/t4.testcase\\ne 0\\n' | LD_LIBRARY_PATH=$MW $MW/target-m3-${mode}; echo dryrun_status=\$?"
done

# n4: 新配置：内存访问轨迹泄漏 + 控制流泄漏，禁用惰性绑定
for mode in on off; do
    D="$MW/$mode"
    cat > "$D/config2.yml" <<YAML
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
      LD_BIND_NOW: "1"
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
    - module: instruction-memory-access-trace-leakage
      module-options:
        output-directory: \$\$PERSIST_DIR\$\$/results-memory
        map-files:
          - \$\$TARGET_PATH\$\$.map
          - $MW/libm3${mode}.map

  options:
    input-buffer-size: 1
    max-parallel-threads: 1
YAML
    run "n4-config2-m3-${mode}" "cat $D/config2.yml"
done

# n5: 重跑 Microwalk
for mode in on off; do
    D="$MW/$mode"
    W="$MW/work2-${mode}"
    rm -rf "$W"
    mkdir -p "$W/work/target-m3-${mode}" "$W/persist/target-m3-${mode}"
    run "n5-microwalk2-m3-${mode}" "cd $D && TESTCASE_DIRECTORY=$MW/testcases TARGET_NAME=target-m3-${mode} WORK_DIR=$W PIN_PATH='$PINROOT' PINTOOL='$PINTOOL' dotnet '$MICROWALK_DIR/Microwalk.dll' $D/config2.yml -p '$PLUGIN_DIR'"
done

# n6: 报告
for mode in on off; do
    W="$MW/work2-${mode}"
    run "n6-report2-m3-${mode}" "find $W/persist -type f | sort; echo '--- call-stacks.txt ---'; cat $W/persist/target-m3-${mode}/results/call-stacks.txt 2>/dev/null | head -100; echo '--- memory results list ---'; ls -la $W/persist/target-m3-${mode}/results-memory/ 2>/dev/null | head -20; echo '--- memory report head ---'; for f in $W/persist/target-m3-${mode}/results-memory/*.txt; do echo \"== \$f\"; head -60 \"\$f\"; done 2>/dev/null"
done

printf 'm3_microwalk_fix2_complete\n'
