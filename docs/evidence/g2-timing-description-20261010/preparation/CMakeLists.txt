cmake_minimum_required(VERSION 3.21)
project(analyze_frequency_windows LANGUAGES C)

include(CTest)
option(FREQUENCY_ANALYSIS_SANITIZERS "Enable ASan/UBSan" OFF)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use an out-of-source build")
endif()
if(NOT CMAKE_C_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang)$")
    message(FATAL_ERROR "This module requires GCC or Clang")
endif()
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE
        RelWithDebInfo
        CACHE STRING "Build configuration" FORCE
    )
endif()
add_executable(analyze_windows analyze_windows.c)
target_compile_options(
    analyze_windows
    PRIVATE -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wconversion
            -Wstrict-prototypes
            -Wformat=2
            -Werror
)
set_target_properties(analyze_windows PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
if(FREQUENCY_ANALYSIS_SANITIZERS)
    target_compile_options(
        analyze_windows PRIVATE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
    )
    target_link_options(analyze_windows PRIVATE -fsanitize=address,undefined)
endif()
if(BUILD_TESTING)
    add_test(NAME frequency_analysis_selfcheck COMMAND analyze_windows --selfcheck)
    add_test(NAME frequency_timing_description_selfcheck COMMAND analyze_windows --timing-selfcheck)
endif()
