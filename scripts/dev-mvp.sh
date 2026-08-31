#!/usr/bin/env bash
# Prepare the light MVP stack: Postgres + Keycloak, Python venv, Alembic.
# Does not start uvicorn or Flutter (those stay in your terminals so you see logs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/apps/backend_fastapi"
DOCKER_DIR="$ROOT_DIR/docker"

if ! docker info >/dev/null 2>&1; then
  if command -v colima >/dev/null 2>&1; then
    echo "Docker n'est pas joignable. Démarrage de Colima..."
    colima start --cpu 4 --memory 8 2>/dev/null || colima start
  else
    echo "Docker n'est pas démarré. Installe Colima (macOS) : brew install colima docker docker-compose"
    echo "ou ouvre Docker Desktop, puis relance ce script."
    exit 1
  fi
fi

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'confidia-backend'; then
  echo "Attention : le conteneur confidia-backend tourne déjà (port 8000)."
  echo "Pour l'API en local avec uvicorn, arrête-le d'abord :"
  echo "  cd docker && docker compose stop backend"
  echo ""
fi

echo "Démarrage de PostgreSQL et Keycloak..."
cd "$DOCKER_DIR"
docker compose up -d postgres keycloak

echo "Attente de PostgreSQL (healthy)..."
for _ in $(seq 1 30); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' confidia-postgres 2>/dev/null || true)"
  if [[ "$status" == "healthy" ]]; then
    break
  fi
  sleep 2
done
if [[ "$(docker inspect --format '{{.State.Health.Status}}' confidia-postgres 2>/dev/null || true)" != "healthy" ]]; then
  echo "PostgreSQL n'est pas healthy. Logs : docker logs confidia-postgres"
  exit 1
fi

echo "Attente de Keycloak (realm confidia)..."
for _ in $(seq 1 60); do
  if curl -sf "http://localhost:8080/realms/confidia" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
if ! curl -sf "http://localhost:8080/realms/confidia" >/dev/null 2>&1; then
  echo "Keycloak n'expose pas encore le realm. Réessaie dans une minute :"
  echo "  curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:8080/realms/confidia"
  echo "Logs : docker logs confidia-keycloak"
  exit 1
fi

if [[ ! -f "$BACKEND_DIR/.env" ]]; then
  cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
  echo "Fichier .env créé depuis .env.example"
fi

if [[ ! -d "$BACKEND_DIR/.venv" ]]; then
  echo "Création de apps/backend_fastapi/.venv ..."
  python3 -m venv "$BACKEND_DIR/.venv"
  "$BACKEND_DIR/.venv/bin/pip" install -U pip
  (cd "$BACKEND_DIR" && .venv/bin/pip install ".[dev]")
fi

echo "Application du schéma SQL (alembic upgrade head)..."
(cd "$BACKEND_DIR" && .venv/bin/alembic upgrade head)

echo ""
echo "Infrastructure MVP prête."
echo ""
echo "Ensuite, laisse deux terminaux ouverts :"
echo ""
echo "  Terminal API :"
echo "    cd apps/backend_fastapi"
echo "    source .venv/bin/activate"
echo "    uvicorn api.main:app --reload --port 8000"
echo ""
echo "  Terminal Flutter :"
echo "    cd apps/frontend_flutter"
echo "    flutter run -d chrome --web-port=8082"
echo ""
echo "Puis ouvre http://localhost:8082  (compte de test : user / user)"
echo "Sans Flutter, tu n'as que l'API (http://localhost:8000/docs)."
echo ""
echo "Tests de non-régression : ./scripts/test.sh"
