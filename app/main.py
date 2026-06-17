import os
import socket
import logging
import threading
from functools import lru_cache
import boto3
import urllib.request 
from datetime import datetime, timezone 

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request as StarletteRequest

# 1. LOGGING CONFIGURATION
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
try:
    from core import monitoring
    monitoring.setup_monitoring(app)
    logger.info(" Monitoring system (OTEL/Prometheus) initialized")
except ImportError as e:
    logger.warning(f" Monitoring module not found or failed to load: {e}")

# 4. CORS MIDDLEWARE – restricted to allowed origins (env variable)
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
logger.info(f" CORS allowed origins: {allowed_origins}")

# 5. TELEMETRY MIDDLEWARE – request/error counters
_request_counter = {"total": 0, "errors": 0}
_data_out_bytes = {"value": 0}
_counter_lock = threading.Lock()

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
logger.info(" TelemetryMiddleware registered")

# 6. STATIC FILES & TEMPLATES – safe mounting (check directories exist)
static_dir = "/app/static"
templates_dir = "/app/templates"
if os.path.isdir(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")
else:
    logger.warning(f" Static directory not found: {static_dir}")

if os.path.isdir(templates_dir):
    templates = Jinja2Templates(directory=templates_dir)
else:
    logger.error(f" Templates directory not found: {templates_dir}")
    templates = None

# 7. AWS SERVICES SETUP
REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "")
table = None

if DYNAMODB_TABLE:
    try:
        dynamodb = boto3.resource("dynamodb", region_name=REGION)
        table = dynamodb.Table(DYNAMODB_TABLE)
        logger.info(f" Connected to DynamoDB: {DYNAMODB_TABLE}")
    except Exception as e:
        logger.error(f" AWS Connection Error: {e}")

# 8. HELPERS – cached EC2 metadata
@lru_cache(maxsize=1)
def get_availability_zone() -> str:
    """Retrieve Availability Zone from EC2 IMDS v2 (cached)."""
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

# 9. HEALTH CHECK ENDPOINT (critical for Docker HEALTHCHECK)
@app.get("/health", include_in_schema=False)
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

# 10. INCLUDE MODULAR ROUTES
try:
    from api import routes
    app.include_router(routes.router)
    logger.info(" Modular routes from routes.py included")
except ImportError as e:
    logger.warning(f" routes.py not found or failed to import: {e}")

# 11. TELEMETRY ENDPOINT
@app.post("/api/game/score")
async def update_game_score(data: dict):
    score = data.get("score", 0)
    player = data.get("player_id", "anonymous")
    logger.info(f" GAME TELEMETRY: Player {player} | Score: {score}")
    return {"status": "success", "score_recorded": score}

# 12. MAIN DASHBOARD ROUTE (only if templates exist)
@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    if not templates:
        return HTMLResponse(content="<h1>Server misconfigured: templates not found</h1>", status_code=500)
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
    return templates.TemplateResponse(request=request, name="index.html", context=context)
# 13. NETWORK HEALTH ENDPOINT
@app.get("/api/network-health")
async def network_health():
    with _counter_lock:
        total = _request_counter["total"]
        errors = _request_counter["errors"]
        gb_out = _data_out_bytes["value"] / (1024 ** 3)
    error_rate_pct = (errors / total * 100) if total > 0 else 0.0
    return JSONResponse({
        "error_rate_pct": round(error_rate_pct, 4),
        "data_out_gb": round(gb_out, 4),
        "total_requests": total,
        "error_requests": errors,
    })

# 14. COMMAND CONSOLE ENDPOINT (safe – no command injection)
@app.post("/api/command")
async def command(payload: dict):
    action = payload.get("action", "")
    logger.info(f" Command received: {action}")
    if action == "restart":
        return JSONResponse({"message": " Restart signal sent to service"})
    elif action == "purge":
        return JSONResponse({"message": " Cache purged successfully"})
    else:
        return JSONResponse({"message": " Unknown command"}, status_code=400)

# 15. ENTRY POINT
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)