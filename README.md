# production-ready-aws-infrastructure

Production-grade AWS infrastructure — Multi-AZ EC2 ASG, Blue/Green CodeDeploy, WAF, GuardDuty, Security Hub, SLO error budgets, zero static keys via OIDC. Live at [api.patriciolumbe.com](https://api.patriciolumbe.com).

```
curl https://api.patriciolumbe.com/health/live
```
Call it repeatedly — watch different availability zones respond. Multi-AZ load balancing, live in 10 seconds.

---

## Architecture

| Layer | Service | Configuration | Module |
|---|---|---|---|
| DNS | Route53 | Hosted zone | networking/ |
| SSL | ACM | api.patriciolumbe.com, DNS validated | loadbalancer/ |
| WAF | AWS WAFv2 | CommonRuleSet + KnownBadInputs + rate limit | waf/ |
| Threat detection | GuardDuty | Detector + EventBridge HIGH → SNS | security/ |
| Security posture | Security Hub | CIS + AWS Foundational standards | security/ |
| IAM analysis | IAM Access Analyzer | Account-level, detects overly permissive policies | security/ |
| Load balancing | ALB | HTTPS 443, HTTP redirect 80→443, /health check | loadbalancer/ |
| Compute | EC2 ASG | min=1 max=2 (dev), t3.micro, Target Tracking 50% CPU, Multi-AZ | compute/ |
| Deployment | CodeDeploy | Blue/Green on ASG, lifecycle hooks, alarm rollback | cicd/ |
| Pipeline | CodePipeline | Source → Build → Approve → Deploy, GitHub connection | cicd/ |
| Build | CodeBuild | buildspec.yml: test → Docker build → ECR push | cicd/ |
| Registry | ECR | Docker images, lifecycle policy: keep last 10 | cicd/ |
| Secrets | Secrets Manager | DB credentials, KMS encrypted, 7-day recovery | secrets/ |
| Config | Parameter Store | API key (SecureString), app config, SLO gate | secrets/ |
| IaC auth | GitHub Actions OIDC | Plan on PR, apply on merge — zero static keys | .github/ |
| Monitoring | CloudWatch | Dashboards + alarms (CPU, latency p95, error rate, unhealthy hosts) | monitoring/ |
| SLO enforcement | Lambda | Error budget checker every 5 min, blocks deploys on breach | monitoring/ |
| Audit | CloudTrail | All regions, S3 delivery, file validation | monitoring/ |
| Compliance | AWS Config | 4 rules: no-public-ip, restricted-ssh, encrypted-volumes, s3-public | compliance/ |
| Backup | AWS Backup | Daily snapshots, 14-day retention (30 in prod) | compliance/ |
| State | S3 + DynamoDB | Remote backend, versioned, encrypted, lock table | backend.tf |
| App | FastAPI Python | GET /health/live (returns AZ+hostname), GET /items, POST /items | app/ |
| Network | VPC Flow Logs | ALL traffic logged to CloudWatch | networking/ |

---

## Why this matters to clients and recruiters

- **No live project** is the most common junior gap. This one is live — `/health/live` returns AZ proves Multi-AZ is real, not a slide.
- **Terraform module structure** signals separation of concerns — not a single flat `main.tf`.
- **OIDC with no static keys** is a senior-level security practice visible in the GitHub Actions workflow.
- **Blue/Green CodeDeploy** proves zero-downtime deployment understanding — the thing that causes most production incidents.
- **Security Hub + IAM Access Analyzer** (Path A+) is genuine compliance posture, not just GuardDuty enabled.
- **SLO error budgets with automatic deployment gate** (Path A+) is real SRE methodology — extremely rare in portfolios.
- **CloudTrail + AWS Config + GuardDuty** shows compliance thinking, not just deployment thinking.

---

## Folder structure

```
production-ready-aws-infrastructure/
├── backend.tf                    # S3 + DynamoDB remote state
├── main.tf                       # Root module — calls all child modules
├── variables.tf / outputs.tf
├── provider.tf
├── modules/
│   ├── networking/               # VPC, subnets, NAT GW, IGW, route tables, VPC Flow Logs
│   ├── compute/                  # ASG, Launch Template, IAM instance role
│   ├── loadbalancer/             # ALB, TG, listeners, ACM
│   ├── security/                 # OIDC provider, GuardDuty, Security Hub, IAM Access Analyzer
│   ├── monitoring/               # CloudWatch, SNS, alarms, CloudTrail, SLO Lambda
│   ├── cicd/                     # CodePipeline, CodeBuild, CodeDeploy, ECR
│   ├── secrets/                  # Secrets Manager, Parameter Store, KMS
│   ├── compliance/               # AWS Config rules, AWS Backup
│   ├── storage/                  # S3 artifacts bucket, DynamoDB metrics table
│   └── waf/                      # WAFv2 ACL, managed rules, rate limiting
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars
├── app/
│   ├── main.py                   # FastAPI: /health/live, /health/ready, /items
│   ├── Dockerfile                # Multi-stage build, non-root user
│   ├── buildspec.yml             # CodeBuild: test → Docker build → ECR push
│   ├── appspec.yml               # CodeDeploy lifecycle hooks
│   └── scripts/                  # stop_server.sh, start_server.sh, health_check.sh
├── .github/workflows/
│   ├── aws-check.yml             # Validate + plan on every PR
│   ├── deploy-dev.yml            # Auto-apply on push to develop
│   ├── deploy-staging.yml        # Auto-apply on merge to main
│   ├── deploy-prod.yml           # Manual approval, triggered by git tag v*.*.*
│   └── destroy-dev.yml           # Manual destroy with DESTROY confirmation
└── docs/
    ├── slo.md                    # SLO definitions and error budget runbook
    └── adr/
        ├── 001-oidc-over-static-keys.md
        ├── 002-waf-managed-rules.md
        └── 003-acm-dns-validation-squarespace.md
```

---

## Deployment flow

```
develop branch  →  deploy-dev.yml      →  DEV auto-apply
     ↓ PR to main
main branch     →  deploy-staging.yml  →  STAGING auto-apply
     ↓ git tag v1.0.0
tag v*.*.*      →  deploy-prod.yml     →  PROD manual approval required
```

---

## Cost estimate

| Environment | Monthly estimate |
|---|---|
| Dev (min=1, t3.micro) | ~$28/month |
| Staging (min=1, t3.micro) | ~$28/month |
| Prod (min=2, t3.small) | ~$65/month |

Main cost drivers: ALB ($16), NAT Gateway ($32), EC2 instances, CloudTrail, WAF.

---

## GitHub Secrets required

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::678632990341:role/GitHubActions-Terraform-Role` |
| `DB_PASSWORD` | Minimum 16 characters |
| `API_KEY` | Any non-empty string |

Set per environment in GitHub → Settings → Environments.

---

## ADRs

- [ADR 001 — OIDC Federation over Static IAM Keys](docs/adr/001-oidc-over-static-keys.md)
- [ADR 002 — AWS WAF with Managed Rule Groups](docs/adr/002-waf-managed-rules.md)
- [ADR 003 — ACM DNS Validation via Squarespace](docs/adr/003-acm-dns-validation-squarespace.md)

---

*Built by [Patricio Lumbe](https://patriciolumbe.com)*
