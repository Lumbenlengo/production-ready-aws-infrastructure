#!/bin/bash
# app/scripts/start_server.sh
set -euo pipefail

echo "Starting application..."

IMAGE_URI_FILE="/opt/app/image_uri.txt"
if [ -f "$IMAGE_URI_FILE" ]; then
  IMAGE_URI=$(cat "$IMAGE_URI_FILE")
elif [ -n "${ECR_REPOSITORY_URI:-}" ]; then
  IMAGE_URI="${ECR_REPOSITORY_URI}:latest"
  echo "WARNING: image_uri.txt not found, using ECR_REPOSITORY_URI:latest"
else
  echo "ERROR: image_uri.txt not found and ECR_REPOSITORY_URI not provided."
  exit 1
fi

echo "Pulling image: $IMAGE_URI"
REGISTRY="${IMAGE_URI%%/*}"
REGION="${REGISTRY#*.ecr.}"
REGION="${REGION%%.amazonaws.com}"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$IMAGE_URI"

TABLE_FILE="/opt/app/dynamodb_table_name.txt"
if [ -f "$TABLE_FILE" ]; then
  DYNAMODB_TABLE=$(cat "$TABLE_FILE")
elif [ -n "${DYNAMODB_TABLE:-}" ]; then
  echo "WARNING: dynamodb_table_name.txt not found, using DYNAMODB_TABLE env var"
else
  echo "ERROR: No DynamoDB table configuration found."
  exit 1
fi

docker run -d \
  --name app-container \
  -p 8000:8000 \
  -e DYNAMODB_TABLE="$DYNAMODB_TABLE" \
  -e APP_VERSION="${IMAGE_URI##*:}" \
  --restart unless-stopped \
  "$IMAGE_URI"

echo "Application started on port 8000 using image $IMAGE_URI"
exit 0