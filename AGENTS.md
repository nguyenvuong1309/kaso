# Kaso — Hướng dẫn cho AI Coding Agents (Codex / GPT / etc.)

> File này được đọc tự động bởi **OpenAI Codex** và mọi agent tuân thủ chuẩn `AGENTS.md`.
> Nội dung tương đương `.claude/CLAUDE.md` nhưng theo format chung — mọi agent đọc được.
> Project **Kaso**: app quản lý tài chính cá nhân iOS, enterprise-grade, SwiftUI + Metal.

## Tài liệu phải đọc trước khi code

1. **`plan.md`** — toàn bộ tính năng, ưu tiên, lộ trình 6 phase
2. **`tech-stack.md`** — tech stack, kiến trúc, cấu trúc module
3. **`.claude/CLAUDE.md`** — chi tiết mở rộng (tương thích, có thêm SwiftUI patterns examples)

Không đề xuất tính năng / công nghệ trái với 2 doc trên mà chưa hỏi user.

## Triết lý kỹ thuật (không thoả hiệp)

1. **Apple-native first** — không thêm dependency third-party nếu Apple đã có
2. **Swift 6 strict concurrency** — không `@unchecked Sendable`, không pragma tắt warning
3. **SwiftUI-only** — UIKit chỉ khi SwiftUI thực sự không được, phải comment lý do
4. **TCA (The Composable Architecture)** cho mọi feature — không MVVM, không vanilla `@StateObject`
5. **Test trước, code sau** — Reducer phải có test, Domain ≥90% coverage
6. **Metal là moat** — đừng ngại viết shader cho hiệu ứng khác biệt
7. **Privacy by default** — không log PII, dữ liệu tài chính mã hoá at-rest

## Setup & build

### Yêu cầu môi trường

- Xcode 16+ (Swift 6.0)
- iOS 17.0+ deployment target
- Tuist (`brew install tuist`)
- SwiftLint, SwiftFormat (`brew install swiftlint swiftformat`)
- xcbeautify (`brew install xcbeautify`)

### Lệnh build/test chuẩn

```bash
# Generate Xcode project (nếu Tuist setup)
tuist generate --no-open

# Build
xcodebuild build \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  | xcbeautify

# Test (SPM, nhanh)
swift test --parallel

# Test với simulator
xcodebuild test \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -parallel-testing-enabled YES \
  | xcbeautify

# Lint
swiftlint lint --quiet --strict

# Format
swiftformat --quiet .
```

### Pre-commit checklist

Bắt buộc pass trước khi commit (xem `.codex/prompts/audit.md`):
1. `swiftformat --lint --quiet .`
2. `swiftlint lint --strict`
3. `xcodebuild build` (no warning)
4. `swift test --parallel`
5. `periphery scan --strict` (dead code)
6. Verify `PrivacyInfo.xcprivacy` updated

## Quy ước code

### Naming

- **Type**: `UpperCamelCase`. TCA reducer suffix `Feature` (`TransactionFeature`)
- **Property/function**: `lowerCamelCase`
- **File**: trùng tên type chính
- **Test file**: suffix `Tests`
- **Snapshot file**: suffix `Snapshots`
- **Metal shader**: snake_case file `.metal` + UpperCamelCase function
- **Comment** có thể tiếng Việt; **identifier** luôn tiếng Anh

### File organization

```swift
// 1. Imports — Apple frameworks first, third-party, internal cuối
import Foundation
import SwiftUI
import ComposableArchitecture
import KasoDesignSystem

// 2. Type declaration
@Reducer
struct TransactionFeature {
    @ObservableState
    struct State { /* ... */ }

    enum Action { /* ... */ }

    @Dependency(\.transactionRepository) var repository

    var body: some Reducer<State, Action> { /* ... */ }
}
```

### Cấm tuyệt đối

| Cấm | Thay bằng |
|-----|-----------|
| `force unwrap` (`!`) | `if let`, `guard let`, `??` |
| `try!` | `try?` hoặc `do/catch` |
| `Any`, `AnyObject` | Generic, protocol cụ thể |
| `print()` | `Logger` từ `KasoLogging` |
| `DispatchQueue.main.async` | `await MainActor.run` hoặc `@MainActor` |
| `ObservableObject` | `@Observable` macro |
| `Combine` cho code mới | `AsyncStream` |
| Singleton mutable state | `@Dependency` injection |

### Khuyến khích

- `let` mặc định, `var` chỉ khi cần
- `private` mặc định
- `some View` / `some Reducer` thay vì erase type
- `if let x` shorthand
- Trailing closure cho closure cuối
- `guard` để early return

## Cấu trúc module

Mọi feature mới nằm trong **Swift Package** dưới `Packages/Features/`. Quy tắc dependency (cấm vi phạm):

```
App → Features → Domain → Data → Core
       ↓
  DesignSystem
```

- `Domain` **KHÔNG** phụ thuộc `Features` hoặc `Data`
- Mỗi `Feature` package phải build và `#Preview` được độc lập

## Workflow chuẩn cho mỗi task

1. Đọc `plan.md` tìm feature tương ứng
2. Propose approach với user nếu task >30 phút
3. Viết failing test cho reducer/domain logic
4. Implement theo convention
5. Snapshot test cho view
6. Lint + format
7. Build clean (no warning)
8. Preview light + dark + Dynamic Type lớn

