variable "project_name" { type = string }
variable "environment" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "api_key" {
  type      = string
  sensitive = true
}
