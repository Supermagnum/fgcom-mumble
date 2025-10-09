# Targeted Mutation Testing Strategy for FGcom-mumble

This document outlines the targeted approach to mutation testing, focusing on one module at a time with specific mutation score thresholds based on criticality.

## 🎯 Target Mutation Scores

Based on the criticality of each module:

| Module | Target Score | Criticality | Rationale |
|--------|-------------|-------------|-----------|
| **Security Module** | **90%+** | 🔒 Safety-critical | Authentication, authorization, and security logic must be thoroughly tested |
| **Radio Propagation** | **85%+** | 📡 Core aviation logic | Frequency calculations and propagation models are critical for aviation safety |
| **AGC/Squelch** | **85%+** | 🎛️ Audio quality critical | Audio processing affects communication quality and safety |
| **Audio Processing** | **80%+** | 🎵 Important but less critical | Audio codecs and processing are important but have fallback mechanisms |
| **Database Config** | **75%+** | 🗄️ Configuration logic | Configuration loading is important but not safety-critical |

## 🚀 Quick Start

### Test a Single Module

```bash
# Test security module (target: 90%+)
./scripts/run_targeted_mutation_testing.sh security

# Test radio propagation (target: 85%+)
./scripts/run_targeted_mutation_testing.sh radio_propagation

# Test AGC/Squelch (target: 85%+)
./scripts/run_targeted_mutation_testing.sh agc_squelch

# Test audio processing (target: 80%+)
./scripts/run_targeted_mutation_testing.sh audio_processing

# Test database config (target: 75%+)
./scripts/run_targeted_mutation_testing.sh database_config
```

### Test All Modules

```bash
# Test all modules sequentially
./scripts/run_targeted_mutation_testing.sh all
```

## 📊 Understanding Results

### Score Interpretation

- **✅ TARGET ACHIEVED**: Score meets or exceeds target
- **⚠️ CLOSE TO TARGET**: Within 10% of target (needs minor improvements)
- **❌ BELOW TARGET**: Significantly below target (needs major improvements)

### Example Output

```
==========================================
Results for security:
==========================================
Total Mutations: 45
Killed: 38
Survived: 7
Timeout: 0
Error: 0
Mutation Score: 84%
Target Score: 90%

❌ BELOW TARGET! Score: 84% (Target: 90%)
   Significant improvement needed in test coverage.
```

## 🔧 Improvement Strategies by Module

### 🔒 Security Module (Target: 90%+)

**Focus Areas:**
- Authentication and authorization logic
- Input validation and sanitization
- Security policy enforcement
- Access control mechanisms

**Test Improvements:**
```cpp
// Add authentication failure tests
TEST(SecurityModule, AuthenticationFailures) {
    EXPECT_THROW(authenticate("invalid_user", "wrong_password"), AuthenticationException);
    EXPECT_THROW(authenticate("", "password"), InvalidInputException);
    EXPECT_THROW(authenticate("user", ""), InvalidInputException);
}

// Test boundary conditions
TEST(SecurityModule, BoundaryConditions) {
    // Test with maximum length inputs
    std::string max_user(1000, 'a');
    EXPECT_THROW(authenticate(max_user, "password"), InputTooLongException);
    
    // Test with special characters
    EXPECT_THROW(authenticate("user<script>", "password"), InvalidCharacterException);
}
```

### 📡 Radio Propagation (Target: 85%+)

**Focus Areas:**
- Frequency calculations
- Distance and altitude calculations
- Atmospheric conditions
- Antenna pattern effects

**Test Improvements:**
```cpp
// Test edge cases in frequency calculations
TEST(RadioPropagation, FrequencyEdgeCases) {
    // Test boundary frequencies
    EXPECT_NO_THROW(calculatePathLoss(118e6, 1000)); // VHF aviation
    EXPECT_THROW(calculatePathLoss(-1e6, 1000), InvalidFrequencyException);
    EXPECT_THROW(calculatePathLoss(0, 1000), InvalidFrequencyException);
    
    // Test extreme distances
    EXPECT_NO_THROW(calculatePathLoss(118e6, 0.1)); // Very close
    EXPECT_NO_THROW(calculatePathLoss(118e6, 1000000)); // Very far
}

// Test atmospheric conditions
TEST(RadioPropagation, AtmosphericConditions) {
    // Test with different weather conditions
    EXPECT_GT(calculateAtmosphericLoss(118e6, 1000, WeatherCondition::HEAVY_RAIN), 
             calculateAtmosphericLoss(118e6, 1000, WeatherCondition::CLEAR));
}
```

### 🎛️ AGC/Squelch (Target: 85%+)

**Focus Areas:**
- Audio level thresholds
- Noise floor calculations
- Squelch open/close logic
- Gain control algorithms

**Test Improvements:**
```cpp
// Test AGC threshold logic
TEST(AGCSquelch, ThresholdLogic) {
    AudioProcessor processor;
    
    // Test below threshold
    std::vector<float> quiet_audio = {0.01f, 0.02f, 0.01f};
    EXPECT_FALSE(processor.shouldOpenSquelch(quiet_audio, -20.0f));
    
    // Test above threshold
    std::vector<float> loud_audio = {0.5f, 0.6f, 0.7f};
    EXPECT_TRUE(processor.shouldOpenSquelch(loud_audio, -20.0f));
}

// Test noise floor calculations
TEST(AGCSquelch, NoiseFloor) {
    AudioProcessor processor;
    
    // Test with known noise floor
    std::vector<float> noise = generateWhiteNoise(1000, -40.0f);
    double calculated_floor = processor.calculateNoiseFloor(noise);
    EXPECT_NEAR(calculated_floor, -40.0, 1.0);
}
```

