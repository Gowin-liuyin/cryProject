cmake_minimum_required(VERSION 3.21)
project(update_cost LANGUAGES C)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use the dedicated out-of-source build directory")
endif()
if(NOT CMAKE_SYSTEM_NAME MATCHES "^(Darwin|Linux)$" OR NOT CMAKE_C_COMPILER_ID MATCHES
                                                       "^(GNU|Clang|AppleClang)$"
)
    message(FATAL_ERROR "Requires Linux/macOS and GCC/Clang")
endif()
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION FALSE)
option(UPDATE_COST_SANITIZERS "ASan/UBSan self-check only; formal execution is disabled" OFF)
include(CTest)

add_library(update_cost_options INTERFACE)
target_include_directories(update_cost_options INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/snapshots")
target_compile_options(
    update_cost_options
    INTERFACE -O2
              -g
              -fno-lto
              -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wstrict-prototypes
              -Werror
)
target_link_options(update_cost_options INTERFACE -fno-lto)
if(UPDATE_COST_SANITIZERS)
    target_compile_options(
        update_cost_options INTERFACE -fsanitize=address,undefined -fno-omit-frame-pointer
    )
    target_link_options(update_cost_options INTERFACE -fsanitize=address,undefined)
    target_compile_definitions(update_cost_options INTERFACE UPDATE_COST_SANITIZERS=1)
else()
    target_compile_definitions(update_cost_options INTERFACE UPDATE_COST_SANITIZERS=0)
endif()

add_library(incremental_snapshot OBJECT snapshots/controlled_snapshot.c)
target_compile_definitions(
    incremental_snapshot PRIVATE compute_controlled_result=compute_incremental_controlled_result
)
target_link_libraries(incremental_snapshot PRIVATE update_cost_options)
add_library(naive_snapshot OBJECT snapshots/naive_snapshot.c)
target_compile_definitions(
    naive_snapshot PRIVATE compute_controlled_result=compute_naive_controlled_result
)
target_link_libraries(naive_snapshot PRIVATE update_cost_options)
add_library(paired_snapshot OBJECT snapshots/paired_statistics_snapshot.c)
target_link_libraries(paired_snapshot PRIVATE update_cost_options)
add_executable(
    update_cost update_cost.c $<TARGET_OBJECTS:incremental_snapshot>
                $<TARGET_OBJECTS:naive_snapshot> $<TARGET_OBJECTS:paired_snapshot>
)
target_link_libraries(update_cost PRIVATE update_cost_options m)

file(
    WRITE "${CMAKE_CURRENT_BINARY_DIR}/source-manifest.txt"
    "source_identity=SOURCE-MATH-COST-01\nsource_identity_kind=anonymous_source_alias_not_git\ncompiler=${CMAKE_C_COMPILER}\ncompiler_id=${CMAKE_C_COMPILER_ID}\ncompiler_version=${CMAKE_C_COMPILER_VERSION}\nsystem=${CMAKE_SYSTEM_NAME}\narchitecture=${CMAKE_SYSTEM_PROCESSOR}\noptimization=-O2\nlto=disabled\nsanitizers=${UPDATE_COST_SANITIZERS}\nworking_tree_status=unavailable_export_without_git\n"
)
foreach(
    snapshot_path IN
    ITEMS snapshots/controlled_snapshot.c
          snapshots/naive_snapshot.c
          snapshots/paired_statistics_snapshot.c
          snapshots/controlled_statistics.h
          snapshots/paired_statistics.h
          update_cost.c
          update_cost.h
          failure_check.cmake
          CMakeLists.txt
          audit/result_audit.c
          audit/CMakeLists.txt
          audit/audit_check.cmake
)
    file(SHA256 "${CMAKE_CURRENT_SOURCE_DIR}/${snapshot_path}" source_digest)
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/source-manifest.txt"
         "sha256=${source_digest}  ${snapshot_path}\n"
    )
endforeach()

find_program(CLANG_FORMAT_EXECUTABLE NAMES clang-format)
if(NOT CLANG_FORMAT_EXECUTABLE AND CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    execute_process(
        COMMAND xcrun --find clang-format
        OUTPUT_VARIABLE CLANG_FORMAT_EXECUTABLE
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()
if(CLANG_FORMAT_EXECUTABLE)
    add_custom_target(
        format-check
        COMMAND
            "${CLANG_FORMAT_EXECUTABLE}" --dry-run --Werror
            "${CMAKE_CURRENT_SOURCE_DIR}/update_cost.c" "${CMAKE_CURRENT_SOURCE_DIR}/update_cost.h"
        VERBATIM
    )
endif()
if(BUILD_TESTING)
    add_test(NAME update_cost_selfcheck COMMAND update_cost --selftest)
    add_test(NAME update_cost_fixed_inputs COMMAND update_cost --check-inputs
                                                   "${CMAKE_CURRENT_SOURCE_DIR}/inputs"
    )
    add_test(
        NAME update_cost_failure_record
        COMMAND
            "${CMAKE_COMMAND}" "-DOBSERVER=$<TARGET_FILE:update_cost>"
            "-DCHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}" "-DSANITIZERS=${UPDATE_COST_SANITIZERS}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/failure_check.cmake"
    )
endif()
