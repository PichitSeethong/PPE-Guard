# PPE Guard Flutter App

Flutter client for PPE Guard Site Ready Local Server.

Run development Chrome:

```powershell
flutter pub get
flutter run -d chrome --dart-define=PPE_SERVER_URL=http://localhost:8000
```

For production LAN web deployment, use `server/build_web_and_deploy_windows.bat` after replacing `YOUR_SERVER_IP` with the Server IP.
