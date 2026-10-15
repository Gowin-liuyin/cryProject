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

# Holm 家族管理与固定效应合并只读 CSV，自身不依赖密码库或 libm 以外的运行库。
add_executable(platform_holm tools/platform_stats/holm.c)
if(MATH_LIBRARY)
    target_link_libraries(platform_holm PRIVATE "${MATH_LIBRARY}")
endif()
set_target_properties(
    platform_holm
    PROPERTIES C_STANDARD 11
               C_STANDARD_REQUIRED ON
               C_EXTENSIONS OFF
               INTERPROCEDURAL_OPTIMIZATION FALSE
               RUNTIME_OUTPUT_DIRECTORY "${output_root}"
)
target_compile_options(
    platform_holm
    PRIVATE -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wconversion
            -Wstrict-prototypes
            -Werror
)
# 这两个目标不链接 baseline_options（不需要密码头文件），sanitizer 选项要单独跟上，
# 否则 sanitizer 配置下等于没跑。
if(BASELINE_SANITIZERS)
    target_compile_options(platform_holm PRIVATE -O1 -g -fsanitize=address,undefined
                                                  -fno-omit-frame-pointer
    )
    target_link_options(platform_holm PRIVATE -fsanitize=address,undefined)
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

    # 测试自己挑临时根，仍优先使用 CTest 指定的 A113_TEST_TMPDIR。
    add_executable(test_platform_holm tests/test_platform_holm.c)
    target_compile_options(
        test_platform_holm
        PRIVATE -Wall
                -Wextra
                -Wpedantic
                -Wshadow
                -Wconversion
                -Wstrict-prototypes
                -Werror
                -UNDEBUG
    )
    if(BASELINE_SANITIZERS)
        target_compile_options(test_platform_holm PRIVATE -O1 -g -fsanitize=address,undefined
                                                          -fno-omit-frame-pointer
        )
        target_link_options(test_platform_holm PRIVATE -fsanitize=address,undefined)
    endif()
    add_test(NAME platform_holm COMMAND test_platform_holm "$<TARGET_FILE:platform_holm>")
    set_tests_properties(
        platform_holm PROPERTIES LABELS "platform;stats;software_only" ENVIRONMENT
                                   "A113_TEST_TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/test-tmp"
    )
endif()
