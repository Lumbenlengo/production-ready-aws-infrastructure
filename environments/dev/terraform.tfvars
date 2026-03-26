project_name     = "lumbenlengo"
environment      = "dev"
domain_name      = "api.patriciolumbe.com"
instance_type    = "t3.micro"
desired_capacity = 1
max_size         = 2
min_size         = 1
vpc_cidr         = "10.0.0.0/16"
alert_email      = "patriciolumbee@gmail.com"

github_owner     = "Lumbenlengo"
github_repo_name = "production-ready-aws-infrastructure"
github_repo_url  = "https://github.com/Lumbenlengo/production-ready-aws-infrastructure"

enable_waf_association = false
