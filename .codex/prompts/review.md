---
description: Self-review diff hiện tại theo Kaso enterprise rules trước khi commit.
---

Review `git diff` hiện tại theo các tiêu chí enterprise. Output checklist + score, KHÔNG sửa code.

## Checklist

### Architecture (BLOCKER)
- [ ] File Swift đúng layer? (Domain không import Feature/Data)
- [ ] Có `ObservableObject` mới? → bắt buộc đổi `@Observable`
- [ ] Có `class ViewModel` mới? → bắt buộc đổi TCA Reducer
- [ ] Có UIKit code không cần thiết? → flag

### Code quality (MAJOR)
- [ ] `print()`? → `Logger`
- [ ] `try!` / `force unwrap`? → fix
- [ ] Hardcode color/font/spacing? → token `KasoDesignSystem`
- [ ] Hardcode "VND"/"đ" trong UI string? → formatter

### Concurrency (MAJOR)
- [ ] `@unchecked Sendable`? → tìm cách remove
- [ ] `DispatchQueue.main.async`? → `await MainActor.run`
- [ ] Reducer capture `self`?

### Testing (MAJOR)
- [ ] Reducer mới có TestStore test?
- [ ] View mới có snapshot test?
- [ ] Coverage không drop?

### Privacy & Security (BLOCKER)
- [ ] Log số tiền/tên user/SDT vào console?
- [ ] Gửi PII lên cloud (analytics, AI prompt)?
- [ ] Network call có pinning?
- [ ] Sensitive data lưu Keychain (không UserDefaults)?

### Design & UX (MAJOR)
- [ ] Component mới có dark mode preview?
- [ ] Dynamic Type support?
- [ ] Animation honor `accessibilityReduceMotion`?
- [ ] VoiceOver label đầy đủ?

### Localization (MINOR)
- [ ] String mới trong String Catalog?
- [ ] Plural rules cho cả VN + EN?
- [ ] Format số/ngày qua `.formatted()`?

## Output format

```
## Review: <branch> vs main

### Files changed: X (+Y -Z lines)

### 🚨 Blocker
- [file:line] <issue> — <fix>

### ⚠️ Major
- [file:line] <issue> — <fix>

### 💡 Minor
- [file:line] <issue> — <fix>

### ✓ Good
- <điểm tốt>

## Score
- Architecture: X/10
- Code quality: X/10
- Concurrency: X/10
- Testing: X/10
- Privacy: X/10
- Design: X/10
- **Total: X/60**

## Verdict
✅ Pass / ⚠️ Fix major rồi pass / ❌ Block
```

## Sau review

Nếu pass → suggest `/kaso-audit` để verify CI clean.
KHÔNG fix tự động — user quyết.
