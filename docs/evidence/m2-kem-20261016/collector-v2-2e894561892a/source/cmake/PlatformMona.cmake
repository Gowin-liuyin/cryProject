option(PLATFORM_ENABLE_MONA "Build the fixed upstream Mona offline adapter" OFF)
if(NOT PLATFORM_ENABLE_MONA)
    return()
endif()

find_package(Java 11 REQUIRED COMPONENTS Runtime Development)
get_filename_component(platform_mona_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(PLATFORM_MONA_UPSTREAM_DIR
    "${platform_mona_root}/third_party/mona-timing-report"
    CACHE PATH "Unmodified mona-timing-report at the recorded commit"
)
set(platform_mona_classes "${CMAKE_CURRENT_BINARY_DIR}/platform-mona/classes")
file(STRINGS "${platform_mona_root}/scripts/platform_mona/upstream.sha256" platform_mona_manifest)
foreach(platform_mona_entry IN LISTS platform_mona_manifest)
    string(SUBSTRING "${platform_mona_entry}" 0 64 platform_mona_expected_sha256)
    string(SUBSTRING "${platform_mona_entry}" 66 -1 platform_mona_relative_path)
    file(SHA256 "${PLATFORM_MONA_UPSTREAM_DIR}/${platform_mona_relative_path}"
         platform_mona_actual_sha256
    )
    if(NOT platform_mona_actual_sha256 STREQUAL platform_mona_expected_sha256)
        message(FATAL_ERROR "Mona fixed-source mismatch: ${platform_mona_relative_path}")
    endif()
endforeach()
file(GLOB_RECURSE platform_mona_sources CONFIGURE_DEPENDS
     "${PLATFORM_MONA_UPSTREAM_DIR}/src/*.java"
)
file(GLOB platform_mona_jars CONFIGURE_DEPENDS "${PLATFORM_MONA_UPSTREAM_DIR}/lib/*.jar")
if(NOT platform_mona_sources)
    message(FATAL_ERROR "Mona source checkout is missing: ${PLATFORM_MONA_UPSTREAM_DIR}")
endif()
set(platform_mona_adapter "${platform_mona_root}/scripts/platform_mona/MonaReplay.java")
add_custom_command(
    OUTPUT "${platform_mona_classes}/compiled.stamp"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${platform_mona_classes}"
    COMMAND
        "${Java_JAVAC_EXECUTABLE}" --release 8 -encoding UTF-8 -cp
        "${PLATFORM_MONA_UPSTREAM_DIR}/lib/*" -d "${platform_mona_classes}" ${platform_mona_sources}
        "${platform_mona_adapter}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${platform_mona_classes}/compiled.stamp"
    DEPENDS ${platform_mona_sources} ${platform_mona_jars} "${platform_mona_adapter}"
    VERBATIM
)
add_custom_target(platform_mona DEPENDS "${platform_mona_classes}/compiled.stamp")
if(BUILD_TESTING)
    find_program(platform_mona_shell NAMES sh REQUIRED)
    add_test(
        NAME platform_mona_calibration
        COMMAND
            "${platform_mona_shell}" "${platform_mona_root}/scripts/platform_mona/self_test.sh"
            "${platform_mona_classes}" "${PLATFORM_MONA_UPSTREAM_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}/test-tmp"
    )
    set_tests_properties(platform_mona_calibration PROPERTIES LABELS platform TIMEOUT 120)
endif()
