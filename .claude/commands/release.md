---
description: Release workflow — bump version, archive, upload TestFlight
argument-hint: [patch|minor|major] (default: patch)
---

Release pipeline cho Kaso.

## CẢNH BÁO
Đây là destructive operation — thay đổi version, push tag, upload binary.
Phải xác nhận user 2 lần trước khi thực hiện.

## Pipeline

1. **Pre-flight check**
   - Branch hiện tại = `main`?
   - Working tree clean?
   - Toàn bộ test pass? (chạy `/audit` trước)
   - Có CHANGELOG entry cho version mới?

2. **Bump version**
   - Đọc current version từ `MARKETING_VERSION` trong project
   - Bump theo arg `${1:-patch}` (semver)
   - Update `CFBundleShortVersionString` và `CFBundleVersion`

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

6. **Upload TestFlight** (qua Fastlane — yêu cầu user confirm lần nữa)
   ```bash
   fastlane beta
   ```

7. **Tag git**
   ```bash
   git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
   ```
   - KHÔNG `git push --tags` tự động — báo user push thủ công

## Output cuối

- Version mới: `X.Y.Z (BUILD)`
- TestFlight processing time estimate
- Link App Store Connect
- Reminder: cập nhật What's New trong App Store Connect
