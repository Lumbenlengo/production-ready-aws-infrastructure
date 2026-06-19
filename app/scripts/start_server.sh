#!/bin/bash
# start_server.sh — pull latest image and start container
set -euo pipefail

echo "[CodeDeploy] Starting application..."

REGION="us-east-1"
CONTAINER_NAME="app"
ENV_FILE="/opt/app/.env"

if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

if [ -z "${ACCOUNT_ID:-}" ] || [ -z "${PROJECT_NAME:-}" ]; then
  echo "[CodeDeploy] ERROR: ACCOUNT_ID or PROJECT_NAME not set in $ENV_FILE"
  exit 1
fi

# Repo name must match the actual ECR repository, not a derived guess
REPOSITORY_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/production-ready-app"
echo "[CodeDeploy] Repository URI: ${REPOSITORY_URI}"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "[CodeDeploy] Pulling image ${REPOSITORY_URI}:latest..."
docker pull "${REPOSITORY_URI}:latest"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[CodeDeploy] Removing existing container..."
  docker stop "$CONTAINER_NAME" --time 30 || true
  docker rm "$CONTAINER_NAME" || true
fi

echo "[CodeDeploy] Starting new container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  -p 8000:8000 \
  --env-file "$ENV_FILE" \
  "${REPOSITORY_URI}:latest"

echo "[CodeDeploy] Container started: $CONTAINER_NAME"

# Give the app a moment to boot before CodeDeploy's ValidateService hook checks it
sleep 5
docker logs "$CONTAINER_NAME" --tail 30 || true 