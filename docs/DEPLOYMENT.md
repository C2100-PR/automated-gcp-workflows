# Deployment Guide

## Prerequisites

1. Google Cloud SDK installed and configured
2. Required IAM permissions:
   - roles/monitoring.admin
   - roles/iam.workloadIdentityPoolAdmin
   - roles/logging.admin

## Installation Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/C2100-PR/automated-gcp-workflows.git
   cd automated-gcp-workflows
   ```

2. Run tests to verify environment:
   ```bash
   cd tests
   ./run_tests.sh
   ```

3. Deploy the infrastructure:
   ```bash
   cd ../automation
   ./run.sh
   ```

## Monitoring Setup

The deployment automatically configures:
- Dashboard for workflow metrics
- Alert policies for authentication failures
- Log-based metrics for API latency

### Alert Configuration

Update notification channels in config files:
1. Edit `config/auth-failure-policy.yaml`
2. Edit `config/latency-alert-policy.yaml`
3. Replace ${PROJECT_ID} and ${CHANNEL_ID} with your values

## Validation

Verify deployment:
```bash
./validate.sh
```

Check monitoring:
```bash
./monitor.sh
```

## Troubleshooting

### Common Issues

1. API enablement failures:
   ```bash
   gcloud services list --enabled
   ```

2. Identity Pool issues:
   ```bash
   gcloud iam workload-identity-pools describe github-pool --location=global
   ```

3. Monitoring setup issues:
   ```bash
   gcloud monitoring dashboards list
   gcloud logging metrics list
   ```

### Logs

Check deployment logs:
```bash
# View recent deployment logs
gcloud logging read 'resource.type="audited_resource"'
```

## Security Considerations

1. IAM Permissions: Regularly audit workload identity pool access
2. Monitoring: Review alert thresholds in config files
3. Logging: Ensure audit logs are retained appropriately

## Rollback Procedure

1. Stop workflows:
   ```bash
   gcloud workflows list
   gcloud workflows delete WORKFLOW_NAME
   ```

2. Remove monitoring:
   ```bash
   ./monitor.sh --cleanup
   ```

3. Remove identity pool:
   ```bash
   gcloud iam workload-identity-pools delete github-pool --location=global
   ```