include_guard(GLOBAL)

function(configure_platform_m2)
    foreach(variant IN ITEMS unfixed fixed)
        set(platform_m2_${variant}_root
            "${CMAKE_CURRENT_SOURCE_DIR}/vendor/kyber-kyberslash-${variant}/ref"
        )
        if(NOT EXISTS "${platform_m2_${variant}_root}/kem.c")
            message(STATUS "M2 vendor missing; run the fixed version-audit/fetch_vendor.sh first")
            return()
        endif()
    endforeach()

    if(NOT CMAKE_C_COMPILER_ID MATCHES "^(Clang|AppleClang)$")
        message(STATUS "M2 pins Clang -Oz; configure with Clang to enable its targets")
        return()
    endif()

    foreach(variant IN ITEMS unfixed fixed)
        set(vendor_root "${platform_m2_${variant}_root}")
        add_library(
            platform_m2_${variant}_vendor STATIC
            "${vendor_root}/kem.c"
            "${vendor_root}/indcpa.c"
            "${vendor_root}/poly.c"
            "${vendor_root}/polyvec.c"
            "${vendor_root}/ntt.c"
            "${vendor_root}/cbd.c"
            "${vendor_root}/reduce.c"
            "${vendor_root}/verify.c"
            "${vendor_root}/fips202.c"
            "${vendor_root}/symmetric-shake.c"
        )
        target_include_directories(platform_m2_${variant}_vendor PUBLIC "${vendor_root}")
        target_compile_definitions(
            platform_m2_${variant}_vendor PRIVATE KYBER_K=3 randombytes=platform_m2_randombytes
        )
        target_compile_options(
            platform_m2_${variant}_vendor PRIVATE -Oz -g -fno-vectorize -fno-slp-vectorize
        )
        add_library(
            platform_m2_${variant} STATIC src/platform_m2_adapter.c src/platform_m2_inputs.c
                                          src/random.c
        )
        target_include_directories(
            platform_m2_${variant} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
        )
        target_compile_definitions(platform_m2_${variant} PRIVATE KYBER_K=3)
        target_compile_options(
            platform_m2_${variant}
            PRIVATE -Wall
                    -Wextra
                    -Wpedantic
                    -Wshadow
                    -Wconversion
                    -Wstrict-prototypes
                    -Werror
        )
        target_link_libraries(platform_m2_${variant} PUBLIC platform_m2_${variant}_vendor)
        if(variant STREQUAL "fixed")
            target_compile_definitions(platform_m2_${variant} PRIVATE PLATFORM_M2_FIXED=1)
        endif()
        if(BASELINE_SANITIZERS)
            foreach(sanitized_target IN ITEMS platform_m2_${variant} platform_m2_${variant}_vendor)
                target_compile_options(
                    ${sanitized_target} PUBLIC -O1 -g -fsanitize=address,undefined
                                               -fno-omit-frame-pointer
                )
                target_link_options(${sanitized_target} PUBLIC -fsanitize=address,undefined)
            endforeach()
        endif()
        set_target_properties(
            platform_m2_${variant} platform_m2_${variant}_vendor
            PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
        )
        foreach(program IN ITEMS baseline measure)
            if(program STREQUAL "baseline")
                set(program_source src/main.c)
            else()
                set(program_source src/measure.c)
            endif()
            add_executable(platform_m2_${variant}_${program} "${program_source}")
            target_link_libraries(platform_m2_${variant}_${program} PRIVATE platform_m2_${variant})
            target_compile_definitions(
                platform_m2_${variant}_${program} PRIVATE PLATFORM_M2_KYBER=1
            )
            target_include_directories(
                platform_m2_${variant}_${program} PRIVATE "${identity_directory}"
            )
            add_dependencies(platform_m2_${variant}_${program} build_identity)
            set_target_properties(
                platform_m2_${variant}_${program}
                PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                           RUNTIME_OUTPUT_DIRECTORY "${output_root}/platform-m2/${variant}"
                           OUTPUT_NAME "${program}"
            )
        endforeach()
        if(BUILD_TESTING)
            add_executable(platform_m2_${variant}_test tests/test_platform_m2.c)
            target_link_libraries(platform_m2_${variant}_test PRIVATE platform_m2_${variant})
            add_test(NAME platform_m2_${variant}_functional COMMAND platform_m2_${variant}_test)
            add_executable(
                platform_m2_${variant}_rng_failure tests/test_platform_m2_random_failure.c
            )
            target_link_libraries(platform_m2_${variant}_rng_failure PRIVATE platform_m2_${variant})
            add_test(NAME platform_m2_${variant}_random_failure
                     COMMAND platform_m2_${variant}_rng_failure
            )
        endif()
    endforeach()

    if(BUILD_TESTING)
        add_test(
            NAME platform_m2_semantic_equivalence
            COMMAND
                "${CMAKE_COMMAND}" "-DM2_unfixed_TEST=$<TARGET_FILE:platform_m2_unfixed_test>"
                "-DM2_fixed_TEST=$<TARGET_FILE:platform_m2_fixed_test>" -P
                "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_platform_m2_equivalence.cmake"
        )
        find_package(OpenSSL QUIET COMPONENTS Crypto)
        if(OpenSSL_FOUND)
            foreach(variant IN ITEMS unfixed fixed)
                add_executable(
                    platform_m2_${variant}_kat tests/test_platform_m2_kat.c
                                               "${platform_m2_${variant}_root}/rng.c"
                )
                target_link_libraries(
                    platform_m2_${variant}_kat PRIVATE platform_m2_${variant} OpenSSL::Crypto
                )
                add_test(
                    NAME platform_m2_${variant}_public_kat
                    COMMAND
                        platform_m2_${variant}_kat
                        "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp"
                )
            endforeach()
        else()
            message(
                WARNING "M2 public KAT needs test-only OpenSSL Crypto; no KAT target was enabled"
            )
        endif()
        set(platform_m2_checks platform_m2_unfixed_test platform_m2_fixed_test
                               platform_m2_unfixed_rng_failure platform_m2_fixed_rng_failure
        )
        if(OpenSSL_FOUND)
            list(APPEND platform_m2_checks platform_m2_unfixed_kat platform_m2_fixed_kat)
        endif()
        add_custom_target(
            platform_m2_check
            COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure -R "^platform_m2_"
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
            DEPENDS ${platform_m2_checks}
        )
    endif()

    add_custom_target(
        platform_m2 DEPENDS platform_m2_unfixed_baseline platform_m2_fixed_baseline
                            platform_m2_unfixed_measure platform_m2_fixed_measure
    )
endfunction()

configure_platform_m2()
