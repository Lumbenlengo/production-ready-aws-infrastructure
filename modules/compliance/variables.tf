# modules/compliance/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for compliance checks"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN to include in backup selection"
  type        = string
}

variable "artifact_bucket_id" {
  description = "S3 artifact bucket name to include in backup selection"
  type        = string
}
