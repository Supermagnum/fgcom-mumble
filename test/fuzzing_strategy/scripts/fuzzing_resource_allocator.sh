#!/bin/bash

# Fuzzing Resource Allocator for 15 Targets with 20 Cores
# Implements priority-based resource allocation strategy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOTAL_CORES=20
TOTAL_TIME_HOURS=6
TOTAL_TIME_SECONDS=$((TOTAL_TIME_HOURS * 3600))

# Tier definitions
TIER1_CORES=8    # 2 cores each for 4 targets
TIER2_CORES=6    # 1 core each for 6 targets  
TIER3_CORES=6    # Shared cores for 5 targets

# Target definitions
declare -A TIER1_TARGETS=(
    ["fuzz_network_protocol"]="2"
    ["fuzz_webrtc_operations"]="2"
    ["fuzz_security_functions"]="2"
    ["fuzz_atis_processing"]="2"
)

declare -A TIER2_TARGETS=(
    ["fuzz_audio_processing"]="1"
    ["fuzz_radio_propagation"]="1"
    ["fuzz_frequency_management"]="1"
    ["fuzz_agc_squelch"]="1"
    ["fuzz_database_operations"]="1"
    ["fuzz_error_handling"]="1"
)

declare -A TIER3_TARGETS=(
    ["fuzz_antenna_patterns"]="1"
    ["fuzz_geographic_calculations"]="1"
    ["fuzz_status_page"]="1"
    ["fuzz_integration_tests"]="1"
    ["fuzz_performance_tests"]="1"
)

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

# Function to calculate resource allocation
calculate_allocation() {
    print_status "Calculating resource allocation for 15 fuzzing targets with 20 cores over 6 hours"
    
    echo ""
    echo "=== TIER 1: CRITICAL TARGETS (High Risk) ==="
    echo "Allocation: 2 cores each, 6 hours duration"
    echo "Total cores: $TIER1_CORES"
    echo "Targets:"
    for target in "${!TIER1_TARGETS[@]}"; do
        cores=${TIER1_TARGETS[$target]}
        echo "  - $target: $cores cores, 6 hours"
    done
    
    echo ""
    echo "=== TIER 2: IMPORTANT TARGETS (Medium Risk) ==="
    echo "Allocation: 1 core each, 6 hours duration"
    echo "Total cores: $TIER2_CORES"
    echo "Targets:"
    for target in "${!TIER2_TARGETS[@]}"; do
        cores=${TIER2_TARGETS[$target]}
        echo "  - $target: $cores cores, 6 hours"
    done
    
    echo ""
    echo "=== TIER 3: STANDARD TARGETS (Lower Risk) ==="
    echo "Allocation: Shared cores, rotating schedule"
    echo "Total cores: $TIER3_CORES"
    echo "Targets:"
    for target in "${!TIER3_TARGETS[@]}"; do
        cores=${TIER3_TARGETS[$target]}
        echo "  - $target: $cores cores, 2-3 hours (rotating)"
    done
    
    echo ""
    echo "=== RESOURCE SUMMARY ==="
    echo "Total cores allocated: $((TIER1_CORES + TIER2_CORES + TIER3_CORES))"
    echo "Total cores available: $TOTAL_CORES"
    echo "Total time: $TOTAL_TIME_HOURS hours"
    echo "Total core-hours: $((TOTAL_CORES * TOTAL_TIME_HOURS))"
}

# Function to generate execution strategies
generate_execution_strategies() {
    print_status "Generating execution strategies"
    
    echo ""
    echo "=== EXECUTION STRATEGY OPTIONS ==="
    
    echo ""
    echo "Option 1: Parallel-First (Recommended)"
    echo "- Run all Tier 1+2 targets simultaneously (14 cores)"
    echo "- Use remaining 6 cores for rotating Tier 3 targets"
    echo "- Each Tier 3 target gets ~1.2 hours of fuzzing time"
    echo "- Benefits: Maximum parallelization, comprehensive coverage"
    
    echo ""
    echo "Option 2: Sequential Priority"
    echo "- Run Tier 1 for full 6 hours (8 cores)"
    echo "- Run Tier 2 for full 6 hours (6 cores)"
    echo "- Run Tier 3 targets for 2 hours each (6 cores rotating)"
    echo "- Benefits: Focused attention on high-priority targets"
    
    echo ""
    echo "Option 3: Staged Approach"
    echo "- Hours 1-3: All 15 targets running (some shared cores)"
    echo "- Hours 3-6: Focus on targets that found issues or show low coverage"
    echo "- Benefits: Adaptive based on early results"
}

