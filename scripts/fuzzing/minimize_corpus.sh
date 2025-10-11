#!/bin/bash

# Corpus Minimization Script for FGCom-Mumble
# Uses AFL++ corpus minimization tools to optimize corpus coverage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CORPUS_DIR="../../corpus"
RESULTS_DIR="results"
MINIMIZED_DIR="corpus_minimized"
TARGET_BINARIES_DIR="../../test/fuzzing_strategy/build"

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
    print_status "Checking prerequisites..."
    
    # Check if AFL++ is installed
    if ! command -v afl-cmin &> /dev/null; then
        print_error "AFL++ is not installed. Please install it first."
        exit 1
    fi
    
    # Check if target binaries exist
    if [ ! -d "$TARGET_BINARIES_DIR" ]; then
        print_error "Target binaries directory not found: $TARGET_BINARIES_DIR"
        print_error "Please build the fuzzing targets first"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to minimize corpus for a specific target
minimize_target_corpus() {
    local target=$1
    local binary_path=$2
    
    print_status "Minimizing corpus for $target..."
    
    # Create minimized directory
    mkdir -p "$MINIMIZED_DIR/$target"
    
    # Check if corpus exists
    if [ ! -d "$CORPUS_DIR/$target" ]; then
        print_warning "Corpus directory not found for $target, skipping..."
        return
    fi
    
    # Check if binary exists
    if [ ! -f "$binary_path" ]; then
        print_warning "Binary not found for $target: $binary_path, skipping..."
        return
    fi
    
    # Count original corpus files
    original_count=$(find "$CORPUS_DIR/$target" -type f | wc -l)
    
    if [ "$original_count" -eq 0 ]; then
        print_warning "No corpus files found for $target, skipping..."
        return
    fi
    
    print_status "Original corpus size for $target: $original_count files"
    
    # Run corpus minimization
    if afl-cmin -i "$CORPUS_DIR/$target" -o "$MINIMIZED_DIR/$target" -- "$binary_path" @@ 2>/dev/null; then
        # Count minimized corpus files
        minimized_count=$(find "$MINIMIZED_DIR/$target" -type f | wc -l)
        reduction=$((original_count - minimized_count))
        reduction_percent=$((reduction * 100 / original_count))
        
        print_success "Corpus minimized for $target: $original_count -> $minimized_count files ($reduction_percent% reduction)"
    else
        print_warning "Corpus minimization failed for $target, keeping original"
        cp -r "$CORPUS_DIR/$target"/* "$MINIMIZED_DIR/$target/" 2>/dev/null || true
    fi
}

# Function to minimize all corpus
minimize_all_corpus() {
    print_status "Starting corpus minimization for all targets..."
    
    # Target binaries mapping
    declare -A TARGET_BINARIES=(
        ["fuzz_radio_propagation"]="$TARGET_BINARIES_DIR/tier2_important"
        ["fuzz_audio_processing"]="$TARGET_BINARIES_DIR/tier2_important"
        ["fuzz_antenna_patterns"]="$TARGET_BINARIES_DIR/tier3_standard"
        ["fuzz_frequency_management"]="$TARGET_BINARIES_DIR/tier2_important"
        ["fuzz_agc_squelch"]="$TARGET_BINARIES_DIR/tier2_important"
        ["fuzz_network_protocol"]="$TARGET_BINARIES_DIR/tier1_critical"
        ["fuzz_geographic_calculations"]="$TARGET_BINARIES_DIR/tier3_standard"
        ["fuzz_atis_processing"]="$TARGET_BINARIES_DIR/tier1_critical"
        ["fuzz_database_operations"]="$TARGET_BINARIES_DIR/tier2_important"
        ["fuzz_security_functions"]="$TARGET_BINARIES_DIR/tier1_critical"
        ["fuzz_status_page"]="$TARGET_BINARIES_DIR/tier3_standard"
        ["fuzz_webrtc_operations"]="$TARGET_BINARIES_DIR/tier1_critical"
        ["fuzz_integration_tests"]="$TARGET_BINARIES_DIR/tier3_standard"
        ["fuzz_performance_tests"]="$TARGET_BINARIES_DIR/tier3_standard"
        ["fuzz_error_handling"]="$TARGET_BINARIES_DIR/tier2_important"
    )
    
    # Create minimized directory
    mkdir -p "$MINIMIZED_DIR"
    
    # Process each target
    for target in "${!TARGET_BINARIES[@]}"; do
        binary_path="${TARGET_BINARIES[$target]}"
        minimize_target_corpus "$target" "$binary_path"
    done
    
    print_success "Corpus minimization complete"
}

# Function to generate summary
generate_summary() {
    print_status "Generating corpus minimization summary..."
    
    echo ""
    echo "=== CORPUS MINIMIZATION SUMMARY ==="
    echo "Timestamp: $(date)"
    echo ""
    
    echo "=== RESULTS BY TARGET ==="
    for target_dir in "$MINIMIZED_DIR"/*; do
        if [ -d "$target_dir" ]; then
            target=$(basename "$target_dir")
            original_count=$(find "$CORPUS_DIR/$target" -type f 2>/dev/null | wc -l)
            minimized_count=$(find "$target_dir" -type f | wc -l)
            
            if [ "$original_count" -gt 0 ]; then
                reduction=$((original_count - minimized_count))
                reduction_percent=$((reduction * 100 / original_count))
                echo "$target: $original_count -> $minimized_count files ($reduction_percent% reduction)"
            else
                echo "$target: No original corpus found"
            fi
        fi
    done
    
    echo ""
    echo "=== TOTAL REDUCTION ==="
    total_original=0
    total_minimized=0
    
    for target_dir in "$MINIMIZED_DIR"/*; do
        if [ -d "$target_dir" ]; then
            target=$(basename "$target_dir")
            original_count=$(find "$CORPUS_DIR/$target" -type f 2>/dev/null | wc -l)
            minimized_count=$(find "$target_dir" -type f | wc -l)
            total_original=$((total_original + original_count))
            total_minimized=$((total_minimized + minimized_count))
        fi
    done
    
    if [ "$total_original" -gt 0 ]; then
        total_reduction=$((total_original - total_minimized))
        total_reduction_percent=$((total_reduction * 100 / total_original))
        echo "Total: $total_original -> $total_minimized files ($total_reduction_percent% reduction)"
    fi
    
    echo ""
    echo "Minimized corpus saved to: $MINIMIZED_DIR"
    echo "To use minimized corpus, copy files from $MINIMIZED_DIR to $CORPUS_DIR"
}

# Main execution
main() {
    echo "=========================================="
    echo "FGCom-Mumble Corpus Minimization Script"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    minimize_all_corpus
    generate_summary
}

# Run main function
main "$@"
