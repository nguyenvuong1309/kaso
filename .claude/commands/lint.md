---
description: Chạy SwiftLint + SwiftFormat lint mode. Optionally auto-fix.
argument-hint: [fix] để auto-fix
---

Lint toàn bộ Swift code.

## Lệnh

```bash
# Lint check
swiftlint lint --quiet --strict

# Format check (không sửa)
swiftformat --lint --quiet .
```

## Nếu argument = "fix"

```bash
swiftlint --fix --quiet
swiftformat --quiet .
```

## Báo cáo

- Số warning theo rule (top 5)
- File vi phạm nhiều nhất (top 5)
- Nếu `--strict` fail: block commit, list error đầu tiên với fix gợi ý

## Cấm

- KHÔNG suppress warning bằng `// swiftlint:disable` trừ khi user approve
- KHÔNG sửa file trong `Packages/*/Tests/Snapshots/` (auto-generated)