# Function to create execution scripts
create_execution_scripts() {
    print_status "Creating execution scripts"
    
    # Create parallel execution script
    cat > fuzzing_parallel.sh << 'EOF'
#!/bin/bash
# Parallel-First Execution Strategy

echo "Starting parallel fuzzing execution..."

# Tier 1 targets (2 cores each)
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    echo "Starting $target with 2 cores"
    timeout 21600 afl-fuzz -i corpus/$target -o results/$target -t 10000 -M $target -- ./targets/tier1_critical @@ &
    sleep 2
done

# Tier 2 targets (1 core each)
for target in fuzz_audio_processing fuzz_radio_propagation fuzz_frequency_management fuzz_agc_squelch fuzz_database_operations fuzz_error_handling; do
    echo "Starting $target with 1 core"
    timeout 21600 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier2_important @@ &
    sleep 2
done

# Tier 3 targets (rotating on 6 cores)
echo "Starting Tier 3 targets in rotation..."
for target in fuzz_antenna_patterns fuzz_geographic_calculations fuzz_status_page; do
    echo "Starting $target with 2 cores (rotation)"
    timeout 7200 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier3_standard @@ &
    sleep 2
done

echo "All fuzzing targets started. Monitor with: watch -n 1 'afl-whatsup results/'"
EOF

    # Create sequential execution script
    cat > fuzzing_sequential.sh << 'EOF'
#!/bin/bash
# Sequential Priority Execution Strategy

echo "Starting sequential fuzzing execution..."

# Phase 1: Tier 1 targets (6 hours)
echo "Phase 1: Running Tier 1 targets for 6 hours..."
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    echo "Starting $target with 2 cores for 6 hours"
    timeout 21600 afl-fuzz -i corpus/$target -o results/$target -t 10000 -M $target -- ./targets/tier1_critical @@ &
    sleep 2
done

wait
echo "Tier 1 fuzzing completed"

# Phase 2: Tier 2 targets (6 hours)
echo "Phase 2: Running Tier 2 targets for 6 hours..."
for target in fuzz_audio_processing fuzz_radio_propagation fuzz_frequency_management fuzz_agc_squelch fuzz_database_operations fuzz_error_handling; do
    echo "Starting $target with 1 core for 6 hours"
    timeout 21600 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier2_important @@ &
    sleep 2
done

wait
echo "Tier 2 fuzzing completed"

# Phase 3: Tier 3 targets (2 hours each, rotating)
echo "Phase 3: Running Tier 3 targets for 2 hours each..."
for target in fuzz_antenna_patterns fuzz_geographic_calculations fuzz_status_page fuzz_integration_tests fuzz_performance_tests; do
    echo "Starting $target with 2 cores for 2 hours"
    timeout 7200 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier3_standard @@ &
    sleep 2
done

wait
echo "All fuzzing phases completed"
EOF

    # Create staged execution script
    cat > fuzzing_staged.sh << 'EOF'
#!/bin/bash
# Staged Approach Execution Strategy

echo "Starting staged fuzzing execution..."

# Stage 1: All targets running (Hours 1-3)
echo "Stage 1: Running all targets for 3 hours..."
# Tier 1 (2 cores each)
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    timeout 10800 afl-fuzz -i corpus/$target -o results/$target -t 10000 -M $target -- ./targets/tier1_critical @@ &
done

# Tier 2 (1 core each)
for target in fuzz_audio_processing fuzz_radio_propagation fuzz_frequency_management fuzz_agc_squelch fuzz_database_operations fuzz_error_handling; do
    timeout 10800 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier2_important @@ &
done

# Tier 3 (shared cores)
for target in fuzz_antenna_patterns fuzz_geographic_calculations fuzz_status_page; do
    timeout 10800 afl-fuzz -i corpus/$target -o results/$target -t 10000 -S $target -- ./targets/tier3_standard @@ &
done

wait
echo "Stage 1 completed - analyzing results..."

# Stage 2: Focus on targets with issues (Hours 3-6)
echo "Stage 2: Focusing on targets with issues for 3 hours..."
# This would be determined by analyzing Stage 1 results
# For now, continue with all targets
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    timeout 10800 afl-fuzz -i results/$target -o results/${target}_stage2 -t 10000 -M ${target}_stage2 -- ./targets/tier1_critical @@ &
done

wait
echo "Staged fuzzing completed"
EOF

    chmod +x fuzzing_parallel.sh fuzzing_sequential.sh fuzzing_staged.sh
    print_success "Execution scripts created"
}

