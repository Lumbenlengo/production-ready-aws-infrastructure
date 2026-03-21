# modules/security/outputs.tf

output "web_sg_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web_sg.id
}

output "guardduty_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}
