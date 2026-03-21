from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api.routes import router
from app.core.monitoring import setup_monitoring, lifespan

app = FastAPI(
    title="Lumbenlengo High Availability Dashboard",
    description="Production-ready AWS Infrastructure Demo",
    version="1.0.0",
    lifespan=lifespan
)

setup_monitoring(app)

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(router)