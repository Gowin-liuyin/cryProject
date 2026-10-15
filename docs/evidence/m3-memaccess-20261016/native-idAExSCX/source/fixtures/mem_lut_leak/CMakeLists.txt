cmake_minimum_required(VERSION 3.21)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(mem_lut_fixture LANGUAGES C)
    include(CTest)
endif()

option(MEM_LUT_ENABLE_CTGRIND "Enable Valgrind secret-input client requests" OFF)
option(MEM_LUT_SANITIZERS "Enable ASan/UBSan; never use these binaries for timing" OFF)

add_library(mem_lut_fixture_options INTERFACE)
target_compile_features(mem_lut_fixture_options INTERFACE c_std_11)
target_compile_options(
    mem_lut_fixture_options
    INTERFACE -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wstrict-prototypes
              -Werror
)
if(MEM_LUT_SANITIZERS)
    target_compile_options(
        mem_lut_fixture_options INTERFACE -O1 -g -fsanitize=address,undefined
                                          -fno-omit-frame-pointer
    )
    target_link_options(mem_lut_fixture_options INTERFACE -fsanitize=address,undefined)
endif()

if(MEM_LUT_ENABLE_CTGRIND)
    find_path(MEM_LUT_VALGRIND_INCLUDE_DIR valgrind/memcheck.h REQUIRED)
endif()

foreach(fixture_mode IN ITEMS on off)
    if(fixture_mode STREQUAL "on")
        set(leak_enabled 1)
    else()
        set(leak_enabled 0)
    endif()
    add_library(mem_lut_${fixture_mode}_kernel STATIC mem_lut.c)
    target_link_libraries(mem_lut_${fixture_mode}_kernel PUBLIC mem_lut_fixture_options)
    target_include_directories(mem_lut_${fixture_mode}_kernel PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
    target_compile_definitions(
        mem_lut_${fixture_mode}_kernel PUBLIC MEM_LUT_LEAK_ENABLED=${leak_enabled}
    )
    set_target_properties(
        mem_lut_${fixture_mode}_kernel
        PROPERTIES C_STANDARD 11
                   C_STANDARD_REQUIRED ON
                   C_EXTENSIONS OFF
                   INTERPROCEDURAL_OPTIMIZATION FALSE
    )
    add_executable(mem_lut_leak_${fixture_mode} main.c)
    target_link_libraries(mem_lut_leak_${fixture_mode} PRIVATE mem_lut_${fixture_mode}_kernel)
    target_compile_definitions(
        mem_lut_leak_${fixture_mode} PRIVATE MEM_LUT_CTGRIND=$<BOOL:${MEM_LUT_ENABLE_CTGRIND}>
    )
    set_target_properties(
        mem_lut_leak_${fixture_mode}
        PROPERTIES C_STANDARD 11
                   C_STANDARD_REQUIRED ON
                   C_EXTENSIONS OFF
                   INTERPROCEDURAL_OPTIMIZATION FALSE
    )
    if(MEM_LUT_ENABLE_CTGRIND)
        target_include_directories(
            mem_lut_leak_${fixture_mode} PRIVATE "${MEM_LUT_VALGRIND_INCLUDE_DIR}"
        )
    endif()
    if(BUILD_TESTING)
        add_test(NAME mem_lut_${fixture_mode}_selftest COMMAND mem_lut_leak_${fixture_mode}
                                                               --selftest
        )
        set_tests_properties(mem_lut_${fixture_mode}_selftest PROPERTIES LABELS "fixture;mem_lut")
    endif()
endforeach()
