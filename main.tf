# Create the main Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 1. Internet Gateway The "Front Door" to the Internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lumbenlengo-igw"
  }
}

# 2. Public Subnet 1 (Availability Zone A)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lumbenlengo-public-1"
  }
}

# 3. Public Subnet 2 (Availability Zone B High Availability)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "lumbenlengo-public-2"
  }
}

# 4. Route Table  The "GPS" for network traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "lumbenlengo-public-rt"
  }
}

# 5. Route Table Association Connecting Subnets to the Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# 6. Private Subnet 1 (Zona A)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "lumbenlengo-private-1"
  }
}

# 7. Private Subnet 2 (Zona B)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "lumbenlengo-private-2"
  }
}



# SECURITY GROUP CONFIGURATION


# Resource: AWS Security Group
# Purpose: Acts as a virtual firewall for the EC2 Instance
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

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


# EC2 INSTANCE CONFIGURATION


resource "aws_instance" "web_server" {
  # Amazon Linux 2023 AMI (North Virginia)
  ami           = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"

  # Networking settings
  # Linking the instance to one of our public subnets
  subnet_id = aws_subnet.public_1.id

  # Attaching the Security Group we just planned
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Assigning a Public IP so we can access it
  associate_public_ip_address = true

  # Storage configuration (Best Practice: gp3)
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}