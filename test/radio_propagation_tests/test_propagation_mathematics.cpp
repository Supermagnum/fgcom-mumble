#include "test_radio_propagation_main.cpp"
#include <cmath>
#include <vector>
#include <algorithm>

// Test class for mathematical model validation
class PropagationMathematicsTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Test parameters from documentation examples
        test_distance_km = 10.0;
        test_frequency_mhz = 150.0;
        test_height1_m = 10.0;
        test_height2_m = 50.0;
        test_power_dbm = 40.0; // 10W
        test_antenna_gain_dbi = 3.0;
        test_noise_floor_dbm = -100.0;
    }
    
    double test_distance_km;
    double test_frequency_mhz;
    double test_height1_m;
    double test_height2_m;
    double test_power_dbm;
    double test_antenna_gain_dbi;
    double test_noise_floor_dbm;
    
    // Mathematical model implementations from documentation
    double calculateFreeSpaceLoss(double distance_km, double frequency_mhz) {
        return 20.0 * std::log10(distance_km) + 20.0 * std::log10(frequency_mhz) + 32.45;
    }
    
    double calculateLineOfSight(double height1_m, double height2_m) {
        return 3.57 * std::sqrt(height1_m + height2_m);
    }
    
    double calculateFresnelRadius(double d1_km, double d2_km, double frequency_mhz, double total_distance_km) {
        return 17.3 * std::sqrt((d1_km * d2_km) / (frequency_mhz * total_distance_km));
    }
    
    double calculateGroundReflection(double angle_rad, double permittivity) {
        double sin_theta = std::sin(angle_rad);
        double cos_theta = std::cos(angle_rad);
        double sqrt_term = std::sqrt(permittivity - cos_theta * cos_theta);
        return (sin_theta - sqrt_term) / (sin_theta + sqrt_term);
    }
    
    double calculateAtmosphericRefraction(double dn_dh) {
        return 1.0 / (1.0 + dn_dh * 1e-6);
    }
    
    double calculateRainAttenuation(double rain_rate, double frequency_mhz) {
        // Simplified rain attenuation model
        double a = 0.0001; // Frequency-dependent coefficient
        double b = 1.0;     // Frequency-dependent coefficient
        return a * std::pow(rain_rate, b);
    }
    
    double calculateKnifeEdgeDiffraction(double v) {
        return 6.9 + 20.0 * std::log10(std::sqrt(std::pow(v - 0.1, 2) + 1) + v - 0.1);
    }
    
    double calculateAntennaGain(double effective_aperture_m2, double wavelength_m) {
        return 10.0 * std::log10(4.0 * M_PI * effective_aperture_m2 / (wavelength_m * wavelength_m));
    }
    
    double calculateSNR(double tx_power_dbm, double tx_gain_dbi, double rx_gain_dbi, 
                       double path_loss_db, double other_losses_db, double noise_floor_dbm) {
        return tx_power_dbm + tx_gain_dbi + rx_gain_dbi - path_loss_db - other_losses_db - noise_floor_dbm;
    }
    
    double calculateDopplerShift(double velocity_ms, double frequency_hz, double angle_rad) {
        const double speed_of_light = 299792458.0; // m/s
        return (velocity_ms * frequency_hz * std::cos(angle_rad)) / speed_of_light;
    }
    
    double calculateThermalNoiseFloor(double temperature_k, double bandwidth_hz) {
        const double boltzmann_constant = 1.38e-23; // J/K
        double noise_power_w = boltzmann_constant * temperature_k * bandwidth_hz;
        return 10.0 * std::log10(noise_power_w * 1000.0); // Convert to dBm
    }
    
    double calculateMUF(double foF2, double angle_rad) {
        return foF2 / std::cos(angle_rad);
    }
    
    double calculateERP(double tx_power_dbm, double antenna_gain_dbi, double cable_loss_db, double connector_loss_db) {
        return tx_power_dbm + antenna_gain_dbi - cable_loss_db - connector_loss_db;
    }
};

// Test 1: Free Space Path Loss
TEST_F(PropagationMathematicsTest, FreeSpacePathLoss) {
    // Test with documented example: 150 MHz, 10 km
    double expected_loss = 20.0 * std::log10(10.0) + 20.0 * std::log10(150.0) + 32.45;
    double calculated_loss = calculateFreeSpaceLoss(10.0, 150.0);
    
    EXPECT_NEAR(calculated_loss, expected_loss, 0.01) << "Free space loss should match documented formula";
    EXPECT_NEAR(calculated_loss, 95.97, 0.1) << "Should match documented example result";
    
    // Test with different parameters
    double loss_5km_100mhz = calculateFreeSpaceLoss(5.0, 100.0);
    double loss_20km_200mhz = calculateFreeSpaceLoss(20.0, 200.0);
    
    EXPECT_GT(loss_20km_200mhz, loss_5km_100mhz) << "Longer distance and higher frequency should have more loss";
}

