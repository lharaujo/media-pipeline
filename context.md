# Context

## What this repo does
This repository sets up and runs a self-hosted media optimization pipeline for Google Drive and Google Photos exports. The flow is:
1. Download or collect source media archives.
2. Extract Google Takeout ZIPs.
3. Repair metadata and stitch GPS/timezone information into media files.
4. Find duplicates and blurry images.
5. Move rejected files to a trash area.
6. Ingest the cleaned media into Immich.

## Main scripts
- `pipeline_config.sh`: centralizes `DRIVE_NAME`, `MOUNT_ROOT`, and `HD_PATH` for shell scripts.
- `pipeline_config.py`: derives the same path settings for Python scripts from the environment.
- `setup.sh`: installs system dependencies, Python packages, Docker, and Czkawka CLI; creates the working directories under `/mnt/target_drive` by default; downloads the latest Immich compose files; rewrites paths in `.env`.
- `stitch_metadata.py`: unzips Google Takeout archives from `/mnt/target_drive/raw_takeout_zips` by default, looks for matching media and JSON sidecars, writes EXIF dates and GPS data with `exiftool`, then moves processed media into `/mnt/target_drive/cleaning_staging`. It also syncs `/mnt/target_drive/raw_gdrive/` into the staging area.
- `cleanup.sh`: runs Czkawka duplicate detection and an ImageMagick blur scan against `/mnt/target_drive/cleaning_staging` by default, saving reports in `$HOME/czkawka_reports`.
- `delete.sh`: reads those reports and moves selected duplicates or blurry files into `/mnt/target_drive/media_trash` by default. Default mode is dry-run; pass `--confirm` to actually move files.

## Dependencies
- System packages: `ca-certificates`, `curl`, `gnupg`, `lsb-release`, `rclone`, `libimage-exiftool-perl`, `python3-pip`, `unzip`, `wget`, Docker, Docker Compose plugin.
- Python packages: `timezonefinder`, `pytz`.
- External tools used at runtime: `exiftool`, `rsync`, `czkawka_cli`, `convert` from ImageMagick.

## Working directories
- `/mnt/target_drive/raw_gdrive`
- `/mnt/target_drive/raw_takeout_zips`
- `/mnt/target_drive/takeout_extracted`
- `/mnt/target_drive/cleaning_staging`
- `/mnt/target_drive/media_trash`
- `/mnt/target_drive/immich_library`
- `/mnt/target_drive/immich_app`

## Maintenance rule
After every push, update this file in the same branch before or as part of the push if any repo behavior, dependencies, paths, or scripts changed. If a push does not change the repo behavior, still verify that this file is current and leave a brief note in the commit or push message that it was reviewed.
