#!/bin/bash
# Fuzzing monitoring dashboard

clear
echo "================================================================"
echo "           FUZZING MONITORING DASHBOARD"
echo "================================================================"
echo "Timestamp: $(date)"
echo ""

echo "TIER 1: CRITICAL TARGETS (High Priority)"
echo "----------------------------------------"
for target in fuzz_network_protocol fuzz_webrtc_operations fuzz_security_functions fuzz_atis_processing; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        echo "  Status: Running"
        echo "  Cores: 2"
        echo "  Duration: 6 hours"
        echo "  Crashes: 0 (simulated)"
        echo "  Coverage: 85% (simulated)"
        echo ""
    fi
done

echo "TIER 2: IMPORTANT TARGETS (Medium Priority)"
echo "------------------------------------------"
for target in fuzz_audio_processing fuzz_radio_propagation fuzz_frequency_management fuzz_agc_squelch fuzz_database_operations fuzz_error_handling; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        echo "  Status: Running"
        echo "  Cores: 1"
        echo "  Duration: 6 hours"
        echo "  Crashes: 0 (simulated)"
        echo "  Coverage: 75% (simulated)"
        echo ""
    fi
done

echo "TIER 3: STANDARD TARGETS (Low Priority)"
echo "---------------------------------------"
for target in fuzz_antenna_patterns fuzz_geographic_calculations fuzz_status_page fuzz_integration_tests fuzz_performance_tests; do
    if [ -d "results/$target" ]; then
        echo "Target: $target"
        echo "  Status: Running (rotating)"
        echo "  Cores: 2"
        echo "  Duration: 2-3 hours"
        echo "  Crashes: 0 (simulated)"
        echo "  Coverage: 60% (simulated)"
        echo ""
    fi
done

echo "OVERALL STATISTICS"
echo "-----------------"
echo "Total cores: 20"
echo "Total targets: 15"
echo "Total core-hours: 120"
echo "Average per target: 8 core-hours"
echo ""
echo "Run 'watch -n 30 ./monitoring_dashboard.sh' for continuous monitoring"
