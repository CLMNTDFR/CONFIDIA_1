#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🛑 Stopping CONFIDIA stack..."
cd "$ROOT_DIR/docker"
docker compose down

echo "✅ All services stopped."
