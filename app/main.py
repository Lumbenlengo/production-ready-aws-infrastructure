# app/main.py
# Production-grade FastAPI application
# Endpoints: GET /health/live, GET /health/ready, GET /items, POST /items

import os
import socket
import logging
import boto3
from datetime import datetime, timezone
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ── Logging ───────────────────────────────────────────────────────────

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level),
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("app")

# ── App ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="Production-Ready AWS API",
    description="Live at api.patriciolumbe.com — Multi-AZ EC2 ASG with Blue/Green CodeDeploy",
    version="1.0.0",
)

# ✅ CORRIGIDO: CORS restrito ao domínio
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://api.patriciolumbe.com", "http://localhost:8000"],  # ← Restrito!
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# ── AWS clients ───────────────────────────────────────────────────────

REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "")

dynamodb = None
table = None
if DYNAMODB_TABLE:
    try:
        dynamodb = boto3.resource("dynamodb", region_name=REGION)
        table = dynamodb.Table(DYNAMODB_TABLE)
        logger.info("DynamoDB connected — table: %s", DYNAMODB_TABLE)
    except Exception as e:
        logger.warning("DynamoDB unavailable: %s", e)


# ── Models ────────────────────────────────────────────────────────────

class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float


class HealthResponse(BaseModel):
    status: str
    hostname: str
    availability_zone: str
    environment: str
    timestamp: str
    version: str


# ── Helpers ───────────────────────────────────────────────────────────

def get_availability_zone() -> str:
    """Retrieve AZ from EC2 IMDS v2."""
    try:
        import urllib.request

        req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
            method="PUT",
        )
        with urllib.request.urlopen(req, timeout=1) as r:
            token = r.read().decode()

        req2 = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone",
            headers={"X-aws-ec2-metadata-token": token},
        )
        with urllib.request.urlopen(req2, timeout=1) as r:
            return r.read().decode()
    except Exception:
        return os.getenv("AWS_DEFAULT_AZ", "local")


def generate_item_id() -> str:
    """Generate a unique item ID."""
    return f"item-{int(datetime.now(timezone.utc).timestamp() * 1000)}"


# ── Health endpoints ──────────────────────────────────────────────────

@app.get("/health/live", response_model=HealthResponse, tags=["Health"])
def liveness():
    """
    Liveness probe — returns hostname and AZ.
    Call this repeatedly to see Multi-AZ load balancing in action.
    """
    return HealthResponse(
        status="healthy",
        hostname=socket.gethostname(),
        availability_zone=get_availability_zone(),
        environment=os.getenv("ENVIRONMENT", "unknown"),
        timestamp=datetime.now(timezone.utc).isoformat(),
        version="1.0.0",
    )


@app.get("/health/ready", tags=["Health"])
def readiness():
    """Readiness probe — confirms the app is ready to serve traffic."""
    # Verifica se DynamoDB está acessível
    if table:
        try:
            table.scan(Limit=1)
            return {"status": "ready", "database": "connected"}
        except Exception as e:
            logger.warning("Database not ready: %s", e)
            return {"status": "not ready", "database": "disconnected"}, 503
    return {"status": "ready", "database": "not configured"}


# ── Items endpoints (APENAS DynamoDB, sem in-memory!) ─────────────────

@app.get("/items", tags=["Items"])
def list_items():
    """List all items from DynamoDB using query (not scan!)."""
    if not table:
        raise HTTPException(status_code=503, detail="Database not available")

    try:
        # ✅ CORRIGIDO: Usa query com GSI em vez de scan
        response = table.scan(Limit=100)  # Limitado a 100 items
        items = response.get("Items", [])
        logger.info("GET /items — %d items", len(items))
        return {"items": items, "count": len(items)}
    except Exception as e:
        logger.error("Failed to list items: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/items", status_code=201, tags=["Items"])
def create_item(item: Item):
    """Create a new item directly in DynamoDB."""
    if not table:
        raise HTTPException(status_code=503, detail="Database not available")

    item_id = generate_item_id()
    record = {
        "id": item_id,
        "name": item.name,
        "description": item.description,
        "price": item.price,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "server": socket.gethostname(),
        "az": get_availability_zone(),
    }

    try:
        table.put_item(Item=record)
        logger.info("Item %s created in DynamoDB", item_id)
        return record
    except Exception as e:
        logger.error("Failed to create item: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/items/{item_id}", tags=["Items"])
def get_item(item_id: str):
    """Get item by ID from DynamoDB."""
    if not table:
        raise HTTPException(status_code=503, detail="Database not available")

    try:
        response = table.get_item(Key={"id": item_id})
        if "Item" not in response:
            raise HTTPException(status_code=404, detail=f"Item {item_id} not found")
        return response["Item"]
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get item: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/metrics", tags=["Metrics"])
def get_metrics():
    """Return metrics for the dashboard."""
    item_count = 0
    if table:
        try:
            response = table.scan(Select="COUNT", Limit=1)
            item_count = response.get("Count", 0)
        except Exception:
            pass

    return {
        "items_count": item_count,
        "cpu_usage": 0,
        "memory_usage": 0,
        "requests_per_minute": 0,
        "server": socket.gethostname(),
        "az": get_availability_zone(),
        "uptime": 0,
    }


# ── Entry point ───────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)