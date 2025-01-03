#!/bin/bash

# Main test runner

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

run_test_suite() {
    local test_file=$1
    local failed=0
    
    log "${GREEN}Running test suite: $test_file${NC}"
    
    if ! bash "$test_file"; then
        log "${RED}Test suite failed: $test_file${NC}"
        ((failed++))
    else
        log "${GREEN}Test suite passed: $test_file${NC}"
    fi
    
    return $failed
}

# Run all test suites
total_failed=0

for test_file in test_*.sh; do
    if [[ -f "$test_file" ]]; then
        run_test_suite "$test_file" || ((total_failed++))
    fi
done

if [[ $total_failed -eq 0 ]]; then
    log "${GREEN}All test suites passed successfully${NC}"
    exit 0
else
    log "${RED}$total_failed test suites failed${NC}"
    exit 1
fi