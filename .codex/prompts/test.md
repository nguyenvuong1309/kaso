---
description: Chạy test (unit + snapshot). Optionally filter scope.
---

Chạy test cho Kaso. Argument:
- không có → all tests via SPM
- tên feature/package → test riêng package đó
- `snapshot` → snapshot tests
- `failed` → re-run test fail lần trước

## Lệnh

```bash
# All tests (nhanh)
swift test --parallel

# Specific package
swift test --package-path Packages/Features/${1}Feature --parallel

# Via Xcode (cần simulator cho UI test)
xcodebuild test \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -parallel-testing-enabled YES \
  -resultBundlePath .build/TestResults.xcresult \
  | xcbeautify --renderer terminal
```

## Báo cáo

| Metric | Value |
|--------|-------|
| Pass | X |
| Fail | X |
| Skip | X |
| Time | Xs |
| Coverage | X% |

Nếu fail: list `FILE:LINE — test name — reason` + fix gợi ý.
Nếu coverage drop dưới threshold (Domain 90%, Features 80%): warn.
Nếu snapshot fail: hỏi user record-mode (KHÔNG tự re-record).

## Sau pass

Suggest next: `/kaso-lint`, `/kaso-audit`, hoặc commit.
Nếu modified Swift file mà không có test mới: warn.
