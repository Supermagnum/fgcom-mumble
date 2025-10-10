#!/bin/bash

# Build fuzzing targets with AFL++
echo "Building fuzzing targets with AFL++..."

# Create build directory
mkdir -p build
cd build

# Build Tier 1 targets
echo "Building Tier 1 targets (Critical)..."
afl-clang-fast++ -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
    -o tier1_critical ../targets/tier1_critical.cpp -lpthread -lm

# Build Tier 2 targets  
echo "Building Tier 2 targets (Important)..."
afl-clang-fast++ -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
    -o tier2_important ../targets/tier2_important.cpp -lpthread -lm

# Build Tier 3 targets
echo "Building Tier 3 targets (Standard)..."
afl-clang-fast++ -O3 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
    -o tier3_standard ../targets/tier3_standard.cpp -lpthread -lm

# Create corpus directories
echo "Setting up corpus directories..."
mkdir -p corpus
mkdir -p results

# Create sample corpus files
echo "Creating sample corpus files..."
echo "sample input" > corpus/sample1.txt
echo "test data" > corpus/sample2.txt
echo "fuzzing input" > corpus/sample3.txt
echo "network packet" > corpus/sample4.txt
echo "webrtc data" > corpus/sample5.txt

echo "Fuzzing targets built successfully!"
echo "Available targets:"
echo "  - tier1_critical (Critical fuzzing targets)"
echo "  - tier2_important (Important fuzzing targets)" 
echo "  - tier3_standard (Standard fuzzing targets)"
echo ""
echo "To run fuzzing:"
echo "  afl-fuzz -i corpus -o results/tier1 -t 10000 -- ./tier1_critical @@"
echo "  afl-fuzz -i corpus -o results/tier2 -t 10000 -- ./tier2_important @@"
echo "  afl-fuzz -i corpus -o results/tier3 -t 10000 -- ./tier3_standard @@"
