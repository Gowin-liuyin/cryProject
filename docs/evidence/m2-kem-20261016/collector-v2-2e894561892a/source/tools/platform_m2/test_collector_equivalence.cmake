# 跨版本等价：两个变体的 collector 类语义/隐式拒绝/类顺序转录必须逐字节相同。
foreach(variant IN ITEMS unfixed fixed)
    execute_process(
        COMMAND "${M2_${variant}_SELFTEST}" --transcript
        RESULT_VARIABLE operation_status
        OUTPUT_VARIABLE transcript_${variant}
        ERROR_VARIABLE error_text
    )
    if(NOT operation_status EQUAL 0)
        message(FATAL_ERROR "${variant} collector transcript failed: ${error_text}")
    endif()
endforeach()
if(NOT transcript_unfixed STREQUAL transcript_fixed)
    message(
        FATAL_ERROR
            "Collector class/rejection/schedule transcripts differ between M2 versions"
    )
endif()
message(
    STATUS
        "Both M2 versions agree on collector class ciphertexts, decapsulation outputs, rejection secrets and schedules"
)
