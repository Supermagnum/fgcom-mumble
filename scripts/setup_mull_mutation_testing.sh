#!/bin/bash

# Comprehensive Mull Mutation Testing Setup for FGcom-mumble
# This script installs and configures Mull for comprehensive mutation testing

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
MULL_DIR="$PROJECT_ROOT/mutation-testing"

print_status "Setting up Mull Mutation Testing for FGcom-mumble"
print_status "Project root: $PROJECT_ROOT"
print_status "Mull directory: $MULL_DIR"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install package
install_package() {
    local package="$1"
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y "$package"
    elif command_exists yum; then
        sudo yum install -y "$package"
    elif command_exists pacman; then
        sudo pacman -S --noconfirm "$package"
    elif command_exists brew; then
        brew install "$package"
    else
        print_error "Package manager not found. Please install $package manually."
        exit 1
    fi
}

echo "=========================================="
echo "FGcom-mumble Mull Mutation Testing Setup"
echo "=========================================="

print_status "1. Installing System Dependencies..."

# Install basic dependencies
if ! command_exists git; then
    print_status "Installing git..."
    install_package "git"
fi

if ! command_exists cmake; then
    print_status "Installing cmake..."
    install_package "cmake"
fi

if ! command_exists make; then
    print_status "Installing build-essential..."
    install_package "build-essential"
fi

if ! command_exists python3; then
    print_status "Installing python3..."
    install_package "python3"
fi

if ! command_exists clang; then
    print_status "Installing clang..."
    install_package "clang"
fi

if ! command_exists llvm-config; then
    print_status "Installing llvm..."
    install_package "llvm"
fi

# Install additional dependencies for Mull
if ! command_exists lcov; then
    print_status "Installing lcov for coverage analysis..."
    install_package "lcov"
fi

if ! command_exists gcov; then
    print_status "Installing gcov..."
    install_package "gcov"
fi

print_success "System dependencies installed"
echo

print_status "2. Installing Mull..."

# Check if Mull is already installed
if command_exists mull-cxx; then
    print_warning "Mull already installed, checking version..."
    mull-cxx --version
else
    print_status "Installing Mull from source..."
    
    # Create mutation testing directory
    mkdir -p "$MULL_DIR"
    cd "$MULL_DIR"
    
    # Clone Mull repository
    if [ ! -d "mull" ]; then
        git clone https://github.com/mull-project/mull.git
    fi
    
    cd mull
    
    # Build Mull
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
    make -j$(nproc)
    
    # Install Mull
    sudo make install
    
    print_success "Mull installed successfully"
fi

echo

print_status "3. Setting up Mutation Testing Environment..."

# Create necessary directories
mkdir -p "$MULL_DIR/results"
mkdir -p "$MULL_DIR/cache"
mkdir -p "$MULL_DIR/reports"
mkdir -p "$MULL_DIR/coverage"

# Set up Mull environment
export MULL_CACHE_DIR="$MULL_DIR/cache"
export MULL_RESULTS_DIR="$MULL_DIR/results"

print_success "Mutation testing environment configured"
echo

print_status "4. Generating Coverage Data..."

# Navigate to the plugin directory
cd "$PROJECT_ROOT/client/mumble-plugin"

# Clean previous builds
make clean > /dev/null 2>&1 || true

# Build with coverage flags
print_status "Building with coverage instrumentation..."
make CFLAGS+="-fprofile-arcs -ftest-coverage -g -O0" clean all

# Run tests to generate coverage data
print_status "Running tests to generate coverage data..."
if [ -d "test" ]; then
    cd test
    # Run any existing tests
    find . -name "*test*" -executable -type f | head -5 | while read test_file; do
        if [ -x "$test_file" ]; then
            print_status "Running $test_file for coverage..."
            timeout 30 ./"$test_file" > /dev/null 2>&1 || true
        fi
    done
    cd ..
fi

# Generate coverage report
print_status "Generating coverage report..."
lcov --capture --directory . --output-file "$MULL_DIR/coverage/coverage.info" || true
lcov --remove "$MULL_DIR/coverage/coverage.info" '/usr/*' '*/test/*' '*/external/*' --output-file "$MULL_DIR/coverage/coverage_filtered.info" || true

print_success "Coverage data generated"
echo

print_status "5. Creating Mull Configuration..."

# Create comprehensive Mull configuration
cat > "$PROJECT_ROOT/mull.yml" << 'EOF'
# Mull Mutation Testing Configuration for FGcom-mumble
# Comprehensive configuration for C++ mutation testing