// Test 2: Line of Sight Distance
TEST_F(PropagationMathematicsTest, LineOfSightDistance) {
    // Test with documented example: 10m and 50m heights
    double expected_los = 3.57 * std::sqrt(10.0 + 50.0);
    double calculated_los = calculateLineOfSight(10.0, 50.0);
    
    EXPECT_NEAR(calculated_los, expected_los, 0.01) << "Line of sight should match documented formula";
    EXPECT_NEAR(calculated_los, 27.65, 0.1) << "Should match documented example result";
    
    // Test with different heights
    double los_5m_15m = calculateLineOfSight(5.0, 15.0);
    double los_20m_80m = calculateLineOfSight(20.0, 80.0);
    
    EXPECT_GT(los_20m_80m, los_5m_15m) << "Higher antennas should have longer line of sight";
}

// Test 3: Fresnel Zone Calculation
TEST_F(PropagationMathematicsTest, FresnelZoneCalculation) {
    // Test with documented example: 150 MHz, obstacle at 5 km, total 20 km
    double d1_km = 5.0;
    double d2_km = 15.0;
    double frequency_mhz = 150.0;
    double total_distance_km = 20.0;
    
    double expected_radius = 17.3 * std::sqrt((5.0 * 15.0) / (150.0 * 20.0));
    double calculated_radius = calculateFresnelRadius(d1_km, d2_km, frequency_mhz, total_distance_km);
    
    EXPECT_NEAR(calculated_radius, expected_radius, 0.01) << "Fresnel radius should match documented formula";
    EXPECT_NEAR(calculated_radius, 2.73, 0.1) << "Should match documented example result";
}

// Test 4: Ground Reflection
TEST_F(PropagationMathematicsTest, GroundReflection) {
    // Test with documented example: wet ground (ε=25) at 30° angle
    double angle_rad = 30.0 * M_PI / 180.0;
    double permittivity = 25.0;
    
    double expected_reflection = calculateGroundReflection(angle_rad, permittivity);
    
    EXPECT_NEAR(expected_reflection, -0.815, 0.1) << "Should match documented example result";
    EXPECT_LT(expected_reflection, 0.0) << "Reflection coefficient should be negative for wet ground";
}

// Test 5: Atmospheric Refraction
TEST_F(PropagationMathematicsTest, AtmosphericRefraction) {
    // Test with documented example: standard atmosphere (dn/dh = -40 N-units/km)
    double dn_dh = -40.0;
    double expected_k = 1.0 / (1.0 + (-40.0) * 1e-6);
    double calculated_k = calculateAtmosphericRefraction(dn_dh);
    
    EXPECT_NEAR(calculated_k, expected_k, 0.00001) << "Should match documented formula";
    EXPECT_NEAR(calculated_k, 1.00004, 0.00001) << "Should match documented example result";
}

// Test 6: Rain Attenuation
TEST_F(PropagationMathematicsTest, RainAttenuation) {
    // Test with documented example: 10 GHz, 10 mm/h rain
    double rain_rate = 10.0; // mm/h
    double frequency_mhz = 10000.0; // 10 GHz
    
    double attenuation = calculateRainAttenuation(rain_rate, frequency_mhz);
    
    EXPECT_GT(attenuation, 0.0) << "Rain attenuation should be positive";
    EXPECT_LT(attenuation, 1.0) << "Rain attenuation should be reasonable";
}

// Test 7: Knife-Edge Diffraction
TEST_F(PropagationMathematicsTest, KnifeEdgeDiffraction) {
    // Test with documented example: v = 2.0
    double v = 2.0;
    double expected_loss = 6.9 + 20.0 * std::log10(std::sqrt(std::pow(2.0 - 0.1, 2) + 1) + 2.0 - 0.1);
    double calculated_loss = calculateKnifeEdgeDiffraction(v);
    
    EXPECT_NEAR(calculated_loss, expected_loss, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_loss, 19.04, 0.1) << "Should match documented example result";
}

// Test 8: Antenna Gain
TEST_F(PropagationMathematicsTest, AntennaGain) {
    // Test with documented example: 1 m² aperture at 150 MHz
    double effective_aperture_m2 = 1.0;
    double frequency_mhz = 150.0;
    double wavelength_m = 300.0 / frequency_mhz; // 2 m
    
    double expected_gain = 10.0 * std::log10(4.0 * M_PI * 1.0 / (2.0 * 2.0));
    double calculated_gain = calculateAntennaGain(effective_aperture_m2, wavelength_m);
    
    EXPECT_NEAR(calculated_gain, expected_gain, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_gain, 4.97, 0.1) << "Should match documented example result";
}

// Test 9: Signal-to-Noise Ratio
TEST_F(PropagationMathematicsTest, SignalToNoiseRatio) {
    // Test with documented example: 10W (40 dBm), 3 dBi antennas, 10 km, 150 MHz
    double tx_power_dbm = 40.0;
    double tx_gain_dbi = 3.0;
    double rx_gain_dbi = 3.0;
    double path_loss_db = calculateFreeSpaceLoss(10.0, 150.0);
    double other_losses_db = 5.0;
    double noise_floor_dbm = -100.0;
    
    double expected_snr = 40.0 + 3.0 + 3.0 - path_loss_db - 5.0 - (-100.0);
    double calculated_snr = calculateSNR(tx_power_dbm, tx_gain_dbi, rx_gain_dbi, 
                                       path_loss_db, other_losses_db, noise_floor_dbm);
    
    EXPECT_NEAR(calculated_snr, expected_snr, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_snr, 45.03, 0.1) << "Should match documented example result";
}

