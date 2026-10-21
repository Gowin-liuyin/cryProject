# 非 x86 平台上的回归项：tsc_calibration 必须明确拒绝，且不得写出任何产物。
#
# 目的是防止「在没有 rdtsc 的机器上给出假测量值」这种静默失败。
if(NOT DEFINED PROGRAM)
    message(FATAL_ERROR "PROGRAM is required")
endif()

set(interval_csv "${CMAKE_CURRENT_BINARY_DIR}/unsupported-intervals.csv")
set(summary_txt "${CMAKE_CURRENT_BINARY_DIR}/unsupported-summary.txt")
file(REMOVE "${interval_csv}" "${summary_txt}")

execute_process(
    COMMAND "${PROGRAM}" 1 100000 32 "${interval_csv}" "${summary_txt}"
    RESULT_VARIABLE exit_code
    OUTPUT_VARIABLE standard_output
    ERROR_VARIABLE standard_error
)

if(exit_code EQUAL 0)
    message(FATAL_ERROR "tool must fail on a platform without rdtsc")
endif()
string(FIND "${standard_error}" "requires x86 rdtsc" guard_position)
if(guard_position EQUAL -1)
    message(FATAL_ERROR "tool must say that it requires x86 rdtsc, got: ${standard_error}")
endif()
if(EXISTS "${interval_csv}" OR EXISTS "${summary_txt}")
    message(FATAL_ERROR "tool must not write outputs on an unsupported platform")
endif()
