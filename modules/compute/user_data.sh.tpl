#!/bin/bash
set -euxo pipefail

# --- System Updates and Core Dependencies ---
# Ensuring the OS is up to date and installing Docker, Ruby (for CodeDeploy), and Wget
yum update -y
yum install -y docker ruby wget

# --- Docker Configuration ---
# Setting up the Docker engine to start on boot and giving permissions to the ec2-user
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user 

# --- AWS CodeDeploy Agent Installation ---
# This agent allows for automated, zero-downtime application deployments
cd /tmp
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# --- Application Deployment via Docker & ECR ---
# Variables are injected from Terraform for high reliability
REGION="${aws_region}"
PROJECT_NAME="${project_name}"
ACCOUNT_ID="678632990341"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${project_name}-app"

# Authenticate Docker against the Amazon ECR Registry
# Requires the EC2 Instance Profile to have 'AmazonEC2ContainerRegistryReadOnly' permissions
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_URL}"

# Pull the latest Docker image and run the application container
# Maps host port 8000 to container port 8000
docker pull "${ECR_URL}:latest"
docker run -d -p 8000:8000 --name app-container "${ECR_URL}:latest"

# --- Environment Configuration ---
# Generating an environment file for the application to consume metadata
mkdir -p /opt/app
cat > /opt/app/.env <<EON
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
AWS_REGION=${aws_region}
EON

echo "Deployment via User Data completed successfully."