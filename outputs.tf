

# ROOT OUTPUTS
# These values are extracted from the modules to be displayed in the terminal

# 1. Networking Outputs
output "vpc_id" {
  description = "The ID of the VPC created by the networking module"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets for external access"
  value       = module.networking.public_subnet_ids
}

# 2. Compute Outputs
output "ec2_public_ip" {
  description = "The Public IP address to access the web server"
  value       = module.compute.ec2_public_ip
}

output "ec2_instance_id" {
  description = "The unique ID of the web server instance"
  value       = module.compute.ec2_instance_id
}