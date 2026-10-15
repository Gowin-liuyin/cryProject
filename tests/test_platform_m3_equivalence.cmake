foreach(fixture_mode IN ITEMS REFERENCE ON OFF)
    set(transcript_path "${OUTPUT_DIRECTORY}/${fixture_mode}.public-test-transcript")
    execute_process(
        COMMAND "${${fixture_mode}_PROGRAM}"
        OUTPUT_FILE "${transcript_path}"
        RESULT_VARIABLE transcript_status
    )
    if(NOT transcript_status EQUAL 0)
        message(FATAL_ERROR "M3 ${fixture_mode} public transcript failed: ${transcript_status}")
    endif()
endforeach()
foreach(fixture_mode IN ITEMS ON OFF)
    execute_process(
        COMMAND
            "${CMAKE_COMMAND}" -E compare_files
            "${OUTPUT_DIRECTORY}/REFERENCE.public-test-transcript"
            "${OUTPUT_DIRECTORY}/${fixture_mode}.public-test-transcript"
        RESULT_VARIABLE equivalence_status
    )
    if(NOT equivalence_status EQUAL 0)
        message(FATAL_ERROR "M3 ${fixture_mode} full-byte outputs differ from reference")
    endif()
endforeach()
message(STATUS "M3 public-seed full-byte equivalence: reference/on/off, 64 seeds x 5 categories")
