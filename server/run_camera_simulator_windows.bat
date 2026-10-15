@echo off
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Please run run_server_windows.bat once before using the simulator.
  pause
  exit /b 1
)
if "%~1"=="" (
  echo Usage:
  echo   run_camera_simulator_windows.bat "C:\path\to\test-image.jpg"
  echo.
  echo The simulator sends heartbeat automatically and alternates SAFE / NOT_SAFE.
  pause
  exit /b 1
)
.\.venv\Scripts\python.exe .\scripts\camera_simulator.py --image "%~1"
pause
