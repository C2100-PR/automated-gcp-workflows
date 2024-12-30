#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log with timestamp
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Error handling
set -euo pipefail
trap 'log "${RED}Error occurred in validate.sh${NC}"' ERR

# Main validation function
validate_infrastructure() {
    log "${GREEN}Starting infrastructure validation${NC}"
    errors=0
    warnings=0

    # 1. Validate API enablement
    log "Validating API enablement..."
    required_apis=(
        "workflows.googleapis.com"
        "iam.googleapis.com" 
        "cloudresourcemanager.googleapis.com"
    )

    for api in "${required_apis[@]}"; do
        status=$(gcloud services list --enabled --filter="config.name:$api" --format="value(state)")
        if [[ $status != "ENABLED" ]]; then
            log "${RED}Error: $api is not enabled${NC}"
            ((errors++))
        else 
            log "$api is enabled"
        fi
    done

    # 2. Validate Workload Identity Pool
    log "Validating Workload Identity Pool..."
    pool_status=$(gcloud iam workload-identity-pools describe github-pool --location="global" --format="value(state)")  
    if [[ $pool_status != "ACTIVE" ]]; then
        log "${RED}Error: Workload Identity Pool is not active${NC}"
        ((errors++))
    else
        log "Workload Identity Pool is active" 
    fi

    # 3. Validate Workload Identity Provider
    log "${GREEN}Validation complete with $errors errors and $warnings warnings${NC}"
    return $errors
}