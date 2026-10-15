from __future__ import annotations

import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .config import settings
from .database import get_connection, init_db
from .routes import auth, cameras, dashboard, events, evidence, statistics, system, users
from .security import create_user
from .websocket import router as websocket_router

app = FastAPI(
    title='PPE Guard Site Ready Local Server',
    version='2.0.0',
    description=(
        'On-premises PPE monitoring for reCamera 2002. Evidence stays on the factory server. '
        'Includes role-based access, audit logging, CSV export, system health, and backups.'
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(cameras.router)
app.include_router(events.router)
app.include_router(statistics.router)
app.include_router(dashboard.router)
app.include_router(evidence.router)
app.include_router(system.router)
app.include_router(system.export_router)
app.include_router(websocket_router)


@app.on_event('startup')
def startup() -> None:
    init_db()
    bootstrap_username = os.getenv('BOOTSTRAP_ADMIN_USERNAME', '').strip()
    bootstrap_password = os.getenv('BOOTSTRAP_ADMIN_PASSWORD', '')
    if bootstrap_username and bootstrap_password:
        connection = get_connection()
        try:
            existing = connection.execute('SELECT id FROM users WHERE username = ?', (bootstrap_username,)).fetchone()
            if existing is None:
                create_user(
                    connection,
                    username=bootstrap_username,
                    password=bootstrap_password,
                    display_name=os.getenv('BOOTSTRAP_ADMIN_DISPLAY_NAME', 'System Administrator'),
                    role='admin',
                    department=os.getenv('BOOTSTRAP_ADMIN_DEPARTMENT', 'Safety Department'),
                    must_change_password=False,
                )
                connection.commit()
        finally:
            connection.close()


@app.get('/health', tags=['health'])
def health() -> dict:
    return {
        'ok': True,
        'service': 'ppe-guard-site-ready-local-server',
        'version': '2.0.0',
        'storage': str(settings.evidence_dir),
        'backups': str(settings.backup_dir),
        'required_ppe': list(settings.required_ppe),
        'camera_key_configured': bool(settings.camera_api_key),
    }


# Flutter Web production build can be copied into server/www by build_web_and_deploy_windows.bat.
settings.web_dist_dir.mkdir(parents=True, exist_ok=True)
if settings.web_dist_dir.exists():
    app.mount('/app', StaticFiles(directory=settings.web_dist_dir, html=True), name='ppe_guard_web')

    @app.get('/app/{path:path}', include_in_schema=False)
    def flutter_web_fallback(path: str) -> FileResponse:
        index = settings.web_dist_dir / 'index.html'
        return FileResponse(index)
