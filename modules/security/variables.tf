# modules/security/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "alb_sg_id" {
  description = "ALB security group ID — web_sg allows ingress from this group only"
  type        = string
}

variable "my_ip" {
  description = "Trusted IP for SSH access (x.x.x.x/32). Set to null to disable SSH entirely."
  type        = string
  default     = null
}
