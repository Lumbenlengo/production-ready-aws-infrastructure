# ==========================================
# Project Metadata
# ==========================================
variable "project_name" {
  description = "Base name used for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# ==========================================
# Networking
# ==========================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# ==========================================
# Compute
# ==========================================
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
}

# ==========================================
# DNS & SSL
# ==========================================
variable "domain_name" {
  description = "Domain name for the API (e.g. api.patriciolumbe.com)"
  type        = string
}

variable "my_ip" {
  description = "Trusted IP for SSH access. Set to null to disable SSH."
  type        = string
  default     = null
}

# ==========================================
# Monitoring & Alerts
# ==========================================
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

# ==========================================
# CI/CD
# ==========================================
variable "github_owner" {
  description = "GitHub username or organisation"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_repo_url" {
  description = "Full GitHub repository URL"
  type        = string
}

variable "enable_waf_association" {
  description = "Associate WAF ACL with the ALB. Set to true after first apply."
  type        = bool
  default     = false
}

# ==========================================
# Load Balancer
# ==========================================
variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB. Always true in prod."
  type        = bool
  default     = false
}

# ==========================================
# Secrets — injected via environment variables
# ==========================================
variable "db_password" {
  description = "Database password — minimum 16 characters"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }
}

variable "api_key" {
  description = "API key stored in SSM Parameter Store"
  type        = string
  sensitive   = true
}
