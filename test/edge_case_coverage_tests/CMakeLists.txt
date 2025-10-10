cmake_minimum_required(VERSION 3.16)

# RapidCheck setup
set(RAPIDCHECK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../rapidcheck_tests/lib/rapidcheck")
set(RAPIDCHECK_INCLUDE_DIR "${RAPIDCHECK_DIR}/include")
set(RAPIDCHECK_SRC_DIR "${RAPIDCHECK_DIR}/src")

# Add RapidCheck as subdirectory if not already added
if(NOT TARGET rapidcheck)
    add_subdirectory(${RAPIDCHECK_DIR} rapidcheck)
endif()
project(edge_case_coverage_tests)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(GTest REQUIRED)
find_package(Threads REQUIRED)

# Platform-specific includes
if(WIN32)
    add_definitions(-D_WIN32)
elseif(UNIX)
    add_definitions(-D__linux__)
    find_library(PTHREAD_LIBRARY pthread)
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../client/mumble-plugin/lib
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Source files
set(TEST_SOURCES
    test_edge_case_coverage.cpp
    test_platform_specific.cpp
)

# Create test executable
add_executable(edge_case_coverage_tests ${TEST_SOURCES})

# Link libraries
target_link_libraries(edge_case_coverage_tests
    rapidcheck
    GTest::GTest
    GTest::Main
    Threads::Threads
    m
    pthread
)

# Platform-specific linking
if(WIN32)
    target_link_libraries(edge_case_coverage_tests
    rapidcheck
        ws2_32
        kernel32
    )
elseif(UNIX)
    target_link_libraries(edge_case_coverage_tests
    rapidcheck
        ${PTHREAD_LIBRARY}
    )
endif()

# Enable testing
enable_testing()

# Add tests
add_test(NAME edge_case_coverage_tests COMMAND edge_case_coverage_tests)


# Debug build configuration
option(ENABLE_DEBUG "Enable debug-specific code paths" OFF)
if(ENABLE_DEBUG)
    add_definitions(-DDEBUG)
    message(STATUS "Debug-specific code paths enabled")
endif()

# Coverage analysis
option(ENABLE_COVERAGE "Enable coverage analysis" OFF)
if(ENABLE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
    message(STATUS "Coverage analysis enabled")
endif()
