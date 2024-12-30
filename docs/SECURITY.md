# Security Policy and Branch Protection Guidelines

## Branch Protection Rules

### Main Branch Protection
- No direct pushes to main
- Pull request required for all changes
- Minimum 1 reviewer approval required
- Stale reviews dismissed on new commits
- Status checks must pass
- Branch must be up to date
- Force pushes prohibited
- Administrators included in restrictions

### Development Workflow
1. Create feature branch from develop
2. Make changes and test
3. Create PR to develop
4. After review, merge to develop
5. Create release PR from develop to main

## Security Checks
- All code must pass automated tests
- Security scanning required
- Dependencies must be up to date
- Credentials and secrets must use environment variables

## Emergency Procedures
1. If security breach detected:
   - Contact security team immediately
   - Document incident details
   - Follow incident response plan
2. For urgent fixes:
   - Create hotfix branch
   - Follow expedited review process
   - Merge with admin approval