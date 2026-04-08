variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "domain_name" { type = string }
variable "hosted_zone_id" { type = string }
variable "enable_deletion_protection" {
  type    = bool
  default = false
}
