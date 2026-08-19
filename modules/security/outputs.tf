output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "github_actions_role_arn" {
  description = "IAM role GitHub Actions assumes via OIDC — set this as the AWS_ROLE_ARN secret"
  value       = aws_iam_role.github_actions.arn
}



output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
