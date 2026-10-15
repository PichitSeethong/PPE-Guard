@echo off
setlocal
set APP_DIR=%~dp0..\ppe_guard_app
set WEB_DIR=%~dp0www
cd /d "%APP_DIR%"
call flutter build web --release --base-href /app/ --dart-define=PPE_SERVER_URL=http://YOUR_SERVER_IP:8000
if errorlevel 1 (
  echo Flutter build failed.
  pause
  exit /b 1
)
if exist "%WEB_DIR%" rmdir /s /q "%WEB_DIR%"
mkdir "%WEB_DIR%"
xcopy /E /I /Y ".\build\web\*" "%WEB_DIR%\" >nul
echo.
echo Web build deployed to: %WEB_DIR%
echo Open http://YOUR_SERVER_IP:8000/app from devices on the LAN.
pause
