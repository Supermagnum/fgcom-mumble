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
