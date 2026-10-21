#!/bin/sh
# final14-20261021：从实际匿名 ZIP 解出后在独立目录重跑 CMake + build + CTest。
# 只在解出目录内构建，不使用仓库本体充当本次复算。
set -eu
set -x
repository=/Users/yin/code/cryProject
archive="$repository/deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final14-20261021.zip"
extract_root="$repository/build/zip-recompute-final14-20261021"

date -u +"started_utc=%Y-%m-%dT%H:%M:%SZ"
hostname
uname -a
sysctl -n machdep.cpu.brand_string 2>/dev/null || true
cmake --version | head -1
cc --version | head -1
shasum -a 256 "$archive"
rm -rf "$extract_root"
mkdir -p "$extract_root"
unzip -q "$archive" -d "$extract_root"
ls "$extract_root" | head -20
shasum -a 256 "$extract_root/CMakeLists.txt"
cmake -S "$extract_root" -B "$extract_root/build" -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$extract_root/build" --parallel 4
ctest --test-dir "$extract_root/build" -N
ctest --test-dir "$extract_root/build" --output-on-failure
shasum -a 256 "$extract_root/data"/*.csv | head -3
date -u +"finished_utc=%Y-%m-%dT%H:%M:%SZ"
