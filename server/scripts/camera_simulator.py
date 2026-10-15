r"""Simulate reCamera 2002 while the YOLO model or camera is not ready.

Example (from the server directory):
  .\.venv\Scripts\python.exe .\scripts\camera_simulator.py --image C:\\test\\person.jpg

The simulator never writes to SQLite itself. It uses the same HTTP endpoints and
X-Camera-Key as reCamera, so it exercises the real Server → Flutter workflow.
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / '.env')


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat()


def post_heartbeat(base_url: str, key: str, camera_id: str, name: str, location: str, model: str) -> None:
    response = requests.post(
        f'{base_url}/api/v1/cameras/heartbeat',
        headers={'X-Camera-Key': key},
        json={'camera_id': camera_id, 'camera_name': name, 'location': location, 'model_version': model},
        timeout=15,
    )
    response.raise_for_status()
    print(f'[heartbeat] {response.status_code} {response.json().get("camera", {}).get("status")}')


def post_event(
    base_url: str,
    key: str,
    image: Path,
    *,
    camera_id: str,
    name: str,
    location: str,
    model: str,
    person_track_id: str,
    status: str,
) -> None:
    safe = status == 'SAFE'
    detected = ['helmet', 'glasses', 'gloves', 'shoes', 'safety-vest'] if safe else ['glasses', 'gloves', 'shoes', 'safety-vest']
    missing = [] if safe else ['helmet']
    payload = {
        'camera_id': camera_id,
        'camera_name': name,
        'location': location,
        'person_track_id': person_track_id,
        'captured_at': now_iso(),
        'current_status': status,
        'missing_ppe': missing,
        'detected_ppe': detected,
        'confidence': 0.96 if safe else 0.93,
        'person_count': 1,
        'model_version': model,
    }
    mime = mimetypes.guess_type(image.name)[0] or 'image/jpeg'
    with image.open('rb') as file:
        response = requests.post(
            f'{base_url}/api/v1/cameras/events',
            headers={'X-Camera-Key': key},
            data={'metadata': json.dumps(payload)},
            files={'evidence_image': (image.name, file, mime)},
            timeout=30,
        )
    response.raise_for_status()
    body = response.json()
    print(f'[event] {status}: accepted={body.get("accepted")} reason={body.get("reason", "-")}')


def main() -> None:
    parser = argparse.ArgumentParser(description='PPE Guard reCamera simulator')
    parser.add_argument('--server', default=os.getenv('SIMULATOR_SERVER_URL', 'http://localhost:8000'))
    parser.add_argument('--api-key', default=os.getenv('CAMERA_API_KEY', ''))
    parser.add_argument('--image', required=True, help='Path to a .jpg/.jpeg/.png evidence image')
    parser.add_argument('--camera-id', default='recamera-01')
    parser.add_argument('--camera-name', default='reCamera 2002 (Simulator)')
    parser.add_argument('--location', default='จุดตรวจ PPE')
    parser.add_argument('--model', default='ppe-simulator-v1')
    parser.add_argument('--person-track-id', default='sim-person-001')
    parser.add_argument('--heartbeat-seconds', type=int, default=30)
    parser.add_argument('--event-seconds', type=int, default=60, help='Seconds between status changes in demo mode')
    parser.add_argument('--once', choices=['SAFE', 'NOT_SAFE'], help='Send one status event then exit')
    args = parser.parse_args()

    base_url = args.server.rstrip('/')
    image = Path(args.image).expanduser().resolve()
    if not image.is_file():
        sys.exit(f'ไม่พบไฟล์ภาพ: {image}')
    if not args.api_key:
        sys.exit('ไม่พบ CAMERA_API_KEY: ใส่ใน server/.env หรือส่ง --api-key')

    print(f'PPE Guard simulator → {base_url} using {image.name}')
    if args.once:
        post_heartbeat(base_url, args.api_key, args.camera_id, args.camera_name, args.location, args.model)
        post_event(
            base_url, args.api_key, image, camera_id=args.camera_id, name=args.camera_name,
            location=args.location, model=args.model, person_track_id=args.person_track_id, status=args.once,
        )
        return

    statuses = ['SAFE', 'NOT_SAFE', 'SAFE']
    index = 0
    next_heartbeat = 0.0
    next_event = 0.0
    try:
        while True:
            now = time.monotonic()
            if now >= next_heartbeat:
                post_heartbeat(base_url, args.api_key, args.camera_id, args.camera_name, args.location, args.model)
                next_heartbeat = now + max(5, args.heartbeat_seconds)
            if now >= next_event:
                status = statuses[index % len(statuses)]
                post_event(
                    base_url, args.api_key, image, camera_id=args.camera_id, name=args.camera_name,
                    location=args.location, model=args.model, person_track_id=args.person_track_id, status=status,
                )
                index += 1
                next_event = now + max(10, args.event_seconds)
            time.sleep(1)
    except KeyboardInterrupt:
        print('\nSimulator stopped.')


if __name__ == '__main__':
    main()
