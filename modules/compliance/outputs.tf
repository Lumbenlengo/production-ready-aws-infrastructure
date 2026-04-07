output "backup_vault_name" {
  value = aws_backup_vault.main.name
}

output "config_bucket_name" {
  value = aws_s3_bucket.config.id
}
