# environments/dev/terraform.tfvars

project_name     = "lumbenlengo-dev"
environment      = "dev"
domain_name      = "api.patriciolumbe.com"
instance_type    = "t3.micro"
desired_capacity = 1
max_size         = 2
min_size         = 1
vpc_cidr         = "10.0.0.0/16"
alert_email      = "patriciolumbee@gmail.com"


# GitHub
github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

# SSH disabled in dev — use SSM Session Manager instead
# my_ip = null  (default)

# WAF: set to true after first apply creates the ALB
enable_waf_association = false
