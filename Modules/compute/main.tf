 # EC2 INSTANCE CONFIGURATION


resource "aws_instance" "web_server" {
  ami                         = "ami-0440d3b780d96b29d"
  instance_type               = "t2.micro"
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  associate_public_ip_address = true


  # USER DATA: Automation Script 
  # This shell script automates the web server installation

  user_data = <<-EOF
              #!/bin/bash
              # Update all system packages
              dnf update -y
              # Install Apache Web Server (httpd)
              dnf install -y httpd
              # Start the service and enable it on boot
              systemctl start httpd
              systemctl enable httpd
              # Create a custom HTML landing page
              echo "<html><body><h1>Welcome to Lumbenlengo Production Server</h1><p>Infrastructure Managed by Terraform</p></body></html>" > /var/www/html/index.html
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}