import os

os.environ["INFLUX_URL"] = "http://localhost:8086"
os.environ["INFLUX_TOKEN"] = "test-token"
os.environ["INFLUX_ORG"] = "stepsy"
os.environ["INFLUX_BUCKET"] = "steps"

from stepsy.app.app import app


def test_health():
    client = app.test_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json == {"status": "ok"}