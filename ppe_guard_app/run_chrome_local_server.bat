@echo off
setlocal
cd /d "%~dp0"
flutter run -d chrome --dart-define=PPE_SERVER_URL=http://localhost:8000
