#!/bin/bash

# Workload Identity Federation setup across environments
source ../common.sh

setup_workload_federation() {
    local env=$1
    local pool_id="github-pool-${env}"
    local provider_id="github-provider-${env}"

    log "INFO" "Setting up Workload Identity Federation for ${env}"

    # Create Workload Identity Pool
    gcloud iam workload-identity-pools create "${pool_id}" \
        --location="global" \
        --display-name="GitHub Actions Pool ${env}" \
        --description="Identity pool for GitHub Actions in ${env}"

    # Create Workload Identity Provider
    gcloud iam workload-identity-pools providers create-oidc "${provider_id}" \
        --location="global" \
        --workload-identity-pool="${pool_id}" \
        --display-name="GitHub Provider ${env}" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
        --issuer-uri="https://token.actions.githubusercontent.com"

    # Set up IAM permissions
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${pool_id}/*" \
        --role="roles/iam.workloadIdentityUser"

    log "INFO" "Workload Federation setup complete for ${env}"
}

# Setup OAuth2 configuration
setup_oauth_config() {
    local env=$1
    
    log "INFO" "Configuring OAuth2 for ${env}"

    # Create OAuth2 client
    gcloud alpha iap oauth-clients create "projects/${PROJECT_NUMBER}/brands/${BRAND_ID}" \
        --display_name="GitHub Integration ${env}" \
        --oauth2-client-type="web"

    # Configure OAuth consent screen
    gcloud alpha iap oauth-settings set \
        --oauth2-client-id="${OAUTH_CLIENT_ID}" \
        --support-email="${SUPPORT_EMAIL}" \
        --application-title="GitHub Workflow Integration ${env}"

    log "INFO" "OAuth2 configuration complete for ${env}"
}

# Main setup function
setup_authentication() {
    local environments=("development" "staging" "production")
    local failed=0

    for env in "${environments[@]}"; do
        log "INFO" "Setting up authentication for ${env}"

        if ! setup_workload_federation "${env}"; then
            log "ERROR" "Failed to setup Workload Federation for ${env}"
            ((failed++))
        fi

        if ! setup_oauth_config "${env}"; then
            log "ERROR" "Failed to setup OAuth2 for ${env}"
            ((failed++))
        fi
    done

    return $failed
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_authentication
fi