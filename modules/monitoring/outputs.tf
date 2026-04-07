output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "rollback_alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.high_error_rate.alarm_name,
    aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_name,
  ]
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.id
}

output "slo_checker_function_name" {
  value = aws_lambda_function.slo_checker.function_name
}
