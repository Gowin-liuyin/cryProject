cmake_minimum_required(VERSION 3.21)
project(msr_counter_snapshot LANGUAGES C)

include(CTest)
option(MSR_READER_SANITIZERS "Enable address and undefined behavior checks" OFF)

add_executable(msr_counter_snapshot msr_counter_snapshot.c)
set_target_properties(
    msr_counter_snapshot
    PROPERTIES C_STANDARD 11
               C_STANDARD_REQUIRED YES
               C_EXTENSIONS NO
)
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(
        msr_counter_snapshot
        PRIVATE -Wall
                -Wextra
                -Wpedantic
                -Wshadow
                -Wconversion
                -Wstrict-prototypes
                -Wformat=2
                -Werror
    )
else()
    message(FATAL_ERROR "This standalone module requires GCC or Clang")
endif()
if(MSR_READER_SANITIZERS)
    target_compile_options(
        msr_counter_snapshot PRIVATE -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
    )
    target_link_options(msr_counter_snapshot PRIVATE -fsanitize=address,undefined)
endif()
if(BUILD_TESTING)
    add_test(NAME msr_counter_snapshot_selfcheck COMMAND msr_counter_snapshot --selfcheck)
endif()
