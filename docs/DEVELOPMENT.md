# Development Guidelines

## Branch Strategy

1. Main Branch (Protected)
   - Production-ready code
   - No direct pushes
   - Requires PR and review

2. Develop Branch
   - Integration branch
   - Feature branches merge here
   - Regular testing

3. Feature Branches
   - Branch from: develop
   - Name format: feature/description
   - Merge to: develop

4. Hotfix Branches
   - Branch from: main
   - Name format: hotfix/description
   - Merge to: main and develop

## Security Requirements

- Run security checks locally
- Keep dependencies updated
- Follow secure coding practices
- Report vulnerabilities privately