cmake_minimum_required(VERSION 3.21)
project(frequency_workload LANGUAGES C)

include(CTest)
option(FREQUENCY_WINDOW_SANITIZERS "Enable ASan/UBSan; these timings are diagnostic only" OFF)
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

add_library(frequency_options INTERFACE)
target_compile_options(
    frequency_options
    INTERFACE -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wstrict-prototypes
              -Wformat=2
              -Werror
)
target_compile_definitions(frequency_options INTERFACE MLK_CONFIG_FILE="baseline_config.h")
target_include_directories(
    frequency_options INTERFACE "${repository_root}/include"
                                "${repository_root}/vendor/mlkem-native/mlkem"
)
if(FREQUENCY_WINDOW_SANITIZERS)
    target_compile_options(
        frequency_options INTERFACE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
    )
    target_link_options(frequency_options INTERFACE -fsanitize=address,undefined)
endif()
add_library(
    frequency_reference STATIC "${repository_root}/src/kernel.c" "${repository_root}/src/mlkem.c"
                               "${repository_root}/src/random.c"
)
target_link_libraries(frequency_reference PUBLIC frequency_options)
set_target_properties(frequency_reference PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
add_executable(frequency_workload frequency_workload.c)
target_link_libraries(frequency_workload PRIVATE frequency_reference)
set_target_properties(frequency_workload PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)

if(BUILD_TESTING)
    add_test(NAME frequency_workload_selfcheck COMMAND frequency_workload --selfcheck)
    add_executable(
        frequency_reference_kat "${repository_root}/tests/test_mlkem.c"
                                "${repository_root}/src/inputs.c"
    )
    target_link_libraries(frequency_reference_kat PRIVATE frequency_reference)
    set_target_properties(frequency_reference_kat PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
    add_test(NAME frequency_reference_kat COMMAND frequency_reference_kat
                                                  "${repository_root}/tests/vectors/mlkem768.txt"
    )
endif()
