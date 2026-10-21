#!/bin/sh
# 构建 T25 网络场景用的三套 network_client / network_server。
#
# 臂：
#   m5ref      mlkem-native 参考路径（仓库默认，无额外依赖）
#   m1unfixed  liboqs 0.10.0 未修（GHSA-f2v9-5498-2vpp / clangover 形态）
#   m1fixed    liboqs 0.10.0 + 官方修复 982c762
#
# 用法：build_network_arms.sh <SOURCE_ROOT> <RUNS_ROOT> <SHORT_COMMIT>
#   SOURCE_ROOT  已放好源码与 vendor/liboqs-0.10.0 的目录
#   RUNS_ROOT    本次运行的输出根（必须新建）
#   SHORT_COMMIT 源码短提交号，用于目录命名
#
# 约束：
#   * 每个臂的构建目录独立，产物不混用。
#   * M1 两版各用一份独立的 liboqs 树：未修树取 vendor/liboqs-0.10.0 原字节；
#     已修树是同版本的副本并打上 docs/patches/liboqs-982c762.patch，不改 vendor 下的原树。
#   * 临时文件与缓存都在 RUNS_ROOT 之下，不写 /tmp。
#   * 修复臂的 liboqs 树不改写原树，用独立目录并记录补丁应用日志。
set -eu

if [ "$#" -ne 3 ]; then
    printf 'usage: %s SOURCE_ROOT RUNS_ROOT SHORT_COMMIT\n' "$0" >&2
    exit 2
fi

source_root=$(realpath "$1")
runs_root=$2
short_commit=$3

case "${runs_root}" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf 'Require runs root under Cry.\n' >&2; exit 2 ;;
esac
if [ -e "${runs_root}" ]; then
    printf 'Runs root must be new.\n' >&2
    exit 2
fi
mkdir -p "${runs_root}"
runs_root=$(realpath "${runs_root}")
export TMPDIR="${runs_root}/tmp"
export TMP="${TMPDIR}"
export TEMP="${TMPDIR}"
export XDG_CACHE_HOME="${runs_root}/cache"
mkdir -p "${TMPDIR}" "${XDG_CACHE_HOME}"

patch_file="${source_root}/docs/patches/liboqs-982c762.patch"
vendor_tree="${source_root}/vendor/liboqs-0.10.0"
if [ ! -d "${vendor_tree}" ]; then
    printf 'Missing vendor/liboqs-0.10.0; run tools/fetch_liboqs_0.10.0.sh first.\n' >&2
    exit 1
fi

# 已修臂的独立 liboqs 树：复制原树后打补丁，原树不动。
fixed_tree="${runs_root}/liboqs-0.10.0-fixed"
printf 'copying vendor tree for the fixed arm...\n'
cp -a "${vendor_tree}" "${fixed_tree}"
printf 'applying 982c762 to the fixed arm tree...\n'
if [ ! -d "${fixed_tree}/.git" ]; then
    # 非 git 副本：patch -p1 静默应用
    ( cd "${fixed_tree}" && patch -p1 --batch --forward < "${patch_file}" > "${runs_root}/patch-982c762.log" 2>&1 ) || {
        printf 'Patch application failed; see %s\n' "${runs_root}/patch-982c762.log" >&2
        exit 1
    }
else
    ( cd "${fixed_tree}" && git apply --whitespace=nowarn "${patch_file}" > "${runs_root}/patch-982c762.log" 2>&1 ) || {
        printf 'Patch application failed; see %s\n' "${runs_root}/patch-982c762.log" >&2
        exit 1
    }
fi
printf 'patch applied\n' >> "${runs_root}/patch-982c762.log"
sha256sum "${patch_file}" > "${runs_root}/patch-982c762.sha256"

# —— 通用：把 network_client / network_server 接到给定的 mlkem 库 ——
build_arms_with_library() {
    arm_name=$1
    library_target=$2
    library_dir=$3
    build_dir="${runs_root}/build-${arm_name}"
    mkdir -p "${build_dir}"
    cmake -S "${source_root}" -B "${build_dir}" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DBUILD_TESTING=ON \
        ${library_dir} \
        > "${build_dir}/cmake.log" 2>&1
    cmake --build "${build_dir}" --target network_client network_server \
        --parallel 4 > "${build_dir}/build.log" 2>&1
    printf 'built %s\n' "${arm_name}"
}

# m5ref：默认的 mlkem_reference 库，不需要额外开关。
build_arms_with_library m5ref mlkem_reference ""

# M1 两版：liboqs 0.10.0 的 ExternalProject 需要在 configure 期指定源树。
# Liboqs010Historical.cmake 把源树硬编码在 CMAKE_CURRENT_SOURCE_DIR/vendor/liboqs-0.10.0，
# 所以两个臂各用一份独立的源码根（软链其余目录、替换 vendor）。
make_historical_source_root() {
    arm_name=$1
    liboqs_tree=$2
    arm_source="${runs_root}/source-${arm_name}"
    mkdir -p "${arm_source}"
    # 链接除 vendor 外的所有顶层项，vendor 单独建真实目录。
    for entry in "${source_root}"/*; do
        base=$(basename "${entry}")
        [ "${base}" = "vendor" ] && continue
        ln -s "${entry}" "${arm_source}/${base}"
    done
    mkdir -p "${arm_source}/vendor"
    for entry in "${source_root}"/vendor/*; do
        base=$(basename "${entry}")
        [ "${base}" = "liboqs-0.10.0" ] && continue
        ln -s "${entry}" "${arm_source}/vendor/${base}"
    done
    ln -s "${liboqs_tree}" "${arm_source}/vendor/liboqs-0.10.0"
    printf '%s\n' "${arm_source}"
}

m1unfixed_source=$(make_historical_source_root m1unfixed "${vendor_tree}")
m1fixed_source=$(make_historical_source_root m1fixed "${fixed_tree}")

build_arms_with_library m1unfixed mlkem_historical \
    "-DBASELINE_ENABLE_LIBOQS010=ON -DCMAKE_SOURCE_DIR_OVERRIDE=${m1unfixed_source}"
build_arms_with_library m1fixed mlkem_historical \
    "-DBASELINE_ENABLE_LIBOQS010=ON -DCMAKE_SOURCE_DIR_OVERRIDE=${m1fixed_source}"

printf 'NETWORK_ARMS_BUILT\n'
