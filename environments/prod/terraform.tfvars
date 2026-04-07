# environments/prod/terraform.tfvars

project_name     = "lumbenlengo"
environment      = "prod"
domain_name      = "api.patriciolumbe.com"
aws_region       = "us-east-1"
vpc_cidr         = "10.2.0.0/16"
instance_type    = "t3.small"
desired_capacity = 2
max_size         = 6
min_size         = 2
alert_email      = "patriciolumbee@gmail.com"

github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

# Production hardening
enable_deletion_protection = true
enable_waf_association     = true
