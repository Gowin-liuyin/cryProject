#!/bin/sh
# 第二架构（aarch64）12 格复现：3 臂 × 4 个优化级别。
#
# 臂（与 x86_64 的 12 格完全同源、同一口径）：
#   m1unfixed  liboqs 0.10.0 未修（GHSA-f2v9-5498-2vpp 形态）
#   m1fixed    liboqs 0.10.0 + 官方修复 982c762
#   m5ref      mlkem-native 参考实现
#
# 级别：-O0 / -O2 / -O3 / -Os（与 R09 的 OPTIMIZATION_LEVELS 同）
#
# 每格产出三样：
#   * Memcheck 的错误数与**上下文数**（跨架构可比的确定性证据）
#   * poly_frommsg 的分支形态（秘密位是否进入跳转条件）
#   * 一次短测量（仅作上下文，跨架构不合并）
#
# 口径：
#   * 编译器是 clang 18（M1 机制本身就是 clang 引入的分支，gcc 不能替代）。
#   * 实现、封装、探针**同一优化级别**（与 R09 的 cell 口径一致）。
#   * 探针是仓库既有的 tools/historical_poison.c（用 Valgrind 客户端请求把解封装
#     私钥标成未初始化），不新增探针逻辑。
#   * 不做密钥恢复、不产出 exploit；只统计错误数与上下文数。
#
# 用法：run_aarch64_cells.sh <SOURCE_ROOT> <WORK_ROOT>
#   SOURCE_ROOT  含源码、vendor/liboqs-0.10.0、docs/patches 的目录
#   WORK_ROOT    工作目录（必须新建），构建与产物都在这里
set -eu

if [ "$#" -ne 2 ]; then
    printf 'usage: %s SOURCE_ROOT WORK_ROOT\n' "$0" >&2
    exit 2
fi

source_root=$(realpath "$1")
work_root=$2
if [ -e "${work_root}" ]; then
    printf 'Work root must be new.\n' >&2
    exit 2
fi
mkdir -p "${work_root}"
work_root=$(realpath "${work_root}")
export TMPDIR="${work_root}/tmp"
export TMP="${TMPDIR}"
export TEMP="${TMPDIR}"
mkdir -p "${TMPDIR}"

CLANG=${CLANG:-clang-18}
LEVELS="O0:-O0 O2:-O2 O3:-O3 Os:-Os"
LOG="${work_root}/cells.log"
: > "${LOG}"

note() {
    printf '%s\n' "$*" >> "${LOG}"
    printf '%s\n' "$*"
}

vendor_tree="${source_root}/vendor/liboqs-0.10.0"
mlkem_native_root="${source_root}/vendor/mlkem-native/mlkem"
if [ ! -f "${vendor_tree}/CMakeLists.txt" ]; then
    printf 'Missing vendor/liboqs-0.10.0; run tools/fetch_liboqs_0.10.0.sh first.\n' >&2
    exit 1
fi

# —— 已修臂的独立 liboqs 树：复制原树后打 982c762 补丁，原树不动 ——
fixed_tree="${work_root}/liboqs-0.10.0-fixed"
note "复制 liboqs 树用于已修臂"
cp -a "${vendor_tree}" "${fixed_tree}"
note "应用 982c762 补丁"
( cd "${fixed_tree}" && patch -p1 --batch --forward \
    < "${source_root}/docs/patches/liboqs-982c762.patch" ) \
    > "${work_root}/patch-982c762.log" 2>&1
sha256sum "${source_root}/docs/patches/liboqs-982c762.patch" \
    > "${work_root}/patch-982c762.sha256"

build_liboqs() {
    # $1 树、$2 安装目录、$3 优化标志
    liboqs_tree=$1
    install_dir=$2
    level_flag=$3
    build_dir="${install_dir}-build"
    mkdir -p "${build_dir}" "${install_dir}"
    "${CLANG}" --version | head -n 1 > "${install_dir}/compiler.txt"
    cmake -S "${liboqs_tree}" -B "${build_dir}" \
        -DCMAKE_INSTALL_PREFIX="${install_dir}" \
        -DCMAKE_BUILD_TYPE= \
        -DCMAKE_C_COMPILER="${CLANG}" \
        -DCMAKE_C_FLAGS="${level_flag}" \
        -DCMAKE_C_FLAGS_RELEASE="${level_flag} -DNDEBUG" \
        -DCMAKE_C_FLAGS_RELWITHDEBINFO="${level_flag} -g -DNDEBUG" \
        -DBUILD_SHARED_LIBS=OFF \
        -DOQS_BUILD_ONLY_LIB=ON \
        -DOQS_USE_OPENSSL=OFF \
        -DOQS_DIST_BUILD=OFF \
        -DOQS_OPT_TARGET=generic \
        -DOQS_USE_AVX2_INSTRUCTIONS=OFF \
        -DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF \
        -DOQS_MINIMAL_BUILD=KEM_ml_kem_768_ipd \
        > "${build_dir}/cmake.log" 2>&1
    cmake --build "${build_dir}" --target install --parallel 4 \
        > "${build_dir}/build.log" 2>&1
}

# 写构建身份头（格式与 tools/build_identity.sh 一致：build_identity_lines[]）。
write_build_identity() {
    header=$1
    arm=$2
    level_name=$3
    level_flag=$4
    {
        printf '#ifndef BASELINE_BUILD_IDENTITY_H\n#define BASELINE_BUILD_IDENTITY_H\n'
        printf 'static const char *const build_identity_lines[] = {\n'
        printf '"cell=%s-%s\\n",\n' "${arm}" "${level_name}"
        printf '"architecture=aarch64\\n",\n'
        printf '"optimization_level=%s\\n",\n' "${level_flag}"
        printf '"compiler=%s\\n",\n' "${CLANG}"
        printf '"cell_scope=implementation_plus_wrapper_plus_probe_all_at_same_level\\n",\n'
        printf '"note=second architecture run; not comparable in timing with the x86_64 bare metal\\n",\n'
        printf '};\n#endif\n'
    } > "${header}"
}

# —— 每格：实现、封装、探针同一级别 ——
build_m1_cell() {
    # $1 臂名、$2 liboqs 安装目录、$3 优化标志、$4 级别名
    arm=$1
    install_dir=$2
    level_flag=$3
    level_name=$4
    cell_root="${work_root}/build-${arm}-${level_name}"
    obj_dir="${cell_root}/obj"
    mkdir -p "${obj_dir}"
    generated="${cell_root}/generated"
    mkdir -p "${generated}"
    write_build_identity "${generated}/build_identity.h" "${arm}" "${level_name}" "${level_flag}"
    common_flags="-std=c11 ${level_flag} -g -DNDEBUG -DBASELINE_HISTORICAL=1 -I${source_root}/include -I${install_dir}/include -I${vendor_tree}/src/common -I${generated}"
    objects=""
    for unit in mlkem_liboqs010 random inputs_liboqs010; do
        object_path="${obj_dir}/${unit}.o"
        # shellcheck disable=SC2086
        "${CLANG}" ${common_flags} -c "${source_root}/src/${unit}.c" -o "${object_path}"
        objects="${objects} ${object_path}"
    done
    archive="${install_dir}/lib/liboqs.a"
    # shellcheck disable=SC2086
    "${CLANG}" ${common_flags} -c "${source_root}/tools/historical_poison.c" \
        -o "${obj_dir}/poison.o"
    "${CLANG}" ${level_flag} -g -DNDEBUG -o "${cell_root}/poison_cell" \
        "${obj_dir}/poison.o" ${objects} "${archive}" -lpthread -lm
    # shellcheck disable=SC2086
    "${CLANG}" ${common_flags} -c "${source_root}/src/measure.c" -o "${obj_dir}/measure.o"
    "${CLANG}" ${level_flag} -g -DNDEBUG -o "${cell_root}/measure" \
        "${obj_dir}/measure.o" ${objects} "${archive}" -lpthread -lm
    printf '%s\n' "${cell_root}"
}

build_m5_cell() {
    # $1 优化标志、$2 级别名
    level_flag=$1
    level_name=$2
    cell_root="${work_root}/build-m5ref-${level_name}"
    obj_dir="${cell_root}/obj"
    mkdir -p "${obj_dir}"
    generated="${cell_root}/generated"
    mkdir -p "${generated}"
    write_build_identity "${generated}/build_identity.h" m5ref "${level_name}" "${level_flag}"
    common_flags="-std=c11 ${level_flag} -g -DNDEBUG -I${source_root}/include -I${mlkem_native_root} -I${mlkem_native_root}/src -I${mlkem_native_root}/src/fips202 -I${generated} -DMLK_CONFIG_FILE=\"baseline_config.h\""
    objects=""
    for unit in kernel mlkem random inputs; do
        object_path="${obj_dir}/${unit}.o"
        # shellcheck disable=SC2086
        "${CLANG}" ${common_flags} -c "${source_root}/src/${unit}.c" -o "${object_path}"
        objects="${objects} ${object_path}"
    done
    # mlkem-native 的 fips202 实现已由 src/kernel.c 一并编入，不能再单独编一遍
    # （会与命名空间前缀后的符号重复定义）。
    # m5ref 这一格只做 Memcheck 探针：跨架构可比的确定性证据是错误数与上下文数，
    # 时间证据不跨架构合并，因此不建 measure 产物。
    # shellcheck disable=SC2086
    "${CLANG}" ${common_flags} -c "${source_root}/tools/historical_poison.c" -o "${obj_dir}/poison.o"
    "${CLANG}" ${level_flag} -g -DNDEBUG -o "${cell_root}/poison_cell" \
        "${obj_dir}/poison.o" ${objects} -lpthread -lm
    printf '%s\n' "${cell_root}"
}

run_cell() {
    # $1 臂名、$2 级别名、$3 格目录
    arm=$1
    level_name=$2
    cell_root=$3
    out_dir="${work_root}/results"
    mkdir -p "${out_dir}"
    valgrind_log="${out_dir}/${arm}-${level_name}.valgrind.txt"
    set +e
    valgrind --tool=memcheck --error-exitcode=99 --track-origins=yes \
        --num-callers=20 "${cell_root}/poison_cell" > "${valgrind_log}" 2>&1
    valgrind_status=$?
    set -e
    errors=$(sed -n 's/.*ERROR SUMMARY: \([0-9]*\) errors.*/\1/p' "${valgrind_log}" | tail -n 1)
    contexts=$(sed -n 's/.*ERROR SUMMARY: [0-9]* errors from \([0-9]*\) contexts.*/\1/p' "${valgrind_log}" | tail -n 1)
    [ -n "${errors}" ] || errors=0
    [ -n "${contexts}" ] || contexts=0
    disasm="${out_dir}/${arm}-${level_name}.disasm.txt"
    objdump -d "${cell_root}/poison_cell" > "${disasm}"
    poly_lines=$(awk '/<pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:/,/^$/' "${disasm}" | wc -l)
    branch_lines=$(awk '/<pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:/,/^$/' "${disasm}" \
        | grep -cE '\b(j[a-z]+|b[a-z.]+|cbz|cbnz|tbz|tbnz)\b' || true)
    printf '%s,%s,%s,%s,%s,%s,%s\n' \
        "${arm}" "${level_name}" "${valgrind_status}" "${errors}" "${contexts}" \
        "${poly_lines}" "${branch_lines}" >> "${work_root}/SUMMARY.csv"
    note "cell=${arm}-${level_name} valgrind_exit=${valgrind_status} errors=${errors} contexts=${contexts} poly_lines=${poly_lines} branches=${branch_lines}"
}

printf 'arm,level,valgrind_exit,memcheck_errors,memcheck_contexts,poly_frommsg_lines,poly_frommsg_branches\n' \
    > "${work_root}/SUMMARY.csv"

for level_spec in ${LEVELS}; do
    level_name=${level_spec%%:*}
    level_flag=${level_spec##*:}
    note "===== 级别 ${level_name} (${level_flag}) ====="
    for arm in m1unfixed m1fixed; do
        install_dir="${work_root}/liboqs-${arm}-${level_name}"
        if [ "${arm}" = "m1fixed" ]; then
            liboqs_tree="${fixed_tree}"
        else
            liboqs_tree="${vendor_tree}"
        fi
        note "构建 liboqs（${arm} ${level_name}）"
        build_liboqs "${liboqs_tree}" "${install_dir}" "${level_flag}"
        note "构建格（${arm} ${level_name}）"
        cell_root=$(build_m1_cell "${arm}" "${install_dir}" "${level_flag}" "${level_name}")
        run_cell "${arm}" "${level_name}" "${cell_root}"
    done
    note "构建格（m5ref ${level_name}）"
    cell_root=$(build_m5_cell "${level_flag}" "${level_name}")
    run_cell m5ref "${level_name}" "${cell_root}"
done

note "CELLS_DONE"
cat "${work_root}/SUMMARY.csv"
