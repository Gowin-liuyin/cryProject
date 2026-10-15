# Optional historical positive-control backend: liboqs 0.10.0 (GHSA-f2v9-5498-2vpp).
# Included from the top-level CMakeLists.txt. Does not alter mlkem-native variants.

# 默认是钉住的 0.10.0 树。修后复测可指向一份仍报 0.10.0 版本文本的副本，
# 不要改 vendor/liboqs-0.10.0，也不要把阳性树升级到 0.10.1。
set(LIBOQS010_SOURCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/vendor/liboqs-0.10.0"
    CACHE PATH
          "liboqs 0.10.0 tree (pinned vendor snapshot, or a same-version patched copy)"
)
set(LIBOQS010_PIN_COMMIT "36be57445d8ca53f7095160fde548efe82ace09d")
set(LIBOQS010_PIN_TAG "0.10.0")

set(LIBOQS010_C_FLAGS
    ""
    CACHE STRING
          "Extra C flags for the liboqs 0.10.0 ExternalProject (clangover: -Os or -O1 -fno-vectorize on x86_64 Clang 15-18)"
)

if(NOT EXISTS "${LIBOQS010_SOURCE_DIR}/CMakeLists.txt")
    message(
        STATUS
            "BASELINE_ENABLE_LIBOQS010=ON but ${LIBOQS010_SOURCE_DIR} is missing; run tools/fetch_liboqs_0.10.0.sh. Historical targets are skipped."
    )
    return()
endif()

if(NOT EXISTS "${LIBOQS010_SOURCE_DIR}/LICENSE.txt")
    message(FATAL_ERROR "liboqs 0.10.0 tree is missing LICENSE.txt")
endif()

file(STRINGS "${LIBOQS010_SOURCE_DIR}/CMakeLists.txt" _liboqs010_version_line
     REGEX "set\\(OQS_VERSION_TEXT \"0\\.10\\.0\"\\)" LIMIT_COUNT 1
)
if(_liboqs010_version_line STREQUAL "")
    message(FATAL_ERROR "${LIBOQS010_SOURCE_DIR} does not look like release 0.10.0")
endif()

include(ExternalProject)
include(FindThreads)

