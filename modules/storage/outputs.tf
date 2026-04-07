output "artifact_bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}

output "artifact_bucket_id" {
  value = aws_s3_bucket.artifacts.id
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.metrics.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.metrics.name
}
