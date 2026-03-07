#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if [[ -f "$ROOT_DIR/Backend/main.py" ]]; then
	APP_DIR="Backend"
	APP_MODULE="Backend.main:app"
elif [[ -f "$ROOT_DIR/backend/main.py" ]]; then
	APP_DIR="backend"
	APP_MODULE="backend.main:app"
else
	echo "ERROR: Could not find Backend/main.py or backend/main.py"
	exit 1
fi

VENV_ACTIVATE="$ROOT_DIR/$APP_DIR/venv/bin/activate"
if [[ ! -f "$VENV_ACTIVATE" ]]; then
	echo "Virtualenv missing at $VENV_ACTIVATE"
	echo "Run ./setup.sh first."
	exit 1
fi

source "$VENV_ACTIVATE"
exec uvicorn "$APP_MODULE" --host 0.0.0.0 --port 8080
