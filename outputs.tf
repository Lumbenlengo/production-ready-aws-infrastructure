# ROOT OUTPUTS
# These values are extracted from the modules to be displayed in the terminal

# 1. Networking Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets where the ASG and ALB are running"
  value       = module.networking.public_subnet_ids
}

# 2. Compute/Load Balancer Outputs
output "alb_dns_name" {
  description = "The DNS name of the load balancer. USE THIS TO ACCESS YOUR APP!"
  value       = module.loadbalancer.alb_dns_name
}

# 3. Auto Scaling Group Name (Useful for AWS CLI monitoring)
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.compute.asg_name
}