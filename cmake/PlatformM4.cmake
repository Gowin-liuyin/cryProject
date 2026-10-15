include_guard(GLOBAL)

get_filename_component(platform_m4_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(platform_m4_sources "${platform_m4_root}/tools/platform_m4")
set(platform_m4_fixture "${platform_m4_root}/fixtures/early_reject_memcmp")
option(PLATFORM_M4_SANITIZERS "Enable ASan/UBSan for M4 software checks only" OFF)

foreach(compare_variant IN ITEMS vulnerable ct)
    if(compare_variant STREQUAL "vulnerable")
        set(compare_kernel "${platform_m4_fixture}/compare_early.c")
    else()
        set(compare_kernel "${platform_m4_fixture}/compare_ct.c")
    endif()
    add_library(
        platform_m4_${compare_variant}_kernel STATIC
        "${platform_m4_fixture}/compare_checked.c" "${compare_kernel}"
        "${platform_m4_sources}/inputs.c"
    )
    target_include_directories(
        platform_m4_${compare_variant}_kernel PUBLIC "${platform_m4_fixture}"
                                                     "${platform_m4_sources}"
    )
    target_compile_definitions(
        platform_m4_${compare_variant}_kernel PUBLIC M4_VARIANT_NAME="${compare_variant}"
    )
    add_executable(platform_m4_measure_${compare_variant} "${platform_m4_sources}/measure.c")
    target_link_libraries(
        platform_m4_measure_${compare_variant} PRIVATE platform_m4_${compare_variant}_kernel
    )
    set(m4_owned_targets platform_m4_${compare_variant}_kernel
                         platform_m4_measure_${compare_variant}
    )
    if(BUILD_TESTING)
        add_executable(
            test_platform_m4_${compare_variant} "${platform_m4_root}/tests/test_platform_m4.c"
        )
        target_link_libraries(
            test_platform_m4_${compare_variant} PRIVATE platform_m4_${compare_variant}_kernel
        )
        list(APPEND m4_owned_targets test_platform_m4_${compare_variant})
        add_test(NAME platform_m4_${compare_variant}_inputs
                 COMMAND test_platform_m4_${compare_variant}
        )
        add_test(NAME platform_m4_${compare_variant}_describe
                 COMMAND platform_m4_measure_${compare_variant} --describe
        )
        set_tests_properties(
            platform_m4_${compare_variant}_inputs platform_m4_${compare_variant}_describe
            PROPERTIES LABELS "platform;m4;software_only"
        )
    endif()
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$"
       AND EXISTS "${platform_m4_root}/third_party/dudect/src/dudect.h"
    )
        add_executable(
            platform_m4_dudect_${compare_variant} "${platform_m4_sources}/dudect_online.c"
        )
        target_link_libraries(
            platform_m4_dudect_${compare_variant} PRIVATE platform_m4_${compare_variant}_kernel m
        )
        target_include_directories(
            platform_m4_dudect_${compare_variant} SYSTEM
            PRIVATE "${platform_m4_root}/third_party/dudect/src"
        )
        target_compile_options(platform_m4_dudect_${compare_variant} PRIVATE -UNDEBUG)
        list(APPEND m4_owned_targets platform_m4_dudect_${compare_variant})
        if(BUILD_TESTING)
            add_test(NAME platform_m4_${compare_variant}_dudect_describe
                     COMMAND platform_m4_dudect_${compare_variant} --describe
            )
            set_tests_properties(
                platform_m4_${compare_variant}_dudect_describe
                PROPERTIES LABELS "platform;m4;software_only"
            )
        endif()
    endif()
    foreach(owned_target IN LISTS m4_owned_targets)
        set_target_properties(
            ${owned_target}
            PROPERTIES C_STANDARD 11
                       C_STANDARD_REQUIRED ON
                       C_EXTENSIONS OFF
                       INTERPROCEDURAL_OPTIMIZATION FALSE
        )
        target_compile_options(
            ${owned_target}
            PRIVATE -Wall
                    -Wextra
                    -Wpedantic
                    -Wshadow
                    -Wconversion
                    -Wstrict-prototypes
                    -Werror
        )
        if(PLATFORM_M4_SANITIZERS)
            target_compile_options(
                ${owned_target} PRIVATE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
            )
            target_link_options(${owned_target} PRIVATE -fsanitize=address,undefined)
        endif()
    endforeach()
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR MATCHES
                                              "^(x86_64|AMD64|amd64|i.86)$"
    )
        add_executable(
            platform_m4_formal_${compare_variant} "${platform_m4_sources}/binsec_harness.c"
                                                  "${compare_kernel}"
        )
        target_include_directories(
            platform_m4_formal_${compare_variant} PRIVATE "${platform_m4_fixture}"
        )
        target_compile_options(
            platform_m4_formal_${compare_variant}
            PRIVATE -m32
                    -O1
                    -g
                    -ffreestanding
                    -fno-pie
                    -fno-stack-protector
                    -fno-builtin
        )
        target_link_options(
            platform_m4_formal_${compare_variant} PRIVATE -m32 -nostdlib -no-pie -Wl,-e,m4_entry
        )
        set_target_properties(
            platform_m4_formal_${compare_variant}
            PROPERTIES C_STANDARD 11
                       C_STANDARD_REQUIRED ON
                       C_EXTENSIONS OFF
                       INTERPROCEDURAL_OPTIMIZATION FALSE
        )
    endif()
endforeach()

if(BUILD_TESTING)
    add_test(
        NAME platform_m4_cli_rejections
        COMMAND
            "${CMAKE_COMMAND}" "-DVULNERABLE_PROGRAM=$<TARGET_FILE:platform_m4_measure_vulnerable>"
            "-DCT_PROGRAM=$<TARGET_FILE:platform_m4_measure_ct>" -P
            "${platform_m4_root}/tests/test_platform_m4_cli.cmake"
    )
    set_tests_properties(platform_m4_cli_rejections PROPERTIES LABELS "platform;m4;software_only")
endif()
