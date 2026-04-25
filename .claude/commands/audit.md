---
description: Full audit trước khi commit — lint + format + test + build clean + dead code
---

Chạy full audit pipeline. Block commit nếu bất kỳ bước nào fail.

## Pipeline

Chạy tuần tự, dừng ngay khi fail:

1. **Format check**
   ```bash
   swiftformat --lint --quiet .
   ```

2. **Lint strict**
   ```bash
   swiftlint lint --quiet --strict
   ```

3. **Build clean** (no warning)
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

6. **Privacy manifest** — verify `PrivacyInfo.xcprivacy` exists và up-to-date với API usage

7. **Bundle size check** (nếu có archive)
   ```bash
   du -sh .build/DerivedData/Build/Products/*-iphonesimulator/Kaso.app
   ```
   Warn nếu >50MB.

## Báo cáo cuối

| Bước | Kết quả | Thời gian |
|------|---------|-----------|
| Format | ✓/✗ | ?s |
| Lint | ✓/✗ | ?s |
| Build | ✓/✗ | ?s |
| Test | ✓/✗ | ?s |
| Dead code | ✓/✗ | ?s |
| Privacy | ✓/✗ | ?s |

## Sau khi pass

- Báo: "Ready to commit"
- KHÔNG tự động commit — đợi user
- Suggest commit message theo conventional commits

## Sau khi fail

- Highlight bước fail
- Hiển thị error
- Đề xuất fix cụ thể
- KHÔNG suggest skip bước
