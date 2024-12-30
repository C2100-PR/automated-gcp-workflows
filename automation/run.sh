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

# Check required scripts
check_dependencies() {
    local scripts=("deploy.sh" "validate.sh" "monitor.sh")
    local missing=0
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$(dirname "$0")/$script" ]]; then
            log "ERROR" "Required script $script not found"
            ((missing++))
        fi
    done
    
    return $missing
}

# Source required scripts with error handling
source_scripts() {
    local scripts=("deploy.sh" "validate.sh" "monitor.sh")
    
    for script in "${scripts[@]}"; do
        if ! source "$(dirname "$0")/$script"; then
            log "ERROR" "Failed to source $script"
            return 1
        fi
        log "INFO" "Successfully loaded $script"
    done
    
    return 0
}

# Main automation function
automate_infrastructure() {
    log "INFO" "Starting infrastructure automation"
    local total_errors=0
    
    # Check dependencies
    if ! check_dependencies; then
        log "ERROR" "Missing required scripts"
        return 1
    fi
    
    # Source required scripts
    if ! source_scripts; then
        log "ERROR" "Failed to load required scripts"
        return 1
    fi
    
    # 1. Deploy infrastructure
    log "INFO" "Deploying infrastructure..."
    if ! deploy_infrastructure; then
        log "ERROR" "Infrastructure deployment failed"
        return 1
    fi
    
    # 2. Validate infrastructure
    log "INFO" "Validating infrastructure..."
    if ! validate_infrastructure; then
        log "ERROR" "Infrastructure validation failed"
        ((total_errors++))
    fi
    
    # 3. Setup monitoring
    log "INFO" "Setting up monitoring..."
    if ! monitor_infrastructure; then
        log "ERROR" "Monitoring setup failed"
        ((total_errors++))
    fi
    
    if [ $total_errors -eq 0 ]; then
        log "INFO" "Infrastructure automation completed successfully"
    else
        log "ERROR" "Infrastructure automation completed with $total_errors errors"
    fi
    
    return $total_errors
}

# Execute main function
automate_infrastructure