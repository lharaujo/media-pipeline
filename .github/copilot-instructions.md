# Repository guidance for AI reviewers and coding agents

This project handles personal photo/video archives and can move thousands of files.
Safety matters more than cleverness.

Rules:

- Never add permanent deletion as an automated default.
- Destructive scripts must default to dry-run and require an explicit confirmation flag.
- Preserve support for spaces, Unicode, and localized Google Photos folder names.
- Prefer `rsync`/move-to-trash workflows over irreversible changes.
- Treat Czkawka reports as untrusted text. Parse only strict absolute media paths.
- Keep Immich upload storage (`/data`) separate from the external library (`/library`).
- Add verification commands to documentation whenever workflow behavior changes.
