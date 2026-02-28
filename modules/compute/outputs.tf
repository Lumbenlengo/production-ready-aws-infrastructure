
# Modules/Compute/outputs.tf

output "ec2_instance_id" {
  description = "The unique ID of the web server instance"
  value       = aws_instance.web_server.id
}

output "ec2_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

