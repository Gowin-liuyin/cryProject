if(NOT DEFINED AUDITOR
   OR NOT DEFINED EVIDENCE_ROOT
   OR NOT DEFINED INPUT_ROOT
   OR NOT DEFINED CHECK_ROOT
)
    message(FATAL_ERROR "Missing independent audit arguments")
endif()
string(
    RANDOM
    LENGTH 16
    ALPHABET "0123456789abcdef" audit_suffix
)
set(audit_output "${CHECK_ROOT}/ctest-verification-${audit_suffix}.json")
if(EXISTS "${audit_output}")
    message(FATAL_ERROR "New audit output name already exists")
endif()
execute_process(
    COMMAND "${AUDITOR}" "${EVIDENCE_ROOT}" "${INPUT_ROOT}" "${audit_output}"
    RESULT_VARIABLE audit_status
    OUTPUT_VARIABLE standard_output
    ERROR_VARIABLE error_output
)
if(NOT audit_status EQUAL 0 OR NOT EXISTS "${audit_output}")
    message(FATAL_ERROR "Independent C audit failed: ${standard_output}${error_output}")
endif()
message(STATUS "${standard_output}New audit output: ${audit_output}")
