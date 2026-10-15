#!/bin/sh
# collector-v2 远端构建：普通与 ASan/UBSan 两个独立构建树，命令与选项固定可复现。
# usage: run_collector_build.sh <tree-root>
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: run_collector_build.sh <tree-root>" >&2
    exit 2
fi
tree_root=$1
source_dir=${tree_root}/source
sysroot=${tree_root}/dependencies/sysroot
if [ ! -d "${source_dir}/tools/platform_m2" ] || [ ! -d "${sysroot}/usr/include/openssl" ]; then
    echo "tree-root does not look like a collector-v2 tree" >&2
    exit 2
fi

configure_build() {
    build_name=$1
    shift
    printf '=== configure %s ===\n' "${build_name}"
    cmake -S "${source_dir}/tools/platform_m2" -B "${tree_root}/${build_name}" \
        -DCMAKE_C_COMPILER=/usr/bin/clang-18 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_FLAGS="-isystem ${sysroot}/usr/include/x86_64-linux-gnu" \
        -DOPENSSL_ROOT_DIR="${sysroot}/usr" \
        -DOPENSSL_INCLUDE_DIR="${sysroot}/usr/include" \
        -DOPENSSL_CRYPTO_LIBRARY=/lib/x86_64-linux-gnu/libcrypto.so.3 \
        "$@" 2>&1 | tee "${tree_root}/configure-${build_name}.log"
    printf '=== build %s ===\n' "${build_name}"
    cmake --build "${tree_root}/${build_name}" -j16 2>&1 | tee "${tree_root}/build-${build_name}.log"
    printf '=== ctest %s ===\n' "${build_name}"
    ctest --test-dir "${tree_root}/${build_name}" --output-on-failure 2>&1 |
        tee "${tree_root}/ctest-${build_name}.log"
}

configure_build build-ordinary
configure_build build-sanitize -DM2_COLLECTOR_SANITIZERS=ON
