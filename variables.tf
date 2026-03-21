# Project metadata
variable "project_name" {
  description = "Base name for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Compute
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum instances in ASG"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum instances in ASG"
  type        = number
  default     = 2
}

# DNS
variable "domain_name" {
  description = "Domain name (e.g., app.lumbenlengo.com)"
  type        = string
}

# Security
variable "my_ip" {
  description = "Your public IP for SSH access (format: x.x.x.x/32). Prefer SSM — leave empty to disable SSH."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "admin@lumbenlengo.com"
}

# GitHub
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

# WAF
variable "enable_waf_association" {
  description = "Associate WAF with ALB. Set to true after the ALB exists."
  type        = bool
  default     = false
}

# Secrets
variable "db_password" {
  description = "Database password injected into Secrets Manager."
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key injected into SSM Parameter Store as SecureString."
  type        = string
  sensitive   = true
}
