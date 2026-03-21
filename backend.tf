# backend.tf
# The `key` is overridden per environment using -backend-config on the CLI:
#   terraform init -backend-config="key=dev/terraform.tfstate"
#   terraform init -backend-config="key=staging/terraform.tfstate"
#   terraform init -backend-config="key=prod/terraform.tfstate"
#
# This prevents dev/staging/prod from sharing the same state file.

terraform {
  backend "s3" {
    bucket       = "lumbenlengo-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
