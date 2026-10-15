# Architecture

```text
                          ┌──────────────────────────┐
                          │     reCamera 2002         │
                          │  YOLO + status stabilizer │
                          └─────────────┬────────────┘
                       heartbeat / JSON + JPEG over HTTP
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│      On-premises PC Server (FastAPI / Local LAN)                    │
│  - Camera API key                                                   │
│  - JWT + RBAC + login lockout                                       │
│  - SQLite: users, PPE events, status periods, audit logs           │
│  - Evidence: D:\PPE_Server\evidence                                │
│  - Backup:   D:\PPE_Server\backups                                 │
│  - WebSocket for live Flutter refresh                               │
└───────────────┬─────────────────────────────────────────────────────┘
                │ REST / WebSocket
      ┌─────────┼──────────────┐
      ▼         ▼              ▼
 PPE Guard  Entrance Screen  CSV / Backup
 Web/Phone  at site entrance Admin operations
```

Remote viewing is intentionally excluded from this version. It can be added safely later using a VPN, not public port forwarding.
