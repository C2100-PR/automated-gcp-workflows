#!/bin/bash

# Comprehensive verification script for api-for-warp-drive project
PROJECT_ID="api-for-warp-drive"
LOG_FILE="verification_$(date +%Y%m%d_%H%M%S).log"

echo "Starting verification for project: $PROJECT_ID" | tee $LOG_FILE
echo "----------------------------------------" | tee -a $LOG_FILE

# Check project access
echo "Verifying project access..." | tee -a $LOG_FILE
gcloud config set project $PROJECT_ID

# Verify APIs
echo -e "\nChecking enabled APIs..." | tee -a $LOG_FILE
REQUIRED_APIS=(
    "compute.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "cloudbuild.googleapis.com"
    "cloudfunctions.googleapis.com"
    "cloudscheduler.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudkms.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="NAME:$api" --quiet | grep -q "$api"; then
        echo "✅ $api is enabled" | tee -a $LOG_FILE
    else
        echo "❌ $api is NOT enabled" | tee -a $LOG_FILE
    fi
done

# Verify Service Accounts
echo -e "\nChecking service accounts..." | tee -a $LOG_FILE
REQUIRED_SAS=(
    "warp-drive-admin"
    "warp-drive-service"
    "deployment-sa"
    "security-scan-sa"
    "monitoring-sa"
    "logging-sa"
)

for sa in "${REQUIRED_SAS[@]}"; do
    if gcloud iam service-accounts list --filter="email:$sa@$PROJECT_ID.iam.gserviceaccount.com" --quiet | grep -q "$sa"; then
        echo "✅ $sa exists" | tee -a $LOG_FILE
    else
        echo "❌ $sa is missing" | tee -a $LOG_FILE
    fi
done

# Check IAM Roles
echo -e "\nVerifying IAM roles..." | tee -a $LOG_FILE
for sa in "${REQUIRED_SAS[@]}"; do
    echo "Roles for $sa:" | tee -a $LOG_FILE
    gcloud projects get-iam-policy $PROJECT_ID \
        --flatten="bindings[].members" \
        --format="table(bindings.role)" \
        --filter="bindings.members:$sa@$PROJECT_ID.iam.gserviceaccount.com" | tee -a $LOG_FILE
done

# Check Labels
echo -e "\nChecking project labels..." | tee -a $LOG_FILE
REQUIRED_LABELS=(
    "environment"
    "team"
    "cost-center"
    "app"
    "security-level"
)

gcloud alpha resource-manager labels list --project=$PROJECT_ID | tee -a $LOG_FILE

# Verify Storage Buckets
echo -e "\nChecking storage buckets..." | tee -a $LOG_FILE
REQUIRED_BUCKETS=(
    "$PROJECT_ID-west1"
    "$PROJECT_ID-artifacts"
)

for bucket in "${REQUIRED_BUCKETS[@]}"; do
    if gsutil ls -b "gs://$bucket" &> /dev/null; then
        echo "✅ Bucket $bucket exists" | tee -a $LOG_FILE
    else
        echo "❌ Bucket $bucket is missing" | tee -a $LOG_FILE
    fi
done

# Check Cloud Functions
echo -e "\nChecking Cloud Functions..." | tee -a $LOG_FILE
gcloud functions list --project=$PROJECT_ID | tee -a $LOG_FILE

# Verify Scheduler Jobs
echo -e "\nChecking Cloud Scheduler jobs..." | tee -a $LOG_FILE
gcloud scheduler jobs list --project=$PROJECT_ID | tee -a $LOG_FILE

# Summary
echo -e "\n----------------------------------------" | tee -a $LOG_FILE
echo "Verification completed. Check $LOG_FILE for full details." | tee -a $LOG_FILE
echo "Please review any ❌ items and take necessary action." | tee -a $LOG_FILE