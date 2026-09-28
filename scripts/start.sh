#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required for readiness checks."
  echo "Install curl (macOS: already present; Debian/Ubuntu: sudo apt-get install curl) and retry."
  exit 1
fi

# Start Colima if Docker is not available (macOS without Docker Desktop)
if ! docker info >/dev/null 2>&1; then
  if command -v colima >/dev/null 2>&1; then
    echo "Starting Colima (Docker runtime)..."
    colima start --cpu 4 --memory 8 2>/dev/null || colima start
  else
    echo "Docker not running. Install Colima: brew install colima docker docker-compose"
    exit 1
  fi
fi

port_is_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  elif command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -qE ":${port}[[:space:]]"
  else
    return 1
  fi
}

backend_container_running() {
  docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'confidia-backend'
}

if command -v lsof >/dev/null 2>&1 || command -v ss >/dev/null 2>&1; then
  if port_is_listening 8000 && ! backend_container_running; then
    echo "Port 8000 is in use, but container confidia-backend is not running."
    echo "A local uvicorn (or another process) is holding the port."
    echo "Stop that process, then retry. Do not run uvicorn; the API runs in Docker."
    exit 1
  fi
fi

fail_wait() {
  local message="$1"
  local container="$2"
  echo "$message"
  docker compose ps
  docker logs --tail 80 "$container" || true
  exit 1
}

wait_postgres_healthy() {
  echo "Waiting for PostgreSQL (healthy)..."
  local status
  for _ in $(seq 1 30); do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' confidia-postgres 2>/dev/null || true)"
    if [[ "$status" == "healthy" ]]; then
      return 0
    fi
    sleep 2
  done
  fail_wait "PostgreSQL is not healthy." confidia-postgres
}

wait_http() {
  local url="$1"
  local attempts="$2"
  local name="$3"
  local container="$4"
  echo "Waiting for ${name}..."
  for _ in $(seq 1 "$attempts"); do
    if curl -sf "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  fail_wait "${name} did not become ready (${url})." "$container"
}

wait_http_soft() {
  local url="$1"
  local attempts="$2"
  local name="$3"
  echo "Waiting for ${name}..."
  for _ in $(seq 1 "$attempts"); do
    if curl -sf "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "Note: ${name} is not ready yet (${url}). Continuing without it."
}

echo "Starting CONFIDIA stack..."
cd "$ROOT_DIR/docker"
docker compose up -d

wait_postgres_healthy
wait_http "http://localhost:8080/realms/confidia" 60 "Keycloak (realm confidia)" confidia-keycloak
wait_http "http://localhost:8000/health" 60 "backend health" confidia-backend

wait_http_soft "http://localhost:8001" 15 "Paperless"
wait_http_soft "http://localhost:8081" 15 "Nextcloud"

echo ""
echo "CONFIDIA stack is up."
echo ""
echo "  Keycloak:  http://localhost:8080  (admin / admin)"
echo "  Paperless: http://localhost:8001  (admin / admin)"
echo "  Nextcloud: http://localhost:8081  (admin / admin)"
echo "  Backend:   http://localhost:8000  (API docs: /docs, health: /health)"
echo ""
echo "  App login: user / user"
echo ""
echo "Do not run uvicorn locally. The API is already in Docker on port 8000."
echo ""
echo "Flutter frontend from the repo root:"
echo "  cd apps/frontend_flutter && flutter run -d chrome --web-port=8082"
echo ""
echo "Holberton documents use local disk, not Paperless."
