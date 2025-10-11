# Corpus Improvement Guide for FGCom-Mumble Fuzzing

## Overview

This guide provides comprehensive instructions for creating and maintaining high-quality fuzzing corpus files for the FGCom-Mumble project. A good corpus is essential for effective fuzzing as it provides the foundation for mutation-based fuzzing tools like AFL++.

## What Makes a Good Corpus

### 1. **Quality Over Quantity**
- Start with 10-100 high-quality seeds rather than thousands of redundant ones
- Each file should exercise different code paths
- Focus on realistic, valid inputs that represent real-world usage

### 2. **Diverse Input Types**
- **Valid inputs**: Normal, expected data that should work correctly
- **Edge cases**: Boundary conditions, minimum/maximum values, empty inputs
- **Malformed inputs**: Almost-valid data that tests error handling
- **Different formats**: JSON, binary, text, protocol-specific formats

### 3. **Code Path Coverage**
- **Minimal valid inputs**: Smallest possible valid file
- **Maximum complexity**: Deeply nested structures, large sizes
- **Boundary conditions**: Empty, single element, maximum values
- **Feature combinations**: Different options and configurations

## Current Corpus Structure

The FGCom-Mumble project has 15 fuzzing targets organized by priority:

### **Tier 1 - Critical (High Risk)**
- `fuzz_network_protocol` - Network packet processing
- `fuzz_webrtc_operations` - WebRTC connection handling
- `fuzz_security_functions` - Security-critical operations
- `fuzz_atis_processing` - ATIS message processing

### **Tier 2 - Important (Medium Risk)**
- `fuzz_audio_processing` - Audio pipeline processing
- `fuzz_radio_propagation` - Radio signal propagation
- `fuzz_frequency_management` - Frequency allocation
- `fuzz_agc_squelch` - Automatic gain control
- `fuzz_database_operations` - Database operations
- `fuzz_error_handling` - Error handling paths

### **Tier 3 - Standard (Lower Risk)**
- `fuzz_antenna_patterns` - Antenna pattern calculations
- `fuzz_geographic_calculations` - Geographic computations
- `fuzz_status_page` - Status page generation
- `fuzz_integration_tests` - Integration testing
- `fuzz_performance_tests` - Performance testing

## Corpus File Examples

### Radio Propagation Corpus
```json
{
  "frequency": 121.5,
  "power": 25.0,
  "antenna_height": 100.0,
  "distance": 50.0,
  "terrain": "flat",
  "weather": "clear"
}
```

### Audio Processing Corpus
```json
{
  "sample_rate": 48000,
  "channels": 1,
  "bit_depth": 16,
  "format": "PCM",
  "duration": 1.0,
  "gain": 1.0,
  "noise_gate": -60.0,
  "compression": {
    "threshold": -20.0,
    "ratio": 4.0,
    "attack": 0.01,
    "release": 0.1
  }
}
```

### Network Protocol Corpus
```json
{
  "protocol": "UDP",
  "port": 64738,
  "packet_type": "audio",
  "sequence": 1,
  "timestamp": 1640995200,
  "payload": "SGVsbG8gV29ybGQ=",
  "checksum": "a1b2c3d4",
  "compression": false,
  "encryption": false
}
```

## Corpus Improvement Workflow

### 1. **Gather Real-World Inputs**
```bash
# Collect valid examples from production systems
# Include edge cases from testing
# Use public datasets when available
```

### 2. **Create Diverse Samples**
- **Valid inputs**: Normal operation scenarios
- **Edge cases**: Boundary conditions, empty inputs
- **Malformed inputs**: Invalid but parseable data
- **Binary formats**: Raw protocol data, audio files

### 3. **Use Corpus Tools**
```bash
# Validate corpus quality
./scripts/fuzzing/validate_corpus.sh

# Minimize corpus to remove redundancy
./scripts/fuzzing/minimize_corpus.sh

# Run fuzzing to test corpus effectiveness
./scripts/fuzzing/run_fuzzing.sh
```

