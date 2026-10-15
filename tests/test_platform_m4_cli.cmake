foreach(program IN ITEMS "${VULNERABLE_PROGRAM}" "${CT_PROGRAM}")
    execute_process(
        COMMAND "${program}" --describe
        RESULT_VARIABLE describe_status
        OUTPUT_VARIABLE description
        ERROR_VARIABLE describe_error
    )
    if(NOT describe_status EQUAL 0 OR NOT description MATCHES "timing_collection=not_run")
        message(FATAL_ERROR "M4 describe failed: ${describe_error}")
    endif()
    foreach(invalid_call IN ITEMS "no_arguments" "zero_count" "zero_seed" "signed_count"
                                  "bad_run_id"
    )
        if(invalid_call STREQUAL "no_arguments")
            set(invalid_arguments)
        elseif(invalid_call STREQUAL "zero_count")
            set(invalid_arguments --collect must-not-create.csv 0 1 test)
        elseif(invalid_call STREQUAL "zero_seed")
            set(invalid_arguments --collect must-not-create.csv 2 0 test)
        elseif(invalid_call STREQUAL "signed_count")
            set(invalid_arguments --collect must-not-create.csv -2 1 test)
        else()
            set(invalid_arguments --collect must-not-create.csv 2 1 "invalid,run")
        endif()
        execute_process(
            COMMAND "${program}" ${invalid_arguments}
            RESULT_VARIABLE rejection_status
            OUTPUT_QUIET ERROR_QUIET
        )
        if(NOT rejection_status EQUAL 2)
            message(FATAL_ERROR "M4 must reject ${invalid_call} before collection")
        endif()
    endforeach()
endforeach()
