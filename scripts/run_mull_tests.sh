#!/bin/bash

# Mull Mutation Testing Runner for FGcom-mumble
# This script runs comprehensive mutation testing using Mull

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/mutation-results"

echo "=========================================="
echo "FGcom-mumble Mull Mutation Testing"
echo "=========================================="

# Check if Mull is installed
if ! command -v mull-cxx >/dev/null 2>&1; then
    print_error "Mull is not installed!"
    echo "Please install Mull first:"
    echo "  wget https://github.com/mull-project/mull/releases/download/v0.20.0/mull-0.20.0-ubuntu-20.04.deb"
    echo "  sudo dpkg -i mull-0.20.0-ubuntu-20.04.deb"
    echo "  sudo apt-get install -f"
    exit 1
fi

# Check if configuration file exists
if [ ! -f "$PROJECT_ROOT/mull.yml" ]; then
    print_error "Configuration file mull.yml not found!"
    echo "Please ensure mull.yml is in the project root directory."
    exit 1
fi

# Check if compilation database exists
if [ ! -f "$PROJECT_ROOT/client/mumble-plugin/compile_commands.json" ]; then
    print_warning "Compilation database not found!"
    echo "Generating compilation database..."
    
    cd "$PROJECT_ROOT/client/mumble-plugin"
    
    # Try to generate compilation database
    if [ -f "Makefile" ]; then
        print_status "Using existing Makefile..."
        # For Makefile-based projects, we need to generate compile_commands.json differently
        if command -v bear >/dev/null 2>&1; then
            print_status "Using bear to generate compilation database..."
            bear -- make clean all
        else
            print_warning "bear not found. Please install bear or generate compile_commands.json manually."
            echo "You can install bear with: sudo apt-get install bear"
            exit 1
        fi
    elif [ -d "build" ]; then
        print_status "Using CMake build directory..."
        cd build
        cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
        cp compile_commands.json ../compile_commands.json
    else
        print_error "No build system found. Please generate compile_commands.json manually."
        exit 1
    fi
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

