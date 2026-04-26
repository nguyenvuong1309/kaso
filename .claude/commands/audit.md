---
description: Full pre-commit audit — lint + format + test + clean build + dead code
---

Run the full audit pipeline. Block commit if any step fails.

## Pipeline

Run sequentially and stop immediately on failure:

1. **Format check**
   ```bash
   swiftformat --lint --quiet .
   ```

2. **Lint strict**
   ```bash
   swiftlint lint --quiet --strict
   ```

3. **Clean build** (no warnings)
   ```bash
   xcodebuild build -scheme Kaso \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
     -derivedDataPath .build/DerivedData \
     OTHER_SWIFT_FLAGS='-warnings-as-errors' \
     | xcbeautify
   ```

4. **Test all**
   ```bash
   swift test --parallel
   ```

5. **Dead code check**
   ```bash
   periphery scan --quiet --strict
   ```

6. **Privacy manifest** — verify `PrivacyInfo.xcprivacy` exists and is up to date with API usage

7. **Bundle size check** (if an archive exists)
   ```bash
   du -sh .build/DerivedData/Build/Products/*-iphonesimulator/Kaso.app
   ```
   Warn if >50MB.

## Final Report

| Step | Result | Time |
|------|---------|-----------|
| Format | ✓/✗ | ?s |
| Lint | ✓/✗ | ?s |
| Build | ✓/✗ | ?s |
| Test | ✓/✗ | ?s |
| Dead code | ✓/✗ | ?s |
| Privacy | ✓/✗ | ?s |

## After Passing

- Report: "Ready to commit"
- Do not commit automatically — wait for the user
- Suggest a conventional commit message

## After Failure

- Highlight the failed step
- Show the error
- Propose a specific fix
- Do not suggest skipping the step
