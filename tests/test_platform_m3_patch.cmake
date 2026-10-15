if(IS_SYMLINK "${OUTPUT_DIRECTORY}")
    message(FATAL_ERROR "M3 patch test output directory must not be a symlink")
endif()
file(MAKE_DIRECTORY "${OUTPUT_DIRECTORY}")
file(COPY "${SOURCE_ROOT}/vendor/mlkem-native/mlkem" DESTINATION "${OUTPUT_DIRECTORY}")
execute_process(
    COMMAND "${PATCH_EXECUTABLE}" --dry-run --fuzz=0 -p1 -i "${PATCH_FILE}"
    WORKING_DIRECTORY "${OUTPUT_DIRECTORY}"
    RESULT_VARIABLE patch_status
)
if(NOT patch_status EQUAL 0)
    message(FATAL_ERROR "M3 patch dry run failed: ${patch_status}")
endif()
