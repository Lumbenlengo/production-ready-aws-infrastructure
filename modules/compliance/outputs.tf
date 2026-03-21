# modules/compliance/outputs.tf

output "config_recorder_id" {
  description = "AWS Config recorder ID"
  value       = aws_config_configuration_recorder.main.id
}

output "backup_vault_arn" {
  description = "AWS Backup vault ARN"
  value       = aws_backup_vault.main.arn
}

output "backup_plan_id" {
  description = "AWS Backup plan ID"
  value       = aws_backup_plan.main.id
}
