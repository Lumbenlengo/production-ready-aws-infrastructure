# modules/security/variables.tf

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "my_ip" {
  type    = string
  default = null
}

variable "alb_sg_id" {
  type = string
}


