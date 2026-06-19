import os
import structlog
from contextlib import asynccontextmanager

from fastapi import FastAPI
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
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
    try:
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
    except Exception as e:
        logger.warning("otel_tracer_setup_failed", error=str(e))
    yield
    logger.info("application_shutting_down")


def setup_monitoring(app: FastAPI):
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # NOTE: prometheus_fastapi_instrumentator's Instrumentator().instrument(app)
    # crashes with AttributeError: '_IncludedRouter' object has no attribute 'path'
    # when routes are registered via app.include_router() (as routes.py does).
    # We expose metrics manually instead, using the Counter/Histogram/Gauge
    # objects defined above and already used directly in routes.py.
    @app.get("/metrics", include_in_schema=False)
    async def metrics():
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

    try:
        FastAPIInstrumentor.instrument_app(app)
    except Exception as e:
        logger.warning("otel_fastapi_instrumentation_failed", error=str(e))