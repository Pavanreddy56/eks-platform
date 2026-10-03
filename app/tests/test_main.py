from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_returns_service_info():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["status"] == "running"


def test_liveness():
    assert client.get("/healthz").json() == {"status": "ok"}


def test_readiness_without_database(monkeypatch):
    monkeypatch.delenv("DB_HOST", raising=False)
    resp = client.get("/readyz")
    assert resp.status_code == 200
    assert resp.json()["database"] == "not_configured"


def test_visits_without_database_returns_503(monkeypatch):
    monkeypatch.delenv("DB_HOST", raising=False)
    assert client.post("/api/visits").status_code == 503


def test_metrics_exposes_request_counter():
    client.get("/")
    body = client.get("/metrics").text
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body
