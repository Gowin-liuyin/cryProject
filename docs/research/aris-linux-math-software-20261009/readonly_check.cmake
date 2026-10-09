if(NOT DEFINED M02_ROOT OR NOT DEFINED OUTPUT_ROOT)
    message(FATAL_ERROR "Missing read-only check roots")
endif()
if(DEFINED PROCESS_NUMBER)
    if(NOT PROCESS_NUMBER MATCHES "^[123]$"
       OR NOT DEFINED AUDITOR
       OR NOT DEFINED INPUT_ROOT
    )
        message(FATAL_ERROR "Missing process audit arguments")
    endif()
    set(view_root "${OUTPUT_ROOT}/process-${PROCESS_NUMBER}-view")
    set(output_path "${OUTPUT_ROOT}/process-${PROCESS_NUMBER}.json")
    set(expected_path "${M02_ROOT}/independent-audits/process-${PROCESS_NUMBER}.json")
    if(EXISTS "${view_root}" OR EXISTS "${output_path}")
        message(FATAL_ERROR "Read-only audit outputs must be new")
    endif()
    file(MAKE_DIRECTORY "${view_root}")
    file(CREATE_LINK "${M02_ROOT}/run-${PROCESS_NUMBER}" "${view_root}/run" SYMBOLIC
         RESULT link_status
    )
    if(NOT link_status STREQUAL "0")
        message(FATAL_ERROR "Cannot create audit view: ${link_status}")
    endif()
    execute_process(
        COMMAND "${AUDITOR}" "${view_root}" "${INPUT_ROOT}" "${output_path}"
        RESULT_VARIABLE check_status
        OUTPUT_VARIABLE standard_output
        ERROR_VARIABLE error_output
    )
else()
    if(NOT DEFINED SUMMARY)
        message(FATAL_ERROR "Missing summary program")
    endif()
    set(output_path "${OUTPUT_ROOT}/process-summary.json")
    set(expected_path "${M02_ROOT}/process-summary.json")
    if(EXISTS "${output_path}")
        message(FATAL_ERROR "Read-only summary output must be new")
    endif()
    execute_process(
        COMMAND "${SUMMARY}" "${M02_ROOT}" "${output_path}"
        RESULT_VARIABLE check_status
        OUTPUT_VARIABLE standard_output
        ERROR_VARIABLE error_output
    )
endif()
if(NOT check_status EQUAL 0 OR NOT EXISTS "${output_path}")
    message(FATAL_ERROR "C read-only check failed: ${standard_output}${error_output}")
endif()
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E compare_files "${output_path}" "${expected_path}"
    RESULT_VARIABLE comparison_status
)
file(SHA256 "${output_path}" actual_digest)
file(SHA256 "${expected_path}" expected_digest)
if(NOT comparison_status EQUAL 0)
    message(FATAL_ERROR "Frozen JSON mismatch: actual=${actual_digest} expected=${expected_digest}")
endif()
message(STATUS "${standard_output}Byte-identical frozen JSON: ${actual_digest}")
