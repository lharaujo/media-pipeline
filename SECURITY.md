# Security Policy

## Supported versions

The `main` branch is the supported version.

## Reporting a vulnerability

Please open a private vulnerability report on GitHub if available, or contact the maintainer directly. Do not post secrets, private file lists, or personal media paths in public issues.

## Sensitive data warning

This project may handle:

- personal media filenames
- Google Takeout metadata
- GPS metadata embedded in photos
- local mount paths
- Docker and Immich configuration

Before making the repository public, do not commit real `.env` files, rclone tokens, Takeout archives, logs containing private paths, screenshots with personal data, or generated media folders.
