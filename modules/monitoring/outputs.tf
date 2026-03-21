# modules/monitoring/outputs.tf

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudtrail_id" {
  description = "CloudTrail trail ID"
  value       = aws_cloudtrail.main.id
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "high_cpu_alarm_name" {
  description = "Name of the high-CPU alarm (used by CodeDeploy rollback)"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "high_5xx_alarm_name" {
  description = "Name of the high-5XX alarm (used by CodeDeploy rollback)"
  value       = aws_cloudwatch_metric_alarm.high_5xx.alarm_name
}
