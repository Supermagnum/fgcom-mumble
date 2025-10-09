# Mull Mutation Testing Setup for FGcom-mumble

This guide provides comprehensive setup instructions for Mull mutation testing in the FGcom-mumble project.

## Overview

Mull is a mutation testing tool that helps evaluate the quality of test suites by introducing small changes (mutations) to the code and checking if tests catch these changes. A high mutation score indicates good test coverage.

## Quick Setup (Ubuntu/Debian)

### 1. Install Mull

```bash
# Download and install Mull 0.20.0
wget https://github.com/mull-project/mull/releases/download/v0.20.0/mull-0.20.0-ubuntu-20.04.deb
sudo dpkg -i mull-0.20.0-ubuntu-20.04.deb

# Fix any dependency issues
sudo apt-get install -f
```

### 2. Copy Configuration Files

The following files should be in your project:

- `mull.yml` → project root (✅ Already created)
- `docs/MULL_SETUP.md` → docs/ (✅ This file)
- `scripts/run_mull_tests.sh` → scripts/ (make executable)

```bash
# Make the script executable
chmod +x scripts/run_mull_tests.sh
```

### 3. Generate Compilation Database

```bash
# Navigate to your build directory
cd client/mumble-plugin
# or create a build directory if using CMake
mkdir -p build && cd build

# Generate compilation database
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
make

# Copy compile_commands.json to the expected location
cp compile_commands.json ../compile_commands.json
```

### 4. Run Mutation Tests

```bash
# From project root
./scripts/run_mull_tests.sh
```

## Detailed Configuration

### Mull Configuration (`mull.yml`)

The configuration includes:

- **Comprehensive mutators**: Arithmetic, logical, comparison, and assignment operators
- **Smart filtering**: Only mutates code covered by tests
- **Multiple output formats**: HTML, JSON, SQLite for different analysis needs
- **Performance optimization**: 6 parallel workers, 5-second timeout per test
- **Project-specific exclusions**: Excludes test files, third-party code, build artifacts

### Key Features

1. **Coverage-based mutation**: Only mutates code that has test coverage
2. **Comprehensive mutator set**: 20+ different mutation types
3. **Multiple reporters**: IDE, HTML, JSON, SQLite output formats
4. **Performance optimized**: Parallel execution with configurable workers
5. **CI/CD ready**: Includes GitHub Actions workflow
6. **Smart exclusions**: Automatically excludes slow/problematic test modules

## Understanding Results

### Mutation Score Interpretation

- **90%+**: Excellent test coverage - tests catch almost all mutations
- **80-89%**: Good test coverage - most mutations are caught
- **70-79%**: Adequate test coverage - room for improvement
- **<70%**: Poor test coverage - significant gaps in testing

### Mutation Types

- **KILLED**: Test suite caught the mutation (good)
- **SURVIVED**: Test suite didn't catch the mutation (needs improvement)
- **TIMEOUT**: Mutation caused test timeout
- **ERROR**: Mutation caused compilation or runtime error

## Improving Mutation Score

### 1. Add More Test Cases

```cpp
// Example: Test edge cases for radio frequency calculations
TEST(RadioModel, FrequencyValidation) {
    // Test boundary conditions
    EXPECT_THROW(validateFrequency(-1.0), std::invalid_argument);
    EXPECT_THROW(validateFrequency(0.0), std::invalid_argument);
    EXPECT_NO_THROW(validateFrequency(118.0e6)); // Valid VHF frequency
    EXPECT_THROW(validateFrequency(1e12), std::invalid_argument); // Too high
}
```

### 2. Improve Assertion Quality

```cpp
// Instead of generic assertions
ASSERT_TRUE(result > 0);

// Use specific assertions
ASSERT_NEAR(result, expectedValue, 0.001);
ASSERT_EQ(result.getStatus(), Status::SUCCESS);
```

### 3. Test Edge Cases

```cpp
// Test boundary conditions
TEST(AudioProcessing, EdgeCases) {
    // Test with empty input
    std::vector<float> empty;
    auto result = processAudio(empty);
    EXPECT_TRUE(result.empty());
    
    // Test with extreme values
    std::vector<float> extreme = {std::numeric_limits<float>::max()};
    EXPECT_NO_THROW(processAudio(extreme));
}
```

### 4. Property-Based Testing

```cpp
// Use RapidCheck for property-based testing
TEST(RadioPropagation, PropertyTests) {
    rc::check("Path loss should be positive", [](double freq, double dist) {
        RC_PRE(freq > 0 && dist > 0);
        double loss = calculatePathLoss(freq, dist);
        RC_ASSERT(loss > 0);
    });
}
```

