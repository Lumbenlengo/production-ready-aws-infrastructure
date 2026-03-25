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

}

# Compute
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum instances in ASG"
  type        = number
}

variable "min_size" {
  description = "Minimum instances in ASG"
  type        = number
}

# DNS
variable "domain_name" {
  description = "Domain name"
  type        = string
}

# Security
variable "my_ip" {
  description = "SSH access IP. Empty = use SSM Session Manager (recommended)."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string

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
  description = <<-EOT
    Database password injected into Secrets Manager.

    Never set a default here. Supply via for example:
      export TF_VAR_db_password="..."
    or pass through your CI/CD pipeline secrets.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }
}

variable "api_key" {
  description = <<-EOT
    API key injected into SSM Parameter Store as an encrypted SecureString.

    Never set a default here. Supply via for example:
      export TF_VAR_api_key="..."
    or pass through your CI/CD pipeline secrets.
  EOT
  type        = string
  sensitive   = true
}
