#!/usr/bin/env bash
# cryProject WSL2 跨环境复现脚本（不锁频、不写 sysfs、不调用锁频控制器）
# 用法：bash wsl_repro.sh <阶段>    阶段：check deps fetch build verify p0m1 p0m5 p1opt p1perf p2m4 p2m2 stats pack all status
# 环境变量：WORK（默认 ~/cry-wsl）  CPU（绑核编号，默认最后一个逻辑核）  SAMPLES（每类，默认 20000，上限 20000）
#           REPEATS（每个种子重复次数，默认 3）  QUICK=1（每类 2000、重复 1，用于试跑）  FORCE=1（重做已完成阶段）
# 幂等：每个阶段完成后写 $OUT/.stamps/<阶段>.done，再次运行自动跳过；中断后重跑同一命令即可续跑。
# 不修改仓库内任何源码；只在 vendor/ 下放取件（被 .gitignore 排除），在 $WORK 下放构建与结果。
set -uo pipefail
shopt -s nullglob

WORK=${WORK:-$HOME/cry-wsl}
REPO=$WORK/repo
OUT=$WORK/out
BASE_COMMIT=${BASE_COMMIT:-04baad4}
REPO_URL=${REPO_URL:-https://github.com/Gowin-liuyin/cryProject.git}
CC_BIN=${CC_BIN:-clang-18}
NPROC=$(nproc)
CPU=${CPU:-$((NPROC - 1))}
JOBS=${JOBS:-$(( NPROC > 8 ? 8 : NPROC ))}
if [ "${QUICK:-0}" = 1 ]; then SAMPLES=${SAMPLES:-2000}; REPEATS=${REPEATS:-1}; else SAMPLES=${SAMPLES:-20000}; REPEATS=${REPEATS:-3}; fi
SEEDS="31337 424242 7"
OPTS="O0 O2 O3 Os"
LIBOQS_FIX_COMMIT=982c762c242ef549c914891b47bf6e0ed6321f91

mkdir -p "$OUT/logs" "$OUT/.stamps" "$OUT/raw" "$OUT/env" "$OUT/disasm" "$OUT/memcheck" "$OUT/stats" "$OUT/perf"
LOG="$OUT/logs/wsl_repro-$(date +%Y%m%dT%H%M%S)-${1:-none}.log"
exec > >(tee -a "$LOG") 2>&1

say()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
err()  { say "错误：$*"; printf '%s\t%s\t%s\n' "$(date -Iseconds)" "${PHASE:-?}" "$*" >> "$OUT/ERRORS.tsv"; }
done_p(){ [ "${FORCE:-0}" != 1 ] && [ -f "$OUT/.stamps/$1.done" ]; }
mark()  { date -Iseconds > "$OUT/.stamps/$1.done"; say "阶段 $1 完成"; }
freq_snap() { # $1 标签
  { echo "## $1 $(date -Iseconds)"; grep -E '^cpu MHz' /proc/cpuinfo || echo "cpu MHz 不可读"; uptime; } >> "$OUT/env/freq_snapshots.txt"; }
pin()   { taskset -c "$CPU" "$@"; }
B_PLAT=$WORK/build/platform
B_M1U=$WORK/build/m1-unfixed-Os
B_M1F=$WORK/build/m1-fixed-Os

phase_check() {
  PHASE=check; say "== 前置检查 =="
  grep -qi microsoft /proc/version && say "检测到 WSL 内核：$(uname -r)" || say "警告：未检测到 WSL（可在普通 Linux 上运行，但请在 RESULT.md 写明）"
  case "$WORK" in /mnt/*) err "WORK 在 /mnt 下（Windows 盘，9p 文件系统，慢且计时噪声大）。请改用 ~ 下目录。"; exit 1;; esac
  df -h "$HOME" | tail -1
  [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] 2>/dev/null && say "cpufreq 可写（少见于 WSL）。本脚本仍不调频。" || say "cpufreq 不可写/不存在：符合 WSL 预期，本流程按『不锁频』运行。"
  say "逻辑核数 $NPROC，绑核 CPU=$CPU，每类样本 $SAMPLES，每种子重复 $REPEATS"
  mark check
}

phase_deps() {
  done_p deps && { say "deps 已完成，跳过"; return; }
  PHASE=deps; say "== 安装依赖（需要 sudo）=="
  sudo apt-get update -y || say "警告：apt update 有错误（镜像临时故障时常见），继续尝试安装；若安装失败请稍后重跑 deps"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    clang-18 llvm-18 cmake make git curl ca-certificates patch valgrind binutils util-linux \
    python3 openssl perl procps || { err "apt install 失败"; return 1; }
  command -v "$CC_BIN" >/dev/null || { err "找不到 $CC_BIN"; return 1; }
  mark deps
}

phase_fetch() {
  done_p fetch && { say "fetch 已完成，跳过"; return; }
  PHASE=fetch; say "== 获取仓库与第三方件（处理 BLOCKERS B05）=="
  if [ ! -d "$REPO/.git" ]; then git clone "$REPO_URL" "$REPO" || { err "git clone 失败"; return 1; }; fi
  git -C "$REPO" fetch -q origin || true
  git -C "$REPO" checkout -q "$BASE_COMMIT" || { err "checkout $BASE_COMMIT 失败"; return 1; }
  say "仓库 HEAD：$(git -C "$REPO" rev-parse HEAD)"
  ( cd "$REPO" && sh tools/fetch_liboqs_0.10.0.sh ) || { err "liboqs 0.10.0 取件失败"; return 1; }
  if [ ! -f "$REPO/vendor/liboqs-0.10.0-982c762/.patched" ]; then
    rm -rf "$REPO/vendor/liboqs-0.10.0-982c762"
    cp -a "$REPO/vendor/liboqs-0.10.0" "$REPO/vendor/liboqs-0.10.0-982c762"
    curl -fsSL -o "$OUT/env/liboqs-982c762.patch" "https://github.com/open-quantum-safe/liboqs/commit/${LIBOQS_FIX_COMMIT}.patch" || { err "下载 982c762 补丁失败"; return 1; }
    sha256sum "$OUT/env/liboqs-982c762.patch" | tee "$OUT/env/liboqs-982c762.patch.sha256"
    ( cd "$REPO/vendor/liboqs-0.10.0-982c762" && patch -p1 -s < "$OUT/env/liboqs-982c762.patch" ) || { err "打 982c762 补丁失败"; return 1; }
    grep -q cmov_int16 "$REPO/vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c" || { err "补丁后 poly.c 无 cmov_int16"; return 1; }
    touch "$REPO/vendor/liboqs-0.10.0-982c762/.patched"
  fi
  if [ ! -d "$REPO/vendor/kyber-kyberslash-unfixed" ]; then
    ( cd "$REPO" && sh docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh ) || err "M2 vendor 取件失败（M2 将跳过，不影响 P0/P1）"
  fi
  if [ ! -f "$REPO/third_party/dudect/src/dudect.h" ]; then
    git clone -q https://github.com/oreparaz/dudect.git "$REPO/third_party/dudect" && \
    git -C "$REPO/third_party/dudect" checkout -q dc269651fb2567e46755cfb2a13d3875592968b5 || err "dudect 取件失败（dudect 将跳过）"
  fi
  mark fetch
}

build_m1() { # $1 unfixed|fixed  $2 优化级别 Os/O0/O2/O3
  local v=$1 o=$2 b=$WORK/build/m1-$1-$2 src=$REPO/vendor/liboqs-0.10.0
  [ "$v" = fixed ] && src=$REPO/vendor/liboqs-0.10.0-982c762
  [ -x "$b/historical/measure" ] && [ "${FORCE:-0}" != 1 ] && return 0
  ( cd "$REPO" && cmake --preset historical-clangover -B "$b" -DCMAKE_C_COMPILER="$CC_BIN" \
      -DLIBOQS010_SOURCE_DIR="$src" "-DLIBOQS010_C_FLAGS=-$o -fno-vectorize" ) > "$OUT/logs/cfg-m1-$v-$o.log" 2>&1 || { err "M1 $v $o 配置失败"; return 1; }
  cmake --build "$b" -j "$JOBS" > "$OUT/logs/build-m1-$v-$o.log" 2>&1 || { err "M1 $v $o 构建失败"; return 1; }
}
build_m5() { # $1 优化级别
  local o=$1 b=$WORK/build/m5-$1
  [ -x "$b/reference/measure" ] && [ "${FORCE:-0}" != 1 ] && return 0
  cmake -S "$REPO" -B "$b" -DCMAKE_C_COMPILER="$CC_BIN" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=OFF \
     "-DCMAKE_C_FLAGS_RELWITHDEBINFO=-$o -g -DNDEBUG" -DBUILD_TESTING=OFF > "$OUT/logs/cfg-m5-$o.log" 2>&1 || { err "M5 $o 配置失败"; return 1; }
  cmake --build "$b" -j "$JOBS" --target reference_measure > "$OUT/logs/build-m5-$o.log" 2>&1 || { err "M5 $o 构建失败"; return 1; }
}

phase_build() {
  done_p build && { say "build 已完成，跳过"; return; }
  PHASE=build; say "== 构建 =="
  if [ ! -x "$B_PLAT/platform_stats" ] || [ "${FORCE:-0}" = 1 ]; then
    cmake -S "$REPO" -B "$B_PLAT" -DCMAKE_C_COMPILER="$CC_BIN" -DOPENSSL_EXECUTABLE="$(command -v openssl)" \
      -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF > "$OUT/logs/cfg-platform.log" 2>&1 || { err "平台配置失败"; return 1; }
    cmake --build "$B_PLAT" -j "$JOBS" > "$OUT/logs/build-platform.log" 2>&1 || { err "平台构建失败"; return 1; }
  fi
  build_m1 unfixed Os && build_m1 fixed Os || return 1
  mark build
}

phase_verify() {
  done_p verify && { say "verify 已完成，跳过"; return; }
  PHASE=verify; say "== 正确性验证（CTest / KAT）=="
  ctest --test-dir "$B_PLAT" --output-on-failure > "$OUT/logs/ctest-platform.log" 2>&1; say "平台：$(grep -E 'tests passed' "$OUT/logs/ctest-platform.log")"
  for v in unfixed fixed; do
    ctest --test-dir "$WORK/build/m1-$v-Os" --output-on-failure > "$OUT/logs/ctest-m1-$v.log" 2>&1; say "M1 $v：$(grep -E 'tests passed' "$OUT/logs/ctest-m1-$v.log")"
  done
  grep -hE 'tests passed' "$OUT"/logs/ctest-*.log > "$OUT/stats/ctest_summary.txt"
  if [ "$(wc -l < "$OUT/stats/ctest_summary.txt")" -lt 3 ] || grep -qv ' 0 tests failed' "$OUT/stats/ctest_summary.txt"; then
    err "CTest 有失败或缺结果，见 logs/ctest-*.log（继续执行，但须在 RESULT.md 写明）"; fi
  mark verify
}

disasm_m1() { # $1 build dir  $2 out name
  objdump -d --no-show-raw-insn "$1/historical/measure" | awk '/<pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:/{f=1} f&&/^$/{f=0} f' > "$OUT/disasm/$2.s"
  printf '%s\tbt=%s\tjae=%s\tsetb=%s\tcmov_call=%s\tcond_jumps=%s\n' "$2" \
    "$(grep -cE '\sbt\s' "$OUT/disasm/$2.s")" "$(grep -cE '\sjae\s' "$OUT/disasm/$2.s")" "$(grep -cE '\ssetb\s' "$OUT/disasm/$2.s")" \
    "$(grep -c 'cmov_int16' "$OUT/disasm/$2.s")" "$(grep -cE '\sj(e|ne|ae|b|be|a|s|ns)\s' "$OUT/disasm/$2.s")" >> "$OUT/disasm/SUMMARY.tsv"
}
memcheck_m1() { # $1 build dir  $2 name
  "$CC_BIN" -O2 -g -std=c11 -DBASELINE_HISTORICAL=1 -I"$REPO/include" -I"$1/liboqs010-install/include" \
     "$REPO/tools/historical_poison.c" "$1/historical/libmlkem.a" "$1/liboqs010-install/lib/liboqs.a" -o "$WORK/build/poison-$2" \
     || { err "poison $2 编译失败"; return 1; }
  valgrind "$WORK/build/poison-$2" > "$OUT/memcheck/$2.log" 2>&1
  printf '%s\t%s\n' "$2" "$(grep 'ERROR SUMMARY' "$OUT/memcheck/$2.log" | sed 's/==[0-9]*== //')" >> "$OUT/memcheck/SUMMARY.tsv"
}
collect() { # $1 tag  $2 measure 程序   采集：种子 × 重复
  local tag=$1 bin=$2 s r name
  for s in $SEEDS; do for r in $(seq 1 "$REPEATS"); do
    name="$tag-s$s-r$r"; [ -f "$OUT/raw/$name.csv" ] && continue
    freq_snap "before $name"
    pin "$bin" "$name" "$s" "$SAMPLES" "$OUT/raw/$name.csv.part" "$OUT/raw/$name.meta" > "$OUT/logs/run-$name.log" 2>&1 \
      && mv "$OUT/raw/$name.csv.part" "$OUT/raw/$name.csv" || { err "采集 $name 失败"; rm -f "$OUT/raw/$name.csv.part" "$OUT/raw/$name.meta"; }
    freq_snap "after $name"
  done; done
}

phase_p0m1() {
  done_p p0m1 && { say "p0m1 已完成，跳过"; return; }
  PHASE=p0m1; say "== P0：M1 liboqs 0.10.0 未修 vs 982c762，-Os，message-zero vs message-ones =="
  disasm_m1 "$B_M1U" m1-unfixed-Os; disasm_m1 "$B_M1F" m1-fixed-Os
  memcheck_m1 "$B_M1U" m1-unfixed-Os; memcheck_m1 "$B_M1F" m1-fixed-Os
  collect m1-unfixed-Os "$B_M1U/historical/measure"
  collect m1-fixed-Os   "$B_M1F/historical/measure"
  if [ -f "$REPO/third_party/dudect/src/dudect.h" ]; then
    for v in unfixed fixed; do
      b=$WORK/build/m1-$v-Os; [ -f "$OUT/raw/dudect-m1-$v-Os.log" ] && continue
      "$CC_BIN" -O2 -g -std=c11 -DBASELINE_HISTORICAL=1 -I"$REPO/include" -I"$REPO/third_party/dudect/src" -I"$b/liboqs010-install/include" \
        "$REPO/tools/historical_dudect.c" "$b/historical/libmlkem.a" "$b/liboqs010-install/lib/liboqs.a" -lm -o "$WORK/build/hdudect-$v" \
        && pin "$WORK/build/hdudect-$v" > "$OUT/raw/dudect-m1-$v-Os.log" 2>&1 || err "M1 $v dudect 失败"
    done
  fi
  mark p0m1
}

phase_p0m5() {
  done_p p0m5 && { say "p0m5 已完成，跳过"; return; }
  PHASE=p0m5; say "== P0：M5 mlkem-native 参考实现（阴性对照，默认 -O2）=="
  collect m5-O2default "$B_PLAT/reference/measure"
  [ -x "$B_PLAT/platform_m5_dudect" ] && { [ -f "$OUT/raw/dudect-m5.csv" ] || pin "$B_PLAT/platform_m5_dudect" --collect --seed 31337 --raw "$OUT/raw/dudect-m5.csv" > "$OUT/raw/dudect-m5.log" 2>&1 || err "M5 dudect 失败"; }
  mark p0m5
}

phase_p1opt() {
  done_p p1opt && { say "p1opt 已完成，跳过"; return; }
  PHASE=p1opt; say "== P1：-O0/-O2/-O3/-Os 四级（M1 两版 + M5）=="
  local o v
  for o in $OPTS; do
    for v in unfixed fixed; do
      build_m1 $v $o || continue
      [ "$o" = Os ] || { disasm_m1 "$WORK/build/m1-$v-$o" "m1-$v-$o"; memcheck_m1 "$WORK/build/m1-$v-$o" "m1-$v-$o"; }
      [ "$o" = Os ] || collect "m1-$v-$o" "$WORK/build/m1-$v-$o/historical/measure"
    done
    build_m5 $o || continue
    objdump -d --no-show-raw-insn "$WORK/build/m5-$o/reference/measure" | awk '/<baseline_native_poly_frommsg>:/{f=1} f&&/^$/{f=0} f' > "$OUT/disasm/m5-$o.s"
    printf 'm5-%s\tcond_jumps=%s\n' "$o" "$(grep -cE '\sj(e|ne|ae|b|be|a|s|ns)\s' "$OUT/disasm/m5-$o.s")" >> "$OUT/disasm/SUMMARY.tsv"
    collect "m5-$o" "$WORK/build/m5-$o/reference/measure"
  done
  mark p1opt
}

phase_p1perf() {
  done_p p1perf && { say "p1perf 已完成，跳过"; return; }
  PHASE=p1perf; say "== P1：性能（完整 decaps/keygen/encaps，防护前后）=="
  local STRICT="-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror"
  build_arm() { # $1 名 $2 libmlkem.a $3 额外库
    # shellcheck disable=SC2086
    "$CC_BIN" $STRICT -DPERF_ARM_NAME="\"$1\"" -DPERF_BUILD_FLAGS="\"$CC_BIN -O2\"" -I "$REPO/include" \
      "$REPO/tools/platform_perf/perf_measure.c" -o "$WORK/build/perf-$1" "$2" ${3:-} -lm -lpthread || { err "perf 臂 $1 编译失败"; return 1; }
  }
  build_arm m1unfixed "$B_M1U/historical/libmlkem.a" "$B_M1U/liboqs010-install/lib/liboqs.a"
  build_arm m1fixed   "$B_M1F/historical/libmlkem.a" "$B_M1F/liboqs010-install/lib/liboqs.a"
  build_arm m5ref     "$B_PLAT/reference/libmlkem.a"
  local blk arm
  for blk in 1 2 3 4; do for arm in m1unfixed m1fixed m5ref; do   # ABAB 交错，抵消漂移
    f="$OUT/perf/perf-$arm-b$blk.csv"; [ -f "$f" ] && continue
    freq_snap "before perf $arm b$blk"
    pin "$WORK/build/perf-$arm" --run-id "perf-$arm-b$blk" --seed 31337 --raw "$f" --meta "${f%.csv}.meta" \
      --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 --arm "$arm" --block-index $((blk-1)) --block-count 4 --order-seed 2026 \
      > "$OUT/logs/perf-$arm-b$blk.log" 2>&1 || err "perf $arm b$blk 失败"
  done; done
  mark p1perf
}

phase_p2m4() {
  done_p p2m4 && { say "p2m4 已完成，跳过"; return; }
  PHASE=p2m4; say "== P2：M4 人工构造校准 vulnerable vs ct =="
  local a s r n
  for a in vulnerable ct; do for s in $SEEDS; do for r in $(seq 1 "$REPEATS"); do
    n="m4-$a-s$s-r$r"; [ -f "$OUT/raw/$n.csv" ] && continue
    pin "$B_PLAT/platform_m4_measure_$a" --collect "$OUT/raw/$n.csv" "$SAMPLES" "$s" "$n" --compare-bytes 32 > "$OUT/logs/run-$n.log" 2>&1 || err "$n 失败"
  done; done
    [ -x "$B_PLAT/platform_m4_dudect_$a" ] && { [ -f "$OUT/raw/dudect-m4-$a.csv" ] || pin "$B_PLAT/platform_m4_dudect_$a" --collect "$OUT/raw/dudect-m4-$a.csv" 10 31337 > "$OUT/raw/dudect-m4-$a.log" 2>&1 || err "M4 $a dudect 失败"; }
  done
  mark p2m4
}

phase_p2m2() {
  done_p p2m2 && { say "p2m2 已完成，跳过"; return; }
  PHASE=p2m2; say "== P2：M2 KyberSlash 历史 Kyber768 未修 vs 已修（平台 measure 臂）=="
  if [ ! -x "$B_PLAT/platform-m2/unfixed/measure" ]; then
    say "平台构建里没有 M2 臂（vendor 未取到？先跑 fetch 再 FORCE=1 跑 build）"; err "M2 臂缺失，跳过"; mark p2m2; return; fi
  collect m2-unfixed "$B_PLAT/platform-m2/unfixed/measure"
  collect m2-fixed   "$B_PLAT/platform-m2/fixed/measure"
  mark p2m2
}

phase_stats() {
  PHASE=stats; say "== 统计（仓库 platform_stats 电池 + 合并/分位数/性能汇总）=="
  local f n cls
  for f in "$OUT"/raw/*.csv; do
    n=$(basename "$f" .csv); case "$n" in dudect-*) continue;; esac
    [ -f "$OUT/stats/runs/$n/ci_welch.json" ] && continue
    case "$n" in m4-*) cls="mismatch-first mismatch-last";; *) cls="message-zero message-ones";; esac
    mkdir -p "$OUT/stats/runs"
    # shellcheck disable=SC2086
    sh "$REPO/scripts/run_stats_battery.sh" --input "$f" --format measure --classes $cls \
      --output-dir "$OUT/stats/runs/$n" --stats-bin "$B_PLAT/platform_stats" > "$OUT/logs/stats-$n.log" 2>&1 || err "统计 $n 失败"
  done
  python3 "$OUT/analyze_wsl.py" "$OUT" || err "汇总脚本失败"
  say "汇总表：$OUT/stats/SUMMARY.md"
}

phase_env() {
  PHASE=env; local E="$OUT/env/ENV.txt"
  { echo "# 环境记录 $(date -Iseconds)"
    echo "## Windows"; (cmd.exe /c ver 2>/dev/null | tr -d '\r') || echo "cmd.exe 不可用"
    (powershell.exe -NoProfile -Command "powercfg /getactivescheme; (Get-CimInstance Win32_Processor | Select Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | Format-List | Out-String); (Get-CimInstance Win32_Battery | Select BatteryStatus | Format-List | Out-String)" 2>/dev/null | tr -d '\r') || echo "powershell.exe 不可用"
    (wsl.exe --version 2>/dev/null | tr -d '\r\0') || echo "wsl.exe --version 不可用"
    echo "## WSL/Linux"; uname -a; cat /proc/version; cat /etc/os-release
    echo "## CPU"; lscpu; echo "nproc=$(nproc)  绑核 CPU=$CPU"
    echo "## 内存"; free -h; echo "## 磁盘"; df -h "$WORK"
    echo "## 编译器/工具"; "$CC_BIN" --version | head -1; gcc --version 2>/dev/null | head -1; cmake --version | head -1; valgrind --version; python3 --version; openssl version
    echo "## 计时源"; cat /sys/devices/system/clocksource/clocksource0/current_clocksource 2>/dev/null; cat /sys/devices/system/clocksource/clocksource0/available_clocksource 2>/dev/null
    grep -m1 -E 'clock_resolution_ns' "$OUT"/raw/*.meta 2>/dev/null | head -1
    echo "## 频率管理"; ls /sys/devices/system/cpu/cpu0/cpufreq 2>&1 | head -3; echo "（WSL2 下通常不存在 → 不锁频、不关 boost）"
    echo "## 负载"; uptime; ps -eo pcpu,pmem,comm --sort=-pcpu | head -15
    echo "## .wslconfig"; (cat "/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')/.wslconfig" 2>/dev/null) || echo "未读取到 .wslconfig"
    echo "## 仓库"; git -C "$REPO" rev-parse HEAD 2>/dev/null; git -C "$REPO" status --short 2>/dev/null | head -20
  } > "$E" 2>&1
  freq_snap "env"
  say "环境记录：$E"
}

phase_pack() {
  PHASE=pack; phase_env
  [ -f "$OUT/RESULT.md" ] || cp "$OUT/RESULT_TEMPLATE.md" "$OUT/RESULT.md" 2>/dev/null || true
  local name="wsl-repro-$(hostname)-$(date +%Y%m%d).tar.gz"
  ( cd "$WORK" && tar --exclude='out/raw/*.csv.part' --exclude='out/stats/runs/*/normalized.csv' --exclude='out/stats/runs/*/input.csv' -czf "$name" out ) && say "完整回传包（含原始 CSV）：$WORK/$name（$(du -h "$WORK/$name" | cut -f1)）"
  local lite="wsl-repro-lite-$(hostname)-$(date +%Y%m%d).tar.gz"
  ( cd "$WORK" && tar --exclude='out/raw/*.csv' --exclude='out/raw/*.csv.part' --exclude='out/perf/*.csv' --exclude='out/stats/runs/*/normalized.csv' --exclude='out/stats/runs/*/input.csv' -czf "$lite" out ) && say "精简回传包（无原始 CSV，便于聊天发送）：$WORK/$lite（$(du -h "$WORK/$lite" | cut -f1)）"
}

phase_status() { ls -1 "$OUT/.stamps" 2>/dev/null; [ -f "$OUT/ERRORS.tsv" ] && { echo "--- 错误记录 ---"; cat "$OUT/ERRORS.tsv"; }; }

# ---------- 汇总分析脚本（纯 Python 标准库）----------
write_analyzer() {
cat > "$OUT/analyze_wsl.py" <<'PY'
import csv, json, math, os, sys, glob, random, re
from collections import defaultdict
OUT = sys.argv[1]
def q(xs, p):  # 与仓库 reference-benchmark 相同的零基下标，不插值
    return xs[int(math.floor(p * (len(xs) - 1) + 0.5))]
def load(path, c0, c1):
    a, b = [], []
    with open(path) as f:
        for r in csv.DictReader(f):
            if r['input_category'] == c0: a.append(int(r['elapsed_nanoseconds']))
            elif r['input_category'] == c1: b.append(int(r['elapsed_nanoseconds']))
    return a, b
def mv(x):
    m = sum(x) / len(x); return m, sum((v - m) ** 2 for v in x) / (len(x) - 1)
lines = ["# WSL 复现统计汇总（自动生成）", "",
         "Δ = 类0 均值 − 类1 均值（M1/M2/M5：message-zero − message-ones；M4：mismatch-first − mismatch-last）。",
         "Welch 95% CI 为正态近似（z=1.96），与仓库 platform_stats 一致；每行同时给出仓库电池 ci_welch.json 的 Δ 以便核对。",
         "不锁频虚拟化环境：仅作跨环境描述，不进任何 Holm 家族。", "",
         "## 逐次运行", "", "| run | n/类 | Δ ns | 95% CI | Welch p | 电池 Δ | 中位数差 | p90 差 | p99 差 |", "|---|---|---|---|---|---|---|---|---|"]
groups = defaultdict(list)
for path in sorted(glob.glob(os.path.join(OUT, 'raw', '*.csv'))):
    run = os.path.basename(path)[:-4]
    if run.startswith('dudect'): continue
    c0, c1 = ('mismatch-first', 'mismatch-last') if run.startswith('m4-') else ('message-zero', 'message-ones')
    a, b = load(path, c0, c1)
    if len(a) < 2 or len(b) < 2: continue
    ma, va = mv(a); mb, vb = mv(b); d = ma - mb; se = math.sqrt(va / len(a) + vb / len(b))
    z = d / se if se > 0 else 0.0; p = math.erfc(abs(z) / math.sqrt(2))
    sa, sb = sorted(a), sorted(b)
    bat = ''
    j = os.path.join(OUT, 'stats', 'runs', run, 'ci_welch.json')
    if os.path.exists(j):
        bat = '%.2f' % json.load(open(j)).get('mean_difference_class0_minus_class1_ns', float('nan'))
    lines.append('| %s | %d | %.2f | [%.2f, %.2f] | %.3g | %s | %d | %d | %d |' % (run, len(a), d, d - 1.96 * se, d + 1.96 * se, p, bat,
                 q(sa, .5) - q(sb, .5), q(sa, .9) - q(sb, .9), q(sa, .99) - q(sb, .99)))
    groups[re.sub(r'-s\d+-r\d+$', '', run)].append((d, se))
lines += ["", "## 按臂固定效应合并（逆方差加权；同臂所有种子与重复）", "", "| 臂 | 运行数 | 合并 Δ ns | 95% CI | z | 同号运行数 |", "|---|---|---|---|---|---|"]
for g, rs in sorted(groups.items()):
    w = [1 / se ** 2 for _, se in rs if se > 0]
    if not w: continue
    m = sum(wi * d for wi, (d, _) in zip(w, rs)) / sum(w); s = 1 / math.sqrt(sum(w))
    pos = sum(1 for d, _ in rs if d > 0)
    lines.append('| %s | %d | %.2f | [%.2f, %.2f] | %.2f | +%d / −%d |' % (g, len(rs), m, m - 1.96 * s, m + 1.96 * s, m / s, pos, len(rs) - pos))
# 性能
perf = defaultdict(lambda: defaultdict(list))
for path in glob.glob(os.path.join(OUT, 'perf', 'perf-*.csv')):
    arm = re.sub(r'^perf-|-b\d+\.csv$', '', os.path.basename(path))
    with open(path) as f:
        for r in csv.DictReader(f):
            perf[arm][r['input_category']].append(int(r['elapsed_nanoseconds']))
if perf:
    lines += ["", "## 性能（ns；不锁频）", "", "| 臂 | 操作 | n | 均值 | 中位数 | p90 | p99 |", "|---|---|---|---|---|---|---|"]
    for arm in sorted(perf):
        for op in sorted(perf[arm]):
            x = sorted(perf[arm][op]); lines.append('| %s | %s | %d | %.1f | %d | %d | %d |' % (arm, op, len(x), sum(x) / len(x), q(x, .5), q(x, .9), q(x, .99)))
    if 'm1unfixed' in perf and 'm1fixed' in perf:
        a = perf['m1unfixed'].get('decaps', []); b = perf['m1fixed'].get('decaps', [])
        if a and b:
            rnd = random.Random(2026); sa, sb = sorted(a), sorted(b)
            ov_mean = (sum(b) / len(b)) / (sum(a) / len(a)) - 1; boots = []
            for _ in range(1000):
                ra = [a[rnd.randrange(len(a))] for _ in range(len(a))]; rb = [b[rnd.randrange(len(b))] for _ in range(len(b))]
                boots.append((sum(rb) / len(rb)) / (sum(ra) / len(ra)) - 1)
            boots.sort()
            lines += ["", "M1 decaps 防护开销（已修相对未修）：均值 %+.3f%%（bootstrap 1000 次 95%% CI [%+.3f%%, %+.3f%%]）；中位数 %+.3f%%；p90 %+.3f%%；p99 %+.3f%%" % (
                100 * ov_mean, 100 * boots[25], 100 * boots[974], 100 * (q(sb, .5) / q(sa, .5) - 1), 100 * (q(sb, .9) / q(sa, .9) - 1), 100 * (q(sb, .99) / q(sa, .99) - 1))]
# dudect
lines += ["", "## dudect（族外，阈值 t>10）", ""]
for path in sorted(glob.glob(os.path.join(OUT, 'raw', 'dudect-*.log'))):
    txt = open(path, errors='replace').read().strip().splitlines()
    ts = [float(m.group(1)) for l in txt for m in [re.search(r'max t:\s*([+-]?[\d.]+)', l)] if m]
    tail = [l for l in txt if l.startswith(('stopped_after', 'battery_dudect', 'completed_batches'))]
    lines.append('- %s：最后 max t = %s；%s' % (os.path.basename(path), ('%+.2f' % ts[-1]) if ts else 'n/a', '；'.join(tail)))
for name in ('disasm/SUMMARY.tsv', 'memcheck/SUMMARY.tsv'):
    p = os.path.join(OUT, name)
    if os.path.exists(p):
        lines += ["", "## " + name, "", "```", open(p).read().strip(), "```"]
open(os.path.join(OUT, 'stats', 'SUMMARY.md'), 'w').write('\n'.join(lines) + '\n')
print('\n'.join(lines))
PY
}

write_template() {
[ -f "$OUT/RESULT_TEMPLATE.md" ] && return
cat > "$OUT/RESULT_TEMPLATE.md" <<'MD'
# WSL2 跨环境复现结果（队友机器）

- 执行人 / 日期：
- 仓库提交：（ENV.txt 中的 HEAD）
- 环境一句话：Windows __ / WSL2 内核 __ / Ubuntu __ / CPU __（__ 核）/ clang __ / 电源模式 __ / 是否插电 __
- 频率管理：**未锁频**（WSL2 无 cpufreq 接口），绑核 taskset -c __（vCPU，非物理核）

## 1. 正确性
| 构建 | CTest 通过/总数 | 备注 |
|---|---|---|

## 2. 采集与统计（摘自 stats/SUMMARY.md）
| 项 | 结果 | 与裸金属（nss-marker）方向是否一致 | 备注 |
|---|---|---|---|
| P0 M1 -Os 未修 | | | |
| P0 M1 -Os 已修 | | | |
| P0 M5 | | | |
| P1 四级反汇编/Memcheck | | | |
| P1 四级计时 | | | |
| P1 性能 | | | |
| P2 M4 vulnerable / ct（人工构造校准） | | | |
| P2 M2 | | | |

## 3. 未完成项与错误（如实；照抄 ERRORS.tsv 并说明）

## 4. 口径声明
不锁频虚拟化环境下的结果只作跨环境描述，不进任何 Holm 家族；未检出不等于常数时间；不与裸金属数据合并。
MD
}

write_analyzer; write_template
case "${1:-}" in
  check) phase_check;; deps) phase_deps;; fetch) phase_fetch;; build) phase_build;; verify) phase_verify;;
  p0m1) phase_p0m1;; p0m5) phase_p0m5;; p1opt) phase_p1opt;; p1perf) phase_p1perf;; p2m4) phase_p2m4;; p2m2) phase_p2m2;;
  stats) phase_stats;; env) phase_env;; pack) phase_pack;; status) phase_status;;
  all) phase_check && phase_deps && phase_fetch && phase_build && phase_env && phase_verify && phase_p0m1 && phase_p0m5 && \
       phase_p1opt && phase_p1perf && phase_p2m4 && phase_p2m2; phase_stats; phase_pack;;
  *) sed -n 2,7p "$0"; exit 2;;
esac
