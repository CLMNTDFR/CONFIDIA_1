#!/usr/bin/env bash
# Regression suite to run after each iteration (backend + Flutter).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/apps/backend_fastapi"
FRONTEND_DIR="$ROOT_DIR/apps/frontend_flutter"

echo "== Backend (pytest) =="
if [[ -x "$BACKEND_DIR/.venv/bin/pytest" ]]; then
  (cd "$BACKEND_DIR" && .venv/bin/pytest -q)
else
  (cd "$BACKEND_DIR" && pytest -q)
fi

echo ""
echo "== Frontend (flutter test) =="
(cd "$FRONTEND_DIR" && flutter test)

echo ""
echo "OK : pas de régression détectée par la suite locale."