# Mutators to use - comprehensive set for C++ code
mutators:
  # Arithmetic operators
  - cxx_add_to_sub           # + becomes -
  - cxx_sub_to_add           # - becomes +
  - cxx_mul_to_div           # * becomes /
  - cxx_div_to_mul           # / becomes *
  - cxx_rem_to_div           # % becomes /
  - cxx_inc_to_dec           # ++ becomes --
  - cxx_dec_to_inc           # -- becomes ++
  
  # Comparison operators
  - cxx_eq_to_ne             # == becomes !=
  - cxx_ne_to_eq             # != becomes ==
  - cxx_lt_to_le             # < becomes <=
  - cxx_le_to_lt             # <= becomes <
  - cxx_gt_to_ge             # > becomes >=
  - cxx_ge_to_gt             # >= becomes >
  
  # Logical operators
  - cxx_logical_and_to_or    # && becomes ||
  - cxx_logical_or_to_and    # || becomes &&
  - cxx_bitwise_and_to_or    # & becomes |
  - cxx_bitwise_or_to_and    # | becomes &
  - cxx_bitwise_xor_to_and   # ^ becomes &
  - cxx_bitwise_not          # ~x becomes x
  
  # Unary operators
  - cxx_unary_minus          # -x becomes x
  - cxx_minus_to_noop        # -x becomes x
  - cxx_remove_void_call     # Removes function calls that return void
  
  # Assignment operators
  - cxx_assign_mul_to_div    # *= becomes /=
  - cxx_assign_div_to_mul    # /= becomes *=
  - cxx_assign_add_to_sub    # += becomes -=
  - cxx_assign_sub_to_add    # -= becomes +=
  
  # Conditional operators
  - cxx_remove_negation      # !x becomes x
  - cxx_remove_condition     # if (x) becomes if (true)
  
  # Return value mutations
  - cxx_replace_scalar_return_const # return x becomes return 0
  - cxx_replace_scalar_call_arg     # f(x) becomes f(0)

# Reporters - multiple output formats
reporters:
  - IDE                      # Easy to read in terminal
  - SQLite                   # Store results in database
  - Elements                 # Detailed JSON report
  - HTML                     # Web-based report

# Timeout settings
timeout: 5000                # 5 seconds per test

# Directories to include in mutation testing
include-paths:
  - client/mumble-plugin/lib
  - client/mumble-plugin/src
  - client/mumble-plugin

# Directories to exclude
exclude-paths:
  - test/
  - tests/
  - third-party/
  - external/
  - dependencies/
  - build/
  - .git/
  - node_modules/
  - webrtc-gateway/
  - releases/
  - docs/
  - assets/
  - configs/
  - scripts/
  - server/
  - client/radioGUI/
  - client/fgfs-addon/

# Test framework configuration
test-framework: GoogleTest

# Coverage settings
coverage-info: mutation-testing/coverage/coverage_filtered.info

# Parallel execution
workers: 6                    # Use 6 parallel workers

# Cache results
cache-directory: .mull-cache

# IDE integration
ide-reporter-show-killed: false

# Compilation database
compilation-database: client/mumble-plugin/compile_commands.json

# Debug options
debug: false

# Additional settings
max-mutations-per-file: 1000

# File patterns
include-file-patterns:
  - "*.cpp"
  - "*.c"
  - "*.h"

exclude-file-patterns:
  - "*test*"
  - "*Test*"
  - "*mock*"
  - "*Mock*"
  - "debug.cpp"
  - "debug.h"

# Performance settings
performance:
  max-execution-time: 30s
  memory-limit: 2GB
  cpu-limit: 80%

# Output configuration
output:
  directory: mutation-results
  format: [html, json, sqlite]
  include-source-code: true
  include-mutation-diff: true

# CI/CD integration
ci:
  fail-on-surviving-mutations: true
  min-mutation-score: 80
  max-surviving-mutations: 10

# Logging configuration
logging:
  level: info
  file: mutation-testing.log
  include-timestamps: true
  include-mutation-details: true
EOF

print_success "Mull configuration created"
echo

print_status "6. Creating Mutation Testing Scripts..."

# Create main mutation testing script
cat > "$MULL_DIR/run_mutation_testing.sh" << 'EOF'
#!/bin/bash

# Run Mull mutation testing for FGcom-mumble
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MULL_DIR="$PROJECT_ROOT/mutation-testing"

echo "=========================================="
echo "FGcom-mumble Mutation Testing"
echo "=========================================="

# Change to project root
cd "$PROJECT_ROOT"

