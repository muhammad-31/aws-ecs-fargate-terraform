import psycopg
import pytest
from fastapi.testclient import TestClient

from app import main
from app.config import Settings


@pytest.fixture
def client():
    return TestClient(main.app)


def settings_with_db(**overrides) -> Settings:
    values = dict(
        app_env="test",
        app_version="abc123",
        log_level="info",
        db_host="db.internal",
        db_port=5432,
        db_name="app",
        db_user="app",
        db_password="secret",
        db_sslmode="require",
    )
    values.update(overrides)
    return Settings(**values)


def test_index_reports_version_and_environment(client, monkeypatch):
    monkeypatch.setattr(main, "settings", settings_with_db())

    body = client.get("/").json()

    assert body == {"service": "webapp", "environment": "test", "version": "abc123"}


def test_healthz_is_always_ok(client):
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readyz_without_database_config_is_ok(client, monkeypatch):
    monkeypatch.setattr(main, "settings", settings_with_db(db_host=None))

    response = client.get("/readyz")

    assert response.status_code == 200
    assert response.json()["database"] == "not configured"


def test_readyz_reports_ok_when_database_answers(client, monkeypatch):
    monkeypatch.setattr(main, "settings", settings_with_db())
    seen = {}
    monkeypatch.setattr(main, "check_database", lambda conninfo: seen.setdefault("conninfo", conninfo))

    response = client.get("/readyz")

    assert response.status_code == 200
    assert response.json()["database"] == "ok"
    assert "sslmode=require" in seen["conninfo"]


def test_readyz_returns_503_when_database_is_down(client, monkeypatch):
    monkeypatch.setattr(main, "settings", settings_with_db())

    def broken(conninfo):
        raise psycopg.OperationalError("connection refused")

    monkeypatch.setattr(main, "check_database", broken)

    response = client.get("/readyz")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable", "database": "unreachable"}


def test_conninfo_never_leaks_into_readiness_response(client, monkeypatch):
    monkeypatch.setattr(main, "settings", settings_with_db(db_password="hunter2"))

    def broken(conninfo):
        raise psycopg.OperationalError(f"failed for {conninfo}")

    monkeypatch.setattr(main, "check_database", broken)

    assert "hunter2" not in client.get("/readyz").text
