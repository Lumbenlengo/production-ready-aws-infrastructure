#!/bin/bash
# health_check.sh — validate the app is healthy before CodeDeploy marks deploy complete

set -euo pipefail

echo "[CodeDeploy] Running health check..."

MAX_RETRIES=10
SLEEP_BETWEEN=6
URL="http://localhost:8000/health/live"

for i in $(seq 1 $MAX_RETRIES); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "[CodeDeploy] Health check passed (attempt $i) — HTTP $HTTP_CODE"
    exit 0
  fi

  echo "[CodeDeploy] Attempt $i/$MAX_RETRIES — HTTP $HTTP_CODE — retrying in ${SLEEP_BETWEEN}s..."
  sleep "$SLEEP_BETWEEN"
done

echo "[CodeDeploy] Health check FAILED after $MAX_RETRIES attempts — triggering rollback"
exit 1