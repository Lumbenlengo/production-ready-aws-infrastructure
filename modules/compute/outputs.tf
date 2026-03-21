# modules/compute/outputs.tf

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.web_asg.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.web_asg.arn
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.web_server.id
}

output "instance_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}
