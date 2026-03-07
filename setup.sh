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

if [[ ! -d "$APP_DIR/venv" ]]; then
  python3 -m venv "$APP_DIR/venv"
fi

source "$APP_DIR/venv/bin/activate"
pip install --upgrade pip
pip install -r "$APP_DIR/requirements.txt"

echo "Created/updated backend virtualenv and installed requirements."
echo "To run the server:"
echo "  source $APP_DIR/venv/bin/activate"
echo "  uvicorn $APP_MODULE --host 0.0.0.0 --port 8080"
