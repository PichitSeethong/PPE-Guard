#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
if [ ! -f .env ]; then
  cp .env.example .env
  echo 'Created .env. Edit PPE_DATA_DIR, JWT_SECRET, CAMERA_API_KEY, and BOOTSTRAP_ADMIN_PASSWORD, then run again.'
  exit 0
fi
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
