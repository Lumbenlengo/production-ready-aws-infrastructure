output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  value = aws_lb_target_group.main.arn
}

output "target_group_name" {
  value = aws_lb_target_group.main.name
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.main.arn_suffix
}

output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}
