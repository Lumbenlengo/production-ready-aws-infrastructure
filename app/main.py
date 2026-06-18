import os
import socket
import logging
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

# 5. STATIC FILES & TEMPLATES – safe mounting (check directories exist)
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

# 6. AWS SERVICES SETUP
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

# 7. HELPERS – cached EC2 metadata
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

# 8. HEALTH CHECK ENDPOINT (critical for Docker HEALTHCHECK)
@app.get("/health", include_in_schema=False)
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

# 9. INCLUDE MODULAR ROUTES
try:
    from api import routes
    app.include_router(routes.router)
    logger.info(" Modular routes from routes.py included")
except ImportError as e:
    logger.warning(f" routes.py not found or failed to import: {e}")

# 10. TELEMETRY ENDPOINT
@app.post("/api/game/score")
async def update_game_score(data: dict):
    score = data.get("score", 0)
    player = data.get("player_id", "anonymous")
    logger.info(f" GAME TELEMETRY: Player {player} | Score: {score}")
    return {"status": "success", "score_recorded": score}

# 11. MAIN DASHBOARD ROUTE (only if templates exist)
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

# 12. COMMAND CONSOLE ENDPOINT (safe – no command injection)
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

# 13. ENTRY POINT
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
# Build Metadata
# Last forced sync: Thu Jun 18 08:33:17 AM UTC 2026
# Deployment Version: v63

# Build Configuration
BUILD_TIMESTAMP = "Thu Jun 18 08:50:53 AM UTC 2026"

@app.get("/api/build-info")
async def build_info():
    return {"build_time": BUILD_TIMESTAMP, "version": "v64"}
