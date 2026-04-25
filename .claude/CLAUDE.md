# Kaso — Hướng dẫn cho Claude Code

> Project **Kaso** — app quản lý tài chính cá nhân iOS, enterprise-grade, SwiftUI + Metal.
> Đọc kỹ trước khi đề xuất hoặc viết code.

## Tài liệu định hướng (đọc đầu tiên)

- **`plan.md`** — toàn bộ tính năng đã chốt, ưu tiên, lộ trình 6 phase
- **`tech-stack.md`** — tech stack, kiến trúc, cấu trúc module
- Không đề xuất tính năng / công nghệ trái với 2 tài liệu này mà chưa hỏi user

## Triết lý kỹ thuật (không thoả hiệp)

1. **Apple-native first** — không thêm dependency third-party nếu Apple đã có giải pháp tương đương
2. **Swift 6 strict concurrency** — không dùng `@unchecked Sendable`, không tắt warning bằng pragma
3. **SwiftUI-only** — chỉ dùng UIKit khi SwiftUI thực sự không có cách. Phải comment lý do.
4. **TCA cho mọi feature** — không MVVM, không vanilla `@StateObject`. Reducer thuần, View không chứa logic.
5. **Test trước, code sau** — mọi reducer phải có test. Domain layer ≥90% coverage.
6. **Metal là moat** — đừng ngại viết shader cho hiệu ứng. Đây là điểm khác biệt của Kaso.
7. **Privacy by default** — không log PII. Dữ liệu tài chính phải mã hoá at-rest.

## Quy ước code

### Naming

- **Type**: `UpperCamelCase`. TCA reducer suffix `Feature` (vd: `TransactionFeature`)
- **Property/function**: `lowerCamelCase`
- **File**: tên trùng type chính (`TransactionFeature.swift` chứa `struct TransactionFeature`)
- **Test file**: suffix `Tests` (`TransactionFeatureTests.swift`)
- **Snapshot file**: suffix `Snapshots`
- **Metal shader**: snake_case file `.metal` + UpperCamelCase function name
- **Tiếng Việt**: comment có thể tiếng Việt, **identifier luôn tiếng Anh**

### File organization

```swift
// 1. Imports — Apple frameworks first, third-party sau, internal cuối
import Foundation
import SwiftUI
import ComposableArchitecture
import KasoDesignSystem

// 2. Type declaration
@Reducer
struct TransactionFeature {
    // 3. State (nested types đầu)
    @ObservableState
    struct State { /* ... */ }

    // 4. Action
    enum Action { /* ... */ }

    // 5. Dependencies
    @Dependency(\.transactionRepository) var repository

    // 6. Body
    var body: some Reducer<State, Action> { /* ... */ }
}
```

### Cấm tuyệt đối

- `force unwrap` (`!`) — trừ `@IBOutlet` (mà Kaso không dùng)
- `try!` — thay bằng `try?` hoặc xử lý error
- `Any` / `AnyObject` — type-safe always
- `print()` — dùng `Logger` từ `KasoLogging`
- `DispatchQueue.main.async` — dùng `await MainActor.run` hoặc `@MainActor`
- `ObservableObject` — dùng `@Observable` macro
- `Combine` cho logic mới — dùng `AsyncStream`. Combine chỉ khi tương tác Apple API bắt buộc
- Singleton mutable state — dùng `@Dependency` injection

### Khuyến khích

- `let` thay vì `var` mặc định
- `private` mặc định, mở rộng khi cần
- `some View` / `some Reducer` thay vì erase type
- `if let x` shorthand (Swift 5.7+) thay vì `if let x = x`
- Trailing closure cho closure cuối
- Dùng `guard` để early return

## Cấu trúc module

Mọi feature mới phải nằm trong **Swift Package** riêng dưới `Packages/Features/`. Tham khảo `tech-stack.md` mục 19.

**Quy tắc dependency** (cấm vi phạm):

