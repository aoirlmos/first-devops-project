from app import app

client = app.test_client()


def test_index_returns_greeting():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.get_json()


def test_health_reports_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"


def test_metrics_exposes_request_counter():
    client.get("/")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"app_requests_total" in response.data
