# Modules/Security/outputs.tf

output "security_group_id" {
  description = "The ID of the security group to be used by the EC2 instance"
  value       = aws_security_group.web_sg.id
}




output "alb_security_group_id" {
  description = "The ID of the security group for the Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "web_security_group_id" {
  description = "The ID of the security group for the web server"
  value       = aws_security_group.web_sg.id
}



