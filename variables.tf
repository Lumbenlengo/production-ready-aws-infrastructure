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
    # Inclusion of 'development' to match common GitHub Environment names
    # Allowing empty string "" prevents errors during the 'terraform init' phase
    condition     = var.environment == "" || contains(["dev", "development", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, development, staging, or prod."
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
# Compute (Auto Scaling Group)
# ==========================================
variable "instance_type" {
  description = "EC2 instance type (e.g., t3.micro)"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
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
# DNS & Domains
# ==========================================
variable "domain_name" {
  description = "The root domain name (e.g., patriciolumbe.com)"
  type        = string
}

# ==========================================
# Security & Monitoring
# ==========================================
variable "my_ip" {
  description = "SSH access IP. Leave empty to use SSM Session Manager (recommended)."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications via SNS"
  type        = string
}

# ==========================================
# GitHub CI/CD Integration
# ==========================================
variable "github_owner" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_repo_url" {
  description = "The full HTTPS URL of the GitHub repository"
  type        = string
}

# ==========================================
# WAF (Web Application Firewall)
# ==========================================
variable "enable_waf_association" {
  description = "Whether to associate WAF with the ALB. Set to true after the ALB is created."
  type        = bool
  default     = false
}

# ==========================================
# Secrets (Injected via Environment Variables)
# ==========================================
variable "db_password" {
  description = "Database password for AWS Secrets Manager. Must be 16+ characters."
  type        = string
  sensitive   = true

  validation {
    # Condition allows empty string during 'init' but enforces 16 chars during 'plan/apply'
    condition     = var.db_password == "" || length(var.db_password) >= 16
    error_message = "The db_password must be at least 16 characters long."
  }
}

variable "api_key" {
  description = "API Key stored in SSM Parameter Store as a SecureString"
  type        = string
  sensitive   = true
}
