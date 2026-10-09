cmake_minimum_required(VERSION 3.21)
project(linux_math_readonly_checks LANGUAGES NONE)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use a new out-of-source build")
endif()
foreach(required_path IN ITEMS AUDITOR SUMMARY M02_ROOT INPUT_ROOT OUTPUT_ROOT)
    if(NOT DEFINED ${required_path})
        message(FATAL_ERROR "Missing ${required_path}")
    endif()
endforeach()
if(NOT EXISTS "${AUDITOR}" OR NOT EXISTS "${SUMMARY}")
    message(FATAL_ERROR "Build the fixed C audit and summary programs first")
endif()
if(EXISTS "${OUTPUT_ROOT}")
    message(FATAL_ERROR "Output root must be new")
endif()
file(MAKE_DIRECTORY "${OUTPUT_ROOT}")
include(CTest)
foreach(process_number RANGE 1 3)
    add_test(
        NAME m02_readonly_process_${process_number}
        COMMAND
            "${CMAKE_COMMAND}" "-DAUDITOR=${AUDITOR}" "-DM02_ROOT=${M02_ROOT}"
            "-DINPUT_ROOT=${INPUT_ROOT}" "-DOUTPUT_ROOT=${OUTPUT_ROOT}"
            "-DPROCESS_NUMBER=${process_number}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/readonly_check.cmake"
    )
endforeach()
add_test(
    NAME m02_readonly_summary
    COMMAND "${CMAKE_COMMAND}" "-DSUMMARY=${SUMMARY}" "-DM02_ROOT=${M02_ROOT}"
            "-DOUTPUT_ROOT=${OUTPUT_ROOT}" -P "${CMAKE_CURRENT_SOURCE_DIR}/readonly_check.cmake"
)
set_tests_properties(
    m02_readonly_process_1 m02_readonly_process_2 m02_readonly_process_3 m02_readonly_summary
    PROPERTIES TIMEOUT 60 RUN_SERIAL TRUE
)
