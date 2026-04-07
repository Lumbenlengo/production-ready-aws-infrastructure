variable "project_name" { type = string }
variable "environment" { type = string }
variable "alb_arn" { type = string }
variable "enable_waf_association" {
  type    = bool
  default = false
}
