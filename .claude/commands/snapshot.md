---
description: Manage snapshot tests — record new snapshots, verify, or clean stale snapshots
argument-hint: [record|verify|clean] (default: verify)
---

Manage snapshot tests for Kaso.

## Mode

### `verify` (default)
Run snapshot tests normally and fail if output differs from the baseline.
```bash
swift test --filter Snapshot
```

### `record`
Record new snapshots — **ONLY run when the UI intentionally changed**.
```bash
SNAPSHOT_TESTING_RECORD=true swift test --filter Snapshot
```
- Ask the user to confirm before recording
- After recording: show the diff (number of changed files) for user review
- Do not commit immediately — the user must review each file

### `clean`
Delete snapshots that are no longer referenced (orphans).
```bash
# Script yourself: scan __Snapshots__ folder, cross-check with test file
```

## Rules

- Snapshot tests must cover: light mode, dark mode, Dynamic Type XL
- Snapshot filenames must match test names
- Do not record while debugging — only after verifying the intended change
- If CI fails because of snapshots: do not fix by recording locally — fix the root cause or confirm with the user

## Output

- Number of snapshots passed / failed / new
- Path to `__Snapshots__/` so the user can open visual diffs
- Suggested diff tools: Kaleidoscope or `git diff` (for text snapshots)