- `App` → `Features` → `Domain` → `Data` → `Core`
- `Features` được phụ thuộc `DesignSystem`
- `Domain` **KHÔNG được** phụ thuộc `Features` hoặc `Data`
- Mỗi `Feature` package phải build và `#Preview` được độc lập

## Workflow chuẩn cho mỗi task

1. **Hiểu yêu cầu** — đọc `plan.md` để tìm feature tương ứng nếu có
2. **Lên kế hoạch** — propose approach với user nếu task >30 phút
3. **Test trước** — viết failing test cho reducer/domain logic
4. **Implement** — code theo convention trên
5. **Snapshot test** — viết snapshot cho mọi view mới
6. **Lint & format** — chạy `swiftlint` + `swiftformat` (auto qua hook)
7. **Build clean** — `tuist build` không warning
8. **Preview** — kiểm tra ở light + dark + dynamic type lớn

## SwiftUI patterns

### Đúng

```swift
struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>

    var body: some View {
        List {
            ForEach(store.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .task { await store.send(.task).finish() }
    }
}
```

### Sai — sẽ bị reject

```swift
// ObservableObject + @StateObject
class ViewModel: ObservableObject { /* ... */ }

// Logic trong view body
struct BadView: View {
    var body: some View {
        let total = transactions.reduce(0) { $0 + $1.amount }
        Text("\(total)")
    }
}

// DispatchQueue
DispatchQueue.main.async { self.update() }
```

## Metal patterns

- File `.metal` đặt trong `Sources/.../Shaders/`
- Mỗi shader có DocC comment mô tả input/output
- SwiftUI integration ưu tiên `.colorEffect`, `.distortionEffect`, `.layerEffect` trước khi reach `MTKView`
- `MTKView` chỉ khi cần state phức tạp (60K+ data points, particle system)
- Test shader bằng snapshot — render vào `CGImage` và compare

## Design System

KHÔNG hardcode màu, font, spacing, radius. Dùng token từ `KasoDesignSystem`:

| Đúng | Sai |
|------|-----|
| `Color.kaso.surfacePrimary` | `Color(hex: "#1A1A1A")` |
| `Font.kaso.titleLarge` | `.font(.system(size: 28, weight: .bold))` |
| `Spacing.md` (= 16pt) | `.padding(16)` |

Component mới phải có `#Preview` cho light + dark + Dynamic Type XL.

## Testing

- **Unit test**: Swift Testing (`@Test`) cho code mới, XCTest cho legacy
- **Reducer test**: TCA `TestStore` — assert mọi state change
- **Snapshot test**: Pointfree SnapshotTesting cho mọi view component
- **UI test**: Maestro flow cho critical path (onboarding, log expense, paywall)

```swift
import Testing
@testable import TransactionDomain

@Test("calculates monthly total correctly")
func monthlyTotal() async {
    let transactions: [Transaction] = [/* ... */]
    let total = transactions.monthlyTotal(for: Date())
    #expect(total == 1_500_000)
}
```

## Localization

- App default tiếng Việt, hỗ trợ tiếng Anh
- Dùng **String Catalog** (`.xcstrings`) — không dùng `.strings` cũ
- Format số tiền qua `Decimal.formatted(.currency(code: "VND"))`
- Format ngày qua `Date.formatted(.dateTime.locale(.current))`
- KHÔNG hardcode "VND" hay "đ" trong UI string

## Git workflow

- Branch: `feat/`, `fix/`, `refactor/`, `chore/` + kebab-case
- Commit: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`)
- KHÔNG commit nếu chưa user approve
- KHÔNG `git push` mà chưa user xác nhận
- KHÔNG `--no-verify` skip hook trừ khi user yêu cầu

## Khi gặp lỗi

1. **Đọc error message kỹ** — Swift compiler error rất chi tiết
2. **Không suppress warning** — fix root cause
3. **Không thêm `@MainActor` bừa** — hiểu vì sao concurrency complain
4. **Build clean** — không tolerate warning trong CI

---

*Cập nhật quy ước này khi codebase trưởng thành. Đừng giữ rule cũ chỉ vì lịch sử.*
