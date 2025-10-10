# Fuzzing Strategy for 15 Targets with 20 Cores

## Overview

This document outlines the comprehensive fuzzing strategy for the FGCom-mumble project, designed to maximize bug discovery while efficiently utilizing available resources (20 cores over 6 hours).

## Resource Allocation Challenge

- **15 fuzzing targets** across different risk levels
- **20 cores** available for parallel execution
- **6 hours** total execution time
- **~120 core-hours** total capacity

## Priority-Based Allocation Strategy

### Tier 1: Critical (High Risk) - 8 cores total
**Allocation:** 2 cores each, 6 hours duration

| Target | Cores | Duration | Risk Level | Focus Area |
|--------|-------|----------|------------|------------|
| `fuzz_network_protocol` | 2 | 6h | High | Network-facing, attack surface |
| `fuzz_webrtc_operations` | 2 | 6h | High | External interface, complexity |
| `fuzz_security_functions` | 2 | 6h | High | Security-critical |
| `fuzz_atis_processing` | 2 | 6h | High | Parsing external data |

### Tier 2: Important (Medium Risk) - 6 cores total
**Allocation:** 1 core each, 6 hours duration

| Target | Cores | Duration | Risk Level | Focus Area |
|--------|-------|----------|------------|------------|
| `fuzz_audio_processing` | 1 | 6h | Medium | Crashes affect functionality |
| `fuzz_radio_propagation` | 1 | 6h | Medium | Core functionality |
| `fuzz_frequency_management` | 1 | 6h | Medium | Configuration bugs |
| `fuzz_agc_squelch` | 1 | 6h | Medium | Audio pipeline critical |
| `fuzz_database_operations` | 1 | 6h | Medium | Data corruption risk |
| `fuzz_error_handling` | 1 | 6h | Medium | Safety net testing |

### Tier 3: Standard (Lower Risk) - 6 cores total
**Allocation:** Shared cores, rotating schedule (2-3 hours each)

| Target | Cores | Duration | Risk Level | Focus Area |
|--------|-------|----------|------------|------------|
| `fuzz_antenna_patterns` | 2 | 2h | Low | Mathematical, stable |
| `fuzz_geographic_calculations` | 2 | 2h | Low | Mathematical, stable |
| `fuzz_status_page` | 2 | 2h | Low | Display only, low risk |
| `fuzz_integration_tests` | 2 | 2h | Low | Already covered by other tests |
| `fuzz_performance_tests` | 2 | 2h | Low | Not crash-focused |

## Execution Strategies

### Option 1: Parallel-First (Recommended)
- **Approach:** Run all Tier 1+2 targets simultaneously (14 cores)
- **Remaining cores:** 6 cores for rotating Tier 3 targets
- **Tier 3 rotation:** Each target gets ~1.2 hours of fuzzing time
- **Benefits:** Maximum parallelization, comprehensive coverage

### Option 2: Sequential Priority
- **Phase 1:** Run Tier 1 for full 6 hours (8 cores)
- **Phase 2:** Run Tier 2 for full 6 hours (6 cores)
- **Phase 3:** Run Tier 3 targets for 2 hours each (6 cores rotating)
- **Benefits:** Focused attention on high-priority targets

### Option 3: Staged Approach
- **Hours 1-3:** All 15 targets running (some shared cores)
- **Hours 3-6:** Focus on targets that found issues or show low coverage
- **Benefits:** Adaptive based on early results

## Expected Outcomes by Target Type

### Network/Protocol Targets (Highest Value)
- **Most likely to find bugs** (parsing, state machines, attack surfaces)
- **Highest value fuzzing time**
- **Watch these closely** for crashes and hangs

### Mathematical Targets (Lower Priority)
- **Less likely to crash** (deterministic calculations)
- **Coverage saturates quickly**
- **Lower priority allocation appropriate**

### Integration/Performance Targets (Questionable Value)
- **May be redundant** with unit fuzzing
- **Consider whether these need fuzzing at all**
- **Might be better as property-based tests**

## Honest Assessment

### Questionable Value Targets
Some targets may not need fuzzing:

| Target | Issue | Recommendation |
|--------|-------|----------------|
| `fuzz_integration_tests` | Integration tests aren't typically fuzzed | Convert to regular integration tests |
| `fuzz_performance_tests` | Performance is measured, not fuzzed | Remove or convert to benchmarks |
| `fuzz_status_page` | Display logic, low complexity | Remove or convert to unit tests |

### Cleaner Target List
Removing questionable targets would leave **12 meaningful fuzzing targets**:
- **Tier 1:** 4 targets (8 cores)
- **Tier 2:** 6 targets (6 cores)  
- **Tier 3:** 2 targets (6 cores)

This makes resource allocation much cleaner and more focused.

## Resource Math

- **Total core-hours:** 120 (20 cores × 6 hours)
- **Average per target:** 8 core-hours
- **High-priority targets:** 12-24 core-hours each
- **Low-priority targets:** 4-6 core-hours each

## Implementation

### Directory Structure
```
test/fuzzing_strategy/
├── targets/
│   ├── tier1_critical.cpp      # Tier 1 targets
│   ├── tier2_important.cpp     # Tier 2 targets
│   └── tier3_standard.cpp      # Tier 3 targets
├── scripts/
│   └── fuzzing_resource_allocator.sh
├── configs/
├── results/
└── CMakeLists.txt
```

### Execution Commands
```bash
# Setup
./scripts/fuzzing_resource_allocator.sh

# Execution strategies
./fuzzing_parallel.sh      # Parallel-first (recommended)
./fuzzing_sequential.sh    # Sequential priority
./fuzzing_staged.sh        # Staged approach

# Monitoring
./monitor_fuzzing.sh       # Check status
watch -n 30 ./monitor_fuzzing.sh  # Continuous monitoring
```

### Build Commands
```bash
# Build fuzzing targets
cmake -B build -S .
cmake --build build --target build_fuzzing_targets

# Run specific tiers
cmake --build build --target run_tier1_fuzzing
cmake --build build --target run_tier2_fuzzing
cmake --build build --target run_tier3_fuzzing

# Run all fuzzing
cmake --build build --target run_all_fuzzing
```

## Monitoring and Results

### Key Metrics to Track
- **Coverage achieved** per target
- **Crashes found** per target
- **Corpus final size** per target
- **Execution time** per target
- **Core utilization** efficiency

### Expected Results
- **Network/Protocol targets:** Most bugs found
- **Security targets:** High-value vulnerabilities
- **Mathematical targets:** Quick coverage saturation
- **Integration targets:** Likely redundant

## Conclusion

This strategy provides:
- **Comprehensive coverage** of all 15 targets
- **Efficient resource utilization** (120 core-hours)
- **Priority-based allocation** focusing on high-risk areas
- **Flexible execution options** for different scenarios
- **Clear monitoring and results tracking**

The parallel-first approach is recommended for maximum efficiency, with the option to focus on targets showing issues or low coverage in later stages.
