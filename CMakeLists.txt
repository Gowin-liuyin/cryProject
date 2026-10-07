cmake_minimum_required(VERSION 3.21)
project(
    cryProject
    VERSION 0.1.0
    LANGUAGES C
)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use an out-of-source build: cmake -S . -B build/cmake")
endif()
if(NOT CMAKE_SYSTEM_NAME MATCHES "^(Darwin|Linux)$" OR NOT CMAKE_C_COMPILER_ID MATCHES
                                                       "^(GNU|Clang|AppleClang)$"
)
    message(FATAL_ERROR "This baseline supports Linux/macOS with GCC or Clang")
endif()
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE
        RelWithDebInfo
        CACHE STRING "Build configuration" FORCE
    )
endif()
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
option(BASELINE_SANITIZERS "Enable ASan/UBSan; do not use these timings as performance evidence"
       OFF
)
option(A113_ARCHIVED_CASE_ONLY "Use archived mechanism cases in the delivery workflow" ON)
include(CTest)
find_package(Git REQUIRED)
find_program(PATCH_EXECUTABLE patch REQUIRED)
find_program(SH_EXECUTABLE sh REQUIRED)
find_program(SHASUM_EXECUTABLE shasum REQUIRED)
find_program(AWK_EXECUTABLE awk REQUIRED)

set(vendor_root "${CMAKE_CURRENT_SOURCE_DIR}/vendor/mlkem-native/mlkem")
set(encoder_patch_vulnerable "${CMAKE_CURRENT_SOURCE_DIR}/docs/patches/message-branch.patch")
set(encoder_patch_hardened "${CMAKE_CURRENT_SOURCE_DIR}/docs/patches/message-constant-time.patch")
set(encoder_patch_deployable "${CMAKE_CURRENT_SOURCE_DIR}/docs/patches/message-value-barrier.patch")
set(identity_directory "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>")
if(CMAKE_CONFIGURATION_TYPES)
    set(output_root "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>")
else()
    set(output_root "${CMAKE_CURRENT_BINARY_DIR}")
endif()

add_library(baseline_options INTERFACE)
target_compile_options(
    baseline_options
    INTERFACE -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wstrict-prototypes
              -Werror
)
target_compile_definitions(baseline_options INTERFACE MLK_CONFIG_FILE="baseline_config.h")
target_include_directories(
    baseline_options INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include" "${vendor_root}"
)
if(BASELINE_SANITIZERS)
    target_compile_options(
        baseline_options INTERFACE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
    )
    target_link_options(baseline_options INTERFACE -fsanitize=address,undefined)
endif()

file(GLOB_RECURSE vendor_files CONFIGURE_DEPENDS "${vendor_root}/*")
# 三个变体各有独立的构建目录副本和补丁，vendor 原件始终不动。
foreach(patched_variant IN ITEMS vulnerable hardened deployable)
    set(overlay_root_${patched_variant} "${CMAKE_CURRENT_BINARY_DIR}/${patched_variant}-source")
    add_custom_command(
        OUTPUT "${overlay_root_${patched_variant}}/patched.stamp"
        COMMAND
            "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DOVERLAY_ROOT=${overlay_root_${patched_variant}}"
            "-DPATCH_FILE=${encoder_patch_${patched_variant}}"
            "-DPATCH_EXECUTABLE=${PATCH_EXECUTABLE}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareVariant.cmake"
        DEPENDS ${vendor_files} "${encoder_patch_${patched_variant}}" cmake/PrepareVariant.cmake
        VERBATIM
    )
    add_custom_target(
        prepare_${patched_variant} DEPENDS "${overlay_root_${patched_variant}}/patched.stamp"
    )
endforeach()

# 每次构建刷新版本信息；内容未变时保留头文件时间，避免无谓重编译。
configure_file(
    cmake/build_configuration.txt.in "${CMAKE_CURRENT_BINARY_DIR}/build_configuration.txt.in" @ONLY
)
file(
    GENERATE
    OUTPUT "${identity_directory}/configuration.txt"
    INPUT "${CMAKE_CURRENT_BINARY_DIR}/build_configuration.txt.in"
)
add_custom_target(
    build_identity
    COMMAND
        "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tools/build_identity.sh"
        "${identity_directory}/build_identity.h" "${CMAKE_C_COMPILER}"
        "${identity_directory}/configuration.txt"
    BYPRODUCTS "${identity_directory}/build_identity.h"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM
)

