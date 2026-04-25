---
description: Self-review thay đổi hiện tại theo Kaso rules trước khi commit
---

Review thay đổi local của Kaso theo các tiêu chí enterprise.

## Checklist

### Architecture
- [ ] Có file Swift nào nằm sai layer? (Domain không được import Feature/Data)
- [ ] Có ObservableObject nào mới không? → bắt buộc đổi `@Observable`
- [ ] Có ViewModel nào mới không? → bắt buộc đổi TCA Reducer
- [ ] Có UIKit code không cần thiết? → flag

### Code quality
- [ ] Có `print()` không? → đổi `Logger`
- [ ] Có `try!` / `force unwrap`? → fix
- [ ] Có hardcode color/font/spacing? → dùng `KasoDesignSystem` token
- [ ] Có hardcode currency code "VND" trong UI string? → dùng formatter

### Concurrency
- [ ] `@unchecked Sendable` xuất hiện? → tìm cách remove
- [ ] `DispatchQueue.main.async`? → đổi `await MainActor.run`
- [ ] Reducer có capture `self` không cần thiết?

### Testing
- [ ] Mỗi `Reducer` mới có test?
- [ ] Mỗi `View` mới có snapshot test?
- [ ] Coverage không drop dưới threshold?

### Privacy & Security
- [ ] Có log số tiền/tên user/SDT vào console?
- [ ] Có gửi PII lên cloud (analytics, AI prompt)?
- [ ] Network call có pinning?
- [ ] Sensitive data có lưu Keychain (không UserDefaults)?

### Design & UX
- [ ] Component mới có dark mode preview?
- [ ] Có support Dynamic Type?
- [ ] Animation có honor `accessibilityReduceMotion`?
- [ ] VoiceOver label đầy đủ?

### Localization
- [ ] String mới có trong String Catalog?
- [ ] Plural rules đúng cho cả tiếng Việt + Anh?
- [ ] Format số/ngày qua `Decimal.formatted` / `Date.formatted`?

## Output

Chấm điểm (0-10) cho từng nhóm, list cụ thể:
- File:line vi phạm
- Severity (blocker / major / minor)
- Đề xuất fix

KHÔNG fix tự động — chỉ report. User quyết định.

## Sau review

Nếu pass tất cả → suggest chạy `/audit` để verify CI clean.
