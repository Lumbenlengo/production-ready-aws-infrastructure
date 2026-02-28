# Modules/Security/outputs.tf

output "security_group_id" {
  description = "The ID of the security group to be used by the EC2 instance"
  value       = aws_security_group.web_sg.id
}