# Function to create corpus directories
create_corpus_directories() {
    print_status "Creating corpus directories"
    
    mkdir -p corpus
    mkdir -p results
    
    # Create corpus for each target
    for target in "${!TIER1_TARGETS[@]}" "${!TIER2_TARGETS[@]}" "${!TIER3_TARGETS[@]}"; do
        mkdir -p corpus/$target
        mkdir -p results/$target
        
        # Create sample input files
        echo "sample input for $target" > corpus/$target/sample1.txt
        echo "test data for $target" > corpus/$target/sample2.txt
        echo "fuzzing input for $target" > corpus/$target/sample3.txt
    done
    
    print_success "Corpus directories created"
}

# Function to generate monitoring script
create_monitoring_script() {
    print_status "Creating monitoring script"
    
    cat > monitor_fuzzing.sh << 'EOF'
#!/bin/bash
# Fuzzing monitoring script

echo "=== FUZZING MONITORING DASHBOARD ==="
echo "Timestamp: $(date)"
echo ""

echo "=== TIER 1 TARGETS (Critical) ==="
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        afl-whatsup results/$target 2>/dev/null | head -5
        echo ""
    fi
done

echo "=== TIER 2 TARGETS (Important) ==="
for target in fuzz_audio_processing fuzz_radio_propagation fuzz_frequency_management fuzz_agc_squelch fuzz_database_operations fuzz_error_handling; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        afl-whatsup results/$target 2>/dev/null | head -5
        echo ""
    fi
done

echo "=== TIER 3 TARGETS (Standard) ==="
for target in fuzz_antenna_patterns fuzz_geographic_calculations fuzz_status_page fuzz_integration_tests fuzz_performance_tests; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        afl-whatsup results/$target 2>/dev/null | head -5
        echo ""
    fi
done

echo "=== OVERALL STATISTICS ==="
echo "Total core-hours allocated: $((20 * 6))"
echo "Total targets: 15"
echo "Average core-hours per target: $((120 / 15))"
echo ""
echo "Run 'watch -n 30 ./monitor_fuzzing.sh' for continuous monitoring"
EOF

    chmod +x monitor_fuzzing.sh
    print_success "Monitoring script created"
}

# Main execution
main() {
    print_status "Fuzzing Resource Allocator for 15 Targets with 20 Cores"
    echo "================================================================"
    
    calculate_allocation
    generate_execution_strategies
    create_execution_scripts
    create_corpus_directories
    create_monitoring_script
    
    echo ""
    print_success "Fuzzing strategy setup completed!"
    echo ""
    echo "Available execution strategies:"
    echo "  ./fuzzing_parallel.sh    - Parallel-first approach (recommended)"
    echo "  ./fuzzing_sequential.sh  - Sequential priority approach"
    echo "  ./fuzzing_staged.sh      - Staged approach"
    echo ""
    echo "Monitoring:"
    echo "  ./monitor_fuzzing.sh     - Check fuzzing status"
    echo "  watch -n 30 ./monitor_fuzzing.sh  - Continuous monitoring"
    echo ""
    echo "Expected outcomes:"
    echo "  - Network/Protocol targets: Most likely to find bugs"
    echo "  - Mathematical targets: Coverage saturates quickly"
    echo "  - Total effort: ~100-120 core-hours across 15 targets"
    echo "  - Average: 6-8 core-hours per target"
}

# Run main function
main "$@"
