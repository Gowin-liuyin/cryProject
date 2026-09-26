foreach(variant IN ITEMS REFERENCE VULNERABLE)
    execute_process(COMMAND "${${variant}_PROGRAM}"
        OUTPUT_FILE "${OUTPUT_DIRECTORY}/${variant}-equivalence.txt" RESULT_VARIABLE test_status)
    if(NOT test_status EQUAL 0)
        message(FATAL_ERROR "${variant} equivalence run failed: ${test_status}")
    endif()
endforeach()
execute_process(COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${OUTPUT_DIRECTORY}/REFERENCE-equivalence.txt" "${OUTPUT_DIRECTORY}/VULNERABLE-equivalence.txt"
    RESULT_VARIABLE comparison_status)
if(NOT comparison_status EQUAL 0)
    message(FATAL_ERROR "Reference and vulnerable transcripts differ")
endif()
