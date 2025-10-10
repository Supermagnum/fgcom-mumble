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
