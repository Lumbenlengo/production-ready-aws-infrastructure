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
# Networking
# ============================================================
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ============================================================
# Storage
# ============================================================
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================================
# Secrets & KMS
# ============================================================
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  db_password  = var.db_password
  api_key      = var.api_key
}

# ============================================================
# Load Balancer
# ============================================================
module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  domain_name       = var.domain_name
  hosted_zone_id    = module.networking.hosted_zone_id
  # deletion_protection enabled in prod via variable
  enable_deletion_protection = var.environment == "prod" ? true : false
}

# ============================================================
# Security (security groups + GuardDuty)
# ============================================================
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  alb_sg_id    = module.loadbalancer.alb_security_group_id
  my_ip        = var.my_ip
}

# ============================================================
# WAF
# ============================================================
module "waf" {
  source = "./modules/waf"

  project_name       = var.project_name
  environment        = var.environment
  enable_association = var.enable_waf_association
  alb_arn            = module.loadbalancer.alb_arn
}

# ============================================================
# Compute (ASG in private subnets)
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
# CI/CD
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
}

# ============================================================
# Monitoring (CloudWatch, SNS, CloudTrail, EventBridge)
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
# Compliance (AWS Config + Backup)
# ============================================================
module "compliance" {
  source = "./modules/compliance"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  dynamodb_table_arn = module.storage.table_arn
  artifact_bucket_id = module.storage.artifact_bucket_id
}
