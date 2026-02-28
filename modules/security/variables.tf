variable "project_name" {
  description = "The name of the project used for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}