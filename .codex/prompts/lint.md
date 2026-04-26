---
description: SwiftLint + SwiftFormat lint mode. Argument "fix" to auto-fix.
---

Lint Swift code.

## Commands

### Default (check only)
```bash
swiftlint lint --quiet --strict
swiftformat --lint --quiet .
```

### If argument = "fix"
```bash
swiftlint --fix --quiet
swiftformat --quiet .
```

## Report

- Warning count by rule (top 5)
- Files with the most violations (top 5)
- If `--strict` fails: block commit and list the first error with a suggested fix

## Forbidden

- Do not suppress warnings with `// swiftlint:disable` without user approval
- Do not edit files in `Packages/*/Tests/Snapshots/` (auto-generated)
- Do not disable rules in `.swiftlint.yml` to pass — fix the code
