#!/bin/bash

# Tier 2: Important Fuzzing Targets
# Medium-risk targets that get 1 core each for 6 hours

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIER2_TARGETS=(
    "fuzz_audio_processing"
    "fuzz_radio_propagation"
    "fuzz_frequency_management"
    "fuzz_agc_squelch"
    "fuzz_database_operations"
    "fuzz_error_handling"
)

BINARY_PATH="./test/fuzzing_strategy/build/tier2_important"
TIMEOUT_SECONDS=21600  # 6 hours

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for Tier 2 fuzzing..."
    
    if [ ! -f "$BINARY_PATH" ]; then
        print_error "Tier 2 binary not found: $BINARY_PATH"
        print_error "Please build the fuzzing targets first"
        exit 1
    fi
    
    if ! command -v afl-fuzz &> /dev/null; then
        print_error "AFL++ is not installed. Please install it first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to setup directories
setup_directories() {
    print_status "Setting up directories for Tier 2 targets..."
    
    mkdir -p logs
    for target in "${TIER2_TARGETS[@]}"; do
        mkdir -p corpus/$target
        mkdir -p results/$target
        
        # Create sample input files if corpus is empty
        if [ ! "$(ls -A corpus/$target 2>/dev/null)" ]; then
            echo "sample input for $target" > corpus/$target/sample1.txt
            echo "test data for $target" > corpus/$target/sample2.txt
            echo "fuzzing input for $target" > corpus/$target/sample3.txt
            print_status "Created sample corpus for $target"
        fi
    done
    
    print_success "Directories setup complete"
}

# Function to start fuzzing
start_fuzzing() {
    print_status "Starting Tier 2 fuzzing (Important targets)..."
    print_status "Targets: ${#TIER2_TARGETS[@]}"
    print_status "Time: $((TIMEOUT_SECONDS / 3600)) hours"
    print_status "Cores: 1 per target (6 total)"
    
    # Set AFL environment variables
    export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
    export AFL_SKIP_CPUFREQ=1
    
    # Start fuzzing for each target
    for target in "${TIER2_TARGETS[@]}"; do
        print_status "Starting fuzzing for $target (1 core, 6 hours)..."
        
        # Start AFL fuzzing in background with 1 core
        timeout $TIMEOUT_SECONDS \
        afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- "$BINARY_PATH" @@ \
        > logs/$target.log 2>&1 &
        
        # Store process ID for monitoring
        echo $! >> tier2_fuzzing_pids.txt
        
        # Small delay to prevent resource conflicts
        sleep 2
    done
    
    print_success "All Tier 2 fuzzing targets started"
    print_status "Monitor with: watch -n 30 'afl-whatsup results/'"
}

# Function to wait for completion
wait_for_completion() {
    print_status "Waiting for Tier 2 fuzzing to complete..."
    
    # Wait for all background processes
    wait
    
    print_success "Tier 2 fuzzing complete"
    
    # Generate summary
    generate_summary
}

# Function to generate summary
generate_summary() {
    print_status "Generating Tier 2 fuzzing summary..."
    
    echo ""
    echo "=== TIER 2 FUZZING SUMMARY (IMPORTANT TARGETS) ==="
    echo "Timestamp: $(date)"
    echo "Targets: ${#TIER2_TARGETS[@]}"
    echo "Time: $((TIMEOUT_SECONDS / 3600)) hours"
    echo "Total core-hours: $((6 * TIMEOUT_SECONDS / 3600))"
    echo ""
    
    echo "=== RESULTS BY TARGET ==="
    for target in "${TIER2_TARGETS[@]}"; do
        if [ -d "results/$target" ]; then
            echo "Target: $target"
            afl-whatsup results/$target 2>/dev/null | head -10
            echo ""
        fi
    done
    
    echo "=== CRASHES FOUND ==="
    CRASH_COUNT=0
    for target in "${TIER2_TARGETS[@]}"; do
        if [ -d "results/$target/crashes" ]; then
            crashes=$(find results/$target/crashes -name "id:*" 2>/dev/null | wc -l)
            if [ "$crashes" -gt 0 ]; then
                echo "$target: $crashes crashes found"
                CRASH_COUNT=$((CRASH_COUNT + crashes))
            fi
        fi
    done
    
    if [ $CRASH_COUNT -eq 0 ]; then
        echo "No crashes found"
    else
        echo "Total crashes found: $CRASH_COUNT"
    fi
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up Tier 2 fuzzing..."
    
    # Kill any remaining fuzzing processes
    if [ -f tier2_fuzzing_pids.txt ]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        done < tier2_fuzzing_pids.txt
        rm -f tier2_fuzzing_pids.txt
    fi
    
    print_success "Cleanup complete"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    echo "=========================================="
    echo "Tier 2: Important Fuzzing Targets"
    echo "=========================================="
    echo "Targets: ${#TIER2_TARGETS[@]}"
    echo "Cores: 6 (1 per target)"
    echo "Time: $((TIMEOUT_SECONDS / 3600)) hours"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    setup_directories
    start_fuzzing
    wait_for_completion
}

# Run main function
main "$@"
