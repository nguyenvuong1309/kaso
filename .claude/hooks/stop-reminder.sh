#!/usr/bin/env bash
# Khi Claude kết thúc lượt: nhắc nếu có file Swift modified mà chưa run test.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

modified_swift=$(git status --porcelain 2>/dev/null | grep -E '\.(swift|metal)$' | wc -l | tr -d ' ')

if [[ "$modified_swift" -gt 0 ]]; then
  cat <<EOF
{"systemMessage":"⚠️  ${modified_swift} file Swift/Metal đang modified. Trước khi commit:\n  • swift test (hoặc tuist test)\n  • Snapshot test pass?\n  • Build clean không warning?"}
EOF
fi

exit 0
