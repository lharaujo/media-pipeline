# Self-Hosted Media Optimization Pipeline
An automated pipeline to download, repair metadata, deduplicate, and ingest Google Drive and Google Photos media into a self-hosted Immich instance.

## Overview
The scripts expect a media workspace on an external drive. By default they use the mounted drive name `target_drive`, which resolves to `/mnt/target_drive`.

Drive configuration is centralized in [pipeline_config.sh](/home/leo/projects/media-pipeline/pipeline_config.sh:1):

```bash
DRIVE_NAME="${DRIVE_NAME:-target_drive}"
MOUNT_ROOT="${MOUNT_ROOT:-/mnt}"
HD_PATH="${HD_PATH:-$MOUNT_ROOT/$DRIVE_NAME}"
```

Typical ways to switch targets:

```bash
./setup.sh
DRIVE_NAME=archive_4tb ./setup.sh
HD_PATH=/media/leo/archive_4tb ./setup.sh
```

## Directory Layout
After setup, the drive contains:

- `raw_gdrive`: files copied from Google Drive that should be merged into the staging area
- `raw_takeout_zips`: Google Takeout ZIP archives
- `takeout_extracted`: temporary extraction area for Takeout archives
- `cleaning_staging`: repaired and merged media, ready for duplicate and blur scanning
- `media_trash`: files selected for removal
- `immich_library`: Immich upload library path
- `immich_app`: Immich `docker-compose.yml` and `.env`

## Prerequisites
- A mounted writable drive at `/mnt/target_drive`, or another path passed via `HD_PATH`
- Ubuntu or another Debian-based Linux system with `sudo`
- Internet access for dependency and Immich downloads during setup

`cleanup.sh` also requires ImageMagick's `convert` command. If it is missing, install it manually:

```bash
sudo apt-get install -y imagemagick
```

## Script Usage

### 1. Initial setup
Run the bootstrap script once:

```bash
./setup.sh
```

To use another drive mounted under `/mnt`, change only the drive name:

```bash
DRIVE_NAME=my_other_drive ./setup.sh
```

What it does:
- installs system packages, Python packages, Docker, and `czkawka_cli`
- creates the directory structure on the target drive
- downloads Immich's `docker-compose.yml` and example `.env` into `immich_app`
- rewrites the Immich upload path to use `immich_library`

After setup, refresh your shell group membership before using Docker:

```bash
newgrp docker
```

### 2. Add source media
Copy your inputs into the drive:

- Put Google Takeout ZIPs into `raw_takeout_zips`
- Put already-filtered Google Drive media into `raw_gdrive`

Example:

```bash
cp ~/Downloads/*.zip /mnt/target_drive/raw_takeout_zips/
rsync -a ~/google-drive-export/ /mnt/target_drive/raw_gdrive/
```

### 3. Repair metadata and build the staging set
Run:

```bash
python3 stitch_metadata.py
```

What it does:
- extracts every ZIP from `raw_takeout_zips` into `takeout_extracted`
- reads Google Photos JSON sidecars
- writes timestamps and GPS metadata into matching media with `exiftool`
- moves processed files into `cleaning_staging`
- merges `raw_gdrive` into `cleaning_staging` with `rsync`

### 4. Generate duplicate and blur reports
Run:

```bash
./cleanup.sh
```

Reports are written to:

```bash
$HOME/czkawka_reports
```

Expected files:
- `duplicate_images.txt`
- `duplicate_videos.txt`
- `blurry_images.txt`

### 5. Review and trash flagged files
Start with the default dry run:

```bash
./delete.sh
```

That prints which files would be moved into `media_trash` without changing anything.

To actually move flagged files:

```bash
./delete.sh --confirm
```

### 6. Start Immich
The setup script downloads Immich configuration into `immich_app`. Start it with Docker Compose:

```bash
cd /mnt/target_drive/immich_app
docker compose up -d
```

At that point, point Immich at the configured library path on the same drive.

## Typical End-to-End Flow

```bash
./setup.sh
python3 stitch_metadata.py
./cleanup.sh
./delete.sh
./delete.sh --confirm
cd /mnt/target_drive/immich_app
docker compose up -d
```

## Notes
- Change `DRIVE_NAME` when you want the scripts to use `/mnt/<drive-name>`.
- Set `HD_PATH` directly when the mount is outside `/mnt`.
- `delete.sh` moves files into `media_trash`; it does not permanently delete them.
- `stitch_metadata.py` reprocesses files found in `takeout_extracted`, so keeping that directory tidy matters if you rerun the pipeline.
