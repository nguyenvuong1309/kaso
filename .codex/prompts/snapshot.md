---
description: Manage snapshot tests — record, verify, or clean.
---

Manage snapshot tests. Argument: `record` | `verify` | `clean` (default `verify`).

## Mode

### `verify` (default)
```bash
swift test --filter Snapshot
```
Fails if output differs from the baseline.

### `record`
**ONLY run when the UI intentionally changed.**

```bash
SNAPSHOT_TESTING_RECORD=true swift test --filter Snapshot
```

- Ask the user to confirm before recording
- After recording: show the diff (number of changed files)
- Do not commit immediately — the user reviews each file

### `clean`
Scan the `__Snapshots__/` folder, cross-check with test files, and list orphans.

```bash
find . -path '*/__Snapshots__/*' -type f | while read f; do
    test_name=$(basename "$(dirname "$f")")
    test_file="$(dirname "$(dirname "$f")")/${test_name%.*}.swift"
    [[ ! -f "$test_file" ]] && echo "Orphan: $f"
done
```

## Rules

- Snapshot tests cover: light, dark, Dynamic Type XL
- File names match test names
- Do not record while debugging — only after verifying the intended change
- CI snapshot failure: do not fix by local recording — fix the root cause or confirm with the user

## Output

- Number of snapshots pass/fail/new
- Path to `__Snapshots__/` so the user can open visual diffs
- Suggested tools: Kaleidoscope (image) or `git diff` (text)
