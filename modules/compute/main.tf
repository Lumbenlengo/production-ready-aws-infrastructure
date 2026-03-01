# 1. Dynamic Search for the Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. The Blueprint (Launch Template)
# This replaces the "aws_instance" resource
resource "aws_launch_template" "web_server" {
  name_prefix   = "${var.project_name}-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type # Using the variable from tfvars

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  # Storage configuration moved inside the template
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # User data must be base64 encoded for Launch Templates
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>High Availability Server: $(hostname -f)</h1><p>Managed by Lumbenlengo ASG</p></body></html>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-asg-instance"
    }
  }
}

# 3. The Auto Scaling Group (The "Manager")
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.project_name}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.public_subnet_ids # Spreads instances across AZs

  target_group_arns = [var.target_group_arn] # Connects to the Load Balancer

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  # Use ELB health checks to replace failed instances automatically
  health_check_type         = "ELB"
  health_check_grace_period = 300
}