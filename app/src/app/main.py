"""Small reference service used to exercise the platform end to end.

/healthz  liveness: the process is up (ALB + container health checks)
/readyz   readiness: dependencies (PostgreSQL) answer
/         basic info, including the deployed version
"""

import json
import logging
import time

import psycopg
from fastapi import FastAPI, Response, status

from app.config import Settings, load_settings

settings: Settings = load_settings()



class JsonFormatter(logging.Formatter):
    """One JSON object per line, so CloudWatch Logs Insights can query fields."""

    def format(self, record: logging.LogRecord) -> str:
        entry = {
            "time": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if record.exc_info:
            entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(entry)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=settings.log_level.upper(), handlers=[handler])
log = logging.getLogger("app")

app = FastAPI(title="webapp", version=settings.app_version)


def check_database(conninfo: str) -> None:
    """Open a short-lived connection and run a trivial query."""
    with psycopg.connect(conninfo) as conn:
        conn.execute("SELECT 1")


@app.get("/")
def index() -> dict:
    return {
        "service": "webapp",
        "environment": settings.app_env,
        "version": settings.app_version,
    }


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz")
def readyz(response: Response) -> dict:
    if not settings.database_configured:
        return {"status": "ok", "database": "not configured"}

    started = time.perf_counter()
    try:
        check_database(settings.database_conninfo)
    except psycopg.Error as exc:
        log.warning("readiness check failed: %s", exc.__class__.__name__)
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "unavailable", "database": "unreachable"}

    return {
        "status": "ok",
        "database": "ok",
        "latency_ms": round((time.perf_counter() - started) * 1000, 1),
    }
