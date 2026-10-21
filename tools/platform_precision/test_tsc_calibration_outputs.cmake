# 校验 tsc_calibration 的产物：文件存在、行数与表头一致、摘要含关键字段。
#
# 判据只覆盖「产物形状」，不覆盖任何测量结论（测量结论由实跑数据负责）。
if(NOT DEFINED PROGRAM OR NOT DEFINED WORK_DIR)
    message(FATAL_ERROR "PROGRAM and WORK_DIR are required")
endif()

set(interval_csv "${WORK_DIR}/intervals.csv")
set(summary_txt "${WORK_DIR}/summary.txt")

foreach(required_path "${interval_csv}" "${summary_txt}")
    if(NOT EXISTS "${required_path}")
        message(FATAL_ERROR "missing output: ${required_path}")
    endif()
endforeach()

file(READ "${summary_txt}" summary_content)
foreach(keyword
    "tsc_rate_khz="
    "rdtsc_resolution_counts,"
    "short_interval_implied_frequency_khz,"
    "kernel_scaling_cur_freq_khz,"
    "has_tsc=1"
)
    string(FIND "${summary_content}" "${keyword}" keyword_position)
    if(keyword_position EQUAL -1)
        message(FATAL_ERROR "summary is missing ${keyword}")
    endif()
endforeach()

file(STRINGS "${interval_csv}" interval_lines)
list(LENGTH interval_lines interval_line_count)
if(interval_line_count LESS 2)
    message(FATAL_ERROR "interval CSV must have a header and at least one row")
endif()
list(GET interval_lines 0 interval_header)
if(NOT interval_header STREQUAL "index,tsc_delta,monotonic_delta_nanoseconds,kernel_frequency_kilohertz")
    message(FATAL_ERROR "unexpected interval CSV header: ${interval_header}")
endif()
math(EXPR expected_rows "32 + 1")
if(NOT interval_line_count EQUAL expected_rows)
    message(FATAL_ERROR "interval CSV has ${interval_line_count} lines, expected ${expected_rows}")
endif()
