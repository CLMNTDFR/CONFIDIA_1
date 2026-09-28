#!/bin/sh
set -e

KEYCLOAK_URL="${KEYCLOAK_URL:-http://keycloak:8080}"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-confidia}"
REALM_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}"

# Wait up to about 2 minutes (60 attempts, 2s apart) for Keycloak.
ready=0
attempt=1
while [ "$attempt" -le 60 ]; do
  if curl -sf "$REALM_URL" >/dev/null 2>&1; then
    ready=1
    break
  fi
  attempt=$((attempt + 1))
  sleep 2
done

if [ "$ready" -ne 1 ]; then
  echo "ERROR: Keycloak realm is not reachable at ${REALM_URL} after 120 seconds."
  echo "Start Keycloak and confirm KEYCLOAK_URL and KEYCLOAK_REALM before launching the backend."
  exit 1
fi

alembic upgrade head
exec uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
