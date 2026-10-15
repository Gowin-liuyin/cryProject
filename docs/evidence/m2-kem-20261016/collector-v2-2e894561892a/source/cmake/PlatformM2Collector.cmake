include_guard(GLOBAL)

# M2 collector-v2 独立构建模块：只被 tools/platform_m2/CMakeLists.txt 引用，
# 不复用根构建的 target，也不改动已封存的 platform-m2kem 树。
get_filename_component(platform_m2_collector_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(platform_m2_collector_sources "${platform_m2_collector_root}/tools/platform_m2")
option(M2_COLLECTOR_SANITIZERS "Enable ASan/UBSan for the M2 collector software checks only" OFF)

set(m2_collector_warnings
    -Wall
    -Wextra
    -Wpedantic
    -Wshadow
    -Wconversion
    -Wstrict-prototypes
    -Werror
)

foreach(variant IN ITEMS unfixed fixed)
    set(m2_collector_vendor_root "${platform_m2_collector_root}/vendor/kyber-kyberslash-${variant}/ref")
    if(NOT EXISTS "${m2_collector_vendor_root}/kem.c")
        message(FATAL_ERROR "M2 collector requires vendor/kyber-kyberslash-${variant}/ref")
    endif()
    add_library(
        m2_collector_${variant}_vendor STATIC
        "${m2_collector_vendor_root}/kem.c"
        "${m2_collector_vendor_root}/indcpa.c"
        "${m2_collector_vendor_root}/poly.c"
        "${m2_collector_vendor_root}/polyvec.c"
        "${m2_collector_vendor_root}/ntt.c"
        "${m2_collector_vendor_root}/cbd.c"
        "${m2_collector_vendor_root}/reduce.c"
        "${m2_collector_vendor_root}/verify.c"
        "${m2_collector_vendor_root}/fips202.c"
        "${m2_collector_vendor_root}/symmetric-shake.c"
    )
    target_include_directories(m2_collector_${variant}_vendor PUBLIC "${m2_collector_vendor_root}")
    target_compile_definitions(
        m2_collector_${variant}_vendor PRIVATE KYBER_K=3 randombytes=platform_m2_randombytes
    )
    # 与已封存 platform-m2kem 树相同的热点编译条件。
    target_compile_options(
        m2_collector_${variant}_vendor PRIVATE -Oz -g -fno-vectorize -fno-slp-vectorize
    )
    add_library(
        m2_collector_${variant} STATIC
        "${platform_m2_collector_root}/src/platform_m2_adapter.c"
        "${platform_m2_collector_root}/src/platform_m2_inputs.c"
        "${platform_m2_collector_root}/src/random.c"
        "${platform_m2_collector_sources}/collector_inputs.c"
    )
    target_include_directories(
        m2_collector_${variant}
        PUBLIC "${platform_m2_collector_root}/include" "${platform_m2_collector_sources}"
    )
    target_compile_definitions(m2_collector_${variant} PRIVATE KYBER_K=3)
    target_compile_options(m2_collector_${variant} PRIVATE ${m2_collector_warnings})
    target_link_libraries(m2_collector_${variant} PUBLIC m2_collector_${variant}_vendor)
    if(variant STREQUAL "fixed")
        target_compile_definitions(m2_collector_${variant} PRIVATE PLATFORM_M2_FIXED=1)
    endif()
    set_target_properties(
        m2_collector_${variant} m2_collector_${variant}_vendor
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
    )

    add_executable(
        m2_collector_${variant}_collector "${platform_m2_collector_sources}/collector.c"
    )
    add_executable(
        m2_collector_${variant}_selftest "${platform_m2_collector_sources}/collector_selftest.c"
    )
    add_executable(
        m2_collector_${variant}_keypair "${platform_m2_collector_sources}/keypair_tool.c"
    )
    add_executable(
        m2_collector_${variant}_functional
        "${platform_m2_collector_root}/tests/test_platform_m2.c"
    )
    add_executable(
        m2_collector_${variant}_rng_failure
        "${platform_m2_collector_root}/tests/test_platform_m2_random_failure.c"
    )
    # online dudect 使用上游 RDTSC 计时，只在 x86_64 且存在上游单头库时启用。
    set(m2_collector_dudect_targets)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$"
       AND EXISTS "${platform_m2_collector_root}/third_party/dudect/src/dudect.h"
    )
        add_executable(
            m2_collector_${variant}_dudect "${platform_m2_collector_sources}/dudect_online.c"
        )
        target_include_directories(
            m2_collector_${variant}_dudect SYSTEM
            PRIVATE "${platform_m2_collector_root}/third_party/dudect/src"
        )
        find_library(M2_COLLECTOR_MATH_LIBRARY m)
        target_link_libraries(m2_collector_${variant}_dudect PRIVATE m2_collector_${variant})
        if(M2_COLLECTOR_MATH_LIBRARY)
            target_link_libraries(
                m2_collector_${variant}_dudect PRIVATE "${M2_COLLECTOR_MATH_LIBRARY}"
            )
        endif()
        set_target_properties(
            m2_collector_${variant}_dudect
            PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/collector/${variant}"
                       OUTPUT_NAME "m2_dudect"
        )
        set(m2_collector_dudect_targets m2_collector_${variant}_dudect)
    endif()
    set(m2_collector_programs
        m2_collector_${variant}_collector
        m2_collector_${variant}_selftest
        m2_collector_${variant}_keypair
        m2_collector_${variant}_functional
        m2_collector_${variant}_rng_failure
        ${m2_collector_dudect_targets}
    )
    foreach(program IN LISTS m2_collector_programs)
        target_link_libraries(${program} PRIVATE m2_collector_${variant})
        set_target_properties(${program} PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
    endforeach()
    # 只有本轮新增的源文件按仓库告警口径编译；复用的既有测试保持原状。
    foreach(program IN ITEMS m2_collector_${variant}_collector m2_collector_${variant}_selftest
                             m2_collector_${variant}_keypair
    )
        target_compile_options(${program} PRIVATE ${m2_collector_warnings})
    endforeach()
    set_target_properties(
        m2_collector_${variant}_collector
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/collector/${variant}"
                   OUTPUT_NAME "m2_decaps_collector"
    )
    set_target_properties(
        m2_collector_${variant}_selftest
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                   OUTPUT_NAME "m2_collector_selftest"
    )
    set_target_properties(
        m2_collector_${variant}_keypair
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                   OUTPUT_NAME "m2_make_keypair"
    )
    set_target_properties(
        m2_collector_${variant}_functional
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                   OUTPUT_NAME "m2_platform_functional"
    )
    set_target_properties(
        m2_collector_${variant}_rng_failure
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                   OUTPUT_NAME "m2_platform_rng_failure"
    )

    if(M2_COLLECTOR_SANITIZERS)
        foreach(sanitized_target IN ITEMS m2_collector_${variant}_vendor m2_collector_${variant}
                                       ${m2_collector_programs}
        )
            target_compile_options(
                ${sanitized_target} PUBLIC -O1 -g -fsanitize=address,undefined
                                           -fno-omit-frame-pointer
            )
            target_link_options(${sanitized_target} PUBLIC -fsanitize=address,undefined)
        endforeach()
    endif()

    if(BUILD_TESTING)
        add_test(NAME m2_collector_${variant}_selftest COMMAND m2_collector_${variant}_selftest)
        add_test(
            NAME m2_platform_${variant}_functional COMMAND m2_collector_${variant}_functional
        )
        add_test(
            NAME m2_platform_${variant}_random_failure COMMAND m2_collector_${variant}_rng_failure
        )
        add_test(
            NAME m2_collector_${variant}_cli_guards
            COMMAND
                "${CMAKE_COMMAND}"
                "-DCOLLECTOR=$<TARGET_FILE:m2_collector_${variant}_collector>"
                "-DKEYPAIR_TOOL=$<TARGET_FILE:m2_collector_${variant}_keypair>"
                "-DWORK_DIR=${CMAKE_BINARY_DIR}/qualification/${variant}/cli-guards" -P
                "${platform_m2_collector_sources}/test_collector_cli_guards.cmake"
        )
        set_tests_properties(
            m2_collector_${variant}_selftest m2_platform_${variant}_functional
            m2_platform_${variant}_random_failure m2_collector_${variant}_cli_guards
            PROPERTIES LABELS "platform;m2;collector"
        )
        if(m2_collector_dudect_targets)
            add_test(
                NAME m2_collector_${variant}_dudect_describe
                COMMAND m2_collector_${variant}_dudect --describe
            )
            set_tests_properties(
                m2_collector_${variant}_dudect_describe PROPERTIES LABELS "platform;m2;collector"
            )
        endif()
    endif()
endforeach()

if(BUILD_TESTING)
    add_test(
        NAME m2_platform_semantic_equivalence
        COMMAND
            "${CMAKE_COMMAND}"
            "-DM2_unfixed_TEST=$<TARGET_FILE:m2_collector_unfixed_functional>"
            "-DM2_fixed_TEST=$<TARGET_FILE:m2_collector_fixed_functional>" -P
            "${platform_m2_collector_root}/tests/test_platform_m2_equivalence.cmake"
    )
    add_test(
        NAME m2_collector_transcript_equivalence
        COMMAND
            "${CMAKE_COMMAND}"
            "-DM2_unfixed_SELFTEST=$<TARGET_FILE:m2_collector_unfixed_selftest>"
            "-DM2_fixed_SELFTEST=$<TARGET_FILE:m2_collector_fixed_selftest>" -P
            "${platform_m2_collector_sources}/test_collector_equivalence.cmake"
    )
    set_tests_properties(
        m2_platform_semantic_equivalence m2_collector_transcript_equivalence
        PROPERTIES LABELS "platform;m2;collector;equivalence"
    )

    find_package(OpenSSL QUIET COMPONENTS Crypto)
    if(OpenSSL_FOUND)
        foreach(variant IN ITEMS unfixed fixed)
            add_executable(
                m2_collector_${variant}_kat
                "${platform_m2_collector_root}/tests/test_platform_m2_kat.c"
                "${platform_m2_collector_root}/vendor/kyber-kyberslash-${variant}/ref/rng.c"
            )
            target_link_libraries(
                m2_collector_${variant}_kat PRIVATE m2_collector_${variant} OpenSSL::Crypto
            )
            set_target_properties(
                m2_collector_${variant}_kat
                PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                           OUTPUT_NAME "m2_platform_kat"
            )
            if(M2_COLLECTOR_SANITIZERS)
                target_compile_options(
                    m2_collector_${variant}_kat PUBLIC -O1 -g -fsanitize=address,undefined
                                                        -fno-omit-frame-pointer
                )
                target_link_options(
                    m2_collector_${variant}_kat PUBLIC -fsanitize=address,undefined
                )
            endif()
            add_test(
                NAME m2_platform_${variant}_public_kat
                COMMAND
                    m2_collector_${variant}_kat
                    "${platform_m2_collector_root}/tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp"
            )
            set_tests_properties(
                m2_platform_${variant}_public_kat PROPERTIES LABELS "platform;m2;collector;kat"
            )
        endforeach()
    else()
        message(WARNING "M2 collector public KAT needs test-only OpenSSL Crypto; not enabled")
    endif()
endif()

add_custom_target(
    m2_collector
    DEPENDS m2_collector_unfixed_collector m2_collector_fixed_collector
            m2_collector_unfixed_selftest m2_collector_fixed_selftest
)
