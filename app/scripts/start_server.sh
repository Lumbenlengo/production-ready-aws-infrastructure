#!/bin/bash
# start_server.sh — pull latest image and start container

set -euo pipefail

echo "[CodeDeploy] Starting application..."

REGION="us-east-1"
CONTAINER_NAME="app"
ENV_FILE="/opt/app/.env"

# Load environment variables set by user_data.sh
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# Ensure ACCOUNT_ID and PROJECT_NAME are set
if [ -z "${ACCOUNT_ID:-}" ] || [ -z "${PROJECT_NAME:-}" ]; then
  echo "[CodeDeploy] ERROR: ACCOUNT_ID or PROJECT_NAME not set"
  exit 1
fi

# Build ECR URI directly (no AWS CLI call needed)
REPOSITORY_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-app"
echo "[CodeDeploy] Repository URI: ${REPOSITORY_URI}"

# Authenticate to ECR
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPOSITORY_URI"

# Pull the latest image
echo "[CodeDeploy] Pulling image ${REPOSITORY_URI}:latest..."
docker pull "${REPOSITORY_URI}:latest"

# Stop and remove existing container if running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[CodeDeploy] Stopping existing container..."
  docker stop "$CONTAINER_NAME" --time 30 || true
  docker rm "$CONTAINER_NAME" || true
fi

echo "[CodeDeploy] Starting new container with resource limits..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  -p 8000:8000 \
  --env-file "$ENV_FILE" \
  -e AWS_REGION="$REGION" \
  "${REPOSITORY_URI}:latest"

echo "[CodeDeploy] Container started: $CONTAINER_NAME"