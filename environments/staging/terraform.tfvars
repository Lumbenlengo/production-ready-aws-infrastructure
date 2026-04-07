# environments/staging/terraform.tfvars

project_name     = "lumbenlengo"
environment      = "staging"
domain_name      = "api.patriciolumbe.com"
aws_region       = "us-east-1"
vpc_cidr         = "10.1.0.0/16"
instance_type    = "t3.micro"
desired_capacity = 1
max_size         = 3
min_size         = 1
alert_email      = "patriciolumbee@gmail.com"

github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

enable_deletion_protection = false
enable_waf_association     = true
