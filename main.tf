# 1. Networking Module (The Foundation)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# 2. Security Module (The Firewalls)
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

# 3. Load Balancer Module (The Entry Point)
module "loadbalancer" {
  source       = "./modules/loadbalancer"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  # Ensure 'public_subnet_ids' matches the variable name in modules/loadbalancer/variables.tf
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# Root main.tf
# 4. Compute Module (Auto Scaling Group)
module "compute" {
  source           = "./modules/compute"
  project_name     = var.project_name
  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size

  # Connects the list of subnets from the networking module
  public_subnet_ids = module.networking.public_subnet_ids

  # Security and Load Balancer connections
  security_group_id = module.security.web_sg_id
  target_group_arn  = module.loadbalancer.target_group_arn
}