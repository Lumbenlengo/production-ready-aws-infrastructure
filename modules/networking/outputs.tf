output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "hosted_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  value = aws_route53_zone.main.name_servers
}
