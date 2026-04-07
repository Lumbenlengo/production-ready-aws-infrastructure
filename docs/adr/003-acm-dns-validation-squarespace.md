# ADR 003 — ACM DNS Validation via Squarespace (not Route53)

**Date:** 2025-03-26
**Status:** Accepted

## Context

The domain `patriciolumbe.com` was purchased via Squarespace/Google Workspace for
professional email (`patricio@patriciolumbe.com`) and a personal website. The domain
registrar is Squarespace — the authoritative DNS is managed there, not in Route53.

ACM requires DNS validation to prove domain ownership before issuing an SSL certificate.
The standard Terraform pattern uses `aws_route53_record` to create the validation CNAME
automatically. This is not possible when Route53 is not the authoritative DNS.

## Decision

Manage the ACM DNS validation CNAME manually in Squarespace DNS and remove the
`aws_acm_certificate_validation` resource from Terraform.

The validation CNAME added to Squarespace:
```
Host:  _48303337b71c3bb853d7da8cecabe117.api
Type:  CNAME
Value: _7808c4ea7b9472f2d1e362304ee06afd.jkddzztszm.acm-validations.aws
```

The HTTPS listener references `aws_acm_certificate.cert.arn` directly, since the
certificate is already in `ISSUED` state.

The `api.patriciolumbe.com` CNAME pointing to the ALB is also managed in Squarespace:
```
Host:  api
Type:  CNAME
Value: lumbenlengo-alb-2120541843.us-east-1.elb.amazonaws.com
```

## Consequences

**Positive:**
- No disruption to existing email or website DNS records
- ACM certificate is valid and auto-renews (AWS manages renewal validation)
- No migration of the entire domain required

**Negative:**
- DNS changes require manual Squarespace login — not automated via Terraform
- If the certificate is destroyed and recreated, a new validation CNAME must be
  added manually in Squarespace
- Route53 hosted zone exists but is not authoritative (kept for future migration)

## Future

If `patriciolumbe.com` is migrated to Route53 as the authoritative DNS, restore
`aws_route53_record.cert_validation` and `aws_acm_certificate_validation` resources
and remove the manual Squarespace records.
