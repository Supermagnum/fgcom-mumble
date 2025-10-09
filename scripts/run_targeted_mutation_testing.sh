#!/bin/bash

# Targeted Mutation Testing for FGcom-mumble
# Tests one module at a time with specific mutation score thresholds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

print_target() {
    echo -e "${PURPLE}[TARGET]${NC} $1"
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/mutation-results"

# Module definitions with target mutation scores
declare -A MODULES=(
    ["security"]="90:lib/work_unit_security.cpp:lib/agc_squelch_api.cpp:lib/feature_toggles.cpp"
    ["radio_propagation"]="85:lib/radio_model.cpp:lib/propagation_physics.cpp:lib/atmospheric_ducting.cpp"
    ["agc_squelch"]="85:lib/agc_squelch.cpp:lib/agc_squelch_api.cpp:lib/ctcss_system.cpp"
    ["audio_processing"]="80:lib/audio.cpp:lib/advanced_modulation.cpp:lib/amateur_radio.cpp"
    ["database_config"]="75:lib/radio_model_config_loader.cpp:lib/preset_channel_config_loader.cpp:lib/radio_config.cpp"
)

# Function to show available modules
show_modules() {
    echo "Available modules for targeted mutation testing:"
    echo "=============================================="
    for module in "${!MODULES[@]}"; do
        IFS=':' read -r target_score files <<< "${MODULES[$module]}"
        echo "  $module (Target: ${target_score}%)"
    done
    echo ""
}

# Function to run mutation testing for a specific module
test_module() {
    local module_name="$1"
    local module_config="${MODULES[$module_name]}"
    
    if [ -z "$module_config" ]; then
        print_error "Unknown module: $module_name"
        show_modules
        exit 1
    fi
    
    IFS=':' read -r target_score files <<< "$module_config"
    
    print_target "Testing module: $module_name (Target: ${target_score}%)"
    echo "Files: $files"
    echo ""
    
    # Create module-specific results directory
    local module_results="$RESULTS_DIR/$module_name"
    mkdir -p "$module_results"
    
    # Clean previous results
    rm -rf "$module_results"/* 2>/dev/null || true
    
    print_status "Running mutation testing for $module_name..."
    
    # Determine test program based on module
    local test_program=""
    case "$module_name" in
        "security")
            test_program="$PROJECT_ROOT/test/security_module_tests/build/security_module_tests"
            ;;
        "radio_propagation")
            test_program="$PROJECT_ROOT/test/radio_propagation_tests/build/radio_propagation_tests"
            ;;
        "agc_squelch")
            test_program="$PROJECT_ROOT/test/agc_squelch_tests/build/agc_squelch_tests"
            ;;
        "audio_processing")
            test_program="$PROJECT_ROOT/test/audio_processing_tests/build/audio_processing_tests"
            ;;
        "database_config")
            test_program="$PROJECT_ROOT/test/database_configuration_module_tests/build/database_configuration_module_tests"
            ;;
        *)
            print_error "No test program found for module: $module_name"
            return 1
            ;;
    esac
    
    # Check if test program exists
    if [ ! -f "$test_program" ]; then
        print_warning "Test program not found: $test_program"
        print_status "Building test program..."
        
        # Try to build the test
        local test_dir=$(dirname "$test_program")
        if [ -d "$test_dir" ]; then
            cd "$test_dir"
            make > /dev/null 2>&1 || print_warning "Failed to build test program"
            cd "$PROJECT_ROOT"
        fi
        
        if [ ! -f "$test_program" ]; then
            print_error "Cannot find or build test program for $module_name"
            return 1
        fi
    fi
    
    print_status "Using test program: $test_program"
    
    # Convert colon-separated files to space-separated with full paths
    local source_files=""
    IFS=':' read -ra file_array <<< "$files"
    for file in "${file_array[@]}"; do
        if [ -f "$PROJECT_ROOT/client/mumble-plugin/$file" ]; then
            source_files="$source_files $PROJECT_ROOT/client/mumble-plugin/$file"
        else
            print_warning "Source file not found: $file"
        fi
    done
    
    if [ -z "$source_files" ]; then
        print_error "No valid source files found for $module_name"
        return 1
    fi
    
    print_status "Source files: $source_files"
    
    # Run Mull with module-specific configuration
    # Note: Mull works with compiled object files, not source files
    # We'll use the test program to run mutations
    mull-cxx \
        --reporters=IDE \
        --reporters=SQLite \
        --reporters=Elements \
        --report-dir="$module_results" \
        --report-name="mutation_report" \
        --workers=4 \
        --timeout=3000 \
        --test-program="$test_program" \
        $source_files
    
    # Analyze results
    analyze_module_results "$module_name" "$target_score" "$module_results"
}

# Function to analyze module results
analyze_module_results() {
    local module_name="$1"
    local target_score="$2"
    local module_results="$3"
    
    echo ""
    print_status "Analyzing results for $module_name..."
    
    if [ ! -f "$module_results/mutation_report.json" ]; then
        print_error "No mutation testing results found for $module_name!"
        return 1
    fi
    
    # Extract statistics
    local surviving=$(grep -o '"status":"SURVIVED"' "$module_results/mutation_report.json" | wc -l || echo "0")
    local killed=$(grep -o '"status":"KILLED"' "$module_results/mutation_report.json" | wc -l || echo "0")
    local timeout=$(grep -o '"status":"TIMEOUT"' "$module_results/mutation_report.json" | wc -l || echo "0")
    local error=$(grep -o '"status":"ERROR"' "$module_results/mutation_report.json" | wc -l || echo "0")
    local total=$((surviving + killed + timeout + error))
    
    echo "=========================================="
    echo "Results for $module_name:"
    echo "=========================================="
    echo "Total Mutations: $total"
    echo "Killed: $killed"
    echo "Survived: $surviving"
    echo "Timeout: $timeout"
    echo "Error: $error"
    
    if [ "$total" -gt 0 ]; then
        local score=$((killed * 100 / total))
        echo "Mutation Score: $score%"
        echo "Target Score: ${target_score}%"
        
        if [ "$score" -ge "$target_score" ]; then
            print_success "✅ TARGET ACHIEVED! Score: $score% (Target: ${target_score}%)"
        elif [ "$score" -ge $((target_score - 10)) ]; then
            print_warning "⚠️  CLOSE TO TARGET! Score: $score% (Target: ${target_score}%)"
            echo "   Consider adding a few more test cases to reach the target."
        else
            print_error "❌ BELOW TARGET! Score: $score% (Target: ${target_score}%)"
            echo "   Significant improvement needed in test coverage."
        fi
        
        # Show surviving mutations
        if [ "$surviving" -gt 0 ]; then
            echo ""
            echo "Surviving mutations (need better test coverage):"
            grep -A 5 -B 5 '"status":"SURVIVED"' "$module_results/mutation_report.json" | head -15 || true
        fi
        
        # Generate improvement suggestions
        generate_improvement_suggestions "$module_name" "$score" "$target_score" "$surviving"
        
    else
        print_warning "No mutations were generated for $module_name."
        echo "This might indicate:"
        echo "  - No test coverage for the module"
        echo "  - Module files not found"
        echo "  - Compilation issues"
    fi
    
    echo ""
    echo "Detailed reports available at:"
    echo "  HTML: $module_results/mutation_report.html"
    echo "  JSON: $module_results/mutation_report.json"
    echo ""
}

# Function to generate improvement suggestions
generate_improvement_suggestions() {
    local module_name="$1"
    local current_score="$2"
    local target_score="$3"
    local surviving_count="$4"
    
    echo "=========================================="
    echo "Improvement Suggestions for $module_name:"
    echo "=========================================="
    
    case "$module_name" in
        "security")
            echo "🔒 Security Module (Target: 90%+)"
            echo "  - Add authentication failure tests"
            echo "  - Test invalid input handling"
            echo "  - Test boundary conditions for security checks"
            echo "  - Add property-based tests for security invariants"
            ;;
        "radio_propagation")
            echo "📡 Radio Propagation (Target: 85%+)"
            echo "  - Test edge cases in frequency calculations"
            echo "  - Add tests for extreme distance values"
            echo "  - Test atmospheric conditions (rain, fog, etc.)"
            echo "  - Validate antenna pattern calculations"
            ;;
        "agc_squelch")
            echo "🎛️  AGC/Squelch (Target: 85%+)"
            echo "  - Test audio level thresholds"
            echo "  - Add tests for noise floor calculations"
            echo "  - Test squelch open/close conditions"
            echo "  - Validate gain control algorithms"
            ;;
        "audio_processing")
            echo "🎵 Audio Processing (Target: 80%+)"
            echo "  - Test audio sample processing"
            echo "  - Add tests for audio codec functions"
            echo "  - Test audio quality metrics"
            echo "  - Validate audio filtering algorithms"
            ;;
        "database_config")
            echo "🗄️  Database Config (Target: 75%+)"
            echo "  - Test configuration loading/parsing"
            echo "  - Add tests for invalid configuration handling"
            echo "  - Test configuration validation logic"
            echo "  - Validate default value handling"
            ;;
    esac
    
    if [ "$surviving_count" -gt 0 ]; then
        echo ""
        echo "📋 Next Steps:"
        echo "  1. Review surviving mutations in the HTML report"
        echo "  2. Add specific test cases for uncovered logic"
        echo "  3. Improve assertion quality in existing tests"
        echo "  4. Add edge case and boundary condition tests"
        echo "  5. Re-run mutation testing to verify improvements"
    fi
}

# Function to run all modules
test_all_modules() {
    print_status "Running mutation testing for all modules..."
    echo ""
    
    local total_modules=0
    local passed_modules=0
    
    for module in "${!MODULES[@]}"; do
        IFS=':' read -r target_score files <<< "${MODULES[$module]}"
        total_modules=$((total_modules + 1))
        
        if test_module "$module"; then
            passed_modules=$((passed_modules + 1))
        fi
        
        echo ""
        echo "Press Enter to continue to next module, or Ctrl+C to stop..."
        read -r
    done
    
    echo "=========================================="
    echo "Summary: $passed_modules/$total_modules modules passed their targets"
    echo "=========================================="
}

# Main script logic
echo "=========================================="
echo "FGcom-mumble Targeted Mutation Testing"
echo "=========================================="

# Check if Mull is installed
if ! command -v mull-cxx >/dev/null 2>&1; then
    print_error "Mull is not installed!"
    echo "Please install Mull first:"
    echo "  wget https://github.com/mull-project/mull/releases/download/v0.20.0/mull-0.20.0-ubuntu-20.04.deb"
    echo "  sudo dpkg -i mull-0.20.0-ubuntu-20.04.deb"
    exit 1
fi

# Check if configuration file exists
if [ ! -f "$PROJECT_ROOT/client/mumble-plugin/compile_commands.json" ]; then
    print_warning "Compilation database not found!"
    echo "Generating compilation database..."
    
    cd "$PROJECT_ROOT/client/mumble-plugin"
    
    if [ -f "Makefile" ]; then
        if command -v bear >/dev/null 2>&1; then
            bear -- make clean all
        else
            print_error "bear not found. Please install bear or generate compile_commands.json manually."
            echo "You can install bear with: sudo apt-get install bear"
            exit 1
        fi
    else
        print_error "No build system found. Please generate compile_commands.json manually."
        exit 1
    fi
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <module_name|all>"
    echo ""
    show_modules
    echo "Examples:"
    echo "  $0 security          # Test security module"
    echo "  $0 radio_propagation # Test radio propagation module"
    echo "  $0 all               # Test all modules"
    exit 1
fi

if [ "$1" = "all" ]; then
    test_all_modules
else
    test_module "$1"
fi

echo "=========================================="
echo "Targeted mutation testing completed!"
echo "=========================================="
