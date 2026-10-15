file(MAKE_DIRECTORY "${OVERLAY_ROOT}")
# 诊断覆盖层只存在于构建目录。vendor 原件和正式变体覆盖层都不改。
file(REMOVE_RECURSE "${OVERLAY_ROOT}/mlkem")
file(COPY "${SOURCE_ROOT}/vendor/mlkem-native/mlkem" DESTINATION "${OVERLAY_ROOT}")
if(NOT MECHANISM_PATCH_FILE STREQUAL "")
    execute_process(
        COMMAND "${PATCH_EXECUTABLE}" -p1 --forward -i "${MECHANISM_PATCH_FILE}"
        WORKING_DIRECTORY "${OVERLAY_ROOT}"
        RESULT_VARIABLE mechanism_patch_status
    )
    if(NOT mechanism_patch_status EQUAL 0)
        message(FATAL_ERROR "Applying ${MECHANISM_PATCH_FILE} failed: ${mechanism_patch_status}")
    endif()
endif()
execute_process(
    COMMAND "${PATCH_EXECUTABLE}" -p1 --forward -i "${DIAGNOSTIC_PATCH_FILE}"
    WORKING_DIRECTORY "${OVERLAY_ROOT}"
    RESULT_VARIABLE diagnostic_patch_status
)
if(NOT diagnostic_patch_status EQUAL 0)
    message(FATAL_ERROR "Applying ${DIAGNOSTIC_PATCH_FILE} failed: ${diagnostic_patch_status}")
endif()
file(TOUCH "${OVERLAY_ROOT}/patched.stamp")
