#!/usr/bin/env bash

DRIVE_NAME="${DRIVE_NAME:-target_drive}"
MOUNT_ROOT="${MOUNT_ROOT:-/mnt}"
HD_PATH="${HD_PATH:-$MOUNT_ROOT/$DRIVE_NAME}"

export DRIVE_NAME
export MOUNT_ROOT
export HD_PATH
