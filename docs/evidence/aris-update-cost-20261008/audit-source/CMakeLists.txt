cmake_minimum_required(VERSION 3.21)
project(update_cost_result_review LANGUAGES C)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
add_executable(update_cost_result_review result_audit.c)
target_compile_options(
    update_cost_result_review
    PRIVATE -O2
            -fno-lto
            -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wconversion
            -Wstrict-prototypes
            -Werror
)
target_link_libraries(update_cost_result_review PRIVATE m)
include(CTest)
set(REVIEW_EVIDENCE_ROOT
    ""
    CACHE PATH "Fixed completed evidence to audit"
)
set(REVIEW_ORIGINAL_INPUT_ROOT
    ""
    CACHE PATH "Original sealed input evidence"
)
if(BUILD_TESTING)
    if(NOT IS_DIRECTORY "${REVIEW_EVIDENCE_ROOT}" OR NOT IS_DIRECTORY
                                                     "${REVIEW_ORIGINAL_INPUT_ROOT}"
    )
        message(FATAL_ERROR "Pass the fixed evidence and original input roots")
    endif()
    add_test(
        NAME independent_c_result_audit
        COMMAND update_cost_result_review "${REVIEW_EVIDENCE_ROOT}" "${REVIEW_ORIGINAL_INPUT_ROOT}"
                "${CMAKE_CURRENT_BINARY_DIR}/ctest-verification.json"
    )
endif()
