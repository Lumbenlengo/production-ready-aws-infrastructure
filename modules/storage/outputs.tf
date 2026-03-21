# modules/storage/outputs.tf

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.metrics.arn
}

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.metrics.name
}

output "artifact_bucket_id" {
  description = "S3 artifacts bucket name"
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  description = "S3 artifacts bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}
