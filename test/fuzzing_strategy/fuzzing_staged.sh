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
