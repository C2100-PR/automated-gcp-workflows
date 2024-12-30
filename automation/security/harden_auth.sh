#!/bin/bash

# Enhanced security hardening for authentication
source ../common.sh

harden_workload_identity() {
    local env=$1
    local pool_id="github-pool-${env}"

    log "INFO" "Implementing security hardening for ${env} Workload Identity"

    # Add IP-based access restrictions
    gcloud iam workload-identity-pools update "${pool_id}" \
        --location="global" \
        --allowed-locations="us-east1,us-central1" \
        --condition="expression=request.ip_address.matches_prefix('35.235.240.0/20')" \
        --session-duration="3600s"

    # Implement attribute-based access control
    gcloud iam workload-identity-pools providers update-oidc "${provider_id}" \
        --location="global" \
        --workload-identity-pool="${pool_id}" \
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.workflow=assertion.workflow,attribute.environment=assertion.environment" \
        --attribute-condition="attribute.environment == '${env}' && attribute.repository.startsWith('C2100-PR/')"
}

setup_key_rotation() {
    local env=$1
    
    # Create Cloud Scheduler job for key rotation
    gcloud scheduler jobs create http "rotate-oauth-${env}" \
        --schedule="0 0 1 * *" \
        --uri="https://workflowexecution.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/workflows/rotate-oauth-keys" \
        --oauth-service-account-email="${SA_EMAIL}" \
        --message-body='{"environment": "'${env}'"}'

    # Set up key rotation workflow
    gcloud workflows deploy "rotate-oauth-keys" \
        --source="workflows/key_rotation.yaml" \
        --service-account="${SA_EMAIL}"
}

enhance_logging() {
    # Create aggregated log sink
    gcloud logging sinks create "auth-security-sink" \
        storage.googleapis.com/${BUCKET_NAME}/auth-logs \
        --log-filter="resource.type=\"iam\" OR \
                     resource.type=\"identity_pool\" OR \
                     resource.type=\"oauth2\" \
                     severity>=WARNING"

    # Enable audit logging
    gcloud organizations update ${ORG_ID} \
        --audit-log-config-enabled \
        --audit-log-config-log-type="admin_read" \
        --audit-log-config-log-type="data_write" \
        --audit-log-config-log-type="data_read"
}

# Main hardening function
main() {
    local environments=("development" "staging" "production")
    local failed=0

    # Set up enhanced logging first
    if ! enhance_logging; then
        log "ERROR" "Failed to set up enhanced logging"
        return 1
    fi

    for env in "${environments[@]}"; do
        log "INFO" "Implementing security measures for ${env}"

        if ! harden_workload_identity "${env}"; then
            log "ERROR" "Failed to harden Workload Identity for ${env}"
            ((failed++))
        fi

        if ! setup_key_rotation "${env}"; then
            log "ERROR" "Failed to set up key rotation for ${env}"
            ((failed++))
        fi
    done

    return $failed
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi