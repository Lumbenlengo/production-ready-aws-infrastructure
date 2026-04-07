# modules/security/main.tf

# ── Web Security Group (EC2 instances) ───────────────────────────────

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg-${var.environment}"
  description = "Allow traffic from ALB on port 8000; optional SSH from trusted IP"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  dynamic "ingress" {
    for_each = var.my_ip != null ? [var.my_ip] : []
    content {
      description = "SSH from trusted IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ── GuardDuty ─────────────────────────────────────────────────────────
# modules/security/main.tf

resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-guardduty"
  }
}

# GuardDuty HIGH severity findings → EventBridge → SNS
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

  tags = {
    Name = "${var.project_name}-guardduty-rule"
  }
}

# ── Security Hub (Path A+) ────────────────────────────────────────────

resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# ── IAM Access Analyzer (Path A+) ────────────────────────────────────

resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project_name}-access-analyzer"
  type          = "ACCOUNT"

  tags = {
    Name = "${var.project_name}-access-analyzer"
  }
}
