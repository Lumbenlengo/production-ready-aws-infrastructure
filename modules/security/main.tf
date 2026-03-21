# modules/security/main.tf
# Web server security group and GuardDuty.
# ACM certificate lives exclusively in modules/loadbalancer/main.tf.

# Web Server Security Group
# Allows port 8000 from ALB only. SSH is optional — prefer SSM Session Manager.
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

  # SSH rule is only created when my_ip is explicitly provided.
  # Leave my_ip = null in prod and rely on SSM Session Manager instead.
  dynamic "ingress" {
    for_each = var.my_ip != null ? [var.my_ip] : []
    content {
      description = "SSH from trusted IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
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
    Name        = "${var.project_name}-web-sg"
    Environment = var.environment
  }
}

# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false # Set to true if running EKS
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
    Name        = "${var.project_name}-guardduty"
    Environment = var.environment
  }
}
