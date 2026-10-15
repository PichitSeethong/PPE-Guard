from __future__ import annotations

import sqlite3

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from .database import get_connection
from .security import _get_user_for_token

router = APIRouter()


class ConnectionManager:
    def __init__(self) -> None:
        self.connections: set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self.connections.add(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        self.connections.discard(websocket)

    async def broadcast(self, payload: dict) -> None:
        dead: list[WebSocket] = []
        for websocket in list(self.connections):
            try:
                await websocket.send_json(payload)
            except Exception:
                dead.append(websocket)
        for websocket in dead:
            self.disconnect(websocket)


manager = ConnectionManager()


@router.websocket('/ws/dashboard')
async def dashboard_websocket(websocket: WebSocket) -> None:
    token = websocket.query_params.get('token', '')
    connection: sqlite3.Connection | None = None
    try:
        connection = get_connection()
        _get_user_for_token(connection, token)
    except Exception:
        await websocket.close(code=1008)
        return
    finally:
        if connection is not None:
            connection.close()

    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)
