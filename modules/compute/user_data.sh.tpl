#!/bin/bash
set -euxo pipefail

# --- System Updates ---
yum update -y
yum install -y docker ruby wget

# --- Docker Setup ---
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user 

# --- CodeDeploy Agent ---
cd /tmp
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# --- App Deployment (Variables injected by Terraform) ---
# We use the variables passed from the main.tf map
REGION="${aws_region}"
PROJECT_NAME="${project_name}"
ACCOUNT_ID="${account_id}"

# We define ECR_URL using Bash variables to avoid Terraform conflicts
ECR_URL="${account_id}.dkr.ecr.${aws_region}.amazonaws.com/${project_name}-app"

# Login to ECR
aws ecr get-login-password --region "${aws_region}" | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${aws_region}.amazonaws.com"

# Pull and Run
docker pull \$ECR_URL:latest
docker run -d -p 8000:8000 --name app-container \$ECR_URL:latest

# --- Environment Setup ---
mkdir -p /opt/app
cat > /opt/app/.env <<EON
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
AWS_REGION=${aws_region}
EON