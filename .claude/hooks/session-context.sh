#!/usr/bin/env bash
# Inject context at session start: git status, current phase, notable TODOs.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

context=""

if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  modified=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  context+="📦 Branch: $branch | $modified file(s) modified\n"
fi

if [[ -f "Tuist/Project.swift" ]] || [[ -f "Project.swift" ]]; then
  context+="🔨 Tuist project — run 'tuist generate' before building\n"
fi

if [[ -f "Package.swift" ]]; then
  context+="📦 SPM workspace detected\n"
fi

if [[ -f ".swiftlint.yml" ]]; then
  context+="✓ SwiftLint configured\n"
fi

if [[ -f ".swiftformat" ]]; then
  context+="✓ SwiftFormat configured\n"
fi

if [[ -n "$context" ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"=== Kaso project status ===\n${context}\nSee plan.md for features, tech-stack.md for architecture, and .claude/CLAUDE.md for rules."}}
EOF
fi

exit 0
