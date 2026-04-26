---
description: Build the Kaso app — choose the appropriate scheme/destination
---

Build the Kaso project. First argument (if any) = scheme override, default `Kaso`.

## Steps

1. Detect Tuist setup: if `Tuist/Project.swift` exists → run `tuist generate --no-open` first
2. Run build:

```bash
xcodebuild build \
  -scheme "${1:-Kaso}" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -quiet \
  | xcbeautify --renderer terminal
```

## Report

- Pass: build duration, warning count
- Fail: parse errors by `file:line`, propose fixes
- Do not ignore warnings — list each one
- First build: warn the user it may take ~3-5 minutes (dependency resolution)

## Forbidden

- Do not use `-quiet` to hide warnings
- Do not suggest skipping build errors
- Do not build with `OTHER_SWIFT_FLAGS` that disable strict concurrency
