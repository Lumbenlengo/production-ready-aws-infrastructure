output "asg_name" {
  value = aws_autoscaling_group.main.name
}

output "asg_arn" {
  value = aws_autoscaling_group.main.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2.arn
}
