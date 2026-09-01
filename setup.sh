#!/usr/bin/env bash

set -e

echo "================================="
echo "       Welcome to Stepsy"
echo "         Setup Wizard"
echo "================================="
echo

# --------------------------------------------------
# Check Docker
# --------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    echo "Please install Docker and try again."
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
# Existing configuration
# --------------------------------------------------

if [ -f ".env" ]; then
    echo "WARNING: A .env file already exists."

    read -rp "Overwrite existing configuration? [y/N]: " OVERWRITE

    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Existing configuration was not changed."
        exit 0
    fi

    echo
fi

# --------------------------------------------------
# Port configuration
# --------------------------------------------------

port_in_use() {
    if command -v ss >/dev/null 2>&1; then
        ss -ltn | awk '{print $4}' | grep -qE ":$1$"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -ltn | awk '{print $4}' | grep -qE ":$1$"
    else
        return 1
    fi
}

echo "Configure application ports:"
echo

while true; do
    read -rp "Stepsy API port [5000]: " API_PORT
    API_PORT="${API_PORT:-5000}"

    if ! [[ "$API_PORT" =~ ^[0-9]+$ ]] || [ "$API_PORT" -lt 1 ] || [ "$API_PORT" -gt 65535 ]; then
        echo "Please enter a valid port number between 1 and 65535."
        continue
    fi

    if port_in_use "$API_PORT"; then
        echo "Port $API_PORT is already in use. Please choose another port."
        continue
    fi

    break
done

while true; do
    read -rp "Grafana port [3000]: " GRAFANA_PORT
    GRAFANA_PORT="${GRAFANA_PORT:-3000}"

    if ! [[ "$GRAFANA_PORT" =~ ^[0-9]+$ ]] || [ "$GRAFANA_PORT" -lt 1 ] || [ "$GRAFANA_PORT" -gt 65535 ]; then
        echo "Please enter a valid port number between 1 and 65535."
        continue
    fi

    if [ "$GRAFANA_PORT" = "$API_PORT" ]; then
        echo "Grafana port cannot be the same as the Stepsy API port."
        continue
    fi

    if port_in_use "$GRAFANA_PORT"; then
        echo "Port $GRAFANA_PORT is already in use. Please choose another port."
        continue
    fi

    break
done

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

    PASSWORD_LENGTH=${#INFLUX_PASSWORD}

    if [ "$PASSWORD_LENGTH" -lt 8 ] || [ "$PASSWORD_LENGTH" -gt 72 ]; then
        echo "Password must be between 8 and 72 characters long."
        continue
    fi

    break
done

# --------------------------------------------------
# Generate secure token
# --------------------------------------------------

if command -v openssl >/dev/null 2>&1; then
    INFLUX_TOKEN=$(openssl rand -hex 32)
else
    echo "ERROR: OpenSSL is required to generate a secure token."
    exit 1
fi

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

if ! docker compose config >/dev/null; then
    echo "ERROR: Docker Compose configuration is invalid."
    exit 1
fi

echo "✓ Docker Compose configuration is valid"
echo

# --------------------------------------------------
# Start application
# --------------------------------------------------

read -rp "Start Stepsy now? [Y/n]: " START_NOW
START_NOW="${START_NOW:-Y}"

if [[ "$START_NOW" =~ ^[Yy]$ ]]; then

    echo
    echo "Starting Stepsy..."
    echo

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
    echo "Setup complete!"
    echo
    echo "You can start Stepsy with:"
    echo
    echo "    docker compose up -d --build"
    echo

fi