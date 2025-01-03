#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log with timestamp and severity
log() {
    local severity=$1
    local message=$2
    local color=""
    
    case $severity in
        "ERROR") color=$RED ;;
        "WARNING") color=$YELLOW ;;
        "INFO") color=$GREEN ;;
        *) color=$NC ;;
    esac
    
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color}${severity}${NC}: $message"
}

# Error handling
set -euo pipefail
trap 'log "ERROR" "Script failed - check logs for details"' ERR

validate_apis() {
    local errors=0
    local required_apis=(
        "workflows.googleapis.com"
        "iam.googleapis.com" 
        "cloudresourcemanager.googleapis.com"
        "monitoring.googleapis.com"
    )

    for api in "${required_apis[@]}"; do
        if ! status=$(gcloud services list --enabled --filter="config.name:$api" --format="value(state)" 2>/dev/null); then
            log "ERROR" "Failed to check status of $api"
            ((errors++))
            continue
        fi
        
        if [[ $status != "ENABLED" ]]; then
            log "ERROR" "$api is not enabled"
            ((errors++))
        else 
            log "INFO" "$api is enabled and running"
        fi
    done
    
    return $errors
}

validate_identity_pool() {
    if ! pool_status=$(gcloud iam workload-identity-pools describe github-pool \
        --location="global" \
        --format="value(state)" 2>/dev/null); then
        log "ERROR" "Failed to check Workload Identity Pool status"
        return 1
    fi
    
    if [[ $pool_status != "ACTIVE" ]]; then
        log "ERROR" "Workload Identity Pool is not active"
        return 1
    fi
    
    log "INFO" "Workload Identity Pool is active and correctly configured"
    return 0
}

validate_identity_provider() {
    if ! provider_status=$(gcloud iam workload-identity-pools providers describe github-provider \
        --location="global" \
        --workload-identity-pool="github-pool" \
        --format="value(state)" 2>/dev/null); then
        log "ERROR" "Failed to check Workload Identity Provider status"
        return 1
    fi
    
    if [[ $provider_status != "ACTIVE" ]]; then
        log "ERROR" "Workload Identity Provider is not active"
        return 1
    fi
    
    log "INFO" "Workload Identity Provider is active and correctly configured"
    return 0
}

# Main validation function
validate_infrastructure() {
    log "INFO" "Starting infrastructure validation"
    local total_errors=0
    
    log "INFO" "Validating API enablement..."
    if ! validate_apis; then
        ((total_errors+=$?))
    fi
    
    log "INFO" "Validating Workload Identity Pool..."
    if ! validate_identity_pool; then
        ((total_errors++))
    fi
    
    log "INFO" "Validating Workload Identity Provider..."
    if ! validate_identity_provider; then
        ((total_errors++))
    fi
    
    if [ $total_errors -eq 0 ]; then
        log "INFO" "Validation completed successfully"
    else
        log "ERROR" "Validation completed with $total_errors errors"
    fi
    
    return $total_errors
}

# Only run if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_infrastructure
fi