## Production-Ready AWS Infrastructure

Terraform project that provisions a multi-environment AWS platform (`dev`, `staging`, `prod`) with:
- VPC networking, security groups, ALB and WAF
- EC2 Auto Scaling compute layer
- CI/CD with CodePipeline, CodeBuild and CodeDeploy
- Monitoring, compliance controls and secrets management

## Prerequisites

- Terraform `>= 1.5`
- AWS credentials with permission to manage all configured resources
- GitHub OIDC role configured in repository secrets

## Environment Configuration

Environment-specific values are stored in:
- `environments/dev/terraform.tfvars`
- `environments/staging/terraform.tfvars`
- `environments/prod/terraform.tfvars`

Sensitive values are **not** stored in tfvars files and must be supplied via environment variables:

```bash
export TF_VAR_db_password="your-strong-password"
export TF_VAR_api_key="your-api-key"
```

## Local Usage

Initialize Terraform for a specific environment state key:

```bash
terraform init -backend-config="key=dev/terraform.tfstate"
```

Validate and plan:

```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file="environments/dev/terraform.tfvars"
```
