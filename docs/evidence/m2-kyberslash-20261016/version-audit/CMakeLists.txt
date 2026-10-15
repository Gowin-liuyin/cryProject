cmake_minimum_required(VERSION 3.21)
project(kyberslash_version_audit LANGUAGES C)

if(NOT CMAKE_C_COMPILER_ID MATCHES "^(Clang|AppleClang)$")
    message(FATAL_ERROR "This audit pins Clang -Oz; configure with -DCMAKE_C_COMPILER=clang-18")
endif()

include(CTest)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
get_filename_component(CRYPROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE)
set(M2_VALGRIND_INCLUDE_DIR
    ""
    CACHE PATH "Directory containing valgrind/memcheck.h"
)

foreach(variant IN ITEMS unfixed fixed)
    set(vendor_root "${CRYPROJECT_ROOT}/vendor/kyber-kyberslash-${variant}/ref")
    add_library(
        kyberslash_${variant}_kernel STATIC
        "${vendor_root}/poly.c"
        "${vendor_root}/polyvec.c"
        "${vendor_root}/ntt.c"
        "${vendor_root}/cbd.c"
        "${vendor_root}/reduce.c"
        "${vendor_root}/fips202.c"
        "${vendor_root}/symmetric-shake.c"
    )
    target_include_directories(kyberslash_${variant}_kernel PUBLIC "${vendor_root}")
    target_compile_definitions(kyberslash_${variant}_kernel PUBLIC KYBER_K=3)
    target_compile_options(
        kyberslash_${variant}_kernel PRIVATE -Oz -g -fno-vectorize -fno-slp-vectorize
    )
    set_target_properties(
        kyberslash_${variant}_kernel PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
    )
    add_executable(kyberslash_${variant}_probe poly_probe.c)
    target_link_libraries(kyberslash_${variant}_probe PRIVATE kyberslash_${variant}_kernel)
    target_compile_options(kyberslash_${variant}_probe PRIVATE -Wall -Wextra -Wpedantic -Werror)
    if(M2_VALGRIND_INCLUDE_DIR)
        if(NOT EXISTS "${M2_VALGRIND_INCLUDE_DIR}/valgrind/memcheck.h")
            message(FATAL_ERROR "M2_VALGRIND_INCLUDE_DIR must contain valgrind/memcheck.h")
        endif()
        target_include_directories(kyberslash_${variant}_probe PRIVATE "${M2_VALGRIND_INCLUDE_DIR}")
        target_compile_definitions(kyberslash_${variant}_probe PRIVATE M2_HAVE_VALGRIND=1)
    endif()
    add_test(NAME kyberslash_${variant}_probe_smoke COMMAND kyberslash_${variant}_probe)
endforeach()

if(NOT M2_VALGRIND_INCLUDE_DIR)
    message(STATUS "No Valgrind headers: smoke-only probes; secret poisoning is disabled")
endif()
