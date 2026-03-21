import boto3
import os
import socket
import structlog
import httpx
from datetime import datetime

logger = structlog.get_logger()


# ── DynamoDB — injected via Depends, never instantiated at import time ──

def get_table():
    """
    FastAPI Depends factory.
    Called per-request so tests can override it without touching boto3.
    """
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(os.getenv("DYNAMODB_TABLE", "app-metrics-local"))


# ── EC2 Instance Metadata (IMDSv2) ───────────────────────────────────

async def get_instance_metadata() -> dict:
    metadata = {
        "az": "localhost",
        "region": "local",
        "instance_id": "local",
        "hostname": socket.gethostname(),
    }
    try:
        async with httpx.AsyncClient() as client:
            token_res = await client.put(
                "http://169.254.169.254/latest/api/token",
                headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
                timeout=1.0,
            )
            token = token_res.text

            az_res = await client.get(
                "http://169.254.169.254/latest/meta-data/placement/availability-zone",
                headers={"X-aws-ec2-metadata-token": token},
                timeout=1.0,
            )
            metadata["az"] = az_res.text
            metadata["region"] = metadata["az"][:-1]

            id_res = await client.get(
                "http://169.254.169.254/latest/meta-data/instance-id",
                headers={"X-aws-ec2-metadata-token": token},
                timeout=1.0,
            )
            metadata["instance_id"] = id_res.text

    except Exception as e:
        logger.error("metadata_error", error=str(e))

    return metadata


# ── HealthCheck — tracks uptime, checks DB and dependencies ──────────

class HealthCheck:
    """
    Instantiated once in routes.py and shared via Depends.
    Accepts the table as a parameter so it is testable without AWS.
    """

    def __init__(self):
        self.start_time = datetime.utcnow()

    def check_database(self, table) -> tuple[bool, str]:
        """Verify DynamoDB is reachable."""
        try:
            table.scan(Limit=1)
            return True, "connected"
        except Exception as e:
            logger.error("database_check_failed", error=str(e))
            return False, str(e)

    def check_dependencies(self) -> tuple[bool, str]:
        """Placeholder for future external dependency checks."""
        return True, "all_dependencies_ok"

    def get_uptime(self) -> float:
        """Uptime in seconds since this instance was created."""
        return (datetime.utcnow() - self.start_time).total_seconds()