# 平台统计只处理已有数据，不触发硬件采集。
add_executable(platform_stats scripts/platform_stats/stats_csv.c src/timing_statistics.c)
target_link_libraries(platform_stats PRIVATE mlkem_reference)
if(MATH_LIBRARY)
    target_link_libraries(platform_stats PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(platform_stats PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")

set(platform_dudect_replay_program "-")
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$"
   AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dudect/src/dudect.h"
)
    add_executable(platform_dudect_replay scripts/platform_stats/dudect_replay.c)
    target_include_directories(
        platform_dudect_replay SYSTEM PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dudect/src"
    )
    if(MATH_LIBRARY)
        target_link_libraries(platform_dudect_replay PRIVATE "${MATH_LIBRARY}")
    endif()
    set_target_properties(
        platform_dudect_replay PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}"
    )
    set(platform_dudect_replay_program "$<TARGET_FILE:platform_dudect_replay>")
endif()

if(BUILD_TESTING)
    add_test(
        NAME platform_stats_battery
        COMMAND
            "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_stats_battery.sh"
            "$<TARGET_FILE:platform_stats>" "${CMAKE_CURRENT_SOURCE_DIR}"
            "${platform_dudect_replay_program}"
    )
    set_tests_properties(
        platform_stats_battery PROPERTIES LABELS platform ENVIRONMENT
                                          "A113_TEST_TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/test-tmp"
    )
endif()
