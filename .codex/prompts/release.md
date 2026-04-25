---
description: Release pipeline — bump version, archive, upload TestFlight. Yêu cầu user confirm 2 lần.
---

Release pipeline cho Kaso. **Destructive operation** — hỏi user confirm 2 lần.

Argument: `patch` | `minor` | `major` (default `patch`).

## Pipeline

### 1. Pre-flight check
- Branch hiện tại = `main`?
- Working tree clean (`git status`)?
- Toàn bộ test pass? (chạy `/kaso-audit` trước)
- Có CHANGELOG entry cho version mới?

Nếu fail bất kỳ → abort.

### 2. Bump version
- Đọc `MARKETING_VERSION` hiện tại
- Bump theo arg semver
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

KHÔNG `git push --tags` tự động — báo user push thủ công.

## Output cuối

- Version: `X.Y.Z (BUILD)`
- TestFlight processing time estimate (~10-30 min)
- Link App Store Connect
- Reminder: cập nhật What's New
- Reminder: push tag manual (`git push origin v$NEW_VERSION`)

## Cấm

- KHÔNG release từ branch khác `main`
- KHÔNG skip pre-flight nếu test fail
- KHÔNG auto-push tag
- KHÔNG approve fastlane không hỏi
