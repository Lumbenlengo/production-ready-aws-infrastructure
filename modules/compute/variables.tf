variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type" { type = string }
variable "desired_capacity" { type = number }
variable "max_size" { type = number }
variable "min_size" { type = number }
variable "web_sg_id" { type = string }
variable "target_group_arn" { type = string }


variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "kms_key_arn" {
  type    = string
  default = "arn:aws:kms:*:*:key/*"
}
variable "ecr_repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
}
