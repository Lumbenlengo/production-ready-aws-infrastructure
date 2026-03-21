# modules/waf/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "alb_arn" {
  description = "ALB ARN to associate with WAF. Required when enable_association = true."
  type        = string
  default     = ""
}

variable "enable_association" {
  description = "Associate WAF with the ALB. Set to true after the ALB is created."
  type        = bool
  default     = false
}
