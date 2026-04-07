# modules/secrets/main.tf

# ── KMS Key ───────────────────────────────────────────────────────────

resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# ── Secrets Manager — DB credentials ─────────────────────────────────

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}-db-secret-${var.environment}"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    password = var.db_password
    engine   = "postgres"
    username = "app"
  })
}

# ── SSM Parameter Store — API key ─────────────────────────────────────

resource "aws_ssm_parameter" "api_key" {
  name   = "/${var.project_name}/${var.environment}/api/key"
  type   = "SecureString"
  value  = var.api_key
  key_id = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-api-key"
  }
}

# ── SSM Parameter Store — App config ─────────────────────────────────

resource "aws_ssm_parameter" "app_config" {
  name  = "/${var.project_name}/${var.environment}/app/config"
  type  = "String"
  value = jsonencode({
    environment  = var.environment
    project_name = var.project_name
    log_level    = var.environment == "prod" ? "WARNING" : "DEBUG"
  })

  tags = {
    Name = "${var.project_name}-app-config"
  }
}

# ── SSM Parameter Store — SLO error budget flag (Path A+) ────────────
# Lambda checks this flag before allowing CodePipeline to deploy.
# When error budget is consumed, this is set to "LOCKED".

resource "aws_ssm_parameter" "slo_deployment_gate" {
  name  = "/${var.project_name}/${var.environment}/slo/deployment-gate"
  type  = "String"
  value = "OPEN"

  tags = {
    Name = "${var.project_name}-slo-gate"
  }
}
