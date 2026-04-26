#!/usr/bin/env bash
# When Claude ends a turn: remind if Swift files are modified and tests have not run.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

modified_swift=$(git status --porcelain 2>/dev/null | grep -E '\.(swift|metal)$' | wc -l | tr -d ' ')

if [[ "$modified_swift" -gt 0 ]]; then
  cat <<EOF
{"systemMessage":"⚠️  ${modified_swift} Swift/Metal file(s) are modified. Before committing:\n  • swift test (or tuist test)\n  • Snapshot tests pass?\n  • Clean build with no warnings?"}
EOF
fi

exit 0
