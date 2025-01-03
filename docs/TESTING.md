# Testing Guide

## Test Suite Overview

The test suite consists of three main components:

1. `test_validate.sh`: Tests infrastructure validation
2. `test_monitor.sh`: Tests monitoring setup
3. `run_tests.sh`: Main test runner

## Running Tests

### Full Test Suite

```bash
cd tests
./run_tests.sh
```

### Individual Components

```bash
# Test validation only
./test_validate.sh

# Test monitoring only
./test_monitor.sh
```

## Adding New Tests

1. Create a new test file in the `tests` directory
2. Follow the existing pattern:
   ```bash
   source ../automation/your_script.sh
   
   test_your_function() {
       # Test implementation
   }
   
   run_tests() {
       local failed=0
       test_your_function || ((failed++))
       return $failed
   }
   
   run_tests
   ```

## Mocking

The test suite uses function mocking for gcloud commands:

```bash
# Example mock
gcloud() {
    echo "EXPECTED_OUTPUT"
    return 0
}
export -f gcloud
```

## CI/CD Integration

The test suite is designed to run in CI/CD pipelines:

1. Exit codes indicate success/failure
2. Output is formatted for easy parsing
3. Tests are idempotent

## Test Coverage

Current test coverage includes:

- API validation
- Identity pool validation
- Dashboard creation
- Metrics setup
- Alert policy configuration