from __future__ import annotations

import argparse
import getpass
import sys
from pathlib import Path

SERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER_DIR))

from app.database import get_connection, init_db  # noqa: E402
from app.security import create_user  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description='สร้างบัญชีผู้ใช้สำหรับ PPE Factory Local Server')
    parser.add_argument('--username', required=True)
    parser.add_argument('--display-name', required=True)
    parser.add_argument('--role', choices=['admin', 'supervisor', 'viewer'], default='viewer')
    parser.add_argument('--department', default='Safety Department')
    args = parser.parse_args()

    password = getpass.getpass('Password: ')
    confirm = getpass.getpass('Confirm password: ')
    if password != confirm:
        raise SystemExit('รหัสผ่านไม่ตรงกัน')

    init_db()
    connection = get_connection()
    try:
        user = create_user(connection, args.username, password, args.display_name, args.role, args.department)
        print(f"สร้างผู้ใช้ {user['username']} ({user['role']}) สำเร็จ")
    finally:
        connection.close()


if __name__ == '__main__':
    main()
