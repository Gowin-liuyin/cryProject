include_guard(GLOBAL)

option(PLATFORM_M3_CTGRIND "Build M3 full-decapsulation Memcheck secret-input probes" OFF)
if(PLATFORM_M3_CTGRIND)
    find_path(PLATFORM_M3_VALGRIND_INCLUDE_DIR valgrind/memcheck.h REQUIRED)
endif()

set(platform_m3_patch "${CMAKE_CURRENT_SOURCE_DIR}/docs/patches/m3-mem-lut-toggle.patch")
foreach(fixture_mode IN ITEMS on off)
    set(platform_m3_overlay "${CMAKE_CURRENT_BINARY_DIR}/platform-m3-${fixture_mode}-source")
    set(platform_m3_kernel "${CMAKE_CURRENT_BINARY_DIR}/platform_m3_${fixture_mode}_kernel.c")
    configure_file(src/kernel.c "${platform_m3_kernel}" COPYONLY)
    add_custom_command(
        OUTPUT "${platform_m3_overlay}/patched.stamp"
        COMMAND
            "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DOVERLAY_ROOT=${platform_m3_overlay}" "-DPATCH_FILE=${platform_m3_patch}"
            "-DPATCH_EXECUTABLE=${PATCH_EXECUTABLE}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareVariant.cmake"
        DEPENDS ${vendor_files} "${platform_m3_patch}" cmake/PrepareVariant.cmake
        VERBATIM
    )
    add_custom_target(
        platform_m3_${fixture_mode}_prepare DEPENDS "${platform_m3_overlay}/patched.stamp"
    )
    set_source_files_properties(
        "${platform_m3_kernel}" PROPERTIES OBJECT_DEPENDS "${platform_m3_overlay}/patched.stamp"
    )
    add_library(
        platform_m3_${fixture_mode}_kernel STATIC "${platform_m3_kernel}" src/mlkem.c src/random.c
                                                  src/inputs.c
    )
    target_link_libraries(platform_m3_${fixture_mode}_kernel PUBLIC baseline_options)
    target_include_directories(
        platform_m3_${fixture_mode}_kernel BEFORE PRIVATE "${platform_m3_overlay}/mlkem"
    )
    target_compile_definitions(
        platform_m3_${fixture_mode}_kernel
        PRIVATE PLATFORM_M3_LUT_LEAK=$<STREQUAL:${fixture_mode},on>
                PLATFORM_IMPLEMENTATION_NAME="platform-m3-lut-${fixture_mode}"
    )
    add_dependencies(platform_m3_${fixture_mode}_kernel platform_m3_${fixture_mode}_prepare)
    set_target_properties(
        platform_m3_${fixture_mode}_kernel
        PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                   ARCHIVE_OUTPUT_DIRECTORY "${output_root}/platform-m3/${fixture_mode}"
                   OUTPUT_NAME mlkem
    )
    foreach(program IN ITEMS baseline measure)
        if(program STREQUAL "baseline")
            set(program_source src/main.c)
        else()
            set(program_source src/measure.c)
        endif()
        add_executable(platform_m3_${fixture_mode}_${program} "${program_source}")
        target_link_libraries(
            platform_m3_${fixture_mode}_${program} PRIVATE platform_m3_${fixture_mode}_kernel
        )
        target_include_directories(
            platform_m3_${fixture_mode}_${program} PRIVATE "${identity_directory}"
        )
        add_dependencies(platform_m3_${fixture_mode}_${program} build_identity)
        set_target_properties(
            platform_m3_${fixture_mode}_${program}
            PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
                       RUNTIME_OUTPUT_DIRECTORY "${output_root}/platform-m3/${fixture_mode}"
                       OUTPUT_NAME "${program}"
        )
    endforeach()
    if(PLATFORM_M3_CTGRIND)
        add_executable(platform_m3_${fixture_mode}_probe tools/platform_m3/ctgrind_probe.c)
        target_link_libraries(
            platform_m3_${fixture_mode}_probe PRIVATE platform_m3_${fixture_mode}_kernel
        )
        target_include_directories(
            platform_m3_${fixture_mode}_probe PRIVATE "${PLATFORM_M3_VALGRIND_INCLUDE_DIR}"
        )
    endif()
    if(BUILD_TESTING)
        foreach(test_program IN ITEMS test_mlkem test_random_failure)
            add_executable(platform_m3_${fixture_mode}_${test_program} "tests/${test_program}.c")
            target_link_libraries(
                platform_m3_${fixture_mode}_${test_program}
                PRIVATE platform_m3_${fixture_mode}_kernel
            )
            list(APPEND platform_m3_test_targets platform_m3_${fixture_mode}_${test_program})
        endforeach()
        add_test(NAME platform_m3_${fixture_mode}_kat
                 COMMAND platform_m3_${fixture_mode}_test_mlkem
                         "${CMAKE_CURRENT_SOURCE_DIR}/tests/vectors/mlkem768.txt"
        )
        add_test(NAME platform_m3_${fixture_mode}_random_failure
                 COMMAND platform_m3_${fixture_mode}_test_random_failure
        )
        set_tests_properties(
            platform_m3_${fixture_mode}_kat platform_m3_${fixture_mode}_random_failure
            PROPERTIES LABELS platform_m3
        )
    endif()
