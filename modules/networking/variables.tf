 # modules/networking/variables.tf

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "The name of the project for tagging"
  type        = string
}