## Advanced Usage

### Custom Mutators

Edit `mull.yml` to customize mutators:

```yaml
mutators:
  - cxx_add_to_sub      # + becomes -
  - cxx_eq_to_ne        # == becomes !=
  # Add or remove mutators as needed
```

### Performance Tuning

```yaml
# Adjust based on your system
workers: 8              # More workers for faster execution
timeout: 10000          # Longer timeout for complex tests
max-mutations-per-file: 500  # Limit mutations per file
```

### Coverage Integration

```bash
# Generate coverage data
make CFLAGS+="-fprofile-arcs -ftest-coverage -g -O0" clean all

# Run tests to generate coverage
./run_tests

# Generate coverage report
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/test/*' --output-file coverage_filtered.info
```

## CI/CD Integration

### GitHub Actions

The project includes a GitHub Actions workflow (`.github/workflows/mutation-testing.yml`) that:

- Runs mutation testing on every PR
- Uploads results as artifacts
- Comments on PRs with mutation scores
- Runs weekly on schedule

### Local CI Integration

```bash
# Add to your local CI script
if ./scripts/run_mull_tests.sh; then
    echo "Mutation testing passed"
else
    echo "Mutation testing failed - check results"
    exit 1
fi
```

## Troubleshooting

### Common Issues

1. **"No coverage data found"**
   ```bash
   # Ensure coverage data is generated
   make CFLAGS+="-fprofile-arcs -ftest-coverage -g -O0" clean all
   ./run_tests  # Run your tests
   lcov --capture --directory . --output-file coverage.info
   ```

2. **"Compilation database not found"**
   ```bash
   # Generate compile_commands.json
   cd build
   cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
   cp compile_commands.json ../compile_commands.json
   ```

3. **"High timeout rate"**
   - Increase timeout in `mull.yml`
   - Optimize slow tests
   - Use faster test doubles

4. **"Low mutation score"**
   - Add more test cases
   - Improve assertion quality
   - Test edge cases and boundary conditions

### Debug Mode

Enable debug mode in `mull.yml`:

```yaml
debug: true
```

This provides detailed logging of the mutation testing process.

## Best Practices

### 1. Regular Execution

- Run mutation testing in CI/CD pipeline
- Set up weekly scheduled runs
- Track mutation score trends over time

### 2. Focus on Critical Code

- Prioritize high-risk modules (radio calculations, audio processing)
- Focus on business logic over utility functions
- Test security-critical code paths

### 3. Combine with Coverage

- Use both line coverage and mutation testing
- Line coverage shows what's tested
- Mutation testing shows how well it's tested

### 4. Document Findings

- Keep track of surviving mutations
- Document test improvements
- Share insights with team

## Project-Specific Considerations

### FGcom-mumble Specific Mutations

The configuration includes specialized mutations for:

- **Radio frequency calculations**: Arithmetic mutations for frequency math
- **Audio processing**: Bitwise and logical mutations for audio algorithms
- **Geographic coordinates**: Comparison mutations for coordinate validation
- **Security systems**: Logical mutations for authentication logic

### Critical Code Paths

Focus mutation testing on:

1. **Radio propagation calculations** (`lib/radio_model.cpp`)
2. **Audio processing** (`lib/audio.cpp`)
3. **Frequency management** (`lib/frequency_offset.cpp`)
4. **Security systems** (`lib/work_unit_security.h`)
5. **Geographic calculations** (`lib/terrain_elevation.cpp`)

### Excluded Test Modules

The following test modules are automatically excluded from mutation testing due to performance or reliability issues:

- **❌ Network Module Tests**: Timeout issues with network operations
- **❌ Integration Tests**: 71 seconds execution time - too slow for mutation testing
- **❌ Performance Tests**: Timing-sensitive tests that don't work well with mutations

These exclusions ensure mutation testing runs efficiently while still covering the core business logic.

## Resources

- [Mull Documentation](https://mull.readthedocs.io/)
- [Mutation Testing Best Practices](https://pitest.org/quickstart/best_practices/)
- [FGcom-mumble Testing Framework](testing_framework.md)
- [RapidCheck Property Testing](https://github.com/emil-e/rapidcheck)

## Support

For issues with mutation testing setup:

1. Check the troubleshooting section above
2. Review Mull documentation
3. Check project-specific test coverage
4. Verify compilation database is correct

Remember: The goal is not 100% mutation score, but identifying areas where test coverage can be improved to catch real bugs.
