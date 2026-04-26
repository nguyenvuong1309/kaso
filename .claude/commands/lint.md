---
description: Run SwiftLint + SwiftFormat lint mode. Optionally auto-fix.
argument-hint: [fix] to auto-fix
---

Lint all Swift code.

## Commands

```bash
# Lint check
swiftlint lint --quiet --strict

# Format check (does not edit)
swiftformat --lint --quiet .
```

## If argument = "fix"

```bash
swiftlint --fix --quiet
swiftformat --quiet .
```

## Report

- Warning count by rule (top 5)
- Files with the most violations (top 5)
- If `--strict` fails: block commit and list the first error with a suggested fix

## Forbidden

- Do not suppress warnings with `// swiftlint:disable` unless the user approves
- Do not edit files in `Packages/*/Tests/Snapshots/` (auto-generated)
