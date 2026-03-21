# ADR 003: GitHub OIDC Federation for AWS Access

## Status
Accepted

## Context
GitHub Actions needs to deploy infrastructure to AWS. Traditional approach uses long-lived IAM users with access keys, which is a security risk.

## Decision
We implemented **OIDC federation** between GitHub and AWS:
- No long-lived credentials stored in GitHub Secrets
- Temporary credentials (max 1 hour) generated per workflow run
- IAM role assumed directly by GitHub Actions

## Consequences
- **Improved security**: No access keys to rotate or leak
- **Auditability**: CloudTrail logs show GitHub as the principal
- **Compliance**: Meets security best practices
- **Setup complexity**: Initial configuration requires manual steps