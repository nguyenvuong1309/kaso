#!/usr/bin/env bash
# Chặn các lệnh destructive nguy hiểm chưa được user xác nhận.
# Exit 2 = block hành động và cho Claude biết lý do.

set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [[ -z "$cmd" ]]; then
  exit 0
fi

block() {
  printf 'BLOCKED: %s\n\nLý do: %s\nNếu thực sự cần, user phải chạy thủ công.\n' "$1" "$2" >&2
  exit 2
}

case "$cmd" in
  *"rm -rf /"*|*"rm -rf ~"*|*"rm -rf \$HOME"*)
    block "Lệnh xoá đệ quy thư mục root/home" "Cực kỳ nguy hiểm — không bao giờ được phép"
    ;;
  *"git push --force"*|*"git push -f "*|*"git push --force-with-lease"*)
    block "Force push" "Có thể overwrite work của người khác. User phải tự chạy."
    ;;
  *"git reset --hard"*)
    if [[ "$cmd" != *"HEAD"* ]] && [[ "$cmd" != *"origin"* ]]; then
      exit 0
    fi
    block "git reset --hard" "Mất uncommitted changes. Hỏi user trước."
    ;;
  *"xcrun simctl erase all"*|*"xcrun simctl delete all"*)
    block "Xoá toàn bộ simulator" "Mất data test, settings simulator. Hỏi user trước."
    ;;
  *"DerivedData"*"rm"*|*"rm"*"DerivedData"*)
    exit 0
    ;;
  *"--no-verify"*)
    block "Skip git hook bằng --no-verify" "Hook tồn tại có lý do. Fix root cause thay vì skip."
    ;;
esac

exit 0
