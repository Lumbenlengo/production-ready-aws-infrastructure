output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

# COMPUTE OUTPUTS

output "ec2_public_ip" {
  description = "The Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}


# NETWORK OUTPUTS

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}