// Test 10: Doppler Shift
TEST_F(PropagationMathematicsTest, DopplerShift) {
    // Test with documented example: 100 km/h (27.8 m/s), 150 MHz, 45° angle
    double velocity_ms = 27.8;
    double frequency_hz = 150e6;
    double angle_rad = 45.0 * M_PI / 180.0;
    
    double expected_shift = (27.8 * 150e6 * std::cos(45.0 * M_PI / 180.0)) / 299792458.0;
    double calculated_shift = calculateDopplerShift(velocity_ms, frequency_hz, angle_rad);
    
    EXPECT_NEAR(calculated_shift, expected_shift, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_shift, 9.83, 0.1) << "Should match documented example result";
}

// Test 11: Thermal Noise Floor
TEST_F(PropagationMathematicsTest, ThermalNoiseFloor) {
    // Test with documented example: room temperature (290K), 25 kHz bandwidth
    double temperature_k = 290.0;
    double bandwidth_hz = 25000.0;
    
    double expected_noise = 10.0 * std::log10(1.38e-23 * 290.0 * 25000.0 * 1000.0);
    double calculated_noise = calculateThermalNoiseFloor(temperature_k, bandwidth_hz);
    
    EXPECT_NEAR(calculated_noise, expected_noise, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_noise, -129.996, 0.1) << "Should match documented example result";
}

// Test 12: Maximum Usable Frequency (MUF)
TEST_F(PropagationMathematicsTest, MaximumUsableFrequency) {
    // Test MUF calculation
    double foF2 = 8.0; // MHz
    double angle_rad = 30.0 * M_PI / 180.0;
    
    double expected_muf = 8.0 / std::cos(30.0 * M_PI / 180.0);
    double calculated_muf = calculateMUF(foF2, angle_rad);
    
    EXPECT_NEAR(calculated_muf, expected_muf, 0.01) << "Should match documented formula";
    EXPECT_GT(calculated_muf, foF2) << "MUF should be greater than foF2";
}

// Test 13: Effective Radiated Power (ERP)
TEST_F(PropagationMathematicsTest, EffectiveRadiatedPower) {
    // Test with documented example: 50W (47 dBm), 6 dBi, 2 dB cable, 0.5 dB connector
    double tx_power_dbm = 47.0;
    double antenna_gain_dbi = 6.0;
    double cable_loss_db = 2.0;
    double connector_loss_db = 0.5;
    
    double expected_erp = 47.0 + 6.0 - 2.0 - 0.5;
    double calculated_erp = calculateERP(tx_power_dbm, antenna_gain_dbi, cable_loss_db, connector_loss_db);
    
    EXPECT_NEAR(calculated_erp, expected_erp, 0.01) << "Should match documented formula";
    EXPECT_NEAR(calculated_erp, 50.5, 0.1) << "Should match documented example result";
}

// Test 14: Mathematical Model Consistency
TEST_F(PropagationMathematicsTest, MathematicalModelConsistency) {
    // Test that all models produce reasonable results
    std::vector<double> distances = {1.0, 5.0, 10.0, 50.0, 100.0};
    std::vector<double> frequencies = {14.0, 118.0, 150.0, 300.0, 1000.0};
    
    for (double distance : distances) {
        for (double frequency : frequencies) {
            double fsl = calculateFreeSpaceLoss(distance, frequency);
            EXPECT_GT(fsl, 0.0) << "Free space loss should be positive";
            EXPECT_LT(fsl, 300.0) << "Free space loss should be reasonable";
            
            // Test that higher frequencies have more loss
            if (frequency > 100.0) {
                double fsl_low = calculateFreeSpaceLoss(distance, 100.0);
                EXPECT_GT(fsl, fsl_low) << "Higher frequency should have more loss";
            }
        }
    }
}

// Test 15: Edge Cases and Boundary Conditions
TEST_F(PropagationMathematicsTest, EdgeCasesAndBoundaryConditions) {
    // Test with very small distances
    double fsl_1m = calculateFreeSpaceLoss(0.001, 150.0);
    EXPECT_GT(fsl_1m, 0.0) << "Free space loss should be positive even for very small distances";
    
    // Test with very high frequencies
    double fsl_10ghz = calculateFreeSpaceLoss(10.0, 10000.0);
    EXPECT_GT(fsl_10ghz, 0.0) << "Free space loss should be positive for high frequencies";
    
    // Test line of sight with very low antennas
    double los_low = calculateLineOfSight(1.0, 2.0);
    EXPECT_GT(los_low, 0.0) << "Line of sight should be positive even for low antennas";
    
    // Test Fresnel zone with very short distances
    double fresnel_short = calculateFresnelRadius(0.1, 0.1, 150.0, 0.2);
    EXPECT_GT(fresnel_short, 0.0) << "Fresnel radius should be positive";
}
