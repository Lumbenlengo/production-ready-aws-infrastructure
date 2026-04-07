output "kms_key_arn" {
  value = aws_kms_key.main.arn
}

output "kms_key_id" {
  value = aws_kms_key.main.key_id
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "api_key_parameter_name" {
  value = aws_ssm_parameter.api_key.name
}

output "slo_gate_parameter_name" {
  value = aws_ssm_parameter.slo_deployment_gate.name
}
