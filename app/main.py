"""Demo API for the EKS platform.

Exposes health/readiness probes, Prometheus metrics, and a small endpoint
that writes to PostgreSQL (Amazon RDS) so the full stack is exercised.
"""

import logging
import os
import time

import psycopg
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

APP_NAME = os.getenv("APP_NAME", "demo-app")
APP_VERSION = os.getenv("APP_VERSION", "dev")
KNOWN_PATHS = {"/", "/healthz", "/readyz", "/metrics", "/api/visits"}

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='{"time":"%(asctime)s","level":"%(levelname)s","msg":"%(message)s"}',
)
log = logging.getLogger(APP_NAME)

REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["method", "path", "status"])
LATENCY = Histogram("http_request_duration_seconds", "HTTP request latency", ["method", "path"])

app = FastAPI(title=APP_NAME, version=APP_VERSION)


def db_configured() -> bool:
    return bool(os.getenv("DB_HOST"))


def db_connect() -> psycopg.Connection:
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "appdb"),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode=os.getenv("DB_SSLMODE", "require"),
        connect_timeout=3,
    )


@app.middleware("http")
async def record_metrics(request: Request, call_next):
    # Bucket unknown paths to keep metric cardinality bounded.
    path = request.url.path if request.url.path in KNOWN_PATHS else "other"
    start = time.perf_counter()
    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
        return response
    finally:
        LATENCY.labels(request.method, path).observe(time.perf_counter() - start)
        REQUESTS.labels(request.method, path, str(status)).inc()


@app.get("/")
def root():
    return {"service": APP_NAME, "version": APP_VERSION, "status": "running"}


@app.get("/healthz")
def healthz():
    """Liveness: the process is up. Never checks dependencies."""
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    """Readiness: the app can serve traffic, including reaching the database."""
    if not db_configured():
        return {"status": "ok", "database": "not_configured"}
    try:
        with db_connect() as conn:
            conn.execute("SELECT 1")
        return {"status": "ok", "database": "reachable"}
    except Exception as exc:  # noqa: BLE001 - report any DB failure as not ready
        log.warning("readiness check failed: %s", exc)
        return JSONResponse(status_code=503, content={"status": "error", "database": "unreachable"})


@app.post("/api/visits")
def add_visit():
    """Record a visit in PostgreSQL and return the running total."""
    if not db_configured():
        return JSONResponse(status_code=503, content={"error": "database not configured"})
    with db_connect() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS visits ("
            "id SERIAL PRIMARY KEY, created_at TIMESTAMPTZ NOT NULL DEFAULT now())"
        )
        conn.execute("INSERT INTO visits DEFAULT VALUES")
        total = conn.execute("SELECT count(*) FROM visits").fetchone()[0]
    return {"total_visits": total}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
