import os
from io import BytesIO
from unittest.mock import patch

os.environ["INFLUX_URL"] = "http://localhost:8086"
os.environ["INFLUX_TOKEN"] = "test-token"
os.environ["INFLUX_ORG"] = "stepstack"
os.environ["INFLUX_BUCKET"] = "steps"

from stepstack.app.app import app


def test_upload():
    client = app.test_client()

    csv_data = "2026-08-19,1234\n"

    with patch("stepstack.app.app.write_api.write") as mock_write:
        response = client.post(
            "/upload",
            data={
                "file": (
                    BytesIO(csv_data.encode("utf-8")),
                    "test.csv",
                )
            },
            content_type="multipart/form-data",
        )

    assert response.status_code == 200
    assert response.json["status"] == "ok"
    assert response.json["points"] == 1

    mock_write.assert_called_once()