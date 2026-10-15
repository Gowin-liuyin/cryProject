include_guard(GLOBAL)

add_executable(platform_m5_poison tools/platform_m5/poison.c)
target_link_libraries(platform_m5_poison PRIVATE mlkem_reference)
set_target_properties(platform_m5_poison PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
find_path(PLATFORM_M5_VALGRIND_INCLUDE_DIR valgrind/memcheck.h)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND PLATFORM_M5_VALGRIND_INCLUDE_DIR)
    target_compile_definitions(platform_m5_poison PRIVATE PLATFORM_M5_HAVE_VALGRIND=1)
    target_include_directories(
        platform_m5_poison SYSTEM PRIVATE "${PLATFORM_M5_VALGRIND_INCLUDE_DIR}"
    )
endif()

if(BUILD_TESTING)
    add_test(
        NAME platform_m5_poison_functional
        COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_platform_m5_poison.sh"
                "$<TARGET_FILE:platform_m5_poison>"
    )
    set_tests_properties(platform_m5_poison_functional PROPERTIES LABELS "platform;m5")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$"
   AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dudect/src/dudect.h"
)
    add_executable(platform_m5_dudect tools/platform_m5/dudect.c)
    target_link_libraries(platform_m5_dudect PRIVATE mlkem_reference)
    target_include_directories(
        platform_m5_dudect SYSTEM PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dudect/src"
    )
    if(MATH_LIBRARY)
        target_link_libraries(platform_m5_dudect PRIVATE "${MATH_LIBRARY}")
    endif()
    set_target_properties(platform_m5_dudect PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}")
    if(BUILD_TESTING)
        add_test(
            NAME platform_m5_dudect_selftest
            COMMAND
                "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_platform_m5_dudect.sh"
                "$<TARGET_FILE:platform_m5_dudect>" "${CMAKE_CURRENT_BINARY_DIR}/test-tmp"
        )
        set_tests_properties(platform_m5_dudect_selftest PROPERTIES LABELS "platform;m5")
    endif()
endif()
