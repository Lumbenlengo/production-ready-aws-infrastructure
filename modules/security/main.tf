# SECURITY GROUP CONFIGURATION


# Resource: AWS Security Group
# Purpose: Acts as a virtual firewall for the EC2 Instance
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = var.vpc_id

  # Inbound Rule: HTTP
  # Port: 80
  # Purpose: Allows public web traffic to reach the web server
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound Rule: SSH
  # Port: 22
  # Purpose: Allows administrative access via Terminal
  # Security Note: Using 0.0.0.0/0 is risky; in production, use your specific IP.
  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule: All Traffic
  # Purpose: Allows the server to initiate connections to the internet
  # Examples: Downloading OS updates, security patches, or connecting to S3.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means ALL protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}
