# main.tf (Root)

module "networking" {
  source = "./modules/networking"

  # Passing input values into the module
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}


module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}



module "compute" {
  source            = "./modules/compute"
  project_name      = var.project_name
  subnet_id         = module.networking.public_subnet_ids[0]
  security_group_id = module.security.security_group_id
}