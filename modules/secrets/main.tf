# modules/secrets/main.tf

# KMS Key — used to encrypt secrets and SSM parameters
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-kms"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# Secrets Manager — application database credentials
# The password has no default: it must be passed explicitly via
#   TF_VAR_db_password=... terraform apply
# or injected by the CI/CD pipeline. It is never committed to source control.
resource "aws_secretsmanager_secret" "db" {
  name       = "${var.project_name}-db-secret-${var.environment}"
  kms_key_id = aws_kms_key.main.arn

  # Prevent accidental deletion in production
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name        = "${var.project_name}-db-secret"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
    host     = "localhost"
    port     = 3306
  })
}

# SSM Parameter Store — plain application configuration
resource "aws_ssm_parameter" "app_config" {
  name = "/${var.project_name}/${var.environment}/app/config"
  type = "String"
  value = jsonencode({
    log_level       = "INFO"
    max_connections = 100
    timeout_seconds = 30
  })

  tags = {
    Name        = "${var.project_name}-app-config"
    Environment = var.environment
  }
}

# SSM Parameter Store — encrypted API key
resource "aws_ssm_parameter" "api_key" {
  name   = "/${var.project_name}/${var.environment}/api/key"
  type   = "SecureString"
  value  = var.api_key
  key_id = aws_kms_key.main.arn

  tags = {
    Name        = "${var.project_name}-api-key"
    Environment = var.environment
  }
}
