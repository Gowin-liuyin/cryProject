include_guard(GLOBAL)

# M2 除法热点微基准独立构建模块：只被 tools/platform_m2_micro/CMakeLists.txt 引用，
# 不复用采集件构建目标，也不改动已封存的 platform-m2kem 树。
# 两条臂的 vendor 源、编译选项与告警口径与 collector-v2 完全一致，
# 差别只在新增的两个入口：微基准 m2_hotspot_microbench 与资格 m2_hotspot_qualification。
get_filename_component(platform_m2_micro_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(platform_m2_micro_sources "${platform_m2_micro_root}/tools/platform_m2_micro")
option(M2_MICRO_SANITIZERS "Enable ASan/UBSan for the M2 hotspot microbenchmark checks only" OFF)

set(M2_MICRO_HOST_FUNCTION "poly_tomsg")
set(M2_MICRO_HOST_SYMBOL "pqcrystals_kyber768_ref_poly_tomsg")

set(m2_micro_warnings
    -Wall
    -Wextra
    -Wpedantic
    -Wshadow
    -Wconversion
    -Wstrict-prototypes
    -Werror
)

set(M2_MICRO_FIXTURE_PUBLIC_KEY
    ""
    CACHE FILEPATH "M2 fixture public key (pk.bin) used by the microbenchmark qualification"
)
set(M2_MICRO_FIXTURE_SECRET_KEY
    ""
    CACHE FILEPATH "M2 fixture secret key (sk.bin) used by the microbenchmark qualification"
)
set(M2_MICRO_COLLECTOR_META
    ""
    CACHE FILEPATH "Frozen collector-v2 meta whose input_sequence_digest is re-derived"
)
set(M2_MICRO_KAT_RESPONSE
    "${platform_m2_micro_root}/tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp"
    CACHE FILEPATH "Public round3 KAT response file used by the microbenchmark qualification"
)

foreach(required_path IN ITEMS "${M2_MICRO_FIXTURE_PUBLIC_KEY}" "${M2_MICRO_FIXTURE_SECRET_KEY}"
                               "${M2_MICRO_COLLECTOR_META}" "${M2_MICRO_KAT_RESPONSE}"
)
    if(NOT EXISTS "${required_path}")
        message(FATAL_ERROR "M2 microbenchmark qualification input is missing: ${required_path}")
    endif()
endforeach()

foreach(variant IN ITEMS unfixed fixed)
    set(m2_micro_vendor_root "${platform_m2_micro_root}/vendor/kyber-kyberslash-${variant}/ref")
    if(NOT EXISTS "${m2_micro_vendor_root}/kem.c")
        message(FATAL_ERROR "M2 microbenchmark requires vendor/kyber-kyberslash-${variant}/ref")
    endif()
    add_library(
        m2_micro_${variant}_vendor STATIC
        "${m2_micro_vendor_root}/kem.c"
        "${m2_micro_vendor_root}/indcpa.c"
        "${m2_micro_vendor_root}/poly.c"
        "${m2_micro_vendor_root}/polyvec.c"
        "${m2_micro_vendor_root}/ntt.c"
        "${m2_micro_vendor_root}/cbd.c"
        "${m2_micro_vendor_root}/reduce.c"
        "${m2_micro_vendor_root}/verify.c"
        "${m2_micro_vendor_root}/fips202.c"
        "${m2_micro_vendor_root}/symmetric-shake.c"
    )
    target_include_directories(m2_micro_${variant}_vendor PUBLIC "${m2_micro_vendor_root}")
    target_compile_definitions(
        m2_micro_${variant}_vendor PRIVATE KYBER_K=3 randombytes=platform_m2_randombytes
    )
    # 与采集件相同的热点编译条件：div 机制只在普通 -Oz 构建成立。
    target_compile_options(m2_micro_${variant}_vendor PRIVATE -Oz -g -fno-vectorize
                                                               -fno-slp-vectorize
    )
    # 复用采集件同一份类定义、密文构造与类序实现（字节相同的源文件）。
    add_library(
        m2_micro_${variant} STATIC
        "${platform_m2_micro_root}/src/platform_m2_adapter.c"
        "${platform_m2_micro_root}/src/platform_m2_inputs.c"
        "${platform_m2_micro_root}/src/random.c"
        "${platform_m2_micro_root}/tools/platform_m2/collector_inputs.c"
    )
    target_include_directories(
        m2_micro_${variant}
        PUBLIC "${platform_m2_micro_root}/include" "${platform_m2_micro_root}/tools/platform_m2"
    )
    target_compile_definitions(m2_micro_${variant} PRIVATE KYBER_K=3)
    target_compile_options(m2_micro_${variant} PRIVATE ${m2_micro_warnings})
    target_link_libraries(m2_micro_${variant} PUBLIC m2_micro_${variant}_vendor)
    if(variant STREQUAL "fixed")
        target_compile_definitions(m2_micro_${variant} PRIVATE PLATFORM_M2_FIXED=1)
    endif()
    set_target_properties(
        m2_micro_${variant} m2_micro_${variant}_vendor
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
    )

    add_executable(
        m2_micro_${variant}_hotspot "${platform_m2_micro_sources}/m2_hotspot_microbench.c"
    )
    target_link_libraries(m2_micro_${variant}_hotspot PRIVATE m2_micro_${variant})
    target_compile_options(m2_micro_${variant}_hotspot PRIVATE ${m2_micro_warnings})
    set_target_properties(
        m2_micro_${variant}_hotspot
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/microbench/${variant}"
                   OUTPUT_NAME "m2_hotspot_microbench"
                   INTERPROCEDURAL_OPTIMIZATION FALSE
    )

    # 资格入口用链接期 --wrap 抓取真实解密路径喂给热点的多项式；
    # vendor 源文件保持只读，未做任何改名或补丁。
    add_executable(
        m2_micro_${variant}_qualification "${platform_m2_micro_sources}/m2_hotspot_qualification.c"
    )
    target_link_libraries(m2_micro_${variant}_qualification PRIVATE m2_micro_${variant})
    target_compile_options(m2_micro_${variant}_qualification PRIVATE ${m2_micro_warnings})
    target_link_options(
        m2_micro_${variant}_qualification PRIVATE "-Wl,--wrap=${M2_MICRO_HOST_SYMBOL}"
    )
    set_target_properties(
        m2_micro_${variant}_qualification
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qualification/${variant}"
                   OUTPUT_NAME "m2_hotspot_qualification"
                   INTERPROCEDURAL_OPTIMIZATION FALSE
    )

    if(M2_MICRO_SANITIZERS)
        foreach(sanitized_target IN ITEMS m2_micro_${variant}_vendor m2_micro_${variant}
                                       m2_micro_${variant}_hotspot
                                       m2_micro_${variant}_qualification
        )
            target_compile_options(
                ${sanitized_target} PUBLIC -O1 -g -fsanitize=address,undefined
                                           -fno-omit-frame-pointer
            )
            target_link_options(${sanitized_target} PUBLIC -fsanitize=address,undefined)
        endforeach()
    endif()

    if(BUILD_TESTING)
        # 资格测试只跑功能等价：热点输入/输出必须与同源码对照实现逐字节一致。
        add_test(
            NAME m2_micro_${variant}_qualification
            COMMAND
                m2_micro_${variant}_qualification --public-key "${M2_MICRO_FIXTURE_PUBLIC_KEY}"
                --secret-key "${M2_MICRO_FIXTURE_SECRET_KEY}" --kat-response
                "${M2_MICRO_KAT_RESPONSE}" --collector-meta "${M2_MICRO_COLLECTOR_META}"
        )
        set_tests_properties(
            m2_micro_${variant}_qualification PROPERTIES LABELS "platform;m2;micro;qualification"
        )
    endif()
endforeach()

add_custom_target(
    m2_micro DEPENDS m2_micro_unfixed_hotspot m2_micro_fixed_hotspot
                      m2_micro_unfixed_qualification m2_micro_fixed_qualification
)
