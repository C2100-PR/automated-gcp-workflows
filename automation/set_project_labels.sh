#!/bin/bash

# Script to set project labels for API-FOR-WARP-DRIVE
source ./common.sh

set_project_labels() {
    local project_id="api-for-warp-drive"
    log "INFO" "Setting labels for project: ${project_id}"

    # Apply all labels in a single command to minimize API calls
    gcloud projects update "${project_id}" \
        --update-labels=environment=production,\
 criticality=high,\
 owner=phillip-corey-roark,\
 security_level=confidential,\
 alert_priority=critical,\
 service_type=api,\
 cost_center=warp-drive-operations,\
 business_unit=warp-drive,\
 deployment_type=continuous,\
 monitoring_level=enhanced

    if [ $? -eq 0 ]; then
        log "INFO" "Successfully set labels for ${project_id}"
    else
        log "ERROR" "Failed to set labels for ${project_id}"
        return 1
    fi

    # Verify labels were set correctly
    verify_labels "${project_id}"
}

verify_labels() {
    local project_id=$1
    log "INFO" "Verifying labels for project: ${project_id}"

    local labels=$(gcloud projects describe "${project_id}" \
        --format="get(labels)" --verbosity=none)

    # Check for required labels
    local required_labels=("environment" "criticality" "owner" "security_level" \
                         "alert_priority" "service_type" "cost_center" \
                         "business_unit" "deployment_type" "monitoring_level")

    local missing=0
    for label in "${required_labels[@]}"; do
        if [[ ! "$labels" =~ "$label" ]]; then
            log "ERROR" "Missing required label: $label"
            ((missing++))
        fi
    done

    if [ $missing -eq 0 ]; then
        log "INFO" "All required labels are present"
        return 0
    else
        log "ERROR" "Missing $missing required labels"
        return 1
    fi
}

# Main function
main() {
    log "INFO" "Starting project label configuration"

    if ! set_project_labels; then
        log "ERROR" "Failed to configure project labels"
        return 1
    fi

    log "INFO" "Successfully configured all project labels"
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi