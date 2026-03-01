# This name MUST match what you use in the Root main.tf
output "web_sg_id" {
  description = "The ID of the security group for the web server"
  value       = aws_security_group.web_sg.id
}

output "alb_security_group_id" {
  description = "The ID of the security group for the Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

# You can keep this one as an alias or delete it to keep it clean
output "security_group_id" {
  value = aws_security_group.web_sg.id
}

