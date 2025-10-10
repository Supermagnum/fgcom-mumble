# FGCom-Mumble Fuzzing Scripts

This directory contains organized fuzzing scripts for the FGCom-mumble project, split by priority tiers for better resource management and cleaner execution.

## Scripts Overview

### Individual Tier Scripts

1. **`fuzz_tier1_critical.sh`** - Critical targets (High Risk)
   - **Targets**: 4 (network_protocol, webrtc_operations, security_functions, atis_processing)
   - **Resources**: 2 cores each, 6 hours duration
   - **Total cores**: 8
   - **Focus**: Network-facing, attack surface, security-critical

2. **`fuzz_tier2_important.sh`** - Important targets (Medium Risk)
   - **Targets**: 6 (audio_processing, radio_propagation, frequency_management, agc_squelch, database_operations, error_handling)
   - **Resources**: 1 core each, 6 hours duration
   - **Total cores**: 6
   - **Focus**: Core functionality, audio pipeline, data corruption risk

3. **`fuzz_tier3_standard.sh`** - Standard targets (Lower Risk)
   - **Targets**: 5 (antenna_patterns, geographic_calculations, status_page, integration_tests, performance_tests)
   - **Resources**: Shared cores, 2 hours each (rotating)
   - **Total cores**: 6
   - **Focus**: Mathematical calculations, display logic

### Original Script

4. **`run_fuzzing.sh`** - Comprehensive script (All 15 targets)
   - **Targets**: All 15 targets from your original specification
   - **Resources**: 20 cores total, 6 hours duration
   - **Note**: This is the original script that runs everything at once

## Usage

### Run Individual Tiers

```bash
# Run only critical targets (Tier 1)
./scripts/fuzzing/fuzz_tier1_critical.sh

# Run only important targets (Tier 2)  
./scripts/fuzzing/fuzz_tier2_important.sh

# Run only standard targets (Tier 3)
./scripts/fuzzing/fuzz_tier3_standard.sh
```

### Run All Targets (Original Approach)

```bash
# Run all 15 targets simultaneously
./scripts/fuzzing/run_fuzzing.sh
```

### Sequential Execution

```bash
# Run tiers sequentially (recommended for resource management)
./scripts/fuzzing/fuzz_tier1_critical.sh
./scripts/fuzzing/fuzz_tier2_important.sh  
./scripts/fuzzing/fuzz_tier3_standard.sh
```

## Resource Allocation

| Tier | Targets | Cores | Duration | Total Core-Hours |
|------|---------|-------|----------|------------------|
| Tier 1 | 4 | 8 (2 each) | 6 hours | 48 |
| Tier 2 | 6 | 6 (1 each) | 6 hours | 36 |
| Tier 3 | 5 | 6 (shared) | 2 hours each | 12 |
| **Total** | **15** | **20** | **6 hours** | **96** |

## Monitoring

Each script provides:
- Real-time progress updates
- Comprehensive summary reports
- Crash and hang detection
- Automatic cleanup on exit

Monitor progress with:
```bash
watch -n 30 'afl-whatsup results/'
```

## Prerequisites

- AFL++ installed and in PATH
- Fuzzing target binaries built in `./test/fuzzing_strategy/build/`
- Sufficient disk space for results and corpus

## Expected Outcomes

- **Tier 1**: Highest bug discovery rate (network/protocol targets)
- **Tier 2**: Medium bug discovery rate (core functionality)
- **Tier 3**: Lower bug discovery rate (mathematical/stable targets)

## Cleanup

All scripts include automatic cleanup that will:
- Kill running fuzzing processes on exit
- Remove temporary PID files
- Generate final summary reports

