cmake_minimum_required(VERSION 3.21)
project(partition_management_check LANGUAGES NONE)
include(CTest)
find_package(Python3 3.10 REQUIRED COMPONENTS Interpreter)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/selfcheck-root")
add_test(NAME partition_management_selfcheck
         COMMAND "${Python3_EXECUTABLE}" -I -B "${CMAKE_CURRENT_SOURCE_DIR}/rehearse_partition.py"
                 --selfcheck "${CMAKE_CURRENT_BINARY_DIR}/selfcheck-root"
)
set_tests_properties(
    partition_management_selfcheck
    PROPERTIES
        ENVIRONMENT
        "TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/selfcheck-root;TMP=${CMAKE_CURRENT_BINARY_DIR}/selfcheck-root;TEMP=${CMAKE_CURRENT_BINARY_DIR}/selfcheck-root"
)
