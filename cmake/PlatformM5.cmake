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

# M5 重加密路径的 Binsec checkct 裸机驱动（i386）。
#
# Binsec 0.11.3 的解码器只覆盖 32 位 x86（`-isa amd64` 在带 -sse 分析时
# 报 "Can not resolve decoder for x86-64"），所以 M5 的形式化检查必须走
# i386 裸机产物：`-ffreestanding -nostdlib -fno-pie -Wl,-e,<入口>`。
# 链接用 --gc-sections，只保留被测函数及其依赖，避免把整份 mlkem-native
# 的其他翻译单元（含 fips202）拉进来。
#
# 产物不作普通 CLI 执行，不能与 64 位采集 ELF 混为一份产物。
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR MATCHES
                                              "^(x86_64|AMD64|amd64|i.86)$"
)
    get_filename_component(platform_m5_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
    set(platform_m5_binsec_root "${platform_m5_root}/tools/platform_m5/binsec")

    # 目标一：消息编码步骤 mlk_poly_frommsg（秘密 = 32 字节消息）。
    add_executable(
        platform_m5_formal_frommsg "${platform_m5_binsec_root}/m5_binsec_harness.c"
                                    "${vendor_root}/src/compress.c"
    )
    target_compile_definitions(
        platform_m5_formal_frommsg PRIVATE M5_BINSEC_TARGET_FROMMSG=1
                                           MLK_CONFIG_FILE="m5_formal_config.h"
    )
    target_include_directories(
        platform_m5_formal_frommsg PRIVATE "${platform_m5_binsec_root}"
                                            "${vendor_root}"
                                            "${vendor_root}/src"
    )
    target_compile_options(
        platform_m5_formal_frommsg
        PRIVATE -m32
                -O1
                -g
                -ffreestanding
                -fno-pie
                -fno-stack-protector
                -fno-builtin
                -ffunction-sections
                -fdata-sections
    )
    target_link_options(
        platform_m5_formal_frommsg PRIVATE -m32 -nostdlib -no-pie
                                           -Wl,-e,m5_entry -Wl,--gc-sections
    )

    # 目标二：FO 重加密的比较步骤 mlk_ct_memcmp（秘密 = 重加密出的密文）。
    add_executable(
        platform_m5_formal_compare "${platform_m5_binsec_root}/m5_binsec_harness.c"
    )
    target_compile_definitions(
        platform_m5_formal_compare PRIVATE MLK_CONFIG_FILE="m5_formal_config.h"
    )
    target_include_directories(
        platform_m5_formal_compare PRIVATE "${platform_m5_binsec_root}"
                                            "${vendor_root}"
                                            "${vendor_root}/src"
    )
    target_compile_options(
        platform_m5_formal_compare
        PRIVATE -m32
                -O1
                -g
                -ffreestanding
                -fno-pie
                -fno-stack-protector
                -fno-builtin
                -ffunction-sections
                -fdata-sections
    )
    target_link_options(
        platform_m5_formal_compare PRIVATE -m32 -nostdlib -no-pie
                                            -Wl,-e,m5_entry -Wl,--gc-sections
    )

    foreach(formal_target platform_m5_formal_frommsg platform_m5_formal_compare)
        set_target_properties(
            ${formal_target}
            PROPERTIES C_STANDARD 11
                       C_STANDARD_REQUIRED ON
                       C_EXTENSIONS OFF
                       INTERPROCEDURAL_OPTIMIZATION FALSE
        )
    endforeach()
endif()
