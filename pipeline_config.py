#!/usr/bin/env python3
import os
from pathlib import Path

DRIVE_NAME = os.environ.get("DRIVE_NAME", "target_drive")
MOUNT_ROOT = Path(os.environ.get("MOUNT_ROOT", "/mnt"))
HD_PATH = Path(os.environ.get("HD_PATH", str(MOUNT_ROOT / DRIVE_NAME)))
