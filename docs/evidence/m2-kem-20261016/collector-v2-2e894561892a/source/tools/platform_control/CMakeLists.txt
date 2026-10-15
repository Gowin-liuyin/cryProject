cmake_minimum_required(VERSION 3.21)
project(platform_control_checks LANGUAGES NONE)
include(CTest)
find_package(Python3 3.10 REQUIRED COMPONENTS Interpreter)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mock-root")
add_test(NAME platform_control_mock
         COMMAND "${Python3_EXECUTABLE}" -I -B "${CMAKE_CURRENT_SOURCE_DIR}/test_controller.py"
                 "${CMAKE_CURRENT_BINARY_DIR}/mock-root"
)
set_tests_properties(
    platform_control_mock
    PROPERTIES
        ENVIRONMENT
        "TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/mock-root;TMP=${CMAKE_CURRENT_BINARY_DIR}/mock-root;TEMP=${CMAKE_CURRENT_BINARY_DIR}/mock-root"
)
