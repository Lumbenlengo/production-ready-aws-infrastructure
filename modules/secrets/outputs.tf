# modules/secrets/outputs.tf

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN for DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "app_config_parameter_name" {
  description = "SSM parameter name for app config"
  value       = aws_ssm_parameter.app_config.name
}
