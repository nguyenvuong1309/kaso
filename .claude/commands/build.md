---
description: Build the Kaso app — choose the appropriate target and scheme
argument-hint: [target] (default: Kaso iOS Simulator)
---

Build project Kaso.

## Logic

1. Detect: if `Tuist/Project.swift` exists → run `tuist generate` first
2. Default scheme: `Kaso`
3. Default destination: iPhone 16 Pro Simulator (iOS latest)
4. Argument `$1` overrides the scheme when provided

## Standard Command

```bash
# Generate if needed
[ -f Tuist/Project.swift ] && tuist generate --no-open

# Build
xcodebuild build \
  -scheme "${1:-Kaso}" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -quiet \
  | xcbeautify --renderer terminal
```

## After Build

- If it passes: report "Build success" + duration
- If it fails: parse errors, show file:line, propose fixes
- Do not ignore warnings — list all warnings
- On the first build: warn the user about duration (~3-5 minutes)
