#!/usr/bin/env bash
# Auto-format và lint file Swift sau khi Claude edit/write.
# Đọc tool input từ stdin (JSON), trích file path, chạy formatter + linter nếu là .swift.

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

if [[ -z "$file_path" ]]; then
  exit 0
fi

case "$file_path" in
  *.swift)
    if command -v swiftformat >/dev/null 2>&1; then
      swiftformat --quiet "$file_path" 2>/dev/null || true
    fi
    if command -v swiftlint >/dev/null 2>&1; then
      lint_output=$(swiftlint lint --quiet --path "$file_path" 2>&1 || true)
      if [[ -n "$lint_output" ]]; then
        printf '{"systemMessage":"SwiftLint warnings cho %s:\\n%s"}\n' \
          "$(basename "$file_path")" \
          "$(printf '%s' "$lint_output" | head -20 | sed 's/"/\\"/g' | tr '\n' ' ')"
      fi
    fi
    ;;
  *.metal)
    if command -v xcrun >/dev/null 2>&1; then
      xcrun -sdk iphoneos metal -c "$file_path" -o /dev/null 2>&1 | head -20 || true
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0
