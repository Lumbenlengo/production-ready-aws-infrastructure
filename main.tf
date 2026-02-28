# 1. Networking Module (The Foundation)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# 2. Security Module (The Firewalls)
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

# 3. Compute Module (The Worker)
module "compute" {
  source       = "./modules/compute"
  project_name = var.project_name
  subnet_id    = module.networking.public_subnet_ids[0]
  # Use the web_security_group_id for the server
  security_group_id = module.security.web_security_group_id
}

# 4. Load Balancer Module (The Entry Point)
module "loadbalancer" {
  source                = "./modules/loadbalancer"
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# 5. Target Group Attachment (The Bridge)
resource "aws_lb_target_group_attachment" "web_server_attachment" {
  target_group_arn = module.loadbalancer.target_group_arn
  target_id        = module.compute.ec2_instance_id
  port             = 80
}