# environments/prod/terraform.tfvars

project_name     = "lumbenlengo-prod"
environment      = "production"
domain_name      = "api.patriciolumbe.com"
instance_type    = "t3.medium"
desired_capacity = 4
max_size         = 8
min_size         = 3
vpc_cidr         = "10.2.0.0/16"
alert_email      = "patriciolumbee@gmail.com"

# GitHub
github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

# SSH is explicitly disabled in production.
# Use SSM Session Manager for all instance access:
#   aws ssm start-session --target <instance-id>
# my_ip = null  (default)

# WAF: set to true after first apply creates the ALB
enable_waf_association = false
