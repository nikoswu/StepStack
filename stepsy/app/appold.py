from flask import Flask, request
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import csv
from io import StringIO
import os

app = Flask(__name__)

client = InfluxDBClient(
    url=os.environ["INFLUX_URL"],
    token=os.environ["INFLUX_TOKEN"],
    org=os.environ["INFLUX_ORG"]
)

# 🔥 IMPORTANT CHANGE
write_api = client.write_api(write_options=SYNCHRONOUS)

@app.route("/upload", methods=["POST"])
def upload():
    file = request.files['file']
    content = file.read().decode("utf-8")

    reader = csv.reader(StringIO(content))
    points = []

    for row in reader:
        if not row or len(row) < 2:
            continue

        try:
            date = row[0].strip() + "T00:00:00Z"
            steps = float(row[1].strip())
        except:
            continue

        print("POINT:", date, steps)

        point = Point("steps") \
            .field("count", steps) \
            .time(date)

        points.append(point)

    print("WRITING POINTS:", len(points))

    write_api.write(bucket=os.environ["INFLUX_BUCKET"], record=points)

    return {"status": "ok", "points": len(points)}

@app.route("/")
def home():
    return "Stepsy API is running"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
