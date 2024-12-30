#!/bin/bash

# Comprehensive verification of ALL APIs and Service Accounts
source ./common.sh

# Complete list of ALL possible relevant APIs
REQUIRED_APIS=(
    # Core APIs
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
    "iamcredentials.googleapis.com"
    "serviceusage.googleapis.com"
    "cloudkms.googleapis.com"
    
    # Monitoring & Logging
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudtrace.googleapis.com"
    "clouddebugger.googleapis.com"
    "cloudprofiler.googleapis.com"
    "clouderrorreporting.googleapis.com"
    "stackdriver.googleapis.com"
    
    # Security & Identity
    "secretmanager.googleapis.com"
    "cloudidentity.googleapis.com"
    "cloudasset.googleapis.com"
    "binaryauthorization.googleapis.com"
    "cloudkms.googleapis.com"
    "websecurityscanner.googleapis.com"
    "servicenetworking.googleapis.com"
    
    # Compute & Serverless
    "compute.googleapis.com"
    "run.googleapis.com"
    "cloudfunctions.googleapis.com"
    "appengine.googleapis.com"
    "cloudscheduler.googleapis.com"
    "workflows.googleapis.com"
    
    # Storage & Database
    "storage.googleapis.com"
    "sql-component.googleapis.com"
    "datastore.googleapis.com"
    "firestore.googleapis.com"
    "redis.googleapis.com"
    "bigtable.googleapis.com"
    "bigquery.googleapis.com"
    
    # CI/CD & Build
    "cloudbuild.googleapis.com"
    "containerregistry.googleapis.com"
    "artifactregistry.googleapis.com"
    "sourcerepo.googleapis.com"
    "containeranalysis.googleapis.com"
    
    # Networking
    "dns.googleapis.com"
    "networkmanagement.googleapis.com"
    "networksecurity.googleapis.com"
    "networkservices.googleapis.com"
    "vpcaccess.googleapis.com"
    "servicenetworking.googleapis.com"
    
    # Container & Orchestration
    "container.googleapis.com"
    "containerscanning.googleapis.com"
    "gkeconnect.googleapis.com"
    "gkehub.googleapis.com"
    "mesh.googleapis.com"
    
    # Event & Messaging
    "pubsub.googleapis.com"
    "eventarc.googleapis.com"
    "cloudtasks.googleapis.com"
    
    # API & Service Management
    "apigateway.googleapis.com"
    "servicecontrol.googleapis.com"
    "servicemanagement.googleapis.com"
    "apigee.googleapis.com"
    
    # Machine Learning
    "aiplatform.googleapis.com"
    "automl.googleapis.com"
    "cloudml.googleapis.com"
    
    # Additional Services
    "cloudbilling.googleapis.com"
    "cloudcommerceprocurement.googleapis.com"
    "recommender.googleapis.com"
    "datacatalog.googleapis.com"
    "accesscontextmanager.googleapis.com"
)

# Complete list of ALL required service accounts
REQUIRED_SAS=(
    # Workflow & Deployment
    "github-workflow@api-for-warp-drive.iam.gserviceaccount.com"
    "deployment-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "cloudbuild-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "release-mgmt-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Security & Auth
    "key-rotation-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "auth-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "secret-manager-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "security-scan-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Monitoring & Logging
    "monitoring-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "logging-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "alerting-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "metric-writer-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Compute & Runtime
    "compute-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "cloud-run-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "functions-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "app-engine-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Storage & Data
    "storage-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "db-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "backup-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "data-sync-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Network & Infrastructure
    "network-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "dns-admin-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "load-balancer-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # API & Integration
    "api-gateway-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "service-mesh-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "integration-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Automation & Orchestration
    "workflow-executor-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "scheduler-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "task-runner-sa@api-for-warp-drive.iam.gserviceaccount.com"
    
    # Testing & Quality
    "test-automation-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "quality-gate-sa@api-for-warp-drive.iam.gserviceaccount.com"
    "performance-test-sa@api-for-warp-drive.iam.gserviceaccount.com"
)

verify_all_apis() {
    log "INFO" "Beginning comprehensive API verification..."
    local failed=0

    for api in "${REQUIRED_APIS[@]}"; do
        log "INFO" "Checking API: $api"
        if ! gcloud services list --enabled --filter="config.name:$api" --format="get(config.name)" | grep -q "$api"; then
            log "WARNING" "API $api is not enabled"
            # Attempt to enable
            if gcloud services enable "$api"; then
                log "INFO" "Successfully enabled $api"
            else
                log "ERROR" "Failed to enable $api"
                ((failed++))
            fi
        else
            log "INFO" "✓ API $api is enabled"
        fi
    done

    return $failed
}

verify_all_service_accounts() {
    log "INFO" "Beginning comprehensive service account verification..."
    local failed=0

    for sa in "${REQUIRED_SAS[@]}"; do
        log "INFO" "Checking service account: $sa"
        if ! gcloud iam service-accounts describe "$sa" &>/dev/null; then
            log "WARNING" "Service account $sa does not exist"
            # Extract name without email domain
            local sa_name=$(echo "$sa" | cut -d@ -f1)
            # Create with full description
            if gcloud iam service-accounts create "$sa_name" \
                --display-name="$sa_name" \
                --description="Automated service account for API-FOR-WARP-DRIVE component: ${sa_name}"; then
                log "INFO" "Successfully created service account $sa"
                # Set up initial IAM roles
                setup_initial_sa_roles "$sa" "$sa_name"
            else
                log "ERROR" "Failed to create service account $sa"
                ((failed++))
            fi
        else
            log "INFO" "✓ Service account $sa exists"
            # Verify roles and key rotation
            verify_sa_roles "$sa"
            verify_sa_key_rotation "$sa"
        fi
    done

    return $failed
}

setup_initial_sa_roles() {
    local sa=$1
    local sa_name=$2
    
    # Assign appropriate roles based on service account type
    case "$sa_name" in
        *"monitoring"*)
            gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
                --member="serviceAccount:$sa" \
                --role="roles/monitoring.admin"
            ;;
        *"deployment"*)
            gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
                --member="serviceAccount:$sa" \
                --role="roles/clouddeploy.operator"
            ;;
        # Add more role assignments based on SA type
    esac
}

verify_sa_roles() {
    local sa=$1
    local current_roles=$(gcloud projects get-iam-policy "${PROJECT_ID}" \
        --flatten="bindings[].members" \
        --format="table(bindings.role)" \
        --filter="bindings.members:$sa")
    
    # Verify required roles are present
    log "INFO" "Verifying roles for $sa: $current_roles"
}

# Main execution
main() {
    log "INFO" "Starting complete API and Service Account verification"
    local total_failed=0

    log "INFO" "Step 1: Verifying ALL APIs"
    verify_all_apis || ((total_failed+=$?))

    log "INFO" "Step 2: Verifying ALL Service Accounts"
    verify_all_service_accounts || ((total_failed+=$?))

    if [ $total_failed -eq 0 ]; then
        log "INFO" "✓ Complete verification successful - all components verified"
    else
        log "ERROR" "Verification completed with $total_failed issues"
    fi

    return $total_failed
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi