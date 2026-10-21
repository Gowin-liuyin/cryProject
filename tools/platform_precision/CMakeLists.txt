cmake_minimum_required(VERSION 3.21)
project(platform_precision LANGUAGES C)
include(CTest)

# 计时基准与频率自校准工具。
#
# 这个工具只读：读 TSC、CLOCK_MONOTONIC 与内核 cpufreq 的瞬时频率，
# **不写任何 cpufreq 节点**，也不做固定拍数空转（区间长度用墙钟控制）。
#
# 产物是普通 CLI，可单独构建运行；不与平台采集产物混为一份。
add_executable(tsc_calibration tsc_calibration.c)
target_compile_options(
    tsc_calibration
    PRIVATE -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wconversion
            -Wstrict-prototypes
            -Werror
)
# Linux 上 sqrt 在 libm 里；显式链接，避免只在本机（libm 并入 libc）通过。
find_library(MATH_LIBRARY m)
if(MATH_LIBRARY)
    target_link_libraries(tsc_calibration PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(
    tsc_calibration
    PROPERTIES C_STANDARD 11
               C_STANDARD_REQUIRED ON
               C_EXTENSIONS OFF
               INTERPROCEDURAL_OPTIMIZATION FALSE
)

if(BUILD_TESTING)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64|i.86)$")
        add_test(
            NAME tsc_calibration_cli
            COMMAND tsc_calibration 1 100000 32 "${CMAKE_CURRENT_BINARY_DIR}/intervals.csv"
                    "${CMAKE_CURRENT_BINARY_DIR}/summary.txt"
        )
        # 产物必须存在且列数与表头一致；摘要必须给出 TSC 速率与三项分布。
        add_test(
            NAME tsc_calibration_outputs
            COMMAND
                "${CMAKE_COMMAND}" "-DPROGRAM=$<TARGET_FILE:tsc_calibration>" "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}"
                -P "${CMAKE_CURRENT_LIST_DIR}/test_tsc_calibration_outputs.cmake"
        )
    else()
        # 非 x86 平台没有 rdtsc：工具必须明确拒绝，而不是给出假数据。
        # 这里把「拒绝行为」本身作为回归项。
        add_test(
            NAME tsc_calibration_requires_x86
            COMMAND
                "${CMAKE_COMMAND}" "-DPROGRAM=$<TARGET_FILE:tsc_calibration>" -P
                "${CMAKE_CURRENT_LIST_DIR}/test_tsc_calibration_unsupported.cmake"
        )
    endif()
endif()
