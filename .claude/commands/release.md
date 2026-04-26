---
description: Release workflow — bump version, archive, upload TestFlight
argument-hint: [patch|minor|major] (default: patch)
---

Release pipeline for Kaso.

## WARNING
This is a destructive operation — it changes versions, tags releases, and uploads binaries.
The user must confirm twice before execution.

## Pipeline

1. **Pre-flight check**
   - Current branch = `main`?
   - Working tree clean?
   - All tests pass? (run `/audit` first)
   - CHANGELOG entry exists for the new version?

2. **Bump version**
   - Read current version from `MARKETING_VERSION` in the project
   - Bump theo arg `${1:-patch}` (semver)
   - Update `CFBundleShortVersionString` and `CFBundleVersion`

3. **Generate build number**
   - `CURRENT_PROJECT_VERSION` = git commit count: `git rev-list --count HEAD`

4. **Archive**
   ```bash
   xcodebuild archive \
     -scheme Kaso \
     -destination 'generic/platform=iOS' \
     -archivePath .build/Kaso.xcarchive \
     -derivedDataPath .build/DerivedData \
     | xcbeautify
   ```

5. **Export IPA**
   ```bash
   xcodebuild -exportArchive \
     -archivePath .build/Kaso.xcarchive \
     -exportPath .build/Export \
     -exportOptionsPlist fastlane/ExportOptions.plist
   ```

6. **Upload TestFlight** (through Fastlane — requires user confirmation again)
   ```bash
   fastlane beta
   ```

7. **Tag git**
   ```bash
   git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
   ```
   - Do not run `git push --tags` automatically — tell the user to push manually

## Final Output

- New version: `X.Y.Z (BUILD)`
- TestFlight processing time estimate
- Link App Store Connect
- Reminder: update What's New in App Store Connect
