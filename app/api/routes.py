import os
import time
import socket
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Request, BackgroundTasks, HTTPException, Depends
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

from app.services.aws_service import get_instance_metadata, get_table, HealthCheck
from app.core.monitoring import (
    limiter,
    http_requests_total,
    request_latency_seconds,
    active_connections,
)

router = APIRouter()
templates = Jinja2Templates(directory="templates")

# ── Shared health check instance (tracks uptime from first import) ──
_health_check = HealthCheck()


def get_health_check() -> HealthCheck:
    return _health_check


# ── Background task ──────────────────────────────────────────────────
import asyncio
import structlog

logger = structlog.get_logger()


async def write_metric_to_dynamodb(item_id: str, action: str):
    await asyncio.sleep(2)
    logger.info("background_metric_written", item_id=item_id, action=action)


# ── Pydantic model ───────────────────────────────────────────────────
class Item(BaseModel):
    name: str
    description: Optional[str] = None


# ── Routes ───────────────────────────────────────────────────────────

@router.get("/", response_class=HTMLResponse)
@limiter.limit("60/minute")
async def read_root(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
    table=Depends(get_table),
):
    metadata = await get_instance_metadata()
    active_connections.inc()

    item_count = 0
    try:
        response = table.scan(Select="COUNT")
        item_count = response.get("Count", 0)
    except Exception as e:
        logger.error("dynamodb_scan_error", error=str(e))

    context = {
        "request": request,
        "project": "Lumbenlengo SaaS",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "status": "HEALTHY",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "hostname": metadata["hostname"],
        "az": metadata["az"],
        "region": metadata["region"],
        "instance_id": metadata["instance_id"],
        "item_count": item_count,
        "timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC"),
        "services": [
            {"name": "Load Balancer", "status": "operational"},
            {"name": "Auto Scaling Group", "status": "operational"},
            {"name": "DynamoDB", "status": "operational"},
            {"name": "S3", "status": "operational"},
            {"name": "WAF", "status": "active"},
            {"name": "GuardDuty", "status": "monitoring"},
        ],
    }

    active_connections.dec()
    return templates.TemplateResponse("index.html", context)


# ── Health endpoints ─────────────────────────────────────────────────

@router.get("/health/live")
@limiter.limit("100/minute")
async def liveness(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
):
    return {"status": "alive", "uptime": hc.get_uptime()}


@router.get("/health/ready")
@limiter.limit("100/minute")
async def readiness(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
    table=Depends(get_table),
):
    db_ok, db_status = hc.check_database(table)
    deps_ok, deps_status = hc.check_dependencies()
    status = "ready" if db_ok and deps_ok else "not ready"
    return {
        "status": status,
        "database": db_status,
        "dependencies": deps_status,
        "uptime": hc.get_uptime(),
    }


@router.get("/health/startup")
@limiter.limit("100/minute")
async def startup(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
):
    return {"status": "started", "startup_time": hc.get_uptime()}


@router.get("/health", response_class=HTMLResponse)
async def health_html(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
    table=Depends(get_table),
):
    metadata = await get_instance_metadata()
    db_ok, db_status = hc.check_database(table)
    return HTMLResponse(
        content=f"""
    <html>
        <body style="font-family: sans-serif; padding: 20px;">
            <h2>Health Check</h2>
            <p><strong>Status:</strong>
                <span style="color: {'green' if db_ok else 'red'};">
                    {'✓ HEALTHY' if db_ok else '✗ DEGRADED'}
                </span>
            </p>
            <p><strong>Hostname:</strong> {metadata['hostname']}</p>
            <p><strong>AZ:</strong> {metadata['az']}</p>
            <p><strong>Region:</strong> {metadata['region']}</p>
            <p><strong>Instance ID:</strong> {metadata['instance_id']}</p>
            <p><strong>Database:</strong> {db_status}</p>
            <p><strong>Uptime:</strong> {hc.get_uptime():.2f} seconds</p>
            <p><strong>Time:</strong> {datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")}</p>
        </body>
    </html>
    """
    )


# ── API endpoints ────────────────────────────────────────────────────

@router.get("/api/health")
@limiter.limit("100/minute")
async def api_health(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
    table=Depends(get_table),
):
    metadata = await get_instance_metadata()
    db_ok, db_status = hc.check_database(table)
    http_requests_total.labels(method="GET", endpoint="/api/health", status="200").inc()
    return {
        "status": "healthy" if db_ok else "degraded",
        "hostname": metadata["hostname"],
        "az": metadata["az"],
        "region": metadata["region"],
        "instance_id": metadata["instance_id"],
        "database": db_status,
        "uptime": hc.get_uptime(),
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/api/items")
@limiter.limit("30/minute")
async def get_items(request: Request, table=Depends(get_table)):
    start_time = time.time()
    try:
        response = table.scan()
        items = response.get("Items", [])
        request_latency_seconds.labels(
            method="GET", endpoint="/api/items"
        ).observe(time.time() - start_time)
        http_requests_total.labels(
            method="GET", endpoint="/api/items", status="200"
        ).inc()
        logger.info("items_retrieved", count=len(items), server=socket.gethostname())
        return {"items": items, "count": len(items), "server": socket.gethostname()}
    except Exception as e:
        http_requests_total.labels(
            method="GET", endpoint="/api/items", status="500"
        ).inc()
        logger.error("items_retrieval_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/items")
@limiter.limit("10/minute")
async def create_item(
    item: Item,
    request: Request,
    background_tasks: BackgroundTasks,
    table=Depends(get_table),
):
    try:
        item_dict = item.dict()
        item_dict["id"] = str(int(datetime.utcnow().timestamp()))
        item_dict["created_at"] = datetime.utcnow().isoformat()
        item_dict["server"] = socket.gethostname()
        metadata = await get_instance_metadata()
        item_dict["az"] = metadata["az"]
        table.put_item(Item=item_dict)
        background_tasks.add_task(write_metric_to_dynamodb, item_dict["id"], "create")
        http_requests_total.labels(
            method="POST", endpoint="/api/items", status="200"
        ).inc()
        logger.info("item_created", item_id=item_dict["id"])
        return {"message": "Item created", "item": item_dict}
    except Exception as e:
        http_requests_total.labels(
            method="POST", endpoint="/api/items", status="500"
        ).inc()
        logger.error("item_creation_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/metrics")
@limiter.limit("30/minute")
async def get_metrics(
    request: Request,
    hc: HealthCheck = Depends(get_health_check),
    table=Depends(get_table),
):
    try:
        response = table.scan(Select="COUNT")
        item_count = response.get("Count", 0)
        try:
            import psutil
            cpu_usage = psutil.cpu_percent(interval=1)
            memory_usage = psutil.virtual_memory().percent
        except Exception:
            import random
            cpu_usage = random.randint(10, 30)
            memory_usage = random.randint(20, 40)

        import random
        metadata = await get_instance_metadata()
        http_requests_total.labels(
            method="GET", endpoint="/api/metrics", status="200"
        ).inc()
        return {
            "items_count": item_count,
            "cpu_usage": cpu_usage,
            "memory_usage": memory_usage,
            "requests_per_minute": random.randint(50, 200),
            "server": socket.gethostname(),
            "az": metadata["az"],
            "uptime": hc.get_uptime(),
        }
    except Exception as e:
        http_requests_total.labels(
            method="GET", endpoint="/api/metrics", status="500"
        ).inc()
        logger.error("metrics_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))