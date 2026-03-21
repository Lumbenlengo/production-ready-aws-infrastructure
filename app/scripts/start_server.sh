#!/bin/bash
# app/scripts/start_server.sh
set -euo pipefail

echo "Starting application..."

REGION=$(curl -sf \
  -H "X-aws-ec2-metadata-token: $(curl -sf -X PUT \
    'http://169.254.169.254/latest/api/token' \
    -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')" \
  http://169.254.169.254/latest/meta-data/placement/region)

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/lumbenlengo-lab-app"

# Use the exact image tag built in this pipeline run.
# Falls back to :latest if the file is missing (e.g. manual deploy).
IMAGE_URI_FILE="/opt/app/image_uri.txt"
if [ -f "$IMAGE_URI_FILE" ]; then
  IMAGE_URI=$(cat "$IMAGE_URI_FILE")
else
  IMAGE_URI="${REPO_URI}:latest"
  echo "WARNING: image_uri.txt not found, falling back to :latest"
fi

echo "Pulling image: $IMAGE_URI"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REPO_URI"

docker pull "$IMAGE_URI"

docker run -d \
  --name app-container \
  -p 8000:8000 \
  -e DYNAMODB_TABLE="lumbenlengo-lab-metrics-dev" \
  -e APP_VERSION="${IMAGE_URI##*:}" \
  --restart unless-stopped \
  "$IMAGE_URI"

echo "Application started on port 8000 using image $IMAGE_URI"
exit 0