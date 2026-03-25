# environments/staging/terraform.tfvars

project_name     = "lumbenlengo-staging"
environment      = "staging"
domain_name      = "api.patriciolumbe.com"
instance_type    = "t3.small"
desired_capacity = 2
max_size         = 4
min_size         = 2
vpc_cidr         = "10.1.0.0/16"
alert_email      = "patriciolumbee@gmail.com"

# GitHub
github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

# SSH disabled — use SSM Session Manager
# my_ip = null  (default)

# WAF: set to true after first apply creates the ALB
enable_waf_association = false