### 🎵 Audio Processing (Target: 80%+)

**Focus Areas:**
- Audio sample processing
- Codec functionality
- Audio quality metrics
- Filtering algorithms

**Test Improvements:**
```cpp
// Test audio sample processing
TEST(AudioProcessing, SampleProcessing) {
    AudioProcessor processor;
    
    // Test with various sample rates
    std::vector<float> samples_8k = generateTestSamples(8000);
    std::vector<float> samples_48k = generateTestSamples(48000);
    
    EXPECT_NO_THROW(processor.processSamples(samples_8k, 8000));
    EXPECT_NO_THROW(processor.processSamples(samples_48k, 48000));
}

// Test codec functionality
TEST(AudioProcessing, CodecFunctionality) {
    AudioCodec codec;
    
    // Test encode/decode round trip
    std::vector<float> original = generateTestSamples(48000);
    auto encoded = codec.encode(original);
    auto decoded = codec.decode(encoded);
    
    EXPECT_NEAR(calculateSNR(original, decoded), 30.0, 5.0);
}
```

### 🗄️ Database Config (Target: 75%+)

**Focus Areas:**
- Configuration loading/parsing
- Invalid configuration handling
- Configuration validation
- Default value handling

**Test Improvements:**
```cpp
// Test configuration loading
TEST(DatabaseConfig, ConfigurationLoading) {
    ConfigLoader loader;
    
    // Test valid configuration
    EXPECT_NO_THROW(loader.loadConfig("valid_config.json"));
    
    // Test invalid configuration
    EXPECT_THROW(loader.loadConfig("invalid_config.json"), ConfigParseException);
    EXPECT_THROW(loader.loadConfig("nonexistent.json"), FileNotFoundException);
}

// Test configuration validation
TEST(DatabaseConfig, ConfigurationValidation) {
    ConfigValidator validator;
    
    // Test required fields
    Config valid_config = {"database_url": "localhost:5432", "username": "user"};
    EXPECT_TRUE(validator.validate(valid_config));
    
    // Test missing required fields
    Config invalid_config = {"database_url": "localhost:5432"};
    EXPECT_FALSE(validator.validate(invalid_config));
}
```

## 🔄 Iterative Improvement Process

### 1. Start Small
- Test one module at a time
- Focus on the most critical modules first
- Don't try to achieve all targets at once

### 2. Iterate and Fix
- Run mutation testing for a module
- Identify surviving mutations
- Add specific test cases for uncovered logic
- Re-run mutation testing to verify improvements

### 3. Set Thresholds
- Use the target scores as guidelines
- Adjust based on module criticality
- Don't aim for 100% (it's often not practical)

### 4. Document Results
- Keep track of mutation scores over time
- Document test improvements made
- Share insights with the team

## 📈 Tracking Progress

### Weekly Mutation Testing Report

Create a weekly report template:

```markdown
# Mutation Testing Report - Week of [DATE]

## Module Scores
| Module | Current Score | Target Score | Status | Notes |
|--------|---------------|---------------|--------|-------|
| Security | 84% | 90% | ❌ Below | Need more auth failure tests |
| Radio Propagation | 87% | 85% | ✅ Target | Good coverage |
| AGC/Squelch | 82% | 85% | ⚠️ Close | Add noise floor tests |
| Audio Processing | 78% | 80% | ⚠️ Close | Improve codec tests |
| Database Config | 76% | 75% | ✅ Target | Adequate coverage |

## Improvements Made
- Added 15 new test cases for security module
- Improved AGC threshold testing
- Enhanced audio codec validation

## Next Week Goals
- Security module: Add input validation tests
- AGC/Squelch: Add boundary condition tests
- Audio Processing: Improve codec round-trip tests
```

## 🛠️ Troubleshooting

### Common Issues

1. **No mutations generated**
   - Check if module files exist
   - Verify compilation database is correct
   - Ensure tests are running

2. **High timeout rate**
   - Increase timeout in configuration
   - Optimize slow tests
   - Use test doubles for external dependencies

3. **Low mutation score**
   - Add more test cases
   - Improve assertion quality
   - Test edge cases and boundary conditions

### Debug Mode

Enable debug mode for detailed logging:

```bash
# Add debug flag to mull-cxx command
mull-cxx --debug --reporters=IDE ...
```

## 📚 Best Practices

### 1. Focus on Critical Paths
- Prioritize safety-critical modules
- Focus on business logic over utility functions
- Test security-sensitive code thoroughly

### 2. Quality over Quantity
- Better to have fewer, high-quality tests than many low-quality ones
- Use specific assertions instead of generic ones
- Test edge cases and boundary conditions

### 3. Regular Execution
- Run mutation testing weekly
- Track trends over time
- Set up automated runs in CI/CD

### 4. Team Collaboration
- Share mutation testing results with the team
- Discuss improvement strategies
- Learn from each other's test cases

## 🎯 Success Metrics

### Short-term (1-2 weeks)
- Security module: 90%+ mutation score
- Radio propagation: 85%+ mutation score
- At least 2 modules meeting their targets

### Medium-term (1 month)
- All modules meeting their target scores
- Automated mutation testing in CI/CD
- Team trained on mutation testing concepts

### Long-term (3 months)
- Maintained high mutation scores
- Improved overall code quality
- Reduced production bugs
- Faster development cycle due to better test coverage

Remember: The goal is not to achieve 100% mutation scores, but to identify areas where test coverage can be improved to catch real bugs in production.
