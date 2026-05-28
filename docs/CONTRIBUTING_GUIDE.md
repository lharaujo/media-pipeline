# Contributor Guide

This guide expands on the root `CONTRIBUTING.md` file and explains how to contribute safely to a media-cleanup pipeline.

## What this project values

1. Reversibility over speed.
2. Clear logs over silent automation.
3. Dry-runs over clever defaults.
4. Explicit user confirmation over hidden behavior.
5. Documentation that assumes the user is tired, nervous, and working with irreplaceable family media.

## Areas where help is especially useful

- Google Photos Takeout sidecar matching across more languages and archive layouts.
- Safer duplicate grouping and keep-score heuristics.
- More robust handling of corrupted videos and partial archives.
- Immich external-library setup across different Docker Compose versions.
- Clearer troubleshooting for permissions, thumbnails, and failed jobs.
- Sample test fixtures that contain no personal media.

## Review expectations

The following changes require extra scrutiny:

- anything involving `rm`, `mv`, `rsync --delete`, or trash cleanup;
- anything that parses Czkawka, ExifTool, rclone, Docker, or Immich output;
- anything that writes metadata into media files;
- anything that changes Docker volume mounts;
- anything that changes file permissions recursively.

For those changes, the PR description should include a before/after example and the exact verification commands used.

## Safe examples

Prefer examples like this:

```bash
./scripts/06_delete_duplicates.sh | tee /tmp/delete-dry-run.txt
```

Avoid examples that casually include confirmation flags. It is acceptable to document `--confirm`, but it should be surrounded by warnings and should never be part of an automated quick-start command.

## Public repository hygiene

Before pushing, run:

```bash
git status --short
git ls-files | grep -Ei '(\.env$|rclone|token|secret|takeout|\.zip$|\.tgz$|raw_|cleaning_staging|immich_library|media_trash|\.log$)' || true
```

The repository should not contain private media, OAuth tokens, generated reports, raw archives, personal folder names, or local `.env` files.
