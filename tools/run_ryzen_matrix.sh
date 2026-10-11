#!/bin/sh
# 24 个普通格子。失败写入 summary，不让后一个优化覆盖前一个结果。
set -u

root=/home/nss-marker/yhr/Cry/seven-capabilities-20261011
source_root=${root}/source
export LC_ALL=C
export TMPDIR=${root}/tmp
export TEMP=${root}/tmp
export TMP=${root}/tmp
cd "${source_root}"
find src include vendor docs/patches tools cmake tests Makefile CMakeLists.txt CMakePresets.json \
    -type f ! -name SOURCE_EXPORT.sha256 | LC_ALL=C sort | xargs shasum -a 256 > SOURCE_EXPORT.sha256

mkdir -p "${root}/run-matrix"
: > "${root}/run-matrix/summary.txt"
run_one() {
    compiler=$1
    matrix_opt=$2
    variant=$3
    if "${source_root}/tools/run_matrix_cell.sh" "${source_root}" "${root}/run-matrix" \
        "${compiler}" "${matrix_opt}" "${variant}" 20; then
        printf 'OK %s %s %s\n' "${variant}" "${compiler}" "${matrix_opt}" \
            >> "${root}/run-matrix/summary.txt"
    else
        printf 'FAIL %s %s %s\n' "${variant}" "${compiler}" "${matrix_opt}" \
            >> "${root}/run-matrix/summary.txt"
    fi
}

for compiler in /usr/bin/gcc /usr/bin/clang; do
    for matrix_opt in O0 O1 O2 O3 O2LTO; do
        for variant in reference deployable; do
            run_one "${compiler}" "${matrix_opt}" "${variant}"
        done
    done
    for variant in vulnerable hardened; do
        run_one "${compiler}" O2 "${variant}"
    done
done
printf 'MATRIX_DONE\n' >> "${root}/run-matrix/summary.txt"
