# ADR 001 — OIDC Federation over Static IAM Keys

**Date:** 2025-03-01
**Status:** Accepted

## Context

GitHub Actions requires AWS credentials to run `terraform plan` and `terraform apply`.
The naive approach is to create an IAM user, generate access keys, and store them as
GitHub Secrets. This creates long-lived credentials that can be leaked, rotated
inconsistently, and are a persistent attack surface.

## Decision

Use OIDC (OpenID Connect) federation between GitHub Actions and AWS IAM.

GitHub's OIDC provider issues short-lived JWT tokens per workflow run. AWS IAM
validates the token against the registered OIDC provider and issues temporary
credentials via `sts:AssumeRoleWithWebIdentity`. The credentials expire when the
workflow ends — typically within minutes.

The Terraform resource:
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
```

The GitHub Actions step:
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

## Consequences

**Positive:**
- Zero static credentials stored anywhere — no IAM access keys exist
- Credentials are scoped to a specific repository and branch via IAM condition
- Automatic expiry — no rotation policy needed
- Auditable via CloudTrail: every assume-role call is logged

**Negative:**
- Slightly more complex initial setup (OIDC provider + trust policy)
- Requires the role ARN to be stored as a GitHub Secret (non-sensitive, but still managed)

## Alternatives Considered

- **IAM user with access keys:** Rejected — long-lived credentials, rotation risk
- **EC2 instance role for self-hosted runner:** Rejected — cost and management overhead
