# modules/loadbalancer/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the ACM certificate and Route 53 record"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID (from networking module)"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Should be true in prod."
  type        = bool
  default     = false
}
