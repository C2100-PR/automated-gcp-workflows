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

setup_dashboard() {
    log "INFO" "Creating monitoring dashboard..."
    
    if ! gcloud monitoring dashboards create github-workflows-dashboard \
        --config-from-file=config/monitor-dashboard.json 2>/dev/null; then
        log "ERROR" "Failed to create monitoring dashboard"
        return 1
    fi
    
    log "INFO" "Monitoring dashboard created successfully"
    return 0
}

setup_metrics() {
    log "INFO" "Creating log-based metrics..."
    
    # Authentication failure metric
    if ! gcloud logging metrics create github_auth_failures \
        --description="GitHub authentication failures" \
        --log-filter='resource.type="audited_resource" 
                     severity>=ERROR 
                     jsonPayload.event_type="authentication_failure"' 2>/dev/null; then
        log "ERROR" "Failed to create authentication failure metric"
        return 1
    fi
    
    # API latency metric
    if ! gcloud logging metrics create github_api_latency \
        --description="GitHub API request latency" \
        --log-filter='resource.type="audited_resource" 
                     jsonPayload.event_type="api_request"' 2>/dev/null; then
        log "ERROR" "Failed to create API latency metric"
        return 1
    fi
    
    log "INFO" "Log-based metrics created successfully"
    return 0
}

setup_alerts() {
    log "INFO" "Creating alert policies..."
    
    # Authentication failure alert
    if ! gcloud monitoring policies create \
        --policy-from-file=config/auth-failure-policy.yaml 2>/dev/null; then
        log "ERROR" "Failed to create authentication failure alert policy"
        return 1
    fi
    
    # High latency alert
    if ! gcloud monitoring policies create \
        --policy-from-file=config/latency-alert-policy.yaml 2>/dev/null; then
        log "ERROR" "Failed to create latency alert policy"
        return 1
    fi
    
    log "INFO" "Alert policies created successfully"
    return 0
}

# Main monitoring function
monitor_infrastructure() {
    log "INFO" "Starting monitoring setup"
    local total_errors=0
    
    if ! setup_dashboard; then
        ((total_errors++))
    fi
    
    if ! setup_metrics; then
        ((total_errors++))
    fi
    
    if ! setup_alerts; then
        ((total_errors++))
    fi
    
    if [ $total_errors -eq 0 ]; then
        log "INFO" "Monitoring setup completed successfully"
    else
        log "ERROR" "Monitoring setup completed with $total_errors errors"
    fi
    
    return $total_errors
}

# Only run if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    monitor_infrastructure
fi