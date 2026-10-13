#!/bin/bash
set -eu
run=/home/nss-marker/yhr/Cry/v4-development-8709dfe
exec > "$run/log/wrapper.txt" 2>&1
set -x
echo START
export LC_ALL=C
export TMPDIR="$run/tmp"
export TMP="$run/tmp"
export TEMP="$run/tmp"
mkdir -p "$run/source" "$run/log" "$run/tmp"
real_run=$(readlink -f "$run")
if [ "$real_run" != "$run" ]; then
    echo "PATH_ESCAPE $real_run"
    exit 1
fi
tar -xf "$run/v4-source-8709dfe.tar" -C "$run/source"
cp "$run/SOURCE_EXPORT.sha256" "$run/source/SOURCE_EXPORT.sha256"
# 拒绝指向本运行目录之外的符号链接。
if find "$run/source" -type l -print | grep -q .; then
    echo SYMLINK_PRESENT
    find "$run/source" -type l -print
    exit 1
fi
{
    echo "git_commit=8709dfe09955f44bf0e79311d9975f733069b752"
    echo "protocol_commit=9cf0be4c10ccc2a957bd123b7ab884ee5641d5e6"
    echo "protocol_sha256=d52fc943f68600e9630494757caf7f6854f00cfb1c47927b3c04491adf5be4c7"
    echo "source_tar_sha256=81a8e732aae0db11d86954919233c647452a6c9f71c62e45391a686a33067460"
    echo "source_export_manifest_sha256=d8e46827f10a62fd6701799eebdbeebdc82de3bdb8f2ff821351506618259508"
    echo "prior_failed_link_tree=/home/nss-marker/yhr/Cry/v4-development-9cf0be4"
    echo "frequency_writes=none"
    hostname
    uname -a
    virt=$(systemd-detect-virt || true)
    echo "systemd-detect-virt=$virt"
    nproc
    gcc --version | head -1
    cmake --version | head -1
    echo "work_root=$real_run"
    date -u +start=%Y-%m-%dT%H:%M:%SZ
} > "$run/log/environment.txt"
cd "$run/source"
shasum -a 256 -c SOURCE_EXPORT.sha256 > "$run/log/source-manifest.txt"
shasum -a 256 docs/research/v4-protocol-20261013/PROTOCOL.md > "$run/log/protocol-sha256.txt"
sh -n tools/build_identity.sh
cmake --preset baseline > "$run/log/configure.txt" 2>&1
cmake --build build/cmake --target encoder_branch_v4_collect v4_analyze -j 8 > "$run/log/build.txt" 2>&1
if ! grep -E -q -- '-lm|libm' build/cmake/CMakeFiles/encoder_branch_v4_collect.dir/link.txt; then
    echo NO_LIBM
    exit 1
fi
if ! readelf -d build/cmake/encoder_branch/v4_collect | grep -q 'libm\.so'; then
    echo NEEDED_LIBM_MISSING
    readelf -d build/cmake/encoder_branch/v4_collect
    exit 1
fi
sha256sum build/cmake/encoder_branch/v4_collect build/cmake/v4_analyze > "$run/log/binary-sha256.txt"
cp build/cmake/CMakeFiles/encoder_branch_v4_collect.dir/link.txt "$run/log/encoder-branch-link.txt"
date -u +build_end=%Y-%m-%dT%H:%M:%SZ >> "$run/log/environment.txt"
echo BUILD_OK
