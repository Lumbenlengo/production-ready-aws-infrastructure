# Production-Ready AWS Infrastructure

> A production-style AWS environment built with Terraform, following modern cloud engineering, security, and DevOps practices: Infrastructure as Code, Multi-AZ high availability, automated CI/CD, and defense-in-depth security.

<p>
  <img src="https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform&logoColor=white" height="20">
  <img src="https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws&logoColor=white" height="20">
  <img src="https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white" height="20">
</p>
<p>
  <img width="50" height="50" alt="WAF" src="https://github.com/user-attachments/assets/ad806072-d463-4260-a24c-32ea68021a64" />
  <img width="50" height="50" alt="AWS CloudTrail" src="https://github.com/user-attachments/assets/5fc9d172-1f42-4139-8131-2554f1ca0b0f" />
  <img width="50" height="50" alt="Amazon CloudWatch" src="https://github.com/user-attachments/assets/c43bbdee-c510-4c4b-8189-dfc972d34397" />
  <img width="50" height="50" alt="AWS Config" src="https://github.com/user-attachments/assets/a82401d1-0ba3-4c27-8a21-b239c3423f88" />
  <img width="50" height="50" alt="AWS Security Hub" src="https://github.com/user-attachments/assets/8353bcf5-ebfe-44f7-b6a9-5461692b3e42" />
  <img width="50" height="50" alt="AWS Secrets Manager" src="https://github.com/user-attachments/assets/07c91d5a-9601-415d-8fd9-cd6522b66ac8" />
  <img width="50" height="50" alt="AWS Identity and Access Management (IAM)" src="https://github.com/user-attachments/assets/05b64da2-347c-4ec3-869d-c43ae6c3a31b" />
  <img width="50" height="50" alt="Amazon DynamoDB" src="https://github.com/user-attachments/assets/df976202-72ee-457b-b58f-9509d8ee2427" />
  <img width="50" height="50" alt="Amazon Route 53" src="https://github.com/user-attachments/assets/fe0d34b0-e237-46ea-942a-9483d7abc4af" />
  <img width="50" height="50" alt="Elastic Load Balancing (ELB)" src="https://github.com/user-attachments/assets/701f7251-1288-4bf5-ad96-8f00b486af7e" />
  <img width="50" height="50" alt="Amazon EC2 Auto Scaling" src="https://github.com/user-attachments/assets/3ec28aa2-857b-4daf-bca4-a7600dd042d9" />
  <img width="50" height="50" alt="Amazon EC2" src="https://github.com/user-attachments/assets/d0917868-b83b-4bbe-b0a2-967e169ed8ea" />
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/611b8302-7cb5-4fba-94d0-de72d7fe1e47" width="100%" alt="Production ready" />
</p>

## Overview

This project demonstrates how to design, build, and operate a production-grade AWS environment using Infrastructure as Code not just a single Terraform file that spins up a server, but a full environment: networking, compute, security, observability, and automated deployments, all reproducible across dev, staging, and production.

It touches five disciplines at once:

- **Infrastructure as Code** every resource is defined in Terraform, nothing is clicked into existence in the console
- **Cloud Architecture** Multi-AZ networking, load balancing, and auto scaling
- **DevOps / CI/CD** automated build, test, and deployment pipeline
- **Security** WAF, threat detection, compliance scanning, and zero long-lived credentials
- **Site Reliability Engineering** dashboards, alarms, and an automated deployment gate tied to error budgets

The goal was to build something close to what actually runs behind a real product, not a demo that only works once.

---

## Key Features

- Multi-AZ networking for high availability
- Application Load Balancer with HTTPS (ACM-managed certificate)
- EC2 Auto Scaling Group across two Availability Zones
- Infrastructure fully defined and versioned in Terraform
- Automated deployments via GitHub Actions (OIDC, zero static AWS keys)
- AWS WAF with managed rule groups and rate limiting
- Amazon GuardDuty threat detection
- AWS Security Hub (CIS + AWS Foundational standards)
- IAM Access Analyzer
- AWS Config compliance rules
- AWS Backup with scheduled snapshots
- CloudTrail audit logging across all regions
- CloudWatch dashboards, alarms, and VPC Flow Logs
- Secrets Manager and Parameter Store for configuration and credentials
- KMS encryption at rest
- Modular, reusable Terraform structure across environments

---

## Architecture

Traffic enters through **Route53**, passes through **AWS WAF**, and reaches the **Application Load Balancer**, which terminates HTTPS using an ACM certificate. The ALB distributes requests to EC2 instances running inside private subnets, spread across two Availability Zones and managed by an Auto Scaling Group.

