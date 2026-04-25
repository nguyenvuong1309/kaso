---
description: Chạy test cho Kaso (unit + snapshot). Optionally filter theo scope.
argument-hint: [scope] (vd: TransactionFeature, Domain, all)
---

Chạy test cho Kaso project.

## Logic

- Không có argument → chạy toàn bộ test
- Argument là tên package/feature → chạy test của package đó
- Argument `snapshot` → record-mode cho snapshot test
- Argument `failed` → re-run chỉ test fail lần trước

## Lệnh

```bash
# All tests via SPM (nhanh, không cần simulator)
swift test --parallel

# Specific package
swift test --package-path Packages/Features/$1Feature --parallel

# Via Xcode (nếu cần simulator)
xcodebuild test \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -parallel-testing-enabled YES \
  -test-iterations 1 \
  -resultBundlePath .build/TestResults.xcresult \
  | xcbeautify --renderer terminal
```

## Báo cáo

- **Pass count / Fail count / Skipped count**
- Nếu fail: list `FILE:LINE — test name — reason`, đề xuất fix
- Nếu coverage drop dưới threshold: warn (Domain ≥ 90%, Features ≥ 80%)
- Nếu snapshot fail: hỏi user có muốn re-record không (KHÔNG tự động re-record)

## Sau khi pass

- Suggest next step: lint, build full, hay commit
- Nếu modified file Swift mà chưa có test mới: warn