foreach(variant IN ITEMS reference vulnerable hardened deployable)
    set(kernel_source "${CMAKE_CURRENT_SOURCE_DIR}/src/kernel.c")
    if(NOT variant STREQUAL "reference")
        set(kernel_source "${CMAKE_CURRENT_BINARY_DIR}/${variant}_kernel.c")
        configure_file(src/kernel.c "${kernel_source}" COPYONLY)
        set_source_files_properties(
            "${kernel_source}" PROPERTIES OBJECT_DEPENDS "${overlay_root_${variant}}/patched.stamp"
        )
    endif()
    add_library(mlkem_${variant} STATIC "${kernel_source}" src/mlkem.c src/random.c src/inputs.c)
    target_link_libraries(mlkem_${variant} PUBLIC baseline_options)
    set_target_properties(
        mlkem_${variant}
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                   ARCHIVE_OUTPUT_DIRECTORY "${output_root}/${variant}"
                   OUTPUT_NAME mlkem
    )
    add_dependencies(mlkem_${variant} build_identity)
    if(NOT variant STREQUAL "reference")
        add_dependencies(mlkem_${variant} prepare_${variant})
        target_include_directories(
            mlkem_${variant} BEFORE PRIVATE "${overlay_root_${variant}}/mlkem"
        )
    endif()
    if(variant STREQUAL "vulnerable")
        target_compile_definitions(mlkem_${variant} PRIVATE BASELINE_VULNERABLE=1)
    elseif(variant STREQUAL "hardened")
        target_compile_definitions(mlkem_${variant} PRIVATE BASELINE_HARDENED=1)
    elseif(variant STREQUAL "deployable")
        target_compile_definitions(mlkem_${variant} PRIVATE BASELINE_DEPLOYABLE=1)
    endif()
    set(variant_programs baseline)
    if(NOT A113_ARCHIVED_CASE_ONLY)
        list(APPEND variant_programs measure)
    endif()
    foreach(program IN LISTS variant_programs)
        if(program STREQUAL "baseline")
            set(program_source src/main.c)
        else()
            set(program_source src/measure.c)
        endif()
        add_executable(${variant}_${program} "${program_source}")
        target_link_libraries(${variant}_${program} PRIVATE mlkem_${variant})
        target_include_directories(${variant}_${program} PRIVATE "${identity_directory}")
        set_target_properties(
            ${variant}_${program}
            PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                       RUNTIME_OUTPUT_DIRECTORY "${output_root}/${variant}"
                       OUTPUT_NAME ${program}
        )
    endforeach()
    add_custom_target(${variant} DEPENDS ${variant}_baseline)
    if(NOT A113_ARCHIVED_CASE_ONLY)
        add_dependencies(${variant} ${variant}_measure)
    endif()
    if(BUILD_TESTING)
        foreach(test_program IN ITEMS test_mlkem test_equivalence test_random_failure)
            add_executable(${variant}_${test_program} "tests/${test_program}.c")
            target_link_libraries(${variant}_${test_program} PRIVATE mlkem_${variant})
            set_target_properties(
                ${variant}_${test_program}
                PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}/${variant}" OUTPUT_NAME
                                                                                ${test_program}
            )
        endforeach()
        add_test(NAME ${variant}_kat
                 COMMAND ${variant}_test_mlkem
                         "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/mlkem768.txt"
        )
        add_test(NAME ${variant}_random_failure COMMAND ${variant}_test_random_failure)
    endif()
endforeach()

# 普通测量仅覆盖参考和两种无分支对照，历史五类入口保持原样。
foreach(ordinary_variant IN ITEMS reference hardened deployable)
    add_executable(${ordinary_variant}_benchmark src/measure.c)
    target_compile_definitions(${ordinary_variant}_benchmark PRIVATE BASELINE_ORDINARY_WORKLOAD=1)
    target_link_libraries(${ordinary_variant}_benchmark PRIVATE mlkem_${ordinary_variant})
    target_include_directories(${ordinary_variant}_benchmark PRIVATE "${identity_directory}")
    set_target_properties(
        ${ordinary_variant}_benchmark
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                   RUNTIME_OUTPUT_DIRECTORY "${output_root}/${ordinary_variant}"
                   OUTPUT_NAME benchmark
    )
endforeach()

# 统计分析只读取 CSV，与实现变体无关，因此只构建一个程序。
add_executable(reference_batch_benchmark src/measure.c src/batch_measurement.c)
target_compile_definitions(
    reference_batch_benchmark PRIVATE BASELINE_ORDINARY_WORKLOAD=1 BASELINE_BATCH_WORKLOAD=1
)
target_link_libraries(reference_batch_benchmark PRIVATE mlkem_reference)
target_include_directories(reference_batch_benchmark PRIVATE "${identity_directory}")
set_target_properties(
    reference_batch_benchmark
    PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
               RUNTIME_OUTPUT_DIRECTORY "${output_root}/reference"
               OUTPUT_NAME batch_benchmark
)

find_library(MATH_LIBRARY m)
add_executable(analyze src/analyze.c src/timing_statistics.c)
target_link_libraries(analyze PRIVATE mlkem_reference)
if(MATH_LIBRARY)
    target_link_libraries(analyze PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(
    analyze PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE RUNTIME_OUTPUT_DIRECTORY "${output_root}"
)

# 第二轮预注册的分组检验是独立程序，第一轮的比较族因此保持逐字可复现。
add_executable(analyze_groups src/analyze_groups.c src/timing_statistics.c)
target_link_libraries(analyze_groups PRIVATE mlkem_reference)
if(MATH_LIBRARY)
    target_link_libraries(analyze_groups PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(
    analyze_groups PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE RUNTIME_OUTPUT_DIRECTORY
                                                                 "${output_root}"
)

add_executable(inspect_timing src/inspect_timing.c src/timing_statistics.c)
target_link_libraries(inspect_timing PRIVATE mlkem_reference)
if(MATH_LIBRARY)
    target_link_libraries(inspect_timing PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(inspect_timing PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")

add_library(paired_support STATIC src/paired_data.c src/paired_statistics.c src/timing_statistics.c)
target_link_libraries(paired_support PUBLIC mlkem_reference)
if(MATH_LIBRARY)
    target_link_libraries(paired_support PUBLIC "${MATH_LIBRARY}")
endif()
add_executable(analyze_paired src/analyze_paired.c)
target_link_libraries(analyze_paired PRIVATE paired_support)
set_target_properties(analyze_paired PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(paired_runner src/paired_runner.c)
target_link_libraries(paired_runner PRIVATE paired_support)
target_include_directories(paired_runner PRIVATE "${identity_directory}")
set_target_properties(paired_runner PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(paired_prepare src/paired_prepare.c)
target_link_libraries(paired_prepare PRIVATE paired_support)
target_include_directories(paired_prepare PRIVATE "${identity_directory}")
set_target_properties(paired_prepare PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(native_digest src/native_digest.c)
target_link_libraries(native_digest PRIVATE baseline_options)
set_target_properties(native_digest PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")

add_library(controlled_statistics STATIC src/controlled_statistics.c)
target_link_libraries(controlled_statistics PUBLIC paired_support)
add_executable(controlled_stats src/controlled_stats.c)
target_link_libraries(controlled_stats PRIVATE controlled_statistics)
set_target_properties(controlled_stats PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(calibrate_controlled src/calibrate_controlled.c)
target_link_libraries(calibrate_controlled PRIVATE controlled_statistics)
target_include_directories(calibrate_controlled PRIVATE "${identity_directory}")
add_dependencies(calibrate_controlled build_identity)
set_target_properties(calibrate_controlled PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(compare_replay src/compare_replay.c)
target_link_libraries(compare_replay PRIVATE paired_support)
set_target_properties(compare_replay PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_executable(audit src/audit.c)
target_link_libraries(audit PRIVATE controlled_statistics)
target_include_directories(audit PRIVATE "${identity_directory}")
set_target_properties(audit PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
add_dependencies(
    audit
    reference_baseline
    reference_benchmark
    hardened_benchmark
    deployable_benchmark
    inspect_timing
    analyze
    analyze_groups
    controlled_stats
    calibrate_controlled
)

if(BUILD_TESTING)
    add_executable(test_performance_replay tests/test_performance_replay.c)
    target_link_libraries(test_performance_replay PRIVATE mlkem_reference)
    target_compile_options(test_performance_replay PRIVATE -UNDEBUG)
    add_test(NAME performance_replay COMMAND test_performance_replay $<TARGET_FILE:audit>)
    add_test(NAME audit_workflow
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_workflow.sh"
                     $<TARGET_FILE:audit>
    )
    add_test(NAME source_export
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_source_export.sh"
                     "${CMAKE_CURRENT_SOURCE_DIR}/tools/build_identity.sh" "${CMAKE_C_COMPILER}"
    )
    add_executable(test_controlled_statistics tests/test_controlled_statistics.c)
    target_link_libraries(test_controlled_statistics PRIVATE controlled_statistics)
    target_compile_options(test_controlled_statistics PRIVATE -UNDEBUG)
    add_test(NAME controlled_statistics COMMAND test_controlled_statistics)
    add_test(NAME calibration_oracle COMMAND calibrate_controlled --self-test)
    add_test(
        NAME reference_label_control_failures
        COMMAND
            "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_reference_label_control.sh"
            $<TARGET_FILE:calibrate_controlled>
            "${CMAKE_CURRENT_SOURCE_DIR}/docs/evidence/native-final-20261007/performance"
    )
    add_test(NAME controlled_cli
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_controlled_cli.sh"
                     $<TARGET_FILE:controlled_stats>
    )
    add_test(NAME compare_replay_failures
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_compare_replay.sh"
                     $<TARGET_FILE:compare_replay> $<TARGET_FILE:controlled_stats>
    )
    find_program(OPENSSL_EXECUTABLE openssl REQUIRED)
    add_executable(test_native_digest tests/test_native_digest.c)
    target_link_libraries(test_native_digest PRIVATE baseline_options)
    target_compile_options(test_native_digest PRIVATE -UNDEBUG)
    add_test(NAME native_digest COMMAND test_native_digest $<TARGET_FILE:native_digest>
                                        "${OPENSSL_EXECUTABLE}"
    )
    add_executable(test_paired_prepare tests/test_paired_prepare.c)
    target_link_libraries(test_paired_prepare PRIVATE paired_support)
    target_compile_options(test_paired_prepare PRIVATE -UNDEBUG)
    add_test(NAME paired_prepare
             COMMAND test_paired_prepare $<TARGET_FILE:paired_prepare>
                     $<TARGET_FILE:mlkem_reference> $<TARGET_FILE:paired_runner>
    )
    add_executable(paired_worker_fixture tests/paired_worker_fixture.c)
    target_link_libraries(paired_worker_fixture PRIVATE baseline_options)
    add_executable(test_paired_runner tests/test_paired_runner.c)
    target_link_libraries(test_paired_runner PRIVATE paired_support)
    target_include_directories(test_paired_runner PRIVATE "${identity_directory}")
    target_compile_options(test_paired_runner PRIVATE -UNDEBUG)
    add_test(NAME paired_runner
             COMMAND test_paired_runner $<TARGET_FILE:paired_runner> "${output_root}"
                     $<TARGET_FILE:analyze_paired> $<TARGET_FILE:paired_worker_fixture>
    )
    set_tests_properties(paired_runner PROPERTIES RUN_SERIAL TRUE)
    add_executable(test_paired_statistics tests/test_paired_statistics.c)
    target_link_libraries(test_paired_statistics PRIVATE paired_support)
    target_compile_options(test_paired_statistics PRIVATE -UNDEBUG)
    add_test(NAME paired_statistics COMMAND test_paired_statistics)
    add_executable(test_paired_data tests/test_paired_data.c)
    target_link_libraries(test_paired_data PRIVATE paired_support)
    target_compile_options(test_paired_data PRIVATE -UNDEBUG)
    set_target_properties(test_paired_data PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
    add_test(NAME paired_data COMMAND test_paired_data $<TARGET_FILE:analyze_paired>)
    add_executable(test_paired_rejections tests/test_paired_rejections.c)
    target_link_libraries(test_paired_rejections PRIVATE paired_support)
    target_compile_options(test_paired_rejections PRIVATE -UNDEBUG)
    add_test(NAME paired_rejections COMMAND test_paired_rejections $<TARGET_FILE:test_paired_data>
                                            $<TARGET_FILE:analyze_paired>
    )
    add_executable(test_batch_measurement tests/test_batch_measurement.c src/batch_measurement.c)
    target_link_libraries(test_batch_measurement PRIVATE mlkem_reference)
    target_compile_options(test_batch_measurement PRIVATE -UNDEBUG)
    add_test(NAME batch_measurement
             COMMAND test_batch_measurement $<TARGET_FILE:reference_benchmark>
                     $<TARGET_FILE:reference_batch_benchmark>
    )
    set_tests_properties(batch_measurement PROPERTIES RUN_SERIAL TRUE)
    add_executable(
        test_reference_benchmark tests/test_reference_benchmark.c src/timing_statistics.c
    )
    target_link_libraries(test_reference_benchmark PRIVATE mlkem_reference)
    if(MATH_LIBRARY)
        target_link_libraries(test_reference_benchmark PRIVATE "${MATH_LIBRARY}")
    endif()
    target_compile_options(test_reference_benchmark PRIVATE -UNDEBUG)
    add_test(NAME reference_benchmark COMMAND test_reference_benchmark
                                              $<TARGET_FILE:reference_benchmark>
    )
    set_tests_properties(reference_benchmark PROPERTIES RUN_SERIAL TRUE)
    add_executable(test_timing_diagnostics tests/test_timing_diagnostics.c src/timing_statistics.c)
    target_link_libraries(test_timing_diagnostics PRIVATE mlkem_reference)
    if(MATH_LIBRARY)
        target_link_libraries(test_timing_diagnostics PRIVATE "${MATH_LIBRARY}")
    endif()
    target_compile_options(test_timing_diagnostics PRIVATE -UNDEBUG)
    add_test(NAME timing_diagnostics COMMAND test_timing_diagnostics $<TARGET_FILE:inspect_timing>)
    if(NOT A113_ARCHIVED_CASE_ONLY)
        add_executable(test_measurement tests/test_measurement.c)
        target_link_libraries(test_measurement PRIVATE mlkem_reference)
        set_target_properties(test_measurement PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
    endif()
    foreach(checked_variant IN ITEMS vulnerable hardened deployable)
        add_test(
            NAME equivalence_${checked_variant}
            COMMAND
                "${CMAKE_COMMAND}" "-DBASELINE_PROGRAM=$<TARGET_FILE:reference_test_equivalence>"
                "-DVARIANT_PROGRAM=$<TARGET_FILE:${checked_variant}_test_equivalence>"
                "-DVARIANT_NAME=${checked_variant}" "-DOUTPUT_DIRECTORY=${output_root}" -P
                "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CheckEquivalence.cmake"
        )
    endforeach()
    add_test(NAME cli COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_cli.sh"
                              "${output_root}"
    )
    add_test(NAME reference_cli
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_cli.sh"
                     "${output_root}" reference
    )
    if(NOT A113_ARCHIVED_CASE_ONLY)
        add_test(NAME measurement
                 COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_measurement.sh"
                         "${output_root}"
        )
        set_tests_properties(measurement PROPERTIES RUN_SERIAL TRUE)
    endif()
    add_test(NAME vector_parser
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_vector_parser.sh"
                     "${output_root}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/mlkem768.txt"
    )
    add_test(
        NAME reference_vector_parser
        COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_vector_parser.sh"
                "${output_root}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/mlkem768.txt" reference
    )
    if(NOT A113_ARCHIVED_CASE_ONLY)
        add_test(NAME analysis
                 COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_analysis.sh"
                         "${output_root}"
        )
        add_test(
            NAME analysis_groups
            COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_analysis_groups.sh"
                    "${output_root}"
        )
    endif()
    add_test(
        NAME analysis_round1_replay
        COMMAND "${SH_EXECUTABLE}"
                "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_analysis_round1_replay.sh" "${output_root}"
    )
    set_tests_properties(
        analysis_round1_replay PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    add_test(NAME vector_integrity COMMAND "${SHASUM_EXECUTABLE}" -a 256 -c
                                           tests/vectors/SHA256SUMS
    )
    set_tests_properties(
        vector_integrity PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    set_tests_properties(
        reference_kat reference_random_failure reference_cli reference_vector_parser
        vector_integrity PROPERTIES LABELS reference
    )
    add_custom_target(
        check-reference
        COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CMAKE_CURRENT_BINARY_DIR}" -C "$<CONFIG>"
                --output-on-failure -L reference
        DEPENDS reference_baseline reference_test_mlkem reference_test_random_failure
        USES_TERMINAL VERBATIM
    )
endif()

set(CLANG_FORMAT_EXECUTABLE
    ""
    CACHE FILEPATH "Optional path to clang-format 21"
)
foreach(format_target IN ITEMS format format-check)
    add_custom_target(
        ${format_target}
        COMMAND
            "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DFORMAT_EXECUTABLE=${CLANG_FORMAT_EXECUTABLE}" "-DFORMAT_MODE=${format_target}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Format.cmake"
        VERBATIM
    )
endforeach()
