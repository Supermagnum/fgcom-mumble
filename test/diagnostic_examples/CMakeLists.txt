cmake_minimum_required(VERSION 3.16)

# RapidCheck setup
set(RAPIDCHECK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../rapidcheck_tests/lib/rapidcheck")
set(RAPIDCHECK_INCLUDE_DIR "${RAPIDCHECK_DIR}/include")
set(RAPIDCHECK_SRC_DIR "${RAPIDCHECK_DIR}/src")

# Add RapidCheck as subdirectory if not already added
if(NOT TARGET rapidcheck)
    add_subdirectory(${RAPIDCHECK_DIR} rapidcheck)
endif()
project(diagnostic_examples)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(GTest REQUIRED)
find_package(Threads REQUIRED)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../client/mumble-plugin/lib
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Source files
set(TEST_SOURCES
    test_diagnostic_examples.cpp
)

# Create test executable
add_executable(diagnostic_examples ${TEST_SOURCES})

# Link libraries
target_link_libraries(diagnostic_examples
    rapidcheck
    GTest::GTest
    GTest::Main
    Threads::Threads
    m
    pthread
)

# Enable testing
enable_testing()

# Add tests
add_test(NAME diagnostic_examples COMMAND diagnostic_examples)

