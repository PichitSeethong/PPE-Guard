@echo off
setlocal
cd /d "%~dp0"
flutter run -d windows --dart-define=PPE_SERVER_URL=http://localhost:8000
