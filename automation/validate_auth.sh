#!/bin/bash

# Validate authentication setup across environments
source ./common.sh

validate_workload_federation() {
    local env=$1
    local pool_id="github-pool-${env}"
    local provider_id="github-provider-${env}"
    local failed=0

    log "INFO" "Validating Workload Identity Federation for ${env}"

    # Check pool status
    if ! pool_status=$(gcloud iam workload-identity-pools describe "${pool_id}" \
        --location="global" \
        --format="value(state)" 2>/dev/null); then
        log "ERROR" "Failed to get pool status for ${env}"
        ((failed++))
    elif [[ $pool_status != "ACTIVE" ]]; then
        log "ERROR" "Pool ${pool_id} is not active"
        ((failed++))
    fi

    # Check provider status
    if ! provider_status=$(gcloud iam workload-identity-pools providers describe "${provider_id}" \
        --location="global" \
        --workload-identity-pool="${pool_id}" \
        --format="value(state)" 2>/dev/null); then
        log "ERROR" "Failed to get provider status for ${env}"
        ((failed++))
    elif [[ $provider_status != "ACTIVE" ]]; then
        log "ERROR" "Provider ${provider_id} is not active"
        ((failed++))
    fi

    # Validate IAM bindings
    if ! gcloud projects get-iam-policy "${PROJECT_ID}" \
        --filter="bindings.members:workloadIdentityPools/${pool_id}" \
        --format="value(bindings.role)" | grep -q "roles/iam.workloadIdentityUser"; then
        log "ERROR" "Missing required IAM bindings for ${env}"
        ((failed++))
    fi

    return $failed
}

validate_oauth_config() {
    local env=$1
    local failed=0

    log "INFO" "Validating OAuth2 configuration for ${env}"

    # Check OAuth client existence and configuration
    if ! oauth_status=$(gcloud alpha iap oauth-clients list \
        "projects/${PROJECT_NUMBER}/brands/${BRAND_ID}" \
        --filter="displayName:GitHub Integration ${env}" \
        --format="value(name)" 2>/dev/null); then
        log "ERROR" "OAuth client not found for ${env}"
        ((failed++))
    fi

    # Validate OAuth consent screen configuration
    if ! consent_screen=$(gcloud alpha iap oauth-settings describe \
        --oauth2-client-id="${OAUTH_CLIENT_ID}" \
        --format="value(applicationTitle)" 2>/dev/null); then
        log "ERROR" "OAuth consent screen not properly configured for ${env}"
        ((failed++))
    fi

    return $failed
}

# Main validation function
validate_authentication() {
    local environments=("development" "staging" "production")
    local total_failed=0

    for env in "${environments[@]}"; do
        log "INFO" "Validating authentication for ${env}"

        validate_workload_federation "${env}" || ((total_failed++))
        validate_oauth_config "${env}" || ((total_failed++))
    done

    if [ $total_failed -eq 0 ]; then
        log "INFO" "Authentication validation successful across all environments"
    else
        log "ERROR" "Authentication validation failed with ${total_failed} errors"
    fi

    return $total_failed
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_authentication
fi