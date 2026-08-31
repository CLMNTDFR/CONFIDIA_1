#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Start Colima if Docker is not available (macOS without Docker Desktop)
if ! docker info >/dev/null 2>&1; then
  if command -v colima >/dev/null 2>&1; then
    echo "🐳 Starting Colima (Docker runtime)..."
    colima start --cpu 4 --memory 8 2>/dev/null || colima start
  else
    echo "❌ Docker not running. Install Colima: brew install colima docker docker-compose"
    exit 1
  fi
fi

echo "🚀 Starting CONFIDIA stack..."
cd "$ROOT_DIR/docker"
docker compose up -d

echo ""
echo "Note : stack Docker complète, y compris l'API sur le port 8000."
echo "Ne lance pas uvicorn en local en plus. Pour le MVP léger (Postgres + Keycloak,"
echo "puis uvicorn + Flutter), voir le README.md à la racine ou ./scripts/dev-mvp.sh"
echo ""
echo "✅ Services started:"
echo "   Keycloak:  http://localhost:8080  (admin/admin)"
echo "   Paperless: http://localhost:8001  (admin/admin)"
echo "   Nextcloud: http://localhost:8081  (admin/admin)"
echo "   Backend:   http://localhost:8000  (API docs: /docs)"
echo ""
echo "📱 To run Flutter frontend:"
echo "   cd apps/frontend_flutter && flutter run -d chrome --web-port=8082"
