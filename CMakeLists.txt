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
include(CTest)
find_package(Git REQUIRED)
find_program(PATCH_EXECUTABLE patch REQUIRED)
find_program(SH_EXECUTABLE sh REQUIRED)
find_program(SHASUM_EXECUTABLE shasum REQUIRED)
find_program(AWK_EXECUTABLE awk REQUIRED)

set(vendor_root "${CMAKE_CURRENT_SOURCE_DIR}/vendor/mlkem-native/mlkem")
set(overlay_root "${CMAKE_CURRENT_BINARY_DIR}/vulnerable-source")
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
add_custom_command(
    OUTPUT "${overlay_root}/patched.stamp"
    COMMAND
        "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
        "-DOVERLAY_ROOT=${overlay_root}" "-DPATCH_EXECUTABLE=${PATCH_EXECUTABLE}" -P
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareVariant.cmake"
    DEPENDS ${vendor_files} docs/patches/message-branch.patch cmake/PrepareVariant.cmake
    VERBATIM
)
add_custom_target(prepare_vulnerable DEPENDS "${overlay_root}/patched.stamp")

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

foreach(variant IN ITEMS reference vulnerable)
    set(kernel_source "${CMAKE_CURRENT_SOURCE_DIR}/src/kernel.c")
    if(variant STREQUAL "vulnerable")
        set(kernel_source "${CMAKE_CURRENT_BINARY_DIR}/vulnerable_kernel.c")
        configure_file(src/kernel.c "${kernel_source}" COPYONLY)
        set_source_files_properties(
            "${kernel_source}" PROPERTIES OBJECT_DEPENDS "${overlay_root}/patched.stamp"
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
    if(variant STREQUAL "vulnerable")
        add_dependencies(mlkem_${variant} prepare_vulnerable)
        target_include_directories(mlkem_${variant} BEFORE PRIVATE "${overlay_root}/mlkem")
        target_compile_definitions(mlkem_${variant} PRIVATE BASELINE_VULNERABLE=1)
    endif()
    foreach(program IN ITEMS baseline measure)
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
    add_custom_target(${variant} DEPENDS ${variant}_baseline ${variant}_measure)
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

if(BUILD_TESTING)
    add_executable(test_measurement tests/test_measurement.c)
    target_link_libraries(test_measurement PRIVATE mlkem_reference)
    set_target_properties(test_measurement PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
    add_test(
        NAME equivalence
        COMMAND
            "${CMAKE_COMMAND}" "-DREFERENCE_PROGRAM=$<TARGET_FILE:reference_test_equivalence>"
            "-DVULNERABLE_PROGRAM=$<TARGET_FILE:vulnerable_test_equivalence>"
            "-DOUTPUT_DIRECTORY=${output_root}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CheckEquivalence.cmake"
    )
    add_test(NAME cli COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_cli.sh"
                              "${output_root}"
    )
    add_test(NAME measurement
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_measurement.sh"
                     "${output_root}"
    )
    add_test(NAME vector_parser
             COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_vector_parser.sh"
                     "${output_root}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/mlkem768.txt"
    )
    set_tests_properties(measurement PROPERTIES RUN_SERIAL TRUE)
    add_test(NAME vector_integrity COMMAND "${SHASUM_EXECUTABLE}" -a 256 -c
                                           tests/vectors/SHA256SUMS
    )
    set_tests_properties(
        vector_integrity PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
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
