include_guard(GLOBAL)

# M5 复用未打补丁的参考内核，避免再维护一套密码适配。
add_library(platform_m5_mlkem ALIAS mlkem_reference)
add_custom_target(platform_m5 DEPENDS reference_baseline)
if(TARGET reference_measure)
    add_custom_target(platform_m5_measure DEPENDS reference_measure)
endif()
if(TARGET check-reference)
    add_custom_target(platform_m5_check DEPENDS check-reference)
endif()
