from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.services.system_ops import create_backup

if __name__ == '__main__':
    result = create_backup()
    print(f'Backup created: {result["path"]}')
    print(f'Size: {result["size_bytes"]:,} bytes')
