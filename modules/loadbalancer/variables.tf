 variable "project_name" {
  description = "The name of the project to prefix resource names"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the Load Balancer and Target Group will live"
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs where the ALB will be deployed (for High Availability)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The Security Group ID that allows HTTP traffic from the internet to the ALB"
  type        = string
}