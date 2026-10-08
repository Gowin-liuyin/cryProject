cmake_minimum_required(VERSION 3.21)
project(update_cost_result_review LANGUAGES C)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use an out-of-source audit build directory")
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
add_executable(update_cost_result_review result_audit.c)
target_compile_options(
    update_cost_result_review
    PRIVATE -O2
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
target_link_options(update_cost_result_review PRIVATE -fno-lto)
target_link_libraries(update_cost_result_review PRIVATE m)
include(CTest)
set(REVIEW_EVIDENCE_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../frozen-evidence"
    CACHE PATH "Fixed completed evidence to audit"
)
set(REVIEW_ORIGINAL_INPUT_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../inputs"
    CACHE PATH "Original sealed input copies in this export"
)
file(
    WRITE "${CMAKE_CURRENT_BINARY_DIR}/source-manifest.txt"
    "source_identity=SOURCE-MATH-COST-01\nsource_identity_kind=anonymous_source_alias_not_git\ncompiler=${CMAKE_C_COMPILER}\ncompiler_id=${CMAKE_C_COMPILER_ID}\ncompiler_version=${CMAKE_C_COMPILER_VERSION}\nsystem=${CMAKE_SYSTEM_NAME}\narchitecture=${CMAKE_SYSTEM_PROCESSOR}\noptimization=-O2\nlto=disabled\nsanitizers=OFF\n"
)
foreach(source_path IN ITEMS result_audit.c CMakeLists.txt audit_check.cmake)
    file(SHA256 "${CMAKE_CURRENT_SOURCE_DIR}/${source_path}" source_digest)
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/source-manifest.txt"
         "sha256=${source_digest}  audit/${source_path}\n"
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
        COMMAND "${CLANG_FORMAT_EXECUTABLE}" --dry-run --Werror
                "${CMAKE_CURRENT_SOURCE_DIR}/result_audit.c"
        VERBATIM
    )
endif()
if(BUILD_TESTING)
    if(NOT IS_DIRECTORY "${REVIEW_EVIDENCE_ROOT}" OR NOT IS_DIRECTORY
                                                     "${REVIEW_ORIGINAL_INPUT_ROOT}"
    )
        message(FATAL_ERROR "Pass the fixed evidence and original input roots")
    endif()
    add_test(
        NAME independent_c_result_audit
        COMMAND
            "${CMAKE_COMMAND}" "-DAUDITOR=$<TARGET_FILE:update_cost_result_review>"
            "-DEVIDENCE_ROOT=${REVIEW_EVIDENCE_ROOT}" "-DINPUT_ROOT=${REVIEW_ORIGINAL_INPUT_ROOT}"
            "-DCHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/audit_check.cmake"
    )
endif()
