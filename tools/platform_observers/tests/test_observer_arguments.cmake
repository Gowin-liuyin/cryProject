# P5 观测者非法参数退出码断言：三个观测者对非法参数必须退出 2，且不创建输出文件。
foreach(observer_case
    "SMT;--div-batch;0"
    "SMT;--cpu;not-a-cpu"
    "CACHE;--samples;0"
    "CACHE;--map;missing.bin"
    "BTB;--iterations;0"
    "BTB;--batches;0"
)
    list(GET observer_case 0 observer_kind)
    list(GET observer_case 1 observer_flag)
    list(GET observer_case 2 observer_value)
    if(observer_kind STREQUAL "SMT")
        set(observer_program "${SMT_PROGRAM}")
    elseif(observer_kind STREQUAL "CACHE")
        set(observer_program "${CACHE_PROGRAM}")
    else()
        set(observer_program "${BTB_PROGRAM}")
    endif()
    execute_process(
        COMMAND "${observer_program}" "${observer_flag}" "${observer_value}"
        RESULT_VARIABLE observer_status
        OUTPUT_QUIET
        ERROR_QUIET
    )
    if(NOT observer_status EQUAL 2)
        message(
            FATAL_ERROR
                "${observer_kind} ${observer_flag} ${observer_value}: expected exit 2, got ${observer_status}"
        )
    endif()
endforeach()
message(STATUS "observer invalid-argument exit codes are 2")
