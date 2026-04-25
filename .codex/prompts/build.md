---
description: Build Kaso app — chọn scheme/destination phù hợp
---

Build project Kaso. Argument đầu (nếu có) = scheme override, default `Kaso`.

## Bước

1. Detect Tuist setup: nếu có `Tuist/Project.swift` → chạy `tuist generate --no-open` trước
2. Chạy build:

```bash
xcodebuild build \
  -scheme "${1:-Kaso}" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -quiet \
  | xcbeautify --renderer terminal
```

## Báo cáo

- Pass: thời gian build, số warning
- Fail: parse error theo `file:line`, đề xuất fix
- KHÔNG ignore warning — list từng cái
- Lần đầu build: warn user ~3-5 phút (resolve dependency)

## Cấm

- KHÔNG dùng flag `-quiet` để giấu warning
- KHÔNG suggest skip build error
- KHÔNG build với `OTHER_SWIFT_FLAGS` tắt strict concurrency
