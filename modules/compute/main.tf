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

# 2. EC2 Instance Configuration
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  # USER DATA: Automation script (Must be INSIDE the resource block)
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>Welcome to Lumbenlengo Production Server</h1><p>Infrastructure Managed by Terraform</p></body></html>" > /var/www/html/index.html
              EOF

  # Root Block Device (Must be INSIDE the resource block)
  root_block_device {
    volume_size = 30 # Size fixed to 30GB as required by the AMI
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
} # This is the ONLY place where you close the resource!