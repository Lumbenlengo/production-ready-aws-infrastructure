#!/bin/bash
# Redirect all output to a log file for easier debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -euxo pipefail

echo "--- Starting Deployment Script ---"

# 1. Install System Dependencies
yum update -y
yum install -y docker ruby wget

# 2. Configure Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user 

# 3. Install AWS CodeDeploy Agent
# Uses dynamic region variable for high availability
cd /tmp
wget https://aws-codedeploy-${aws_region}.s3.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# 4. Pull and Run Application Container
# We use sudo here because the group membership takes a reboot/re-login to take effect
REGION="${aws_region}"
ACCOUNT_ID="${account_id}"
PROJECT_NAME="${project_name}"
# No teu ficheiro user_data.sh.tpl, altera para:
ECR_URL="${account_id}.dkr.ecr.${aws_region}.amazonaws.com/${ecr_repo_name}"

echo "Logging into Amazon ECR..."
aws ecr get-login-password --region "${aws_region}" | sudo docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${aws_region}.amazonaws.com"

echo "Pulling latest image from ECR..."
sudo docker pull "$ECR_URL:latest"

echo "Starting application container..."
# Remove any existing container to avoid naming conflicts
sudo docker rm -f app-container || true

sudo docker run -d \
  -p 8000:8000 \
  --name app-container \
  -e AWS_REGION="${aws_region}" \
  -e ENVIRONMENT="${environment}" \
  -e DYNAMODB_TABLE="${dynamodb_table_name}" \
  "$ECR_URL:latest"

# 5. Create Environment File
mkdir -p /opt/app
cat > /opt/app/.env <<EON
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
AWS_REGION=${aws_region}
EON

echo "--- Deployment Script Finished Successfully ---"