set(LIBOQS010_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/liboqs010-install")
set(LIBOQS010_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/liboqs010-build")
file(MAKE_DIRECTORY "${LIBOQS010_INSTALL_DIR}/include")
file(MAKE_DIRECTORY "${LIBOQS010_INSTALL_DIR}/lib")

# 只编 ML-KEM-768-ipd 的 portable C。OQS_DIST_BUILD=OFF 在具备
# AVX2/BMI2/POPCNT 的机器上仍会打开 AVX2 并在运行时分发过去；
# clangover 的对象是 *_ref 的 poly_frommsg，因此显式关掉该后端。
# RelWithDebInfo 的 -O2 写在 CMAKE_C_FLAGS 之后，会盖掉 -Os 并重新
# 打开向量化，所以同一组标志也写入各配置专用变量。
set(_liboqs010_cmake_args
    "-DCMAKE_INSTALL_PREFIX=${LIBOQS010_INSTALL_DIR}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
    "-DCMAKE_C_FLAGS=${LIBOQS010_C_FLAGS}"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DOQS_BUILD_ONLY_LIB=ON"
    "-DOQS_USE_OPENSSL=OFF"
    "-DOQS_DIST_BUILD=OFF"
    "-DOQS_OPT_TARGET=generic"
    "-DOQS_USE_AVX2_INSTRUCTIONS=OFF"
    "-DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF"
    "-DOQS_MINIMAL_BUILD=KEM_ml_kem_768_ipd"
)
if(NOT "${LIBOQS010_C_FLAGS}" STREQUAL "")
    list(APPEND _liboqs010_cmake_args
         "-DCMAKE_C_FLAGS_DEBUG=${LIBOQS010_C_FLAGS} -g"
         "-DCMAKE_C_FLAGS_RELEASE=${LIBOQS010_C_FLAGS} -DNDEBUG"
         "-DCMAKE_C_FLAGS_RELWITHDEBINFO=${LIBOQS010_C_FLAGS} -g -DNDEBUG"
         "-DCMAKE_C_FLAGS_MINSIZEREL=${LIBOQS010_C_FLAGS} -DNDEBUG")
endif()

ExternalProject_Add(
    liboqs010_ep
    SOURCE_DIR "${LIBOQS010_SOURCE_DIR}"
    BINARY_DIR "${LIBOQS010_BINARY_DIR}"
    INSTALL_DIR "${LIBOQS010_INSTALL_DIR}"
    CMAKE_ARGS ${_liboqs010_cmake_args}
    BUILD_BYPRODUCTS "${LIBOQS010_INSTALL_DIR}/lib/liboqs.a"
    EXCLUDE_FROM_ALL TRUE
)

add_library(liboqs010_imported STATIC IMPORTED GLOBAL)
set_target_properties(
    liboqs010_imported
    PROPERTIES IMPORTED_LOCATION "${LIBOQS010_INSTALL_DIR}/lib/liboqs.a"
               INTERFACE_INCLUDE_DIRECTORIES "${LIBOQS010_INSTALL_DIR}/include"
)
add_dependencies(liboqs010_imported liboqs010_ep)

find_package(Threads)
if(Threads_FOUND)
    set(_liboqs010_thread_libs Threads::Threads)
else()
    set(_liboqs010_thread_libs "")
endif()

add_library(mlkem_historical STATIC src/mlkem_liboqs010.c src/random.c src/inputs_liboqs010.c)
target_compile_definitions(mlkem_historical PRIVATE BASELINE_HISTORICAL=1)
target_include_directories(
    mlkem_historical
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
    PRIVATE "${LIBOQS010_INSTALL_DIR}/include" "${LIBOQS010_SOURCE_DIR}/src/common"
)
# Do not attach baseline_options (-Werror / mlkem-native config) to this target.
target_compile_options(mlkem_historical PRIVATE -Wall -Wextra)
target_link_libraries(mlkem_historical PUBLIC liboqs010_imported ${_liboqs010_thread_libs})
add_dependencies(mlkem_historical liboqs010_ep build_identity)
set_target_properties(
    mlkem_historical
    PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
               ARCHIVE_OUTPUT_DIRECTORY "${output_root}/historical"
               OUTPUT_NAME mlkem
)

set(_historical_programs baseline)
if(NOT A113_ARCHIVED_CASE_ONLY)
    list(APPEND _historical_programs measure)
endif()
foreach(historical_program IN LISTS _historical_programs)
    if(historical_program STREQUAL "baseline")
        set(historical_program_source src/main.c)
    else()
        set(historical_program_source src/measure.c)
    endif()
    add_executable(historical_${historical_program} "${historical_program_source}")
    target_link_libraries(historical_${historical_program} PRIVATE mlkem_historical)
    target_include_directories(historical_${historical_program} PRIVATE "${identity_directory}")
    target_compile_definitions(historical_${historical_program} PRIVATE BASELINE_HISTORICAL=1)
    set_target_properties(
        historical_${historical_program}
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                   RUNTIME_OUTPUT_DIRECTORY "${output_root}/historical"
                   OUTPUT_NAME ${historical_program}
    )
endforeach()

add_custom_target(historical DEPENDS historical_baseline)
if(NOT A113_ARCHIVED_CASE_ONLY)
    add_dependencies(historical historical_measure)
endif()

if(BUILD_TESTING)
    add_executable(historical_test_selftest tests/test_historical_selftest.c)
    target_link_libraries(historical_test_selftest PRIVATE mlkem_historical)
    set_target_properties(
        historical_test_selftest
        PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${output_root}/historical" OUTPUT_NAME test_selftest
    )
    add_test(NAME historical_selftest COMMAND historical_test_selftest)
    set_tests_properties(historical_selftest PROPERTIES LABELS historical RUN_SERIAL TRUE)
endif()

message(
    STATUS
        "Historical liboqs ${LIBOQS010_PIN_TAG} (${LIBOQS010_PIN_COMMIT}) from ${LIBOQS010_SOURCE_DIR}; AVX2 dispatch forced OFF. OQS_DIST_BUILD=OFF alone still selects AVX2 on capable x86_64. Clangover timing still requires x86_64 Clang 15-18 with -Os/-O1 (see docs/historical-liboqs-0.10.0.md)"
)
