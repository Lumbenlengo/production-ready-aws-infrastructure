# 1. The website URL (DNS Name)
# The "receipt" that says: "Here is the link to your website!"
output "alb_dns_name" {
  description = "The DNS name of the load balancer to access the application"
  value       = aws_lb.main.dns_name
}

# 2. The Kitchen ID (Target Group ARN)
# The "receipt" that says: "This is the ID of the kitchen where the cooks must enter"
output "target_group_arn" {
  description = "The ARN of the target group to attach instances or ASGs"
  value       = aws_lb_target_group.main.arn
}