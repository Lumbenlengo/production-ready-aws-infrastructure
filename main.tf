terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ============================================================
# L0 — Foundation
# Networking is the base layer. Everything else depends on it.
# Apply this first on a fresh account.
# ============================================================
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ============================================================
# L1 — Data & Secrets
# Independent of compute and networking outputs.
# Safe to apply in parallel with networking.
# ============================================================
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  db_password  = var.db_password
  api_key      = var.api_key
}

# ============================================================
# L2 — Platform
# Load balancer, security groups, WAF.
# Depends on: networking (VPC, subnets, hosted zone).
# ============================================================
module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  domain_name       = var.domain_name
  hosted_zone_id    = module.networking.hosted_zone_id

  # Simplified bool — the comparison already returns a bool value.
  enable_deletion_protection = var.environment == "prod"
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.loadbalancer.alb_security_group_id
  my_ip        = var.my_ip
}

module "waf" {
  source = "./modules/waf"

  project_name       = var.project_name
  environment        = var.environment
  enable_association = var.enable_waf_association
  alb_arn            = module.loadbalancer.alb_arn
}

# ============================================================
# L3 — Compute
# ASG instances in private subnets behind the ALB.
# Depends on: networking, security, loadbalancer, storage.
# ============================================================
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.web_sg_id
  target_group_arn   = module.loadbalancer.target_group_arn
  dynamodb_table_arn = module.storage.table_arn

}

# ============================================================
# L4 — Observability
# Must be applied before CI/CD so alarm names exist when
# CodeDeploy deployment group is created.
# Depends on: loadbalancer (ALB ARN), compute (ASG name).
# ============================================================
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.loadbalancer.alb_arn
  asg_name     = module.compute.asg_name
  alert_email  = var.alert_email
}

# ============================================================
# L5 — CI/CD
# Pipeline, CodeDeploy, ECR.
# Depends on: storage, compute, loadbalancer, monitoring.
# Explicit depends_on ensures monitoring alarms exist before
# the CodeDeploy deployment group references them by name.
# ============================================================
module "cicd" {
  source = "./modules/cicd"

  project_name        = var.project_name
  environment         = var.environment
  github_owner        = var.github_owner
  github_repo_name    = var.github_repo_name
  github_repo_url     = var.github_repo_url
  artifact_bucket_id  = module.storage.artifact_bucket_id
  artifact_bucket_arn = module.storage.artifact_bucket_arn
  asg_name            = module.compute.asg_name
  target_group_name   = module.loadbalancer.target_group_name
  sns_topic_arn       = module.monitoring.sns_topic_arn
  rollback_alarm_names = [
    module.monitoring.high_cpu_alarm_name,
    module.monitoring.high_5xx_alarm_name,
  ]

  # Explicit dependency — monitoring alarms must exist before
  # CodeDeploy deployment group references them by name.
  # Without this, a parallel apply could create the deployment
  # group before the alarms exist and fail with a not-found error.
  depends_on = [module.monitoring]
}

# ============================================================
# L6 — Compliance
# AWS Config and Backup. No other module depends on this.
# Safe to apply last or in parallel with CI/CD.
# Depends on: networking, storage.
# ============================================================
module "compliance" {
  source = "./modules/compliance"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  dynamodb_table_arn = module.storage.table_arn
  artifact_bucket_id = module.storage.artifact_bucket_id
}
