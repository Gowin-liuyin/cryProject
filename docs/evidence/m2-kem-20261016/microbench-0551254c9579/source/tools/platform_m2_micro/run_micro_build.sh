#!/bin/sh
# M2 除法热点微基准的远端构建：普通与 ASan/UBSan 两棵独立构建树，命令与选项固定可复现。
# 源树是 collector-v2 源树的逐字节副本（SOURCE_TREE.sha256 复核 + diff -rq），
# 因此两臂 vendor、告警口径与热点编译条件与采集件一致。
# usage: run_micro_build.sh <tree-root>
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: run_micro_build.sh <tree-root>" >&2
    exit 2
fi
tree_root=$1
source_dir=${tree_root}/source
fixtures=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/qualification-ordinary/fixtures
collector_meta=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/qualification-ordinary/smoke/main_u_seed31337.meta

for required_path in "${source_dir}/tools/platform_m2_micro/CMakeLists.txt" \
    "${source_dir}/vendor/kyber-kyberslash-unfixed/ref/poly.c" \
    "${fixtures}/pk.bin" "${fixtures}/sk.bin" "${collector_meta}"; do
    if [ ! -e "${required_path}" ]; then
        echo "tree-root or frozen input missing: ${required_path}" >&2
        exit 2
    fi
done

configure_build() {
    build_name=$1
    shift
    printf '=== configure %s ===\n' "${build_name}"
    cmake -S "${source_dir}/tools/platform_m2_micro" -B "${tree_root}/${build_name}" \
        -DCMAKE_C_COMPILER=/usr/bin/clang-18 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DM2_MICRO_FIXTURE_PUBLIC_KEY="${fixtures}/pk.bin" \
        -DM2_MICRO_FIXTURE_SECRET_KEY="${fixtures}/sk.bin" \
        -DM2_MICRO_COLLECTOR_META="${collector_meta}" \
        "$@" 2>&1 | tee "${tree_root}/configure-${build_name}.log"
    printf '=== build %s ===\n' "${build_name}"
    cmake --build "${tree_root}/${build_name}" -j16 2>&1 | tee "${tree_root}/build-${build_name}.log"
    printf '=== ctest %s ===\n' "${build_name}"
    ctest --test-dir "${tree_root}/${build_name}" --output-on-failure 2>&1 |
        tee "${tree_root}/ctest-${build_name}.log"
}

configure_build build-ordinary
configure_build build-sanitize -DM2_MICRO_SANITIZERS=ON

for build_name in build-ordinary build-sanitize; do
    for variant in unfixed fixed; do
        for program in microbench qualification; do
            if [ "${program}" = microbench ]; then
                elf_name=m2_hotspot_microbench
            else
                elf_name=m2_hotspot_qualification
            fi
            elf_path=${tree_root}/${build_name}/${program}/${variant}/${elf_name}
            if [ ! -x "${elf_path}" ]; then
                echo "build did not produce ${elf_path}" >&2
                exit 1
            fi
        done
    done
done
printf 'build_status=ok tree=%s\n' "${tree_root}"
