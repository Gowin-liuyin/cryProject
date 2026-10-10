cmake_minimum_required(VERSION 3.21)
project(raw_clock_calibration LANGUAGES C)

include(CTest)
option(RAW_CLOCK_SANITIZERS "Enable ASan/UBSan; never use these builds for calibration" OFF)
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

add_executable(raw_clock_calibration raw_clock_calibration.c)
add_executable(analyze_raw_clock analyze_raw_clock.c)
foreach(raw_clock_target IN ITEMS raw_clock_calibration analyze_raw_clock)
    set_target_properties(${raw_clock_target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
    target_compile_options(
        ${raw_clock_target}
        PRIVATE -Wall
                -Wextra
                -Wpedantic
                -Wshadow
                -Wconversion
                -Wstrict-prototypes
                -Wformat=2
                -Werror
    )
    if(RAW_CLOCK_SANITIZERS)
        target_compile_options(
            ${raw_clock_target} PRIVATE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
        )
        target_link_options(${raw_clock_target} PRIVATE -fsanitize=address,undefined)
    endif()
endforeach()

set(CLANG_FORMAT_EXECUTABLE
    ""
    CACHE FILEPATH "clang-format 21 for this module"
)
if(CLANG_FORMAT_EXECUTABLE)
    execute_process(
        COMMAND "${CLANG_FORMAT_EXECUTABLE}" --version
        OUTPUT_VARIABLE raw_clock_format_version
        RESULT_VARIABLE raw_clock_format_status
    )
    if(NOT raw_clock_format_status EQUAL 0 OR NOT raw_clock_format_version MATCHES "version 21[.]")
        message(FATAL_ERROR "Formatting is pinned to clang-format 21")
    endif()
    add_custom_target(
        format-check
        COMMAND "${CLANG_FORMAT_EXECUTABLE}" --dry-run --Werror
                "${CMAKE_CURRENT_SOURCE_DIR}/raw_clock_calibration.c"
                "${CMAKE_CURRENT_SOURCE_DIR}/analyze_raw_clock.c"
        VERBATIM
    )
endif()

if(BUILD_TESTING)
    add_test(NAME raw_clock_calibration_selfcheck COMMAND raw_clock_calibration --selfcheck)
    add_test(NAME raw_clock_analysis_selfcheck COMMAND analyze_raw_clock --selfcheck)
endif()
