variable "project_name" {
  type = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the instance will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to attach to the instance"
  type        = string
}