# Clean previous results
rm -rf "$MULL_DIR/results"/* 2>/dev/null || true
mkdir -p "$MULL_DIR/results"

echo "1. Running Mull mutation testing..."
echo "   Configuration: mull.yml"
echo "   Results directory: $MULL_DIR/results"
echo "   Coverage data: $MULL_DIR/coverage/coverage_filtered.info"

# Run Mull with comprehensive configuration
mull-cxx \
    --config mull.yml \
    --reporters=IDE,HTML,JSON,SQLite \
    --output="$MULL_DIR/results/mutation_report.html" \
    --output="$MULL_DIR/results/mutation_report.json" \
    --output="$MULL_DIR/results/mutation_report.db" \
    --workers=6 \
    --timeout=5000 \
    --cache-directory="$MULL_DIR/cache" \
    --compilation-database=client/mumble-plugin/compile_commands.json \
    --coverage-info="$MULL_DIR/coverage/coverage_filtered.info" \
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
    --mutators=cxx_add_to_sub,cxx_sub_to_add,cxx_mul_to_div,cxx_div_to_mul,cxx_rem_to_div \
    --mutators=cxx_eq_to_ne,cxx_ne_to_eq,cxx_lt_to_le,cxx_le_to_lt,cxx_gt_to_ge,cxx_ge_to_gt \
    --mutators=cxx_logical_and_to_or,cxx_logical_or_to_and,cxx_bitwise_and_to_or,cxx_bitwise_or_to_and \
    --mutators=cxx_unary_minus,cxx_minus_to_noop,cxx_remove_void_call \
    --mutators=cxx_assign_mul_to_div,cxx_assign_div_to_mul,cxx_assign_add_to_sub,cxx_assign_sub_to_add \
    --mutators=cxx_remove_negation,cxx_remove_condition \
    --mutators=cxx_replace_scalar_return_const,cxx_replace_scalar_call_arg

echo "2. Mutation testing completed!"
echo "   Results available at:"
echo "   - HTML Report: $MULL_DIR/results/mutation_report.html"
echo "   - JSON Report: $MULL_DIR/results/mutation_report.json"
echo "   - SQLite Database: $MULL_DIR/results/mutation_report.db"

# Check if there are surviving mutations
if [ -f "$MULL_DIR/results/mutation_report.json" ]; then
    SURVIVING=$(grep -o '"status":"SURVIVED"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
    KILLED=$(grep -o '"status":"KILLED"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
    TOTAL=$((SURVIVING + KILLED))
    
    if [ "$TOTAL" -gt 0 ]; then
        SCORE=$((KILLED * 100 / TOTAL))
        echo "   Mutation Score: $SCORE% ($KILLED killed, $SURVIVING survived out of $TOTAL total)"
        
        if [ "$SURVIVING" -gt 10 ]; then
            echo "   WARNING: High number of surviving mutations ($SURVIVING)"
            echo "   Consider improving test coverage or adding more specific tests"
        fi
    fi
fi

echo "=========================================="
echo "Mutation testing analysis complete!"
echo "=========================================="
EOF

chmod +x "$MULL_DIR/run_mutation_testing.sh"

# Create quick analysis script
cat > "$MULL_DIR/analyze_results.sh" << 'EOF'
#!/bin/bash

# Analyze Mull mutation testing results
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MULL_DIR="$PROJECT_ROOT/mutation-testing"

echo "=========================================="
echo "FGcom-mumble Mutation Testing Analysis"
echo "=========================================="

if [ ! -f "$MULL_DIR/results/mutation_report.json" ]; then
    echo "ERROR: No mutation testing results found!"
    echo "Run ./run_mutation_testing.sh first"
    exit 1
fi

echo "Analyzing mutation testing results..."

# Extract statistics
SURVIVING=$(grep -o '"status":"SURVIVED"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
KILLED=$(grep -o '"status":"KILLED"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
TIMEOUT=$(grep -o '"status":"TIMEOUT"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
ERROR=$(grep -o '"status":"ERROR"' "$MULL_DIR/results/mutation_report.json" | wc -l || echo "0")
TOTAL=$((SURVIVING + KILLED + TIMEOUT + ERROR))

echo "Mutation Testing Statistics:"
echo "  Total Mutations: $TOTAL"
echo "  Killed: $KILLED"
echo "  Survived: $SURVIVING"
echo "  Timeout: $TIMEOUT"
echo "  Error: $ERROR"

if [ "$TOTAL" -gt 0 ]; then
    SCORE=$((KILLED * 100 / TOTAL))
    echo "  Mutation Score: $SCORE%"
    
    if [ "$SCORE" -lt 80 ]; then
        echo "  WARNING: Low mutation score! Consider improving test coverage."
    elif [ "$SCORE" -ge 90 ]; then
        echo "  EXCELLENT: High mutation score! Test coverage is very good."
    else
        echo "  GOOD: Decent mutation score, but there's room for improvement."
    fi
fi

echo ""
echo "Detailed reports available at:"
echo "  HTML: $MULL_DIR/results/mutation_report.html"
echo "  JSON: $MULL_DIR/results/mutation_report.json"
echo "  SQLite: $MULL_DIR/results/mutation_report.db"

# Show top surviving mutations if any
if [ "$SURVIVING" -gt 0 ]; then
    echo ""
    echo "Top surviving mutations (need better test coverage):"
    grep -A 5 -B 5 '"status":"SURVIVED"' "$MULL_DIR/results/mutation_report.json" | head -20 || true
fi

echo "=========================================="
EOF

chmod +x "$MULL_DIR/analyze_results.sh"

print_success "Mutation testing scripts created"
echo

print_status "7. Creating CI/CD Integration..."

# Create GitHub Actions workflow
mkdir -p "$PROJECT_ROOT/.github/workflows"
cat > "$PROJECT_ROOT/.github/workflows/mutation-testing.yml" << 'EOF'
name: Mutation Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y build-essential cmake clang llvm git python3 lcov gcov
    
    - name: Setup Mull
      run: |
        git clone https://github.com/mull-project/mull.git
        cd mull
        mkdir build && cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        sudo make install
    
    - name: Build with coverage
      run: |
        cd client/mumble-plugin
        make clean
        make CFLAGS+="-fprofile-arcs -ftest-coverage -g -O0" all
    
    - name: Generate coverage data
      run: |
        cd client/mumble-plugin
        lcov --capture --directory . --output-file coverage.info
        lcov --remove coverage.info '/usr/*' '*/test/*' '*/external/*' --output-file coverage_filtered.info
    
    - name: Run mutation testing
      run: |
        ./mutation-testing/run_mutation_testing.sh
    
    - name: Analyze results
      run: |
        ./mutation-testing/analyze_results.sh
    
    - name: Upload results
      uses: actions/upload-artifact@v4
      with:
        name: mutation-testing-results
        path: mutation-testing/results/
        retention-days: 30
    
    - name: Comment PR with results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          try {
            const results = JSON.parse(fs.readFileSync('mutation-testing/results/mutation_report.json', 'utf8'));
            const surviving = results.filter(m => m.status === 'SURVIVED').length;
            const killed = results.filter(m => m.status === 'KILLED').length;
            const total = surviving + killed;
            const score = total > 0 ? Math.round((killed / total) * 100) : 0;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Mutation Testing Results
              
              **Mutation Score:** ${score}%
              **Total Mutations:** ${total}
              **Killed:** ${killed}
              **Survived:** ${surviving}
              
              ${score < 80 ? '⚠️ Low mutation score - consider improving test coverage' : '✅ Good mutation score'}
              
              [View detailed report](https://github.com/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId})`
            });
          } catch (error) {
            console.log('Could not parse mutation testing results:', error);
          }
EOF

print_success "CI/CD integration created"
echo

print_status "8. Creating Documentation..."

# Create comprehensive documentation
cat > "$MULL_DIR/README.md" << 'EOF'
# Mull Mutation Testing for FGcom-mumble

This directory contains comprehensive mutation testing setup for the FGcom-mumble project using Mull.

## Overview

Mutation testing is a technique to evaluate the quality of test suites by introducing small changes (mutations) to the code and checking if tests catch these changes. A high mutation score indicates good test coverage.

## Quick Start

```bash
# Run mutation testing
./mutation-testing/run_mutation_testing.sh

# Analyze results
./mutation-testing/analyze_results.sh
```

## Configuration

The mutation testing is configured via `mull.yml` in the project root. Key settings:

- **Mutators**: Comprehensive set of C++ mutations (arithmetic, logical, comparison operators)
- **Coverage**: Only mutates code covered by tests
- **Parallel execution**: 6 workers for faster execution
- **Timeout**: 5 seconds per test
- **Output formats**: HTML, JSON, SQLite

## Directory Structure

```
mutation-testing/
├── results/                 # Mutation testing results
│   ├── mutation_report.html # HTML report
│   ├── mutation_report.json # JSON report
│   └── mutation_report.db   # SQLite database
├── coverage/               # Coverage data
│   └── coverage_filtered.info
├── cache/                  # Mull cache
├── run_mutation_testing.sh # Main script
├── analyze_results.sh      # Analysis script
└── README.md              # This file
```

## Understanding Results

### Mutation Score
- **90%+**: Excellent test coverage
- **80-89%**: Good test coverage
- **70-79%**: Adequate test coverage
- **<70%**: Poor test coverage - needs improvement

### Mutation Types
- **KILLED**: Test caught the mutation (good)
- **SURVIVED**: Test didn't catch the mutation (needs improvement)
- **TIMEOUT**: Mutation caused timeout
- **ERROR**: Mutation caused compilation/runtime error

## Improving Mutation Score

1. **Add more test cases** for uncovered code paths
2. **Improve assertion quality** - use specific assertions instead of generic ones
3. **Test edge cases** and boundary conditions
4. **Add property-based tests** for complex calculations
5. **Mock external dependencies** to isolate code under test

## CI/CD Integration

Mutation testing runs automatically on:
- Push to main/develop branches
- Pull requests
- Weekly schedule (Sundays at 2 AM)

Results are uploaded as artifacts and PR comments include mutation scores.

## Advanced Usage

### Custom Mutators
Edit `mull.yml` to add/remove specific mutators:

```yaml
mutators:
  - cxx_add_to_sub
  - cxx_eq_to_ne
  # Add more as needed
```

### Coverage
Ensure coverage data is generated:

```bash
# Build with coverage
make CFLAGS+="-fprofile-arcs -ftest-coverage -g -O0" clean all

# Generate coverage
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/test/*' --output-file coverage_filtered.info
```

### Performance Tuning
Adjust workers and timeout in `mull.yml`:

```yaml
workers: 8        # More workers for faster execution
timeout: 10000    # Longer timeout for complex tests
```

## Troubleshooting

### Common Issues

1. **No coverage data**: Ensure tests are run before mutation testing
2. **High timeout rate**: Increase timeout or optimize slow tests
3. **Low mutation score**: Improve test coverage and assertion quality
4. **Build failures**: Check compilation database and dependencies

### Debug Mode
Enable debug mode in `mull.yml`:

```yaml
debug: true
```

This provides detailed logging of mutation testing process.

## Best Practices

1. **Run regularly**: Include mutation testing in CI/CD pipeline
2. **Track trends**: Monitor mutation score over time
3. **Focus on critical code**: Prioritize high-risk modules
4. **Combine with coverage**: Use both line coverage and mutation testing
5. **Document findings**: Keep track of surviving mutations and improvements

## Resources

- [Mull Documentation](https://mull.readthedocs.io/)
- [Mutation Testing Best Practices](https://pitest.org/quickstart/best_practices/)
- [FGcom-mumble Testing Framework](../docs/testing_framework.md)
EOF

print_success "Documentation created"
echo

print_status "9. Final Setup..."

# Create main mutation testing script
cat > "$PROJECT_ROOT/run_mutation_testing.sh" << 'EOF'
#!/bin/bash

# Main mutation testing script for FGcom-mumble
set -e

echo "=========================================="
echo "FGcom-mumble Mutation Testing"
echo "=========================================="

# Check if Mull is installed
if ! command -v mull-cxx >/dev/null 2>&1; then
    echo "ERROR: Mull is not installed!"
    echo "Run: ./scripts/setup_mull_mutation_testing.sh"
    exit 1
fi

# Run mutation testing
./mutation-testing/run_mutation_testing.sh

# Analyze results
./mutation-testing/analyze_results.sh

echo "=========================================="
echo "Mutation testing completed!"
echo "Check mutation-testing/results/ for detailed reports"
echo "=========================================="
EOF

chmod +x "$PROJECT_ROOT/run_mutation_testing.sh"

print_success "Final setup completed"
echo

print_status "10. Verifying Installation..."

# Check Mull installation
if command_exists mull-cxx; then
    print_success "Mull is installed and ready"
    mull-cxx --version
else
    print_error "Mull installation failed"
fi

# Check configuration
if [ -f "$PROJECT_ROOT/mull.yml" ]; then
    print_success "Mull configuration created"
else
    print_error "Configuration file not found"
fi

# Check scripts
if [ -f "$MULL_DIR/run_mutation_testing.sh" ] && [ -f "$MULL_DIR/analyze_results.sh" ]; then
    print_success "Mutation testing scripts created"
else
    print_error "Scripts not created properly"
fi

echo
print_success "Mull mutation testing setup completed successfully!"
print_status "Next steps:"
print_status "1. ./run_mutation_testing.sh"
print_status "2. Check mutation-testing/results/ for reports"
print_status "3. Review mutation-testing/README.md for detailed usage"
print_status "4. Improve test coverage based on mutation testing results"
