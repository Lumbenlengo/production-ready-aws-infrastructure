
#!/bin/bash
# stop_server.sh — gracefully stop the running container before new deploy

set -euo pipefail

echo "[CodeDeploy] Stopping existing container..."

CONTAINER_NAME="app"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[CodeDeploy] Gracefully stopping container..."
  docker stop "$CONTAINER_NAME" --time 30
  docker rm "$CONTAINER_NAME"
  echo "[CodeDeploy] Container stopped and removed."
else
  echo "[CodeDeploy] No running container found — clean slate."
fi