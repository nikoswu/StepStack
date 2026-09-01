#!/usr/bin/env bash

set -e

echo "================================="
echo "       Welcome to Stepsy"
echo "         Setup Wizard"
echo "================================="
echo

# --------------------------------------------------
# Check requirements
# --------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

echo "✓ Docker found"

if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose is not available."
    exit 1
fi

echo "✓ Docker Compose found"
echo

# --------------------------------------------------
# Check existing configuration
# --------------------------------------------------

if [ -f ".env" ]; then
    echo "WARNING: A .env file already exists."
    read -rp "Overwrite existing configuration? [y/N]: " overwrite

    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
        echo "Setup cancelled. Existing configuration was not changed."
        exit 0
    fi

    echo
fi

# --------------------------------------------------
# Port handling
# --------------------------------------------------

port_in_use() {
    local port="$1"

    ss -ltnH 2>/dev/null | awk -v port="$port" '
        $4 ~ ":" port "$" {
            found=1
        }
        END {
            exit !found
        }
    '
}

choose_port() {
    local service="$1"
    local default_port="$2"
    local port

    while true; do
        read -rp "$service port [$default_port]: " port
        port="${port:-$default_port}"

        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo "Please enter a valid port between 1 and 65535." >&2
            continue
        fi

        if port_in_use "$port"; then
            echo "Port $port is already in use. Please choose another port." >&2
            continue
        fi

        printf '%s\n' "$port"
        return 0
    done
}

echo "Configure application ports:"
echo

API_PORT=$(choose_port "Stepsy API" "5000")
GRAFANA_PORT=$(choose_port "Grafana" "3000")

echo
echo "Selected ports:"
echo "Stepsy API: $API_PORT"
echo "Grafana:    $GRAFANA_PORT"
echo

# --------------------------------------------------
# InfluxDB configuration
# --------------------------------------------------

echo "Configure InfluxDB:"
echo

read -rp "InfluxDB username [stepsy]: " INFLUX_USERNAME
INFLUX_USERNAME="${INFLUX_USERNAME:-stepsy}"

while true; do
    read -rsp "InfluxDB password: " INFLUX_PASSWORD
    echo

    if [ -z "$INFLUX_PASSWORD" ]; then
        echo "Password cannot be empty."
        continue
    fi

    break
done

# Generate a secure random token
if command -v openssl >/dev/null 2>&1; then
    INFLUX_TOKEN=$(openssl rand -hex 32)
else
    echo "ERROR: OpenSSL is required to generate a secure token."
    exit 1
fi

echo "✓ Secure InfluxDB token generated"
echo

# --------------------------------------------------
# Create .env file
# --------------------------------------------------

cat > .env <<EOF
# InfluxDB initial setup
INFLUX_USERNAME=$INFLUX_USERNAME
INFLUX_PASSWORD=$INFLUX_PASSWORD
INFLUX_TOKEN=$INFLUX_TOKEN

# Application ports
API_PORT=$API_PORT
GRAFANA_PORT=$GRAFANA_PORT
EOF

echo "✓ Configuration saved to .env"
echo

# --------------------------------------------------
# Validate Docker Compose configuration
# --------------------------------------------------

echo "Validating Docker Compose configuration..."

if docker compose config >/dev/null; then
    echo "✓ Docker Compose configuration is valid"
else
    echo "ERROR: Docker Compose configuration is invalid."
    exit 1
fi

echo

# --------------------------------------------------
# Optional startup
# --------------------------------------------------

read -rp "Start Stepsy now? [Y/n]: " start_stepsy
start_stepsy="${start_stepsy:-Y}"

if [[ "$start_stepsy" == "Y" || "$start_stepsy" == "y" ]]; then

    echo
    echo "Starting Stepsy..."

    docker compose up -d --build

    echo
    echo "================================="
    echo "       Stepsy is running!"
    echo "================================="
    echo
    echo "Stepsy API: http://localhost:$API_PORT"
    echo "Grafana:    http://localhost:$GRAFANA_PORT"
    echo

else

    echo
    echo "Setup complete."
    echo
    echo "Start Stepsy later with:"
    echo
    echo "    docker compose up -d --build"
    echo
fi