## TCA pattern bắt buộc

```swift
@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var transactions: IdentifiedArrayOf<Transaction> = []
        public var isLoading = false
        public init() {}
    }

    public enum Action {
        case task
        case transactionsLoaded([Transaction])
        case loadFailed(Error)
    }

    @Dependency(\.transactionRepository) var repository
    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let txs = try await repository.fetchAll()
                        await send(.transactionsLoaded(txs))
                    } catch {
                        await send(.loadFailed(error))
                    }
                }
            case let .transactionsLoaded(txs):
                state.isLoading = false
                state.transactions = IdentifiedArray(uniqueElements: txs)
                return .none
            case let .loadFailed(error):
                state.isLoading = false
                return .none
            }
        }
    }
}
```

View dùng `@Bindable var store: StoreOf<XxxFeature>`. Không bao giờ dùng `ObservableObject`, `@StateObject`, ViewModel.

## Design System — CẤM hardcode

Dùng token từ `KasoDesignSystem`:

| Đúng | Sai |
|------|-----|
| `Color.kaso.surfacePrimary` | `Color(hex: "#1A1A1A")` |
| `Font.kaso.titleLarge` | `.font(.system(size: 28, weight: .bold))` |
| `Spacing.md` (= 16pt) | `.padding(16)` |
| `Radius.lg` | `cornerRadius: 12` |
| Số tiền: `Font.kaso.numericLarge` | `.font(.title)` |

Component mới phải có `#Preview` cho light + dark + Dynamic Type XL.

## Metal — ưu tiên SwiftUI shader API

Decision tree:
- Pixel color manipulation → `.colorEffect`
- Pixel position warp → `.distortionEffect`
- Đọc neighbor pixel (blur, displacement) → `.layerEffect`
- 60K+ data point hoặc particle stateful → `MTKView` + Renderer

Mọi animation Metal phải có Reduce Motion fallback.

## Testing

- **Swift Testing** (`@Test`) cho code mới, XCTest cho legacy
- **TCA TestStore** cho reducer (assert mọi state change)
- **Pointfree SnapshotTesting** cho view component
- **Maestro** cho E2E flow critical (onboarding, log expense, paywall)

```swift
import Testing
import ComposableArchitecture
@testable import TransactionFeature

@MainActor
@Test("loads transactions on task")
func loadsOnTask() async {
    let mockTxs = [Transaction.mock(amount: 100_000)]
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.transactionRepository.fetchAll = { mockTxs }
    }

    await store.send(.task) { $0.isLoading = true }
    await store.receive(\.transactionsLoaded) {
        $0.isLoading = false
        $0.transactions = IdentifiedArray(uniqueElements: mockTxs)
    }
}
```

## Localization

- Default tiếng Việt, hỗ trợ tiếng Anh
- **String Catalog** (`.xcstrings`), không `.strings` cũ
- Số tiền: `Decimal.formatted(.currency(code: "VND"))`
- Ngày: `Date.formatted(.dateTime.locale(.current))`
- KHÔNG hardcode "VND" / "đ" trong UI string

## Privacy & Security

- KHÔNG log PII (số tiền, tên user, SDT, email, GPS) vào console
- Sensitive data lưu **Keychain**, không UserDefaults
- Network call có **certificate pinning**
- Cập nhật `PrivacyInfo.xcprivacy` khi dùng Required Reason API mới
- KHÔNG gửi PII lên cloud AI prompt — redact trước

## Git workflow

- Branch: `feat/`, `fix/`, `refactor/`, `chore/` + kebab-case
- Commit: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`)
- KHÔNG commit nếu user chưa approve
- KHÔNG `git push` nếu user chưa xác nhận
- KHÔNG `--no-verify` skip hook

## Approval & sandbox (Codex-specific)

Khuyến nghị mode khi làm việc với Kaso:

| Mode | Khi dùng |
|------|----------|
| `sandbox_mode = "workspace-write"` | Default — đủ cho mọi dev task |
| `approval_policy = "on-failure"` | Default — chỉ ask khi hành động fail |
| `approval_policy = "untrusted"` | Khi onboarding feature mới chưa quen |

Cấm tuyệt đối:
- `sandbox_mode = "danger-full-access"` trừ khi user explicit setup
- Approve auto cho `git push`, `fastlane release`, `xcrun altool`

## Sai lầm hay gặp (đừng lặp)

- Tạo `class ViewModel: ObservableObject` → sai, dùng TCA Reducer
- Hardcode `.padding(16)` → dùng `Spacing.md`
- `try!` để "tạm thời" → fix root cause
- Quên `#Preview` cho dark mode → bắt buộc
- Chỉ viết unit test, quên snapshot → cả hai
- Dùng `.system(.title)` cho số tiền → dùng `.kaso.numericLarge` (tabular)
- Viết Metal shader nhưng quên Reduce Motion fallback

## Tài liệu tham khảo

- TCA: https://pointfreeco.github.io/swift-composable-architecture
- Swift 6 migration: https://www.swift.org/migration
- SwiftUI Metal: https://developer.apple.com/documentation/swiftui/colorrendertree
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines

---

*File này là source of truth cho mọi AI agent. Đừng tự ý bỏ qua rule mà không hỏi user.*
*Khi quy ước project tiến hoá, update file này — đừng giữ rule cũ chỉ vì lịch sử.*
