#!/bin/bash
# 复现六种 recipe 写法在 `make -j4` / `make -j` / 无参三种调用下的 jobserver 警告与并行度。
# 用法：bash run-matrix.sh [输出文件]（默认写到本目录 jobserver-matrix-results.txt）
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
INVOKE_DIR=$PWD
OUT=${1:-$HERE/jobserver-matrix-results.txt}
# 脚本会切换到临时目录，相对路径先按调用目录转成绝对路径
case "$OUT" in
/*) ;;
*) OUT="$INVOKE_DIR/$OUT" ;;
esac
export PATH="$HOME/.local/bin:$PATH"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/mk-matrix.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
cp "$HERE/CMakeLists.txt" "$HERE/Makefile" "$WORK/" || exit 1
cd "$WORK" || exit 1
cmake -S . -B build >/dev/null || exit 1
cmake -G Ninja -S . -B build-ninja >/dev/null || exit 1

{
    echo "# jobserver recipe 变体矩阵"
    echo "# 时间：$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "# make: $(make --version | head -1)"
    echo "# cmake: $(cmake --version | head -1)"
    echo "# ninja: $(ninja --version)"
    echo "# 4 个互不依赖 target 各 sleep 1s：串行约 4.2s，4 路并行约 1.1s"
    echo
    printf '%-16s %-6s %-8s %s\n' variant make real warn
    for variant in cur plus_bare plus_jobs makeflags_clear ninja_plus ninja_plain; do
        for jobs in "-j4" "-j" ""; do
            warn_text=$(make "$variant" $jobs 2>&1 | grep -iE "warning:" | head -1)
            real_seconds=$( { /usr/bin/time -p make "$variant" $jobs >/dev/null; } 2>&1 | awk '/^real/{print $2}')
            printf '%-16s %-6s %-8s %s\n' "$variant" "${jobs:-none}" "$real_seconds" "${warn_text:-(none)}"
        done
    done
} | tee "$OUT"
