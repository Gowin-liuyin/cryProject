cmake_minimum_required(VERSION 3.21)
project(platform_mona_standalone NONE)
include(CTest)
set(PLATFORM_ENABLE_MONA
    ON
    CACHE BOOL "Build the fixed upstream Mona offline adapter"
)
include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/PlatformMona.cmake")
