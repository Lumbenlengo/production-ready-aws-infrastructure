 #!/bin/bash
# app/scripts/health_check.sh
# Health check script for CodeDeploy

echo "Running health check..."

# Wait for application to start
sleep 5

# Check if application is responding
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)

if [ $HTTP_CODE -eq 200 ]; then
    echo "Health check passed!"
    exit 0
else
    echo "Health check failed! HTTP Code: $HTTP_CODE"
    exit 1
fi