cmake_minimum_required(VERSION 3.21)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(m4_compare_fixture LANGUAGES C)
    include(CTest)
endif()

option(M4_FIXTURE_SANITIZERS "Enable ASan/UBSan; never use these binaries for timing" OFF)
option(M4_ENABLE_CTGRIND "Mark probe secret input undefined with Valgrind client requests" OFF)
option(M4_BUILD_BINSEC_HARNESSES "Build extracted comparison harnesses; no verification implied" ON)

if(M4_ENABLE_CTGRIND)
    find_path(M4_VALGRIND_INCLUDE_DIR valgrind/memcheck.h REQUIRED)
endif()

foreach(compare_variant IN ITEMS vulnerable ct)
    if(compare_variant STREQUAL "vulnerable")
        set(compare_kernel compare_early.c)
    else()
        set(compare_kernel compare_ct.c)
    endif()
    add_executable(
        m4_compare_${compare_variant} driver.c self_test.c compare_checked.c ${compare_kernel}
    )
    set(m4_variant_targets m4_compare_${compare_variant})
    if(M4_BUILD_BINSEC_HARNESSES)
        add_executable(m4_binsec_${compare_variant} binsec_harness.c ${compare_kernel})
        list(APPEND m4_variant_targets m4_binsec_${compare_variant})
    endif()
    foreach(compare_target IN LISTS m4_variant_targets)
        set_target_properties(
            ${compare_target}
            PROPERTIES C_STANDARD 11
                       C_STANDARD_REQUIRED YES
                       C_EXTENSIONS NO
                       INTERPROCEDURAL_OPTIMIZATION FALSE
        )
        target_compile_options(
            ${compare_target}
            PRIVATE -Wall
                    -Wextra
                    -Wpedantic
                    -Wshadow
                    -Wconversion
                    -Wstrict-prototypes
                    -Werror
        )
        if(M4_FIXTURE_SANITIZERS)
            target_compile_options(
                ${compare_target} PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer
            )
            target_link_options(${compare_target} PRIVATE -fsanitize=address,undefined)
        endif()
    endforeach()
    if(M4_ENABLE_CTGRIND)
        target_compile_definitions(m4_compare_${compare_variant} PRIVATE M4_ENABLE_CTGRIND=1)
        target_include_directories(
            m4_compare_${compare_variant} PRIVATE "${M4_VALGRIND_INCLUDE_DIR}"
        )
    endif()
    if(BUILD_TESTING)
        add_test(NAME m4_${compare_variant}_self_test COMMAND m4_compare_${compare_variant}
                                                              --self-test
        )
        add_test(NAME m4_${compare_variant}_probe_smoke COMMAND m4_compare_${compare_variant}
                                                                --probe
        )
    endif()
endforeach()
