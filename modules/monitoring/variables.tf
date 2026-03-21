# modules/monitoring/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN suffix for CloudWatch dimensions"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name for CloudWatch dimensions"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
}
