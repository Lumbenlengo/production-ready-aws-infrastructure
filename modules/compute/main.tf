# modules/compute/main.tf

# IAM Role for EC2 instances

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ec2_custom" {
  name = "${var.project_name}-ec2-policy-${var.environment}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2.name
}

# Launch Template 
# Defines the blueprint for the EC2 instances in the Auto Scaling Group
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Attach the IAM Role to the instance (needed for ECR and CodeDeploy)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # Use network_interfaces for better control over networking
  network_interfaces {
    associate_public_ip_address = false # Keeping it private for security
    security_groups             = [var.web_sg_id]
  }

  # IMDSv2 — Security Best Practice
  # Ensures all metadata requests require a session token (protects against SSRF)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true # Detailed monitoring (1-minute intervals) for CloudWatch
  }

  # User Data script with variables injected from Terraform
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    aws_region   = var.aws_region
    project_name = var.project_name
    environment  = var.environment
    account_id   = data.aws_caller_identity.current.account_id

  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-instance"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  # Ensures a new template version is created before the old one is deleted
  lifecycle {
    create_before_destroy = true
  }
}
data "aws_caller_identity" "current" {}
# ── AMI Data Source ───────────────────────────────────────────────────
# Automatically fetches the latest Amazon Linux 2023 image
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# Auto Scaling Group 

resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Wait for health checks before marking deploy complete
  health_check_grace_period = 600

  wait_for_capacity_timeout = "20m"

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Tracking Scaling Policy (50% CPU) 

resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.project_name}-cpu-tracking-${var.environment}"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

