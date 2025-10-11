#!/bin/bash

# Corpus Validation Script for FGCom-Mumble
# Validates corpus files and provides coverage analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CORPUS_DIR="../../corpus"
TARGET_BINARIES_DIR="../../test/fuzzing_strategy/build"
VALIDATION_RESULTS="corpus_validation_results.txt"

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

# Function to validate corpus for a specific target
validate_target_corpus() {
    local target=$1
    local binary_path=$2
    
    print_status "Validating corpus for $target..."
    
    # Check if corpus exists
    if [ ! -d "$CORPUS_DIR/$target" ]; then
        print_warning "Corpus directory not found for $target"
        return 1
    fi
    
    # Check if binary exists
    if [ ! -f "$binary_path" ]; then
        print_warning "Binary not found for $target: $binary_path"
        return 1
    fi
    
    # Count corpus files
    corpus_count=$(find "$CORPUS_DIR/$target" -type f | wc -l)
    
    if [ "$corpus_count" -eq 0 ]; then
        print_warning "No corpus files found for $target"
        return 1
    fi
    
    print_status "Found $corpus_count corpus files for $target"
    
    # Test each corpus file
    local valid_count=0
    local invalid_count=0
    local crash_count=0
    
    for corpus_file in "$CORPUS_DIR/$target"/*; do
        if [ -f "$corpus_file" ]; then
            # Test the file with the target binary
            if timeout 5 "$binary_path" "$corpus_file" >/dev/null 2>&1; then
                valid_count=$((valid_count + 1))
            else
                exit_code=$?
                if [ $exit_code -eq 124 ]; then
                    print_warning "Timeout testing $corpus_file with $target"
                    invalid_count=$((invalid_count + 1))
                elif [ $exit_code -eq 139 ] || [ $exit_code -eq 134 ]; then
                    print_warning "Crash detected testing $corpus_file with $target"
                    crash_count=$((crash_count + 1))
                else
                    invalid_count=$((invalid_count + 1))
                fi
            fi
        fi
    done
    
    # Report results
    echo "Target: $target" >> "$VALIDATION_RESULTS"
    echo "  Total files: $corpus_count" >> "$VALIDATION_RESULTS"
    echo "  Valid files: $valid_count" >> "$VALIDATION_RESULTS"
    echo "  Invalid files: $invalid_count" >> "$VALIDATION_RESULTS"
    echo "  Crash files: $crash_count" >> "$VALIDATION_RESULTS"
    echo "" >> "$VALIDATION_RESULTS"
    
    if [ "$crash_count" -gt 0 ]; then
        print_warning "Found $crash_count files that cause crashes in $target"
    fi
    
    if [ "$valid_count" -gt 0 ]; then
        print_success "Validated $valid_count files for $target"
    else
        print_warning "No valid files found for $target"
    fi
    
    return 0
}

# Function to analyze corpus diversity
analyze_corpus_diversity() {
    local target=$1
    
    print_status "Analyzing corpus diversity for $target..."
    
    # Check file types
    local json_count=0
    local bin_count=0
    local txt_count=0
    local other_count=0
    
    for corpus_file in "$CORPUS_DIR/$target"/*; do
        if [ -f "$corpus_file" ]; then
            case "$(file -b --mime-type "$corpus_file")" in
                "application/json")
                    json_count=$((json_count + 1))
                    ;;
                "application/octet-stream")
                    bin_count=$((bin_count + 1))
                    ;;
                "text/plain")
                    txt_count=$((txt_count + 1))
                    ;;
                *)
                    other_count=$((other_count + 1))
                    ;;
            esac
        fi
    done
    
    echo "  File types:" >> "$VALIDATION_RESULTS"
    echo "    JSON: $json_count" >> "$VALIDATION_RESULTS"
    echo "    Binary: $bin_count" >> "$VALIDATION_RESULTS"
    echo "    Text: $txt_count" >> "$VALIDATION_RESULTS"
    echo "    Other: $other_count" >> "$VALIDATION_RESULTS"
    
    # Check file sizes
    local total_size=0
    local min_size=999999999
    local max_size=0
    
    for corpus_file in "$CORPUS_DIR/$target"/*; do
        if [ -f "$corpus_file" ]; then
            size=$(stat -c%s "$corpus_file")
            total_size=$((total_size + size))
            if [ "$size" -lt "$min_size" ]; then
                min_size=$size
            fi
            if [ "$size" -gt "$max_size" ]; then
                max_size=$size
            fi
        fi
    done
    
    local avg_size=0
    if [ "$corpus_count" -gt 0 ]; then
        avg_size=$((total_size / corpus_count))
    fi
    
    echo "  File sizes:" >> "$VALIDATION_RESULTS"
    echo "    Min: $min_size bytes" >> "$VALIDATION_RESULTS"
    echo "    Max: $max_size bytes" >> "$VALIDATION_RESULTS"
    echo "    Avg: $avg_size bytes" >> "$VALIDATION_RESULTS"
    echo "    Total: $total_size bytes" >> "$VALIDATION_RESULTS"
}

# Function to validate all corpus
validate_all_corpus() {
    print_status "Starting corpus validation for all targets..."
    
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
    
    # Initialize results file
    echo "=== CORPUS VALIDATION RESULTS ===" > "$VALIDATION_RESULTS"
    echo "Timestamp: $(date)" >> "$VALIDATION_RESULTS"
    echo "" >> "$VALIDATION_RESULTS"
    
    # Process each target
    for target in "${!TARGET_BINARIES[@]}"; do
        binary_path="${TARGET_BINARIES[$target]}"
        validate_target_corpus "$target" "$binary_path"
        analyze_corpus_diversity "$target"
    done
    
    print_success "Corpus validation complete"
}

# Function to generate summary
generate_summary() {
    print_status "Generating validation summary..."
    
    echo ""
    echo "=== CORPUS VALIDATION SUMMARY ==="
    echo "Results saved to: $VALIDATION_RESULTS"
    echo ""
    
    # Show summary from results file
    if [ -f "$VALIDATION_RESULTS" ]; then
        echo "=== QUICK SUMMARY ==="
        grep -E "(Target:|Total files:|Valid files:|Crash files:)" "$VALIDATION_RESULTS" | head -20
        echo ""
        echo "See $VALIDATION_RESULTS for detailed results"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "FGCom-Mumble Corpus Validation Script"
    echo "=========================================="
    echo ""
    
    validate_all_corpus
    generate_summary
}

# Run main function
main "$@"
