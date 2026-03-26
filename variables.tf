# ==========================================
# Project Metadata
# ==========================================
variable "project_name" {
  description = "Base name for all resources"
  type        = string
}


variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
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

# ==========================================
# DNS & Security
# ==========================================
variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "my_ip" {
  description = "IP for SSH access"
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email for CloudWatch notifications"
  type        = string
}

# ==========================================
# CI/CD & WAF
# ==========================================
variable "github_owner" {
  description = "GitHub username/org"
  type        = string
}

variable "github_repo_name" {
  description = "Repository name"
  type        = string
}

variable "github_repo_url" {
  description = "Full repository URL"
  type        = string
}

variable "enable_waf_association" {
  description = "Associate WAF with ALB"
  type        = bool
  default     = false
}

# ==========================================
# Secrets (Injected via Environment)
# ==========================================
variable "db_password" {
  description = "Database password (min 16 chars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "The db_password must be at least 16 characters long."
  }
}

variable "api_key" {
  description = "API Key for SSM"
  type        = string
  sensitive   = true
}