endforeach()

add_custom_target(
    platform_m3 DEPENDS platform_m3_on_baseline platform_m3_off_baseline platform_m3_on_measure
                        platform_m3_off_measure
)
if(BUILD_TESTING)
    foreach(fixture_mode IN ITEMS reference on off)
        add_executable(platform_m3_${fixture_mode}_equivalence tests/test_platform_m3_equivalence.c)
        if(fixture_mode STREQUAL "reference")
            set(platform_m3_equivalence_library mlkem_reference)
        else()
            set(platform_m3_equivalence_library platform_m3_${fixture_mode}_kernel)
        endif()
        target_link_libraries(
            platform_m3_${fixture_mode}_equivalence PRIVATE ${platform_m3_equivalence_library}
        )
        list(APPEND platform_m3_test_targets platform_m3_${fixture_mode}_equivalence)
    endforeach()
    set(platform_m3_test_directory "${CMAKE_CURRENT_BINARY_DIR}/test-tmp/platform-m3")
    if(IS_SYMLINK "${platform_m3_test_directory}")
        message(FATAL_ERROR "M3 test output directory must not be a symlink")
    endif()
    file(MAKE_DIRECTORY "${platform_m3_test_directory}")
    add_test(
        NAME platform_m3_full_output_equivalence
        COMMAND
            "${CMAKE_COMMAND}"
            "-DREFERENCE_PROGRAM=$<TARGET_FILE:platform_m3_reference_equivalence>"
            "-DON_PROGRAM=$<TARGET_FILE:platform_m3_on_equivalence>"
            "-DOFF_PROGRAM=$<TARGET_FILE:platform_m3_off_equivalence>"
            "-DOUTPUT_DIRECTORY=${platform_m3_test_directory}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_platform_m3_equivalence.cmake"
    )
    set_tests_properties(platform_m3_full_output_equivalence PROPERTIES LABELS platform_m3)
    add_test(
        NAME platform_m3_patch_dry_run
        COMMAND
            "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DOUTPUT_DIRECTORY=${platform_m3_test_directory}/patch-dry-run"
            "-DPATCH_FILE=${platform_m3_patch}" "-DPATCH_EXECUTABLE=${PATCH_EXECUTABLE}" -P
            "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_platform_m3_patch.cmake"
    )
    set_tests_properties(platform_m3_patch_dry_run PROPERTIES LABELS platform_m3)
    add_custom_target(
        platform_m3_check
        COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CMAKE_CURRENT_BINARY_DIR}"
                --output-on-failure -L platform_m3
        DEPENDS ${platform_m3_test_targets}
        USES_TERMINAL VERBATIM
    )
endif()
