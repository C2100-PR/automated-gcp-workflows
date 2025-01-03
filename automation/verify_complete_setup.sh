#!/bin/bash

# Comprehensive verification of APIs and Service Accounts
source ./common.sh

# Required APIs for the API-FOR-WARP-DRIVE project
REQUIRED_APIS=(
    "cloudresourcemanager.googleapis.com"  # Resource Manager API
    "iam.googleapis.com"                   # IAM API
    "iamcredentials.googleapis.com"        # IAM Service Account Credentials API
    "cloudkms.googleapis.com"              # Cloud KMS API
    "monitoring.googleapis.com"            # Cloud Monitoring API
    "logging.googleapis.com"               # Cloud Logging API
    "secretmanager.googleapis.com"         # Secret Manager API
    "cloudbuild.googleapis.com"            # Cloud Build API
    "containerregistry.googleapis.com"     # Container Registry API
    "compute.googleapis.com"               # Compute Engine API
    "cloudfunctions.googleapis.com"        # Cloud Functions API
    "run.googleapis.com"                   # Cloud Run API
    "workflows.googleapis.com"             # Cloud Workflows API
    "artifactregistry.googleapis.com"      # Artifact Registry API
    "eventarc.googleapis.com"              # Eventarc API
    "pubsub.googleapis.com"                # Pub/Sub API
    "cloudscheduler.googleapis.com"        # Cloud Scheduler API
    "serviceusage.googleapis.com"          # Service Usage API
    "cloudasset.googleapis.com"            # Cloud Asset API
    "cloudtrace.googleapis.com"            # Cloud Trace API
    "servicenetworking.googleapis.com"     # Service Networking API
)

# Required Service Accounts
REQUIRED_SAS=(
    "github-workflow@api-for-warp-drive.iam.gserviceaccount.com"
    "monitoring-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "deployment-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "key-rotation-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "auth-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
)

verify_apis() {
    log "INFO" "Verifying API enablement..."
    local failed=0

    for api in "${REQUIRED_APIS[@]}"; do
        if ! gcloud services list --enabled --filter="config.name:$api" --format="get(config.name)" | grep -q "$api"; then
            log "ERROR" "API $api is not enabled"
            ((failed++))
            # Attempt to enable the API
            log "INFO" "Attempting to enable $api"
            if ! gcloud services enable "$api"; then
                log "ERROR" "Failed to enable $api"
            else
                log "INFO" "Successfully enabled $api"
                ((failed--))
            fi
        else
            log "INFO" "API $api is enabled"
        fi
    done

    return $failed
}

verify_service_accounts() {
    log "INFO" "Verifying service accounts..."
    local failed=0

    for sa in "${REQUIRED_SAS[@]}"; do
        if ! gcloud iam service-accounts describe "$sa" &>/dev/null; then
            log "ERROR" "Service account $sa does not exist"
            ((failed++))
            # Create service account if missing
            local sa_name=$(echo "$sa" | cut -d@ -f1)
            log "INFO" "Attempting to create service account $sa_name"
            if ! gcloud iam service-accounts create "$sa_name" \
                --display-name="$sa_name" \
                --description="Auto-created service account for API-FOR-WARP-DRIVE"; then
                log "ERROR" "Failed to create service account $sa_name"
            else
                log "INFO" "Successfully created service account $sa_name"
                ((failed--))
            fi
        else
            log "INFO" "Service account $sa exists"
            # Verify key rotation
            verify_sa_key_rotation "$sa"
        fi
    done

    return $failed
}

verify_sa_key_rotation() {
    local sa=$1
    local keys_age=$(gcloud iam service-accounts keys list \
        --iam-account="$sa" \
        --format="get(validAfterTime)" \
        --sort-by="~validAfterTime" \
        --limit=1)

    if [[ -n "$keys_age" ]]; then
        local age_days=$(( ( $(date +%s) - $(date -d "$keys_age" +%s) ) / 86400 ))
        if (( age_days > 90 )); then
            log "WARNING" "Service account $sa has keys older than 90 days"
            # Schedule key rotation
            log "INFO" "Scheduling key rotation for $sa"
            # Add to key rotation schedule
            echo "$sa" >> "${PROJECT_ROOT}/config/key_rotation_schedule.txt"
        fi
    fi
}

verify_iam_bindings() {
    log "INFO" "Verifying IAM bindings..."
    local failed=0

    # Verify workload identity bindings
    if ! gcloud projects get-iam-policy "${PROJECT_ID}" \
        --format="get(bindings)" | grep -q "serviceAccount:github-workflow@"; then
        log "ERROR" "Missing required workload identity bindings"
        ((failed++))
    fi

    # Verify monitoring bindings
    if ! gcloud projects get-iam-policy "${PROJECT_ID}" \
        --format="get(bindings)" | grep -q "serviceAccount:monitoring-sa@"; then
        log "ERROR" "Missing required monitoring bindings"
        ((failed++))
    fi

    return $failed
}

# Main verification function
main() {
    log "INFO" "Starting comprehensive verification"
    local total_failed=0

    verify_apis || ((total_failed+=$?))
    verify_service_accounts || ((total_failed+=$?))
    verify_iam_bindings || ((total_failed+=$?))

    if [ $total_failed -eq 0 ]; then
        log "INFO" "All verifications passed successfully"
    else
        log "ERROR" "Verification completed with $total_failed issues"
    fi

    return $total_failed
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi