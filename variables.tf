variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "lumbenlengo-production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}