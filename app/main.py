import os
import socket
import logging
import threading
import boto3
import urllib.request
from datetime import datetime, timezone
from typing import Optional

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request as StarletteRequest

# 1. LOGGING CONFIGURATION
# Set up logging early to capture startup events
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level),
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("app")

# 2. FASTAPI INSTANCE
app = FastAPI(
    title="Lumbenlengo SaaS - Production Ready",
    description="Live Telemetry & Infrastructure Monitoring Platform",
    version="1.0.0",
)

# 3. SETUP MONITORING (Modular Core)
# We import directly from 'core' because the Docker WORKDIR includes the app folder
try:
    from core import monitoring
    monitoring.setup_monitoring(app)
    logger.info("✅ Monitoring system (OTEL/Prometheus) initialized")
except ImportError as e:
    logger.warning(f"⚠️ Monitoring module not found or failed to load: {e}")

# 4. MIDDLEWARE
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# 4b. TELEMETRY MIDDLEWARE — counts requests, errors and bytes sent
# Globals for in-memory counters (reset on process restart)
_request_counter = {"total": 0, "errors": 0}
_data_out_bytes  = {"value": 0}
_counter_lock    = threading.Lock()

class TelemetryMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: StarletteRequest, call_next):
        response = await call_next(request)
        with _counter_lock:
            _request_counter["total"] += 1
            if response.status_code >= 400:
                _request_counter["errors"] += 1
            content_length = response.headers.get("content-length")
            if content_length:
                _data_out_bytes["value"] += int(content_length)
        return response

app.add_middleware(TelemetryMiddleware)
logger.info("✅ TelemetryMiddleware registered (error rate + data-out tracking)")

# 5. STATIC FILES & TEMPLATES
# Mapping to the absolute path within the Docker container (/app/...)
app.mount("/static", StaticFiles(directory="/app/static"), name="static")
templates = Jinja2Templates(directory="/app/templates")

# 6. AWS SERVICES SETUP
REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "")
table = None

if DYNAMODB_TABLE:
    try:
        dynamodb = boto3.resource("dynamodb", region_name=REGION)
        table = dynamodb.Table(DYNAMODB_TABLE)
        logger.info(f"✅ Connected to DynamoDB: {DYNAMODB_TABLE}")
    except Exception as e:
        logger.error(f"❌ AWS Connection Error: {e}")

# 7. HELPERS (EC2 Metadata)
def get_availability_zone() -> str:
    """Retrieve Availability Zone from EC2 IMDS v2."""
    try:
        token_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
            method="PUT",
        )
        with urllib.request.urlopen(token_req, timeout=1) as r:
            token = r.read().decode()
        az_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone",
            headers={"X-aws-ec2-metadata-token": token},
        )
        with urllib.request.urlopen(az_req, timeout=1) as r:
            return r.read().decode()
    except Exception:
        return os.getenv("AWS_DEFAULT_AZ", "local-dev")

# 8. INCLUDE MODULAR ROUTES
try:
    from api import routes
    app.include_router(routes.router)
    logger.info("✅ Modular routes from routes.py included")
except ImportError as e:
    logger.warning(f"⚠️ routes.py not found or failed to import: {e}")

# 9. TELEMETRY ENDPOINT
@app.post("/api/game/score")
async def update_game_score(data: dict):
    """Endpoint for the Snake Game to send real-time scores."""
    score = data.get("score", 0)
    player = data.get("player_id", "anonymous")
    logger.info(f"🐍 GAME TELEMETRY: Player {player} | Score: {score}")
    return {"status": "success", "score_recorded": score}

# 10. MAIN DASHBOARD ROUTE
@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """Main landing page serving the telemetry dashboard."""
    context = {
        "request": request,
        "project": "Lumbenlengo SaaS",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "status": "HEALTHY",
        "version": "1.0.0",
        "hostname": socket.gethostname(),
        "az": get_availability_zone(),
        "region": REGION,
        "instance_id": "local-container",
        "item_count": 0,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        "services": [
            {"name": "Load Balancer", "status": "operational"},
            {"name": "Auto Scaling Group", "status": "operational"},
            {"name": "DynamoDB", "status": "operational" if table else "simulated"},
            {"name": "WAF", "status": "active"}
        ]
    }
    return templates.TemplateResponse("index.html", context)

# 11. NETWORK HEALTH ENDPOINT
@app.get("/api/network-health")
async def network_health():
    """Returns error rate % and cumulative data-out in GB for the Network Health section."""
    with _counter_lock:
        total  = _request_counter["total"]
        errors = _request_counter["errors"]
        gb_out = _data_out_bytes["value"] / (1024 ** 3)

    error_rate_pct = (errors / total * 100) if total > 0 else 0.0

    return JSONResponse({
        "error_rate_pct": round(error_rate_pct, 4),
        "data_out_gb":    round(gb_out, 4),
        "total_requests": total,
        "error_requests": errors,
    })

# 12. COMMAND CONSOLE ENDPOINT
@app.post("/api/command")
async def command(payload: dict):
    """
    Handles Restart Service and Purge Cache actions from the dashboard.
    Adapt the logic inside each branch to your real service/cache layer.
    """
    action = payload.get("action", "")
    logger.info(f"🚨 Command received: {action}")

    if action == "restart":
        # Replace with your real restart logic, e.g.:
        # subprocess.Popen(["systemctl", "restart", "lumbenlengo"])
        # or signal your ECS task, PM2, etc.
        return JSONResponse({"message": "✅ Restart signal sent to service"})

    elif action == "purge":
        # Replace with your real cache-clear logic, e.g.:
        # await redis_client.flushdb()
        # or invalidate CloudFront, clear an in-memory dict, etc.
        return JSONResponse({"message": "✅ Cache purged successfully"})

    else:
        return JSONResponse({"message": "⚠️ Unknown command"}, status_code=400)

# 13. ENTRY POINT
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)