#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "--- Starting Deployment Script ---"

yum update -y
yum install -y docker ruby wget

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

cd /tmp
wget https://aws-codedeploy-${aws_region}.s3.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

REGION="${aws_region}"
ACCOUNT_ID="${account_id}"
PROJECT_NAME="${project_name}"
ECR_URL="${account_id}.dkr.ecr.${aws_region}.amazonaws.com/${ecr_repo_name}"

mkdir -p /opt/app
cat > /opt/app/.env <<EON
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
AWS_REGION=${aws_region}
ACCOUNT_ID=${account_id}
DYNAMODB_TABLE=${dynamodb_table_name}
ALLOWED_ORIGINS=*
LOG_LEVEL=INFO
EON

echo "Logging into Amazon ECR..."
aws ecr get-login-password --region "${aws_region}" | sudo docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${aws_region}.amazonaws.com"

echo "Pulling latest image from ECR..."
sudo docker pull "$ECR_URL:latest"

echo "Starting application container..."
sudo docker rm -f app || true

sudo docker run -d \
  -p 8000:8000 \
  --name app \
  --restart unless-stopped \
  --env-file /opt/app/.env \
  "$ECR_URL:latest"

echo "--- Deployment Script Finished Successfully ---"
