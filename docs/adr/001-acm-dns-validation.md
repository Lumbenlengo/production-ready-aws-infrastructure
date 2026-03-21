# ADR 001: ACM Certificate Validation Method

## Status
Accepted

## Context
We need SSL/TLS certificates for HTTPS termination on our Application Load Balancer. AWS Certificate Manager (ACM) provides two validation methods:
- Email validation
- DNS validation

## Decision
We chose **DNS validation** for the following reasons:
1. **Automation**: Can be fully automated with Terraform
2. **No manual steps**: No need to click email links
3. **Renewal**: Automatic renewal without human intervention
4. **Domain control**: Proves domain ownership via DNS records

## Consequences
- Requires Route53 zone for the domain
- Terraform creates validation records automatically
- Certificate renews automatically every 13 months
- No manual intervention needed for certificate lifecycle