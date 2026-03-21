# modules/secrets/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "db_password" {
  description = <<-EOT
    Database password stored in Secrets Manager.
    Never set a default here. Supply via:
      export TF_VAR_db_password="$(aws secretsmanager get-secret-value ...)"
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
  description = "API key stored as an encrypted SSM SecureString parameter"
  type        = string
  sensitive   = true
}
