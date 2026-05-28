# Cross-Platform Desktop App Transformation Plan

## Summary

Transform the current Linux-first media-cleanup pipeline into a Flutter desktop app for Linux, macOS, Windows, and ChromeOS through the ChromeOS Linux environment. The v1 app will wrap the existing shell and Python scripts as the trusted execution engine, preserving the repository's safety-first behavior.

Branch: `feature-cross-platform-desktop-app`

## Safety Rules

- No destructive action runs by default.
- Duplicate cleanup must run in dry-run mode before confirm mode is enabled.
- Confirm mode must remain explicit and visible in both UI and command construction.
- Existing scripts remain the source of truth for media processing behavior.
- Media is moved to `media_trash`; the app must not permanently delete media.

## Implementation Steps

| Step | Status | Commit | Verification | Notes |
| --- | --- | --- | --- | --- |
| 1. Create branch and planning artifacts | Complete | `c61b824` | Plan document and memory file created. | Branch created as `feature-cross-platform-desktop-app` because slash refs were blocked by local `.git` sandboxing. |
| 2. Scaffold Flutter desktop app | Pending | Pending | Pending | Add app shell while preserving existing scripts. |
| 3. Add pipeline runner and step model | Pending | Pending | Pending | Stream logs, pass env vars, capture exit codes. |
| 4. Build core UI | Pending | Pending | Pending | Operational workflow, path settings, logs, guarded actions. |
| 5. Add platform and dependency checks | Pending | Pending | Pending | Linux/ChromeOS full support; macOS/Windows guarded support. |
| 6. Integrate safety-critical workflows | Pending | Pending | Pending | Dry-run review before confirm cleanup or restore. |
| 7. Add tests and CI | Pending | Pending | Pending | Flutter analyze/test plus existing checks. |
| 8. Update user documentation | Pending | Pending | Pending | README, instructions, and app usage docs. |
| 9. Final verification and push | Pending | Pending | Pending | Push structured commits to origin. |

## Public Interfaces

- App settings: `HD_PATH`, `REPORT_DIR`, optional environment overrides.
- App step model: step id, display name, command, platform support, required dependencies, safety level, dry-run requirement, status, logs.
- Existing script CLI contracts remain unchanged unless a small compatibility fix is required for reliable orchestration.

## Test Plan

- Existing checks: ShellCheck, shfmt, Python compile, Ruff, yamllint, Docker Compose config.
- Flutter checks: `flutter analyze`, `flutter test`, desktop build where locally supported.
- Unit coverage for command construction, confirm gating, environment handling, dependency parsing, and step state transitions.

## Progress Log

- 2026-05-28: Started implementation on `feature-cross-platform-desktop-app`.
- 2026-05-28: Completed planning artifact setup; commit `c61b824`.
