#!/bin/bash
# app/scripts/install_dependencies.sh
set -euo pipefail

echo "Preparing host dependencies..."

# Docker and AWS CLI are installed at instance bootstrap time in Terraform user_data.
# This hook keeps deployment idempotent and ensures script files are executable.
chmod +x /opt/app/scripts/*.sh || true

echo "Host dependency check complete."
exit 0
