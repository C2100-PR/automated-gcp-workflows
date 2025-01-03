#!/bin/bash

# Set up notification channels for Phillip Corey Roark
source ./common.sh

setup_mobile_channel() {
    log "INFO" "Setting up mobile notification channel"

    # Create SMS notification channel
    gcloud alpha monitoring channels create \
        --display-name="Phillip Mobile Alerts" \
        --type="sms" \
        --user-labels="owner=phillip,priority=critical" \
        --channel-labels="phone_number=${PHILLIP_MOBILE}" \
        --channel-enabled=true

    # Test notification
    gcloud alpha monitoring channels test \
        --channel-id="${PHILLIP_MOBILE_CHANNEL}" \
        --display-name="Alert System Test" \
        --message="GitHub Workflow Alert System Test Message"
}

setup_notification_policies() {
    log "INFO" "Configuring notification policies"

    # Apply mobile alert configuration
    gcloud alpha monitoring policies create \
        --policy-from-file=config/alerts/mobile_notifications.yaml

    # Verify notification channel is active
    gcloud alpha monitoring channels describe "${PHILLIP_MOBILE_CHANNEL}" \
        --format="value(state)"
}

# Main setup function
main() {
    log "INFO" "Starting notification setup for Phillip Corey Roark"

    if ! setup_mobile_channel; then
        log "ERROR" "Failed to set up mobile channel"
        return 1
    fi

    if ! setup_notification_policies; then
        log "ERROR" "Failed to set up notification policies"
        return 1
    fi

    log "INFO" "Successfully configured mobile notifications"
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi