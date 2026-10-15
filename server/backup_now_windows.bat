@echo off
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Please run run_server_windows.bat once before backup.
  pause
  exit /b 1
)
.\.venv\Scripts\python.exe .\scripts\backup_data.py
pause
