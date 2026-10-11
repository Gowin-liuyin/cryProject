#!/bin/sh
# 构建并记录一个普通矩阵格子。失败也留下日志，不能用另一优化顶替。
set -eu

if [ "$#" -ne 6 ]; then
    echo "usage: run_matrix_cell.sh SOURCE_ROOT BUILD_ROOT CC OPT VARIANT SAMPLES" >&2
    exit 1
fi

source_root=$1
build_root=$2
compiler=$3
matrix_opt=$4
variant=$5
samples_per_category=$6
cell_id="${variant}-$(basename "${compiler}")-${matrix_opt}"
cell_build="${build_root}/${cell_id}"
cell_log="${build_root}/${cell_id}.log"

mkdir -p "${build_root}"
: > "${cell_log}"

if ! command -v "${compiler}" >/dev/null 2>&1; then
    printf 'cell=%s\nstatus=compiler_missing\ncompiler=%s\nopt=%s\nvariant=%s\n' \
        "${cell_id}" "${compiler}" "${matrix_opt}" "${variant}" | tee -a "${cell_log}"
    exit 1
fi

{
    printf 'cell=%s\ncompiler=%s\nopt=%s\nvariant=%s\n' \
        "${cell_id}" "${compiler}" "${matrix_opt}" "${variant}"
    "${compiler}" --version | head -n 1
    cmake -S "${source_root}" -B "${cell_build}" -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_COMPILER="${compiler}" \
        -DBUILD_TESTING=ON \
        -DBASELINE_SANITIZERS=OFF \
        -DA113_ARCHIVED_CASE_ONLY=OFF \
        -DA113_MATRIX_OPT="${matrix_opt}"
    cmake --build "${cell_build}" --target "${variant}_session_collect" "${variant}_test_mlkem" -j 4
} >> "${cell_log}" 2>&1

compile_line=$(python3 - "${cell_build}/compile_commands.json" "${variant}" << 'PY'
import json
import sys
commands = json.load(open(sys.argv[1], encoding="utf-8"))
variant_name = sys.argv[2]
matched = []
for entry in commands:
    source_path = entry["file"].replace("\\", "/")
    command = entry["command"]
    if "diagnostic" in source_path or "diagnostic" in command:
        continue
    if variant_name == "reference" and source_path.endswith("/src/kernel.c"):
        matched.append(command)
    if variant_name != "reference" and source_path.endswith("/" + variant_name + "_kernel.c"):
        matched.append(command)
if not matched:
    raise SystemExit(1)
print(matched[-1])
PY
)
link_file="${cell_build}/CMakeFiles/${variant}_session_collect.dir/link.txt"
if [ ! -f "${link_file}" ]; then
    echo "missing link line for ${cell_id}" | tee -a "${cell_log}"
    exit 1
fi
link_line=$(tr '\n' ' ' < "${link_file}")

case "${matrix_opt}" in
    O0)
        printf '%s\n' "${compile_line}" | grep -q -- '-O0' || {
            echo "O0 compile line lost -O0" | tee -a "${cell_log}"
            exit 1
        }
        printf '%s\n' "${compile_line}" | grep -E -q -- '-O2([[:space:]]|$)' && {
            echo "O0 compile line still contains -O2" | tee -a "${cell_log}"
            exit 1
        }
        ;;
    O2LTO)
        printf '%s\n' "${link_line}" | grep -q -- '-flto' || {
            echo "O2LTO link line does not enable LTO" | tee -a "${cell_log}"
            exit 1
        }
        ;;
esac

"${cell_build}/${variant}/test_mlkem" "${source_root}/tests/vectors/mlkem768.txt" \
    >> "${cell_log}" 2>&1
binary_digest=$(shasum -a 256 "${cell_build}/${variant}/session_collect" | awk '{ print $1 }')
"${cell_build}/${variant}/session_collect" "matrix-${cell_id}" session-basic key-basic 31337 \
    "${samples_per_category}" 20 \
    "${build_root}/${cell_id}.csv" "${build_root}/${cell_id}.meta" \
    "${build_root}/${cell_id}.empty" >> "${cell_log}" 2>&1

{
    printf 'cell=%s\nstatus=qualified\ncompiler=%s\nopt=%s\nvariant=%s\n' \
        "${cell_id}" "${compiler}" "${matrix_opt}" "${variant}"
    printf 'binary_sha256=%s\n' "${binary_digest}"
    printf 'compile_line=%s\n' "${compile_line}"
    printf 'link_line=%s\n' "${link_line}"
    printf 'kat=passed\nbasic_timing_csv=%s\n' "${build_root}/${cell_id}.csv"
} | tee "${build_root}/${cell_id}.manifest"
