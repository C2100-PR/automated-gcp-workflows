#!/bin/bash

# Test suite for validate.sh
source ../automation/validate.sh

test_api_validation() {
    log "INFO" "Testing API validation..."
    
    # Mock gcloud command
    gcloud() {
        echo "ENABLED"
    }
    export -f gcloud
    
    # Run validation
    validate_apis
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log "INFO" "API validation test passed"
        return 0
    else
        log "ERROR" "API validation test failed"
        return 1
    fi
}

test_identity_pool() {
    log "INFO" "Testing identity pool validation..."
    
    # Mock gcloud command
    gcloud() {
        echo "ACTIVE"
    }
    export -f gcloud
    
    # Run validation
    validate_identity_pool
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log "INFO" "Identity pool test passed"
        return 0
    else
        log "ERROR" "Identity pool test failed"
        return 1
    fi
}

# Run all tests
run_tests() {
    local failed=0
    
    test_api_validation || ((failed++))
    test_identity_pool || ((failed++))
    
    return $failed
}

run_tests