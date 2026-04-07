import os
import structlog
from contextlib import asynccontextmanager

from fastapi import FastAPI
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Counter, Histogram, Gauge
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource

logger = structlog.get_logger()

limiter = Limiter(key_func=get_remote_address)

# Custom metrics — exported so routes.py can import and use them
http_requests_total = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
request_latency_seconds = Histogram(
    "request_latency_seconds",
    "Request latency in seconds",
    ["method", "endpoint"],
)
active_connections = Gauge(
    "active_connections",
    "Number of active connections",
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("application_starting", version="1.0.0")
    resource = Resource(attributes={SERVICE_NAME: "lumbenlengo-fastapi"})
    provider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(
        OTLPSpanExporter(
            endpoint=os.getenv(
                "OTEL_EXPORTER_ENDPOINT", "http://localhost:4318/v1/traces"
            )
        )
    )
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)
    yield
    logger.info("application_shutting_down")


def setup_monitoring(app: FastAPI):
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    Instrumentator().instrument(app).expose(app)
    FastAPIInstrumentor.instrument_app(app)