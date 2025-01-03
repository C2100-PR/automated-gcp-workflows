#!/bin/bash

# Test suite for monitor.sh
source ../automation/monitor.sh

test_dashboard_creation() {
    log "INFO" "Testing dashboard creation..."
    
    # Mock gcloud command
    gcloud() {
        return 0
    }
    export -f gcloud
    
    setup_dashboard
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log "INFO" "Dashboard creation test passed"
        return 0
    else
        log "ERROR" "Dashboard creation test failed"
        return 1
    fi
}

test_metrics_creation() {
    log "INFO" "Testing metrics creation..."
    
    # Mock gcloud command
    gcloud() {
        return 0
    }
    export -f gcloud
    
    setup_metrics
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log "INFO" "Metrics creation test passed"
        return 0
    else
        log "ERROR" "Metrics creation test failed"
        return 1
    fi
}

# Run all tests
run_tests() {
    local failed=0
    
    test_dashboard_creation || ((failed++))
    test_metrics_creation || ((failed++))
    
    return $failed
}

run_tests