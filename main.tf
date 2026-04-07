
# ==========================================
# 1. BASE (Foundation)
# ==========================================
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  environment  = var.environment
  db_password  = var.db_password
  api_key      = var.api_key
}


module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.secrets.kms_key_arn
}


# ==========================================
# 2. (Infrastructure)
# ==========================================
module "loadbalancer" {
  source                     = "./modules/loadbalancer"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  domain_name                = var.domain_name
  hosted_zone_id             = module.networking.hosted_zone_id
  enable_deletion_protection = var.enable_deletion_protection
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  my_ip        = var.my_ip
  alb_sg_id    = module.loadbalancer.alb_sg_id
}

module "waf" {
  source                 = "./modules/waf"
  project_name           = var.project_name
  environment            = var.environment
  alb_arn                = module.loadbalancer.alb_arn
  enable_waf_association = var.enable_waf_association
  depends_on             = [module.loadbalancer]
}

# ==========================================
# 3.(Application)
# ==========================================
module "compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  instance_type      = var.instance_type
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  web_sg_id          = module.security.web_sg_id
  target_group_arn   = module.loadbalancer.target_group_arn
  kms_key_arn        = module.secrets.kms_key_arn

}
# ==========================================
# 4. (Observability)
# ==========================================
module "monitoring" {
  source                  = "./modules/monitoring"
  project_name            = var.project_name
  environment             = var.environment
  alert_email             = var.alert_email
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.loadbalancer.alb_arn_suffix
  target_group_arn_suffix = module.loadbalancer.target_group_arn_suffix
}

# ==========================================
# 5. (Deployment)
# ==========================================
module "cicd" {
  source               = "./modules/cicd"
  project_name         = var.project_name
  environment          = var.environment
  github_owner         = var.github_owner
  github_repo_name     = var.github_repo_name
  artifact_bucket_arn  = module.storage.artifact_bucket_arn
  artifact_bucket_id   = module.storage.artifact_bucket_id
  asg_name             = module.compute.asg_name
  target_group_name    = module.loadbalancer.target_group_name
  sns_topic_arn        = module.monitoring.sns_topic_arn
  rollback_alarm_names = module.monitoring.rollback_alarm_names
}

# ==========================================
# 6. (Governance)
# ==========================================
module "compliance" {
  source             = "./modules/compliance"
  project_name       = var.project_name
  environment        = var.environment
  dynamodb_table_arn = module.storage.dynamodb_table_arn
  artifact_bucket_id = module.storage.artifact_bucket_id
  sns_topic_arn      = module.monitoring.sns_topic_arn
}