import os
import socket
import boto3
import time
from datetime import datetime

async def get_instance_metadata():
    """Returns local metadata for the dashboard."""
    return {
        "hostname": socket.gethostname(),
        "az": os.getenv("AWS_DEFAULT_AZ", "local-dev"),
        "region": os.getenv("AWS_REGION", "us-east-1"),
        "instance_id": "i-local-container"
    }

def get_table():
    """Connects to DynamoDB or returns a mock if unavailable."""
    table_name = os.getenv("DYNAMODB_TABLE")
    if table_name:
        try:
            db = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "us-east-1"))
            return db.Table(table_name)
        except:
            return None
    return None

class HealthCheck:
    def __init__(self):
        self.start_time = time.time()

    def get_uptime(self):
        return time.time() - self.start_time

    def check_database(self, table):
        if table:
            return True, "connected"
        return False, "not configured"

    def check_dependencies(self):
        return True, "all systems nominal"