cmake_minimum_required(VERSION 3.16)
project(fuzzing_strategy)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# AFL++ configuration
option(ENABLE_AFL "Enable AFL++ fuzzing" ON)
option(ENABLE_FUZZING "Enable fuzzing targets" ON)

if(ENABLE_AFL AND ENABLE_FUZZING)
    find_program(AFL_CC afl-clang-fast)
    find_program(AFL_CXX afl-clang-fast++)
    
    if(AFL_CC AND AFL_CXX)
        set(CMAKE_C_COMPILER ${AFL_CC})
        set(CMAKE_CXX_COMPILER ${AFL_CXX})
        set(CMAKE_C_FLAGS "-O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer")
        set(CMAKE_CXX_FLAGS "-O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer")
        message(STATUS "AFL++ fuzzing enabled")
    else()
        message(WARNING "AFL++ not found, using standard compiler")
        set(CMAKE_C_FLAGS "-O3 -g -fsanitize=address,undefined")
        set(CMAKE_CXX_FLAGS "-O3 -g -fsanitize=address,undefined")
    endif()
else()
    message(STATUS "Fuzzing disabled")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -g")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -g")
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../client/mumble-plugin/lib
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Find required packages
find_package(Threads REQUIRED)

# Tier 1: Critical targets (2 cores each)
if(ENABLE_FUZZING)
    add_executable(tier1_critical targets/tier1_critical.cpp)
    target_compile_options(tier1_critical PRIVATE -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_libraries(tier1_critical Threads::Threads m pthread)
    set_target_properties(tier1_critical PROPERTIES LINK_FLAGS "-fsanitize=address,undefined")
    
    # Tier 2: Important targets (1 core each)
    add_executable(tier2_important targets/tier2_important.cpp)
    target_compile_options(tier2_important PRIVATE -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_libraries(tier2_important Threads::Threads m pthread)
    set_target_properties(tier2_important PROPERTIES LINK_FLAGS "-fsanitize=address,undefined")
    
    # Tier 3: Standard targets (shared cores)
    add_executable(tier3_standard targets/tier3_standard.cpp)
    target_compile_options(tier3_standard PRIVATE -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_libraries(tier3_standard Threads::Threads m pthread)
    set_target_properties(tier3_standard PROPERTIES LINK_FLAGS "-fsanitize=address,undefined")
endif()

# Custom targets for fuzzing execution
if(ENABLE_FUZZING)
    # Build all fuzzing targets
    add_custom_target(build_fuzzing_targets
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target tier1_critical tier2_important tier3_standard
        COMMENT "Building fuzzing targets"
    )
    
    # Setup corpus directories
    add_custom_target(setup_corpus
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/corpus
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/results
        COMMENT "Setting up corpus and results directories"
    )
    
    # Create sample corpus files
    add_custom_target(create_sample_corpus
        DEPENDS setup_corpus
        COMMAND echo "sample input" > ${CMAKE_BINARY_DIR}/corpus/sample1.txt
        COMMAND echo "test data" > ${CMAKE_BINARY_DIR}/corpus/sample2.txt
        COMMAND echo "fuzzing input" > ${CMAKE_BINARY_DIR}/corpus/sample3.txt
        COMMENT "Creating sample corpus files"
    )
    
    # Fuzzing execution targets
    add_custom_target(run_tier1_fuzzing
        DEPENDS build_fuzzing_targets create_sample_corpus
        COMMAND afl-fuzz -i ${CMAKE_BINARY_DIR}/corpus -o ${CMAKE_BINARY_DIR}/results/tier1 -t 10000 -- ${CMAKE_BINARY_DIR}/tier1_critical @@
        COMMENT "Running Tier 1 fuzzing (Critical targets)"
    )
    
    add_custom_target(run_tier2_fuzzing
        DEPENDS build_fuzzing_targets create_sample_corpus
        COMMAND afl-fuzz -i ${CMAKE_BINARY_DIR}/corpus -o ${CMAKE_BINARY_DIR}/results/tier2 -t 10000 -- ${CMAKE_BINARY_DIR}/tier2_important @@
        COMMENT "Running Tier 2 fuzzing (Important targets)"
    )
    
    add_custom_target(run_tier3_fuzzing
        DEPENDS build_fuzzing_targets create_sample_corpus
        COMMAND afl-fuzz -i ${CMAKE_BINARY_DIR}/corpus -o ${CMAKE_BINARY_DIR}/results/tier3 -t 10000 -- ${CMAKE_BINARY_DIR}/tier3_standard @@
        COMMENT "Running Tier 3 fuzzing (Standard targets)"
    )
    
    # Combined fuzzing execution
    add_custom_target(run_all_fuzzing
        DEPENDS run_tier1_fuzzing run_tier2_fuzzing run_tier3_fuzzing
        COMMENT "Running all fuzzing targets"
    )
    
    # Clean targets
    add_custom_target(clean_fuzzing
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/results
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/corpus
        COMMENT "Cleaning fuzzing outputs and corpus"
    )
    
    # Help target
    add_custom_target(help_fuzzing
        COMMAND ${CMAKE_COMMAND} -E echo "Available fuzzing targets:"
        COMMAND ${CMAKE_COMMAND} -E echo "  build_fuzzing_targets  - Build all fuzzing targets"
        COMMAND ${CMAKE_COMMAND} -E echo "  run_tier1_fuzzing      - Run Tier 1 fuzzing (Critical)"
        COMMAND ${CMAKE_COMMAND} -E echo "  run_tier2_fuzzing      - Run Tier 2 fuzzing (Important)"
        COMMAND ${CMAKE_COMMAND} -E echo "  run_tier3_fuzzing      - Run Tier 3 fuzzing (Standard)"
        COMMAND ${CMAKE_COMMAND} -E echo "  run_all_fuzzing        - Run all fuzzing targets"
        COMMAND ${CMAKE_COMMAND} -E echo "  clean_fuzzing          - Clean fuzzing outputs"
        COMMENT "Fuzzing help information"
    )
endif()

# Enable testing
enable_testing()

# Add tests for fuzzing targets
if(ENABLE_FUZZING)
    add_test(NAME fuzzing_targets_build COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target build_fuzzing_targets)
endif()
