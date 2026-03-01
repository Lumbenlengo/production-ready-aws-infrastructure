variable "project_name" {}
variable "vpc_cidr" {}

# New Compute Variables
variable "instance_type" {}
variable "desired_capacity" { type = number }
variable "max_size" { type = number }
variable "min_size" { type = number }