output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "ALB DNS name — use as CNAME in Squarespace DNS"
  value       = module.loadbalancer.alb_dns_name
}

output "website_url" {
  description = "Live API URL"
  value       = "https://${var.domain_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker pushes"
  value       = module.cicd.ecr_repository_url
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = module.secrets.kms_key_arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "subdomain_ns" {
  description = "Route53 hosted zone nameservers"
  value       = module.networking.hosted_zone_name_servers
}
