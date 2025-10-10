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
