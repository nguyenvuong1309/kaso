#!/usr/bin/env bash
# Block dangerous destructive commands that the user has not confirmed.
# Exit 2 = block the action and tell Claude the reason.

set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [[ -z "$cmd" ]]; then
  exit 0
fi

block() {
  printf 'BLOCKED: %s\n\nReason: %s\nIf this is truly needed, the user must run it manually.\n' "$1" "$2" >&2
  exit 2
}

case "$cmd" in
  *"rm -rf /"*|*"rm -rf ~"*|*"rm -rf \$HOME"*)
    block "Recursive deletion of root/home directory" "Extremely dangerous — never allowed"
    ;;
  *"git push --force"*|*"git push -f "*|*"git push --force-with-lease"*)
    block "Force push" "May overwrite someone else's work. The user must run it manually."
    ;;
  *"git reset --hard"*)
    if [[ "$cmd" != *"HEAD"* ]] && [[ "$cmd" != *"origin"* ]]; then
      exit 0
    fi
    block "git reset --hard" "Loses uncommitted changes. Ask the user first."
    ;;
  *"xcrun simctl erase all"*|*"xcrun simctl delete all"*)
    block "Delete all simulators" "Loses test data and simulator settings. Ask the user first."
    ;;
  *"DerivedData"*"rm"*|*"rm"*"DerivedData"*)
    exit 0
    ;;
  *"--no-verify"*)
    block "Skip git hook with --no-verify" "Hooks exist for a reason. Fix the root cause instead of skipping."
    ;;
esac

exit 0
