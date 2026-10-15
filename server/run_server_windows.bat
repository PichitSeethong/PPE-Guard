@echo off
setlocal
cd /d %~dp0

if not exist .venv (
  py -3 -m venv .venv
)

call .venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if not exist .env (
  copy .env.example .env
  echo.
  echo Created .env from .env.example
  echo Edit .env first: PPE_DATA_DIR, JWT_SECRET, CAMERA_API_KEY, and BOOTSTRAP_ADMIN_PASSWORD.
  echo Then run this file again.
  pause
  exit /b 0
)

echo.
echo PPE Local Server is starting on http://0.0.0.0:8000
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
