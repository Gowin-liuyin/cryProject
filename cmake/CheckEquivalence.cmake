set(baseline_transcript "${OUTPUT_DIRECTORY}/reference-equivalence.txt")
set(variant_transcript "${OUTPUT_DIRECTORY}/${VARIANT_NAME}-equivalence.txt")
execute_process(
    COMMAND "${BASELINE_PROGRAM}"
    OUTPUT_FILE "${baseline_transcript}"
    RESULT_VARIABLE baseline_status
)
if(NOT baseline_status EQUAL 0)
    message(FATAL_ERROR "reference equivalence run failed: ${baseline_status}")
endif()
execute_process(
    COMMAND "${VARIANT_PROGRAM}"
    OUTPUT_FILE "${variant_transcript}"
    RESULT_VARIABLE variant_status
)
if(NOT variant_status EQUAL 0)
    message(FATAL_ERROR "${VARIANT_NAME} equivalence run failed: ${variant_status}")
endif()
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E compare_files "${baseline_transcript}" "${variant_transcript}"
    RESULT_VARIABLE comparison_status
)
if(NOT comparison_status EQUAL 0)
    message(FATAL_ERROR "reference and ${VARIANT_NAME} transcripts differ")
endif()
