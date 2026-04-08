# modules/monitoring/main.tf

# ── SNS Topic for Alerts ──────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = ["cloudwatch.amazonaws.com", "events.amazonaws.com"] }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 80
  alarm_description   = "ASG CPU > 80% — potential deployment rollback trigger"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "missing"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name    = "${var.project_name}-high-cpu"
    Purpose = "deployment-rollback"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project_name}-high-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0.3
  alarm_description   = "ALB p95 response time > 300ms — SLO breach"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "missing"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = {
    Name    = "${var.project_name}-high-latency"
    Purpose = "slo-latency"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-high-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5XX count > 10 — error rate SLO breach"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = {
    Name    = "${var.project_name}-high-error-rate"
    Purpose = "slo-error-rate"
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "One or more targets unhealthy"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = {
    Name    = "${var.project_name}-unhealthy-hosts"
    Purpose = "availability-slo"
  }
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CPU Utilization"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Maximum"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          annotations = {
            horizontal = [
              {
                value = 80
                label = "Alarm threshold"
                color = "#ff0000"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Response Time p95 (SLO: < 300ms)"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "p95"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime",
              "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix]
          ]
          annotations = {
            horizontal = [
              {
                value = 0.3
                label = "SLO threshold 300ms"
                color = "#ff0000"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "5XX Error Rate (SLO: < 0.1%)"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
              "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix]
          ]
          annotations = {
            horizontal = [
              {
                value = 10
                label = "Alert threshold"
                color = "#ff6600"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Healthy / Unhealthy Host Count"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 60
          stat    = "Maximum"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount",
              "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount",
              "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix]
          ]
          annotations = {
            horizontal = [
              {
                value = 1
                label = "Unhealthy threshold"
                color = "#ff0000"
              }
            ]
          }
        }
      }
    ]
  })
}

# ── CloudTrail ────────────────────────────────────────────────────────

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-cloudtrail-${var.environment}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-cloudtrail"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket     = aws_s3_bucket.cloudtrail.id
  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail-${var.environment}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name = "${var.project_name}-cloudtrail"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# ── SLO Error Budget Lambda (Path A+) ────────────────────────────────
# Checks 5XX error rate every 5 minutes.
# If error budget is consumed (>0.1% errors), sets SSM flag to LOCKED,
# which blocks CodePipeline from running new deploys.

resource "aws_iam_role" "slo_lambda" {
  name = "${var.project_name}-slo-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "slo_lambda" {
  name = "${var.project_name}-slo-lambda-policy"
  role = aws_iam_role.slo_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:GetMetricStatistics", "cloudwatch:GetMetricData"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:PutParameter", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "slo_checker" {
  function_name = "${var.project_name}-slo-checker-${var.environment}"
  role          = aws_iam_role.slo_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.slo_lambda.output_path
  source_code_hash = data.archive_file.slo_lambda.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME     = var.project_name
      ENVIRONMENT      = var.environment
      ALB_ARN_SUFFIX   = var.alb_arn_suffix
      TG_ARN_SUFFIX    = var.target_group_arn_suffix
      SSM_GATE_PARAM   = "/${var.project_name}/${var.environment}/slo/deployment-gate"
      ERROR_BUDGET_PCT = "0.001"
    }
  }

  tags = {
    Name = "${var.project_name}-slo-checker"
  }
}

data "archive_file" "slo_lambda" {
  type        = "zip"
  output_path = "/tmp/slo_lambda.zip"

  source {
    content  = <<-PYTHON
import boto3
import os
from datetime import datetime, timedelta, timezone

def handler(event, context):
    cw = boto3.client('cloudwatch')
    ssm = boto3.client('ssm')

    end   = datetime.now(timezone.utc)
    start = end - timedelta(hours=1)

    alb = os.environ['ALB_ARN_SUFFIX']
    tg  = os.environ['TG_ARN_SUFFIX']

    def get_metric(metric_name, stat='Sum'):
        r = cw.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName=metric_name,
            Dimensions=[
                {'Name': 'LoadBalancer', 'Value': alb},
                {'Name': 'TargetGroup',  'Value': tg}
            ],
            StartTime=start, EndTime=end,
            Period=3600, Statistics=[stat]
        )
        return sum(d[stat] for d in r['Datapoints'])

    total   = get_metric('RequestCount')
    errors5 = get_metric('HTTPCode_Target_5XX_Count')
    budget  = float(os.environ.get('ERROR_BUDGET_PCT', '0.001'))
    param   = os.environ['SSM_GATE_PARAM']

    if total > 0 and (errors5 / total) > budget:
        gate = 'LOCKED'
        print(f"SLO BREACH: {errors5}/{total} 5XX ({errors5/total:.4%}) > {budget:.4%} budget")
    else:
        gate = 'OPEN'
        print(f"SLO OK: {errors5}/{total} 5XX")

    ssm.put_parameter(Name=param, Value=gate, Type='String', Overwrite=True)
    return {'gate': gate, 'total': total, 'errors': errors5}
    PYTHON
    filename = "index.py"
  }
}

resource "aws_cloudwatch_event_rule" "slo_schedule" {
  name                = "${var.project_name}-slo-check-${var.environment}"
  description         = "Run SLO error budget checker every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name = "${var.project_name}-slo-schedule"
  }
}

resource "aws_cloudwatch_event_target" "slo_lambda" {
  rule      = aws_cloudwatch_event_rule.slo_schedule.name
  target_id = "SLOCheckerLambda"
  arn       = aws_lambda_function.slo_checker.arn
}

resource "aws_lambda_permission" "slo_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slo_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.slo_schedule.arn
}


resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_high.name
  target_id = "GuardDutySNS"
  arn       = aws_sns_topic.alerts.arn # ← USA O RECURSO LOCAL
}


resource "aws_cloudwatch_event_rule" "guardduty_high" {
  name        = "${var.project_name}-guardduty-high-${var.environment}"
  description = "Capture GuardDuty HIGH severity findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })
}