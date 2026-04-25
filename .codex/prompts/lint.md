---
description: SwiftLint + SwiftFormat lint mode. Argument "fix" để auto-fix.
---

Lint Swift code.

## Lệnh

### Default (check only)
```bash
swiftlint lint --quiet --strict
swiftformat --lint --quiet .
```

### Nếu argument = "fix"
```bash
swiftlint --fix --quiet
swiftformat --quiet .
```

## Báo cáo

- Số warning theo rule (top 5)
- File vi phạm nhiều nhất (top 5)
- Nếu `--strict` fail: block commit, list error đầu với fix gợi ý

## Cấm

- KHÔNG suppress warning bằng `// swiftlint:disable` mà chưa user approve
- KHÔNG sửa file trong `Packages/*/Tests/Snapshots/` (auto-generated)
- KHÔNG tắt rule trong `.swiftlint.yml` để pass — fix code
