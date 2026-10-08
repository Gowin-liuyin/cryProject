if(NOT DEFINED OBSERVER
   OR NOT DEFINED CHECK_ROOT
   OR NOT DEFINED SANITIZERS
)
    message(FATAL_ERROR "Missing software-check arguments")
endif()
string(
    RANDOM
    LENGTH 12
    ALPHABET "0123456789abcdef" fixture_suffix
)
set(fixture_output "${CHECK_ROOT}/failure-check-${fixture_suffix}")
set(missing_input "${CHECK_ROOT}/missing-input-${fixture_suffix}")
execute_process(
    COMMAND "${OBSERVER}" "${missing_input}" "${fixture_output}"
    RESULT_VARIABLE failure_status
    OUTPUT_VARIABLE standard_output
    ERROR_VARIABLE error_output
)
if(SANITIZERS)
    if(NOT failure_status EQUAL 2 OR EXISTS "${fixture_output}")
        message(FATAL_ERROR "Sanitizer formal-run guard failed: ${error_output}")
    endif()
else()
    if(NOT failure_status EQUAL 1 OR NOT EXISTS "${fixture_output}/final-state.meta")
        message(FATAL_ERROR "Missing-input failure was not preserved: ${error_output}")
    endif()
    file(READ "${fixture_output}/final-state.meta" failure_state)
    foreach(required_state IN ITEMS "final_state=partial" "warmup_count=0" "formal_count=0"
                                    "consumed_results=0"
    )
        if(NOT failure_state MATCHES "${required_state}\n")
            message(FATAL_ERROR "Missing failure state field: ${required_state}")
        endif()
    endforeach()
    file(SHA256 "${fixture_output}/final-state.meta" state_before)
    execute_process(
        COMMAND "${OBSERVER}" "${missing_input}" "${fixture_output}"
        RESULT_VARIABLE existing_directory_status
        OUTPUT_QUIET ERROR_QUIET
    )
    file(SHA256 "${fixture_output}/final-state.meta" state_after)
    if(NOT existing_directory_status EQUAL 1 OR NOT state_before STREQUAL state_after)
        message(FATAL_ERROR "Existing output directory was changed")
    endif()
endif()
message(STATUS "Failure-path software check passed; no statistics window was executed")
