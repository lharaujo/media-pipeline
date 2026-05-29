# Immich Settings Storage Design

This repo keeps the storage boundary intentionally narrow:

- non-secret UI preferences may be stored locally when they are needed for app usability;
- secrets must not be written to Git-tracked files;
- API keys stay in memory only until a credential-store design is reviewed and approved.

## Storage Policy

| Data type | Current behavior | Future target |
| --- | --- | --- |
| Immich server URL | In memory for the current app session | Local non-secret settings file if the app needs persistence |
| Immich API key | In memory only | OS-backed credential store or equivalent reviewed secret storage |
| Phone checklist state | Local JSON file | Keep local JSON, but continue excluding secrets |
| Phone checklist notes | Local JSON file | Keep local JSON, but keep notes non-secret |
| App workflow preferences | In memory today | Local non-secret settings file if needed |

## Rules

1. Do not write API keys to repo files.
2. Do not write API keys to the phone checklist JSON file.
3. Do not add a disk-backed secret store until the credential-store design is reviewed.
4. Keep read-only Immich connection checks working without requiring a stored API key.
5. Keep local settings files separate from any future secret store.

## Current Repo State

The desktop app already follows the current policy:

- the Immich API key is held only in memory for the running session;
- the phone checklist persists locally as non-secret JSON;
- the docs explain the local checklist storage path and the in-memory API key behavior.

## References

- [`docs/DESKTOP_APP.md`](DESKTOP_APP.md)
- [`docs/IMMICH_HELP_LIBRARY.md`](IMMICH_HELP_LIBRARY.md)
- [`docs/PRIVATE_BETA_CHECKLIST.md`](PRIVATE_BETA_CHECKLIST.md)
