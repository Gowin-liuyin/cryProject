file(MAKE_DIRECTORY "${OVERLAY_ROOT}")
# 只替换构建目录中的派生副本，vendor 原件保持不动。
file(REMOVE_RECURSE "${OVERLAY_ROOT}/mlkem")
file(COPY "${SOURCE_ROOT}/vendor/mlkem-native/mlkem" DESTINATION "${OVERLAY_ROOT}")
execute_process(COMMAND "${PATCH_EXECUTABLE}" -p1 -i "${SOURCE_ROOT}/docs/patches/message-branch.patch"
    WORKING_DIRECTORY "${OVERLAY_ROOT}" RESULT_VARIABLE patch_status)
if(NOT patch_status EQUAL 0)
    message(FATAL_ERROR "Applying the vulnerable encoder patch failed: ${patch_status}")
endif()
file(TOUCH "${OVERLAY_ROOT}/patched.stamp")