# Clean previous results
rm -rf "$RESULTS_DIR"/* 2>/dev/null || true

print_status "Starting mutation testing..."
print_status "Configuration: mull.yml"
print_status "Results directory: $RESULTS_DIR"
print_status "Compilation database: $PROJECT_ROOT/client/mumble-plugin/compile_commands.json"

# Change to project root
cd "$PROJECT_ROOT"

# Run Mull with comprehensive configuration
print_status "Running Mull mutation testing..."

mull-cxx \
    --config mull.yml \
    --reporters=IDE,HTML,JSON,SQLite \
    --output="$RESULTS_DIR/mutation_report.html" \
    --output="$RESULTS_DIR/mutation_report.json" \
    --output="$RESULTS_DIR/mutation_report.db" \
    --workers=6 \
    --timeout=5000 \
    --cache-directory=.mull-cache \
    --compilation-database=client/mumble-plugin/compile_commands.json \
    --include-path=client/mumble-plugin/lib \
    --include-path=client/mumble-plugin/src \
    --exclude-path=test \
    --exclude-path=tests \
    --exclude-path=build \
    --exclude-path=.git \
    --exclude-path=node_modules \
    --exclude-path=webrtc-gateway \
    --exclude-path=releases \
    --exclude-path=docs \
    --exclude-path=assets \
    --exclude-path=configs \
    --exclude-path=scripts \
    --exclude-path=server \
    --exclude-path=client/radioGUI \
    --exclude-path=client/fgfs-addon \
    --exclude-path=test/network_module_tests \
    --exclude-path=test/integration_tests \
    --exclude-path=test/performance_tests \
    --mutators=cxx_add_to_sub,cxx_sub_to_add,cxx_mul_to_div,cxx_div_to_mul,cxx_rem_to_div \
    --mutators=cxx_eq_to_ne,cxx_ne_to_eq,cxx_lt_to_le,cxx_le_to_lt,cxx_gt_to_ge,cxx_ge_to_gt \
    --mutators=cxx_logical_and_to_or,cxx_logical_or_to_and,cxx_bitwise_and_to_or,cxx_bitwise_or_to_and \
    --mutators=cxx_unary_minus,cxx_minus_to_noop,cxx_remove_void_call \
    --mutators=cxx_assign_mul_to_div,cxx_assign_div_to_mul,cxx_assign_add_to_sub,cxx_assign_sub_to_add \
    --mutators=cxx_remove_negation,cxx_remove_condition \
    --mutators=cxx_replace_scalar_return_const,cxx_replace_scalar_call_arg

# Check if mutation testing completed successfully
if [ $? -eq 0 ]; then
    print_success "Mutation testing completed successfully!"
else
    print_error "Mutation testing failed!"
    exit 1
fi

echo ""
print_status "Analyzing results..."

# Check if results file exists
if [ ! -f "$RESULTS_DIR/mutation_report.json" ]; then
    print_error "No mutation testing results found!"
    exit 1
fi

# Extract statistics
SURVIVING=$(grep -o '"status":"SURVIVED"' "$RESULTS_DIR/mutation_report.json" | wc -l || echo "0")
KILLED=$(grep -o '"status":"KILLED"' "$RESULTS_DIR/mutation_report.json" | wc -l || echo "0")
TIMEOUT=$(grep -o '"status":"TIMEOUT"' "$RESULTS_DIR/mutation_report.json" | wc -l || echo "0")
ERROR=$(grep -o '"status":"ERROR"' "$RESULTS_DIR/mutation_report.json" | wc -l || echo "0")
TOTAL=$((SURVIVING + KILLED + TIMEOUT + ERROR))

echo "=========================================="
echo "Mutation Testing Results"
echo "=========================================="
echo "Total Mutations: $TOTAL"
echo "Killed: $KILLED"
echo "Survived: $SURVIVING"
echo "Timeout: $TIMEOUT"
echo "Error: $ERROR"

if [ "$TOTAL" -gt 0 ]; then
    SCORE=$((KILLED * 100 / TOTAL))
    echo "Mutation Score: $SCORE%"
    
    if [ "$SCORE" -ge 90 ]; then
        print_success "EXCELLENT: High mutation score! Test coverage is very good."
    elif [ "$SCORE" -ge 80 ]; then
        print_success "GOOD: Decent mutation score, but there's room for improvement."
    elif [ "$SCORE" -ge 70 ]; then
        print_warning "ADEQUATE: Test coverage is acceptable, but could be better."
    else
        print_error "POOR: Low mutation score! Consider improving test coverage."
    fi
    
    if [ "$SURVIVING" -gt 10 ]; then
        print_warning "High number of surviving mutations ($SURVIVING)"
        echo "Consider improving test coverage or adding more specific tests"
    fi
else
    print_warning "No mutations were generated. Check your configuration and coverage data."
fi

echo ""
echo "Detailed reports available at:"
echo "  HTML: $RESULTS_DIR/mutation_report.html"
echo "  JSON: $RESULTS_DIR/mutation_report.json"
echo "  SQLite: $RESULTS_DIR/mutation_report.db"

# Show top surviving mutations if any
if [ "$SURVIVING" -gt 0 ]; then
    echo ""
    echo "Top surviving mutations (need better test coverage):"
    grep -A 3 -B 3 '"status":"SURVIVED"' "$RESULTS_DIR/mutation_report.json" | head -20 || true
fi

echo ""
echo "=========================================="
echo "Mutation testing analysis complete!"
echo "=========================================="

# Exit with appropriate code based on mutation score
if [ "$TOTAL" -gt 0 ]; then
    if [ "$SCORE" -lt 70 ]; then
        print_error "Mutation score is too low. Please improve test coverage."
        exit 1
    else
        print_success "Mutation testing passed with score: $SCORE%"
        exit 0
    fi
else
    print_warning "No mutations generated. Please check configuration."
    exit 0
fi
