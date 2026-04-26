---
description: Release pipeline — bump version, archive, upload TestFlight. Requires the user to confirm twice.
---

Release pipeline for Kaso. **Destructive operation** — ask the user to confirm twice.

Argument: `patch` | `minor` | `major` (default `patch`).

## Pipeline

### 1. Pre-flight check
- Current branch = `main`?
- Working tree clean (`git status`)?
- All tests pass? (run `/kaso-audit` first)
- CHANGELOG entry exists for the new version?

Abort if any item fails.

### 2. Bump version
- Read current `MARKETING_VERSION`
- Bump by semver argument
- Update `CFBundleShortVersionString`

### 3. Build number
```bash
CURRENT_PROJECT_VERSION=$(git rev-list --count HEAD)
```

### 4. Archive
```bash
xcodebuild archive \
  -scheme Kaso \
  -destination 'generic/platform=iOS' \
  -archivePath .build/Kaso.xcarchive \
  -derivedDataPath .build/DerivedData \
  | xcbeautify
```

### 5. Export IPA
```bash
xcodebuild -exportArchive \
  -archivePath .build/Kaso.xcarchive \
  -exportPath .build/Export \
  -exportOptionsPlist fastlane/ExportOptions.plist
```

### 6. Upload TestFlight (CONFIRM AGAIN)
```bash
fastlane beta
```

### 7. Tag git
```bash
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
```

Do not run `git push --tags` automatically — tell the user to push manually.

## Final Output

- Version: `X.Y.Z (BUILD)`
- TestFlight processing time estimate (~10-30 min)
- Link App Store Connect
- Reminder: update What's New
- Reminder: push tag manual (`git push origin v$NEW_VERSION`)

## Forbidden

- Do not release from a branch other than `main`
- Do not skip pre-flight if tests fail
- Do not auto-push tags
- Do not approve Fastlane without asking
