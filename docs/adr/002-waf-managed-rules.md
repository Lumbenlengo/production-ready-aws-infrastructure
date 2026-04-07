# ADR 002 — AWS WAF with Managed Rule Groups

**Date:** 2025-03-01
**Status:** Accepted

## Context

The ALB is publicly accessible on ports 80 and 443. Without a WAF, the application
is exposed to OWASP Top 10 attacks (SQL injection, XSS, path traversal), known
malicious IPs, and volumetric abuse by a single client.

## Decision

Deploy AWS WAFv2 with four rule groups in priority order:

| Priority | Rule | Action |
|---|---|---|
| 1 | AWSManagedRulesCommonRuleSet | Count/Block |
| 2 | IP Rate Limit (1000 req/5min) | Block |
| 3 | AWSManagedRulesKnownBadInputsRuleSet | Count/Block |
| 4 | AWSManagedRulesAmazonIpReputationList | Count/Block |

The WAF is associated with the ALB after the first `terraform apply` via the
`enable_waf_association` variable. This avoids a circular dependency on the first
deploy (ALB must exist before WAF can be associated).

## Consequences

**Positive:**
- AWS-maintained rule groups — threat signatures updated automatically
- Rate limiting protects against scraping and brute force without custom logic
- All blocked requests are logged to CloudWatch for forensic analysis
- No custom rule maintenance required

**Negative:**
- Managed rules add ~$10/month at dev traffic levels (WAF ACL + rule group fees)
- CommonRuleSet can produce false positives on non-standard API payloads
- First deploy requires two applies (WAF created, then associated)

## Alternatives Considered

- **No WAF:** Rejected — the ALB alone cannot block Layer 7 attacks
- **Custom WAF rules:** Rejected — requires ongoing maintenance of threat signatures
- **Cloudflare:** Rejected — adds external dependency and DNS complexity
