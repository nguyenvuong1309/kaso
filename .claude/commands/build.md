---
description: Build Kaso app — chọn target và scheme phù hợp
argument-hint: [target] (default: Kaso iOS Simulator)
---

Build project Kaso.

## Logic

1. Detect: nếu có `Tuist/Project.swift` → chạy `tuist generate` trước
2. Default scheme: `Kaso`
3. Default destination: iPhone 16 Pro Simulator (iOS latest)
4. Argument `$1` override scheme nếu có

## Lệnh chuẩn

```bash
# Generate nếu cần
[ -f Tuist/Project.swift ] && tuist generate --no-open

# Build
xcodebuild build \
  -scheme "${1:-Kaso}" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -quiet \
  | xcbeautify --renderer terminal
```

## Sau khi build

- Nếu pass: báo "Build success" + thời gian
- Nếu fail: parse error, hiển thị file:line, đề xuất fix
- KHÔNG ignore warning — list tất cả warning
- Nếu lần đầu build: warn user về thời gian (~3-5 phút)
