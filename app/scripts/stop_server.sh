#!/bin/bash
# app/scripts/stop_server.sh
# Stop the application server

echo "Stopping application..."

# Stop Docker container if running
docker stop app-container 2>/dev/null || true
docker rm app-container 2>/dev/null || true

# Kill any process on port 8000
fuser -k 8000/tcp 2>/dev/null || true

echo "Application stopped"
exit 0