Each Availability Zone has its own public subnet (with a NAT Gateway for outbound traffic) and private application subnets, so a single AZ failure never takes the application down. The application instances access DynamoDB directly for data persistence.

Security and governance run alongside the application layer rather than bolted on afterward: WAF filters requests at the edge, GuardDuty and Security Hub continuously monitor for threats and misconfigurations, IAM Access Analyzer checks for overly permissive policies, AWS Config enforces compliance rules, and CloudTrail logs every API call. CloudWatch ties observability together with dashboards, alarms, and VPC Flow Logs, and alarm breaches feed into SNS notifications.

The full flow, end to end:

```
A developer pushes code
        ↓
GitHub Actions starts
        ↓
Terraform validates the infrastructure
        ↓
Docker image is built
        ↓
Image is pushed to ECR
        ↓
Infrastructure is updated
        ↓
Application is deployed to the Auto Scaling Group
        ↓
CloudWatch verifies health
        ↓
Monitoring continues
```

> **Note on the diagram:** it intentionally shows only what exists in this repo's Terraform today — no CloudFront, no RDS, no Prometheus/OpenTelemetry. Data persistence is DynamoDB, not a relational database.

---

## Repository Structure

```
production-ready-aws-infrastructure/
├── backend.tf                    # S3 + DynamoDB remote state
├── main.tf                       # Root module — wires up all child modules
├── variables.tf / outputs.tf
├── provider.tf
├── Dockerfile                     # Multi-stage build, non-root user
├── modules/
│   ├── networking/                # VPC, subnets, NAT GW, IGW, route tables, VPC Flow Logs
│   ├── compute/                   # ASG, launch template, IAM instance role
│   ├── loadbalancer/               # ALB, target group, listeners, ACM
│   ├── security/                   # OIDC provider, GuardDuty, Security Hub, IAM Access Analyzer
│   ├── monitoring/                 # CloudWatch, SNS, alarms, CloudTrail, SLO Lambda
│   ├── secrets/                    # Secrets Manager, Parameter Store, KMS
│   ├── compliance/                 # AWS Config rules, AWS Backup
│   ├── storage/                    # S3 artifacts bucket, DynamoDB table
│   └── waf/                        # WAFv2 ACL, managed rules, rate limiting
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars
├── app/
│   ├── main.py                     # FastAPI: /health/live, /health/ready, /items
│   ├── api/                        # routes.py
│   ├── core/                       # aws_service.py, monitoring.py
│   ├── buildspec.yml                # CodeBuild: test → Docker build → ECR push
│   ├── appspec.yml                  # CodeDeploy lifecycle hooks
│   └── scripts/                     # start/stop server, health check, install deps
├── .github/workflows/
│   ├── validate.yml                 # Validate + plan on every PR
│   ├── deploy-dev.yml               # Auto-apply on push to develop
│   ├── deploy-staging.yml           # Auto-apply on push to main
│   ├── deploy-production.yml        # Manual approval, triggered by tag v*.*.*
│   └── destroy-production.yml       # Manual destroy, requires typed confirmation
└── docs/
    ├── slo.md                       # SLO definitions and error-budget runbook
    └── adr/                         # Architecture Decision Records
```

---

## Terraform Modules

| Module | Responsibility |
|---|---|
| `networking` | VPC, public/private subnets, NAT Gateways, route tables, VPC Flow Logs |
| `compute` | Launch template, Auto Scaling Group, instance IAM role |
| `loadbalancer` | ALB, target group, HTTPS listener, ACM certificate |
| `security` | GitHub OIDC provider, GuardDuty, Security Hub, IAM Access Analyzer |
| `waf` | WAFv2 web ACL, AWS managed rule groups, rate-based rule | 
| `secrets` | Secrets Manager, Parameter Store, KMS key |
| `monitoring` | CloudWatch dashboards/alarms, SNS topics, CloudTrail, SLO Lambda |
| `compliance` | AWS Config rules, AWS Backup plan |
| `storage` | S3 artifact bucket, DynamoDB table |

Every module pulls environment-specific values from `environments/{dev,staging,prod}/terraform.tfvars`, allowing the exact same code to deploy three isolated environments—development, staging, and production—with different sizing and safety rules. For instance, you can use smaller instances and shorter backup retention in development, while applying stricter, more secure settings in production.

> **Note on CI/CD Architecture:** GitHub Actions handles the entire integration and deployment flow, managing both the application build-and-deploy process and the authenticated Terraform runs. This keeps the delivery pipeline lean, modern, and efficient without any unnecessary orchestration overhead.

## Security

Security is designed in from the networking layer up, not added afterward:

- **Zero static AWS credentials.** GitHub Actions authenticates via OIDC and assumes a short-lived, scoped IAM role — no access keys stored anywhere. See [ADR 001](docs/adr/001-oidc-over-static-keys.md).
- **Edge protection.** AWS WAF filters requests with managed rule groups (common exploits, known bad inputs) plus a rate-based rule, before traffic ever reaches the ALB. See [ADR 002](docs/adr/002-waf-managed-rules.md).
- **Threat detection.** GuardDuty monitors for anomalous account and network activity; high-severity findings route to SNS via EventBridge.
- **Compliance posture.** Security Hub evaluates the account against CIS and AWS Foundational benchmarks; IAM Access Analyzer flags overly permissive policies; AWS Config enforces rules like no-public-ip, restricted-ssh, and encrypted-volumes.
- **Audit trail.** CloudTrail logs every API call across all regions with log file validation enabled.
- **Secrets never touch the app code.** Database credentials live in Secrets Manager (KMS-encrypted); configuration values live in Parameter Store.

---

## Monitoring & Reliability

CloudWatch dashboards track CPU, p95 latency, error rate, and unhealthy host count, with alarms wired directly into CodeDeploy as rollback triggers — a bad deploy rolls itself back before it becomes an incident.

On top of that, a small Lambda function checks the 5xx error rate every 5 minutes against an error budget. If the error rate crosses the threshold, it locks a Parameter Store flag that the pipeline checks before every deployment — releases can be blocked automatically instead of relying on someone noticing at 2 a.m. Full details and the recovery runbook are in [docs/slo.md](docs/slo.md).

---

## Technology Stack

| Category | Technology |
|---|---|
| IaC | Terraform |
| Cloud provider | AWS |
| Compute | EC2, Auto Scaling |
| Networking | VPC, ALB, Route53, NAT Gateway |
| Data | DynamoDB |
| Containers | Docker, ECR |
| CI/CD | GitHub Actions |
| Security | WAF, GuardDuty, Security Hub, IAM Access Analyzer, AWS Config |
| Secrets | Secrets Manager, Parameter Store, KMS |
| Observability | CloudWatch, CloudTrail, VPC Flow Logs, SNS |
| Application | FastAPI (Python) |

---

## Project Highlights

- **`/health/live` returns the AZ and hostname of whichever instance answered** an easy way to prove Multi-AZ failover is real, not just declared in a `.tf` file.
- **The deployment pipeline can block itself.** The SLO Lambda locks deployments automatically when the error budget is breached  real SRE methodology that most portfolio projects don't attempt.
- **No IAM access keys exist anywhere.** Every credential used by CI is short-lived and scoped via OIDC.
- **Security Hub + IAM Access Analyzer + AWS Config together** actual compliance posture, not just "GuardDuty is on."

---

## Getting Started

Requirements: Terraform ≥ 1.5, an AWS account, and the AWS CLI configured locally (or the GitHub Actions OIDC role, for CI).

```bash
git clone https://github.com/<your-username>/production-ready-aws-infrastructure.git
cd production-ready-aws-infrastructure

# Initialize with the dev backend
terraform init -backend-config=environments/dev/backend.hcl

# Review the plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

Staging and production follow the same pattern with their respective `terraform.tfvars`, but in normal use they're applied through the GitHub Actions workflows described above, not run by hand.

Required GitHub Secrets (set per environment under **Settings → Environments**):

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | IAM role assumed via OIDC |
| `DB_PASSWORD` | 16+ characters |
| `API_KEY` | Any non-empty string |
| `ECR_REPOSITORY_NAME` | ECR repository the app image is pushed to |

---

## Future Improvements

- Add a staging smoke-test suite that runs automatically after each deploy
- Extend the SLO Lambda to publish error-budget burn rate to a dashboard, not just a pass/fail gate
- Add a cost dashboard per environment (Cost Explorer tags are already in place)

---

## Architecture Decision Records

- [ADR 001 — OIDC Federation over Static IAM Keys](docs/adr/001-oidc-over-static-keys.md)
- [ADR 002 — AWS WAF with Managed Rule Groups](docs/adr/002-waf-managed-rules.md)
- [ADR 003 — ACM DNS Validation via Squarespace](docs/adr/003-acm-dns-validation-squarespace.md)

---

## Author

Built by [Patricio Lumbe](https://patriciolumbe.com)<br>
https://patriciolumbe.com


