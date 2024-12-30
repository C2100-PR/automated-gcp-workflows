#!/bin/bash

# Configuration script for api-for-warp-drive project

PROJECT_ID="api-for-warp-drive"

# Enable APIs
apis=(
    "compute.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "cloudbuild.googleapis.com"
    "cloudfunctions.googleapis.com"
    "cloudscheduler.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudkms.googleapis.com"
    "cloudasset.googleapis.com"
    "websecurityscanner.googleapis.com"
    "containerscanning.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudtrace.googleapis.com"
    "clouddebugger.googleapis.com"
    "cloudprofiler.googleapis.com"
)

# Service Accounts
service_accounts=(
    "warp-drive-admin"
    "warp-drive-service"
    "deployment-sa"
    "security-scan-sa"
    "monitoring-sa"
    "logging-sa"
)

# Labels
labels=(
    "environment=production"
    "team=warp-drive"
    "cost-center=research"
    "app=warp-drive"
    "security-level=high"
    "compliance=required"
    "data-classification=confidential"
)

# Enable APIs
for api in "${apis[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --project=$PROJECT_ID
done

# Create Service Accounts
for sa in "${service_accounts[@]}"; do
    echo "Creating service account $sa..."
    gcloud iam service-accounts create $sa \
        --display-name=$sa \
        --project=$PROJECT_ID
done

# Apply Labels
for label in "${labels[@]}"; do
    echo "Applying label $label..."
    gcloud alpha resource-manager labels update \
        --project=$PROJECT_ID \
        --update-labels=$label
done

echo "Configuration complete!"