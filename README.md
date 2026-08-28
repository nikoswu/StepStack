# Stepsy

A self-hosted step tracking stack built with:

* Flask API
* InfluxDB
* Grafana
* Docker Compose

Steps are uploaded as a CSV file through the Stepsy API, stored in InfluxDB, and visualized in Grafana.

## Architecture

```text
CSV file
   │
   ▼
Stepsy API
   │
   ▼
InfluxDB
   │
   ▼
Grafana Dashboard
```

## Requirements

Before starting, make sure the following are installed:

* Docker Engine
* Docker Compose

Verify the installation:

```bash
docker --version
docker compose version
```

## Installation

Clone the repository:

```bash
git clone <YOUR_REPOSITORY_URL>
cd stepsy-api
```

Create your local environment configuration:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
nano .env
```

Configure the following values:

```env
# InfluxDB initial setup
INFLUX_USERNAME=stepsy
INFLUX_PASSWORD=change_this_password
INFLUX_TOKEN=replace_with_a_long_random_token

# Application ports
API_PORT=5000
GRAFANA_PORT=3000
```

### Important

Choose a strong password and a long random token.

The `.env` file contains local credentials and is not committed to Git.

## Start Stepsy

Start the complete stack:

```bash
docker compose up -d --build
```

This starts:

* Stepsy API
* InfluxDB
* Grafana

Check that all containers are running:

```bash
docker compose ps
```

## Access the services

### Stepsy API

```text
http://SERVER_IP:5000
```

Health check:

```text
http://SERVER_IP:5000/health
```

CSV upload page:

```text
http://SERVER_IP:5000/upload-form
```

### Grafana

```text
http://SERVER_IP:3000
```

If you changed `API_PORT` or `GRAFANA_PORT` in `.env`, use those ports instead.

The InfluxDB datasource and Stepsy dashboard are automatically provisioned when Grafana starts.

## Upload step data

Open:

```text
http://SERVER_IP:5000/upload-form
```

Upload a CSV file using the following format:

```csv
2026-04-18,6032
2026-04-19,69
2026-04-20,10461
```

Format:

```text
YYYY-MM-DD,STEP_COUNT
```

After uploading, the data is written to InfluxDB.

Open Grafana and select the Stepsy dashboard to view the data.

## Docker services

The stack consists of:

```text
stepsy-api
stepsy-influxdb
stepsy-grafana
```

All services communicate through an internal Docker network.

InfluxDB and Grafana data are stored in Docker volumes:

```text
influxdb_data
grafana_data
```

These volumes persist data when containers are restarted or recreated.

## Updating the deployment

Pull the latest version:

```bash
git pull
```

Rebuild and update the stack:

```bash
docker compose up -d --build
```

## Stop the stack

Stop the containers:

```bash
docker compose down
```

This does not remove your InfluxDB or Grafana data.

## Remove all data

Warning: this permanently deletes the stored InfluxDB and Grafana data.

```bash
docker compose down -v
```

## Configuration

The `.env` file controls:

| Variable          | Description                                          | Default      |
| ----------------- | ---------------------------------------------------- | ------------ |
| `INFLUX_USERNAME` | InfluxDB administrator username                      | `stepsy`     |
| `INFLUX_PASSWORD` | InfluxDB administrator password                      | User defined |
| `INFLUX_TOKEN`    | Token used by the API and Grafana to access InfluxDB | User defined |
| `API_PORT`        | Port exposed by the Stepsy API                       | `5000`       |
| `GRAFANA_PORT`    | Port exposed by Grafana                              | `3000`       |

## Security

Do not commit your `.env` file.

The `.env.example` file contains only placeholder values and can safely remain in the repository.

For an internet-facing deployment, consider placing the API and Grafana behind a reverse proxy with HTTPS.

## Development

Run the test suite:

```bash
pytest
```

## Deployment

The project is designed to be deployed with a single Docker Compose command:

```bash
docker compose up -d --build
```

A new deployment should follow this process:

```text
Clone repository
        │
        ▼
Create .env from .env.example
        │
        ▼
Configure credentials and ports
        │
        ▼
docker compose up -d --build
        │
        ├── Stepsy API starts
        ├── InfluxDB initializes
        └── Grafana provisions
              ├── InfluxDB datasource
              └── Stepsy dashboard
```
