 # ADR 002: WAF Managed Rules Selection

## Status
Accepted

## Context
We need to protect our web application from common web exploits. AWS WAF offers both custom rules and managed rule groups.

## Decision
We selected the following AWS managed rule groups:
1. **AWSManagedRulesCommonRuleSet**: Protects against SQL injection, XSS, etc.
2. **AWSManagedRulesAmazonIpReputationList**: Blocks known malicious IPs
3. **Rate-based rule**: 1000 requests per 5 minutes per IP

## Consequences
- Reduced operational overhead (AWS maintains the rules)
- Protection against OWASP Top 10 vulnerabilities
- Rate limiting prevents DDoS and brute force attacks
- Additional cost for WAF usage (~$5/month + $1 per million requests)