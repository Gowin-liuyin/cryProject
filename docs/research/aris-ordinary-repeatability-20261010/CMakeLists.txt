cmake_minimum_required(VERSION 3.21)
project(reference_repeatability LANGUAGES C)

include(CTest)
option(REFERENCE_REPEATABILITY_SANITIZERS "Enable ASan/UBSan; never use these builds for timing"
       OFF
)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use an out-of-source build")
endif()
if(NOT CMAKE_SYSTEM_NAME MATCHES "^(Darwin|Linux)$" OR NOT CMAKE_C_COMPILER_ID MATCHES
                                                       "^(GNU|Clang|AppleClang)$"
)
    message(FATAL_ERROR "This module supports Linux/macOS with GCC or Clang")
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
get_filename_component(repository_root "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)

add_library(reference_repeatability_options INTERFACE)
target_compile_options(
    reference_repeatability_options
    INTERFACE -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wstrict-prototypes
              -Wformat=2
              -Werror
)
target_compile_definitions(
    reference_repeatability_options INTERFACE MLK_CONFIG_FILE="baseline_config.h"
)
target_include_directories(
    reference_repeatability_options INTERFACE "${repository_root}/include"
                                              "${repository_root}/vendor/mlkem-native/mlkem"
)
if(REFERENCE_REPEATABILITY_SANITIZERS)
    target_compile_options(
        reference_repeatability_options INTERFACE -O1 -g -fsanitize=address,undefined
                                                  -fno-omit-frame-pointer
    )
    target_link_options(reference_repeatability_options INTERFACE -fsanitize=address,undefined)
endif()
add_library(
    repeatability_reference STATIC
    "${repository_root}/src/kernel.c" "${repository_root}/src/mlkem.c"
    "${repository_root}/src/random.c"
)
target_link_libraries(repeatability_reference PUBLIC reference_repeatability_options)
set_target_properties(repeatability_reference PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
add_executable(reference_repeatability reference_repeatability.c)
target_link_libraries(reference_repeatability PRIVATE repeatability_reference)
set_target_properties(reference_repeatability PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
add_executable(analyze_reference_repeatability analyze_reference_repeatability.c)
target_link_libraries(analyze_reference_repeatability PRIVATE reference_repeatability_options)
set_target_properties(analyze_reference_repeatability PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)

set(CLANG_FORMAT_EXECUTABLE
    ""
    CACHE FILEPATH "clang-format 21 for this module"
)
if(CLANG_FORMAT_EXECUTABLE)
    execute_process(
        COMMAND "${CLANG_FORMAT_EXECUTABLE}" --version
        OUTPUT_VARIABLE reference_repeatability_format_version
        RESULT_VARIABLE reference_repeatability_format_status
    )
    if(NOT reference_repeatability_format_status EQUAL 0
       OR NOT reference_repeatability_format_version MATCHES "version 21[.]"
    )
        message(FATAL_ERROR "Formatting is pinned to clang-format 21")
    endif()
    add_custom_target(
        format-check
        COMMAND
            "${CLANG_FORMAT_EXECUTABLE}" --dry-run --Werror
            "${CMAKE_CURRENT_SOURCE_DIR}/reference_repeatability.c"
            "${CMAKE_CURRENT_SOURCE_DIR}/analyze_reference_repeatability.c"
        VERBATIM
    )
endif()

if(BUILD_TESTING)
    add_test(NAME reference_repeatability_selfcheck COMMAND reference_repeatability --selfcheck)
    add_test(NAME reference_repeatability_analysis_selfcheck COMMAND analyze_reference_repeatability
                                                                     --selfcheck
    )
    add_test(NAME reference_repeatability_fixture_check COMMAND reference_repeatability
                                                                --fixture-check
    )
    add_executable(
        reference_repeatability_kat "${repository_root}/tests/test_mlkem.c"
                                    "${repository_root}/src/inputs.c"
    )
    target_link_libraries(reference_repeatability_kat PRIVATE repeatability_reference)
    set_target_properties(reference_repeatability_kat PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
    add_test(NAME reference_repeatability_nist_kat
             COMMAND reference_repeatability_kat "${repository_root}/tests/vectors/mlkem768.txt"
    )
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        add_test(NAME reference_repeatability_process_safety COMMAND reference_repeatability
                                                                     --process-safety-check
        )
    endif()
endif()
