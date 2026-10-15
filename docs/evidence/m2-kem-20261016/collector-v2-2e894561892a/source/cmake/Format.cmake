if(NOT FORMAT_EXECUTABLE)
    if(APPLE)
        execute_process(
            COMMAND xcrun --find clang-format
            OUTPUT_VARIABLE apple_formatter
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
        )
        if(EXISTS "${apple_formatter}")
            set(FORMAT_EXECUTABLE "${apple_formatter}")
        endif()
    endif()
    if(NOT FORMAT_EXECUTABLE)
        find_program(FORMAT_EXECUTABLE NAMES clang-format-21 clang-format)
    endif()
endif()
if(NOT FORMAT_EXECUTABLE)
    message(FATAL_ERROR "Install clang-format 21 or configure CLANG_FORMAT_EXECUTABLE")
endif()
execute_process(
    COMMAND "${FORMAT_EXECUTABLE}" --version
    OUTPUT_VARIABLE formatter_version
    RESULT_VARIABLE version_status
)
if(NOT version_status EQUAL 0 OR NOT formatter_version MATCHES "version 21\\.")
    message(FATAL_ERROR "Formatting is pinned to clang-format 21; found: ${formatter_version}")
endif()
file(
    GLOB
    owned_sources
    "${SOURCE_ROOT}/src/*.c"
    "${SOURCE_ROOT}/include/*.h"
    "${SOURCE_ROOT}/tests/*.c"
    "${SOURCE_ROOT}/scripts/platform_stats/*.c"
    "${SOURCE_ROOT}/fixtures/mem_lut_leak/*.c"
    "${SOURCE_ROOT}/fixtures/mem_lut_leak/*.h"
    "${SOURCE_ROOT}/fixtures/early_reject_memcmp/*.c"
    "${SOURCE_ROOT}/fixtures/early_reject_memcmp/*.h"
)
if(FORMAT_MODE STREQUAL "format")
    set(format_arguments -i)
else()
    set(format_arguments --dry-run --Werror)
endif()
execute_process(
    COMMAND "${FORMAT_EXECUTABLE}" --style=file ${format_arguments} ${owned_sources}
    WORKING_DIRECTORY "${SOURCE_ROOT}"
    RESULT_VARIABLE format_status
)
if(NOT format_status EQUAL 0)
    message(FATAL_ERROR "C style check failed; run the format target, then inspect the diff")
endif()