## Format-Specific Guidelines

### **JSON Formats**
- Include files with different structural variations
- Valid files with different optional fields
- Files that exercise error handling (almost-valid inputs)
- Empty objects, arrays, and null values

### **Binary Formats**
- Valid files with different header types
- Chunk variations and compression methods
- Different encoding schemes
- Protocol-specific binary structures

### **Text/Protocol Formats**
- Varying lengths and special characters
- Unicode and different encodings
- Protocol-specific text formats
- Malformed but parseable text

## Corpus Maintenance

### **Regular Updates**
- Add new corpus files when discovering new code paths
- Remove redundant files that don't improve coverage
- Update corpus when adding new features

### **Quality Assurance**
- Validate corpus files with target binaries
- Check for crashes caused by corpus files
- Ensure good coverage across all targets

### **Monitoring**
- Track corpus effectiveness during fuzzing
- Monitor coverage improvements
- Identify gaps in corpus coverage

## Best Practices

### **1. Start Small but Diverse**
- Begin with 10-100 high-quality seeds
- Each file should exercise different code paths
- Quality over quantity - the fuzzer will generate variations

### **2. Include Edge Cases**
- Empty inputs and null values
- Minimum and maximum values
- Boundary conditions
- Invalid but parseable data

### **3. Use Real-World Data**
- Collect from production systems
- Include test suite examples
- Use public datasets when available
- Include edge cases from testing

### **4. Regular Maintenance**
- Update corpus when adding features
- Remove redundant files
- Validate corpus quality regularly
- Monitor fuzzing effectiveness

## Tools and Scripts

### **Corpus Validation**
```bash
./scripts/fuzzing/validate_corpus.sh
```
- Tests corpus files with target binaries
- Identifies crashes and invalid files
- Analyzes corpus diversity and coverage

### **Corpus Minimization**
```bash
./scripts/fuzzing/minimize_corpus.sh
```
- Removes redundant files
- Optimizes corpus for maximum coverage
- Reduces corpus size while maintaining effectiveness

### **Fuzzing Execution**
```bash
# Run all targets
./scripts/fuzzing/run_fuzzing.sh

# Run specific tiers
./scripts/fuzzing/fuzz_tier1_critical.sh
./scripts/fuzzing/fuzz_tier2_important.sh
./scripts/fuzzing/fuzz_tier3_standard.sh
```

## Expected Outcomes

### **Improved Coverage**
- Better code path coverage
- More effective fuzzing
- Faster bug discovery

### **Reduced Redundancy**
- Smaller, more efficient corpus
- Faster fuzzing startup
- Better resource utilization

### **Higher Quality**
- More realistic test data
- Better edge case coverage
- Improved fuzzing effectiveness

## Monitoring and Metrics

### **Coverage Metrics**
- Code coverage percentage
- Branch coverage
- Function coverage

### **Fuzzing Metrics**
- Crashes found per hour
- Hangs discovered
- Coverage improvements

### **Corpus Metrics**
- Corpus size and diversity
- File type distribution
- Size distribution

## Troubleshooting

### **Common Issues**
- **Corpus too large**: Use minimization tools
- **Poor coverage**: Add more diverse samples
- **Crashes in corpus**: Remove problematic files
- **Slow fuzzing**: Optimize corpus size

### **Debugging**
- Check corpus validation results
- Monitor fuzzing progress
- Analyze coverage reports
- Review crash reports

## Conclusion

A well-maintained corpus is essential for effective fuzzing. By following this guide, you can create and maintain a high-quality corpus that maximizes fuzzing effectiveness while minimizing resource usage. Regular maintenance and monitoring ensure continued improvement in fuzzing results.

Remember: **Quality over quantity** - a small, diverse corpus is more effective than a large, redundant one. The fuzzer will generate variations, so focus on providing good starting points that exercise different code paths.
