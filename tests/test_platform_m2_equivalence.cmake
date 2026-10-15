foreach(variant IN ITEMS unfixed fixed)
    execute_process(
        COMMAND "${M2_${variant}_TEST}" --transcript
        RESULT_VARIABLE operation_status
        OUTPUT_VARIABLE transcript_${variant}
        ERROR_VARIABLE error_text
    )
    if(NOT operation_status EQUAL 0)
        message(FATAL_ERROR "${variant} transcript failed: ${error_text}")
    endif()
endforeach()
if(NOT transcript_unfixed STREQUAL transcript_fixed)
    message(FATAL_ERROR "Public test-seed transcripts differ between M2 versions")
endif()
message(STATUS "Both M2 versions agree on key bytes and 160 ciphertext/decapsulation cases")
