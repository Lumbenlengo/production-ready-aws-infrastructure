# app/Dockerfile
# Multi-stage build — keeps the final image small and secure

# ── Build stage ───────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir --target=/app/deps -r requirements.txt

# ── Runtime stage ─────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Create non-root user — security best practice
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy installed deps from builder
COPY --from=builder /app/deps /app/deps
ENV PYTHONPATH=/app/deps

# Copy application source
COPY main.py .

# IMDSv2 — no AWS credentials baked in
ENV AWS_EC2_METADATA_V1_DISABLED=true
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run as non-root
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/live')"

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--timeout-keep-alive", "5"]
