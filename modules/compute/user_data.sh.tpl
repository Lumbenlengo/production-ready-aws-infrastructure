#!/bin/bash
set -euxo pipefail

# Install Docker and CodeDeploy agent
yum update -y
yum install -y docker ruby wget

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install CodeDeploy agent
cd /tmp
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Get account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Build ECR URL
ECR_URL="$${ACCOUNT_ID}.dkr.ecr.$${REGION}.amazonaws.com/${project_name}-app"

# Login to ECR
aws ecr get-login-password --region "$${REGION}" | docker login --username AWS --password-stdin "$${ECR_URL}"

# Pull latest image
docker pull "$${ECR_URL}:latest"

# Run container
docker run -d -p 8000:8000 --name app-container "$${ECR_URL}:latest"

# Write environment file (quoted heredoc)
cat > /opt/app/.env <<'EOF'
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
AWS_REGION=${aws_region}
EOF 