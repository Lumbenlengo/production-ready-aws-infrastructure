# environments/dev/terraform.tfvars

project_name     = "lumbenlengo"
environment      = "dev"
domain_name      = "api.patriciolumbe.com"
aws_region       = "us-east-1"
owner            = "Patricio Lumbe"
vpc_cidr         = "10.0.0.0/16"
instance_type    = "t3.micro"
desired_capacity = 1
max_size         = 2
min_size         = 1
alert_email      = "patriciolumbee@gmail.com"
aws_account_id   = "678632990341"

github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

# SSH disabled in dev use SSM Session Manager instead
# my_ip = null  (default)

# ALB deletion protection only in prod
enable_deletion_protection = false

# Set to true after first apply creates the ALB
enable_waf_association = false
