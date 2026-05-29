# Immich Duplicate Confirm Mode Design

The desktop app currently exposes the Immich Takeout duplicate cleanup as a dry-run only step. This is intentional.

The confirm path for `scripts/12_clean_immich_takeout_duplicates.sh` requires a typed confirmation phrase on stdin:

```text
MOVE TAKEOUT DUPLICATES
```

The current `PipelineRunner` does not provide interactive stdin, so the app should not wire `--confirm` directly into a button or one-click action yet.

## Proposed App Design

1. Keep the existing dry-run step in the app workflow.
2. Add a separate confirm UI only after the app can provide stdin to a child process.
3. Require an explicit typed phrase in the UI before the confirm step is enabled.
4. Keep the dry-run and confirm actions separate in the step model.
5. Keep the confirm action Linux-only and review-gated.

## Safety Requirements

- The confirm action must never be automatic.
- The confirm action must never be the default button.
- The confirm action must only be available after a successful dry-run in the same session.
- The app must show the dry-run summary before any confirm action is allowed.
- The confirm action must still move files to `media_trash`; it must not delete files.

## Acceptance Criteria

- The app can pass typed stdin to the cleanup script.
- The confirm button is disabled until the typed phrase matches exactly.
- The confirm path remains separate from the dry-run path.
- The app continues to work on non-Linux platforms without exposing confirm mode.
- The docs make it clear that confirm mode is currently CLI-only until the app supports stdin.
