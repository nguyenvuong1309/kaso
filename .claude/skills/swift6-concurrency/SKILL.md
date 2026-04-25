---
name: swift6-concurrency
description: Swift 6 strict concurrency patterns — Sendable, actor, MainActor, isolation. Trigger khi user gặp concurrency warning/error, hoặc khi viết async code, actor, Sendable conformance.
---

# Swift 6 Strict Concurrency cho Kaso

Project Kaso bật strict concurrency từ ngày 1. Mọi file `.swift` phải compile clean ở mode này.

## 1. Mental model

| Khái niệm | Nghĩa |
|-----------|-------|
| **Isolation** | "Code này chạy ở context nào" — main actor, custom actor, hoặc nonisolated |
| **Sendable** | "Type này an toàn truyền giữa isolation domain" |
| **Actor** | "Type bảo vệ state — chỉ 1 task access tại 1 thời điểm" |

Compiler check ở compile time — không runtime cost cho check.

## 2. `@MainActor` — UI code

Mọi code chạm UI (SwiftUI View, UIKit, Core Animation) phải MainActor:

```swift
@MainActor
public final class KasoRenderer: NSObject, MTKViewDelegate {
    func draw(in view: MTKView) {
        // tự động MainActor
    }
}

@Reducer
public struct TransactionFeature {
    // KHÔNG cần MainActor — TCA Reducer là `Sendable`, chạy trên TCA's queue
}

public struct TransactionView: View {
    // SwiftUI View tự động `@MainActor`
}
```

## 3. `Sendable` — value cross-isolation

```swift
// Struct value-type chỉ chứa Sendable: tự động Sendable
public struct Transaction: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let amount: Decimal      // Sendable
    public let date: Date           // Sendable
    public let note: String         // Sendable
}

// Class — phải explicit
public final class TransactionStore: Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var _items: [Transaction] = []
    // ... với lock bảo vệ
}

// Tốt hơn: dùng actor
public actor TransactionStore {
    private var items: [Transaction] = []
    public func add(_ transaction: Transaction) { items.append(transaction) }
}
```

## 4. Actor cho mutable shared state

```swift
public actor RateLimiter {
    private var lastCall: Date?
    private let minInterval: TimeInterval

    public init(minInterval: TimeInterval) {
        self.minInterval = minInterval
    }

    public func shouldAllow() -> Bool {
        let now = Date()
        guard let last = lastCall else {
            lastCall = now
            return true
        }
        if now.timeIntervalSince(last) >= minInterval {
            lastCall = now
            return true
        }
        return false
    }
}

// Dùng:
let limiter = RateLimiter(minInterval: 1.0)
if await limiter.shouldAllow() {
    // ...
}
```

## 5. `@Dependency` closure — phải `@Sendable`

```swift
public struct TransactionRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Transaction]
    public var save: @Sendable (Transaction) async throws -> Void
}
```

`@Sendable` closure: KHÔNG capture mutable non-Sendable state.

## 6. Bridging Apple API cũ

Nhiều Apple API chưa annotate `Sendable` đầy đủ. Pattern xử lý:

```swift
// MTKView delegate — tự MainActor
@MainActor
final class Renderer: NSObject, MTKViewDelegate {
    func draw(in view: MTKView) { /* main actor */ }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { /* main actor */ }
}

// CoreLocation, CloudKit — wrap thành actor hoặc dùng AsyncStream
public func locationStream() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let manager = CLLocationManager()
        let delegate = LocationDelegate { location in
            continuation.yield(location)
        }
        manager.delegate = delegate
        manager.startUpdatingLocation()
        continuation.onTermination = { _ in manager.stopUpdatingLocation() }
    }
}
```

## 7. `nonisolated` khi cần

```swift
@MainActor
public final class ViewModel {
    public let id: UUID = UUID()  // immutable, không cần MainActor

    nonisolated public func description() -> String {
        "VM-\(id)"  // không touch isolated state
    }
}
```

## 8. Async/await chuẩn

```swift
// Đúng
public func loadDashboard() async throws -> Dashboard {
    async let transactions = repository.fetchTransactions()
    async let budgets = repository.fetchBudgets()
    return try await Dashboard(
        transactions: transactions,
        budgets: budgets
    )
}

// Sai — sequential khi có thể parallel
public func loadBad() async throws -> Dashboard {
    let transactions = try await repository.fetchTransactions()
    let budgets = try await repository.fetchBudgets()  // chờ transactions xong mới start
    return Dashboard(transactions: transactions, budgets: budgets)
}
```

## 9. `TaskGroup` cho dynamic parallel

```swift
public func parseStatements(_ urls: [URL]) async throws -> [Transaction] {
    try await withThrowingTaskGroup(of: [Transaction].self) { group in
        for url in urls {
            group.addTask { try await parser.parse(url: url) }
        }
        var all: [Transaction] = []
        for try await batch in group {
            all.append(contentsOf: batch)
        }
        return all
    }
}
```

## 10. Cancellation

```swift
public func search(_ query: String) async throws -> [Transaction] {
    try await Task.sleep(for: .milliseconds(300))  // debounce
    try Task.checkCancellation()
    return try await repository.search(query)
}

// TCA effect:
return .run { send in
    for try await result in searchService.stream(query) {
        try Task.checkCancellation()
        await send(.results(result))
    }
}
.cancellable(id: SearchID.self, cancelInFlight: true)
```

## 11. AsyncStream thay Combine

```swift
// Cũ — Combine
let cancellable = NotificationCenter.default
    .publisher(for: UIApplication.didEnterBackgroundNotification)
    .sink { _ in /* ... */ }

// Mới — AsyncStream
for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
    // ...
}
```

## 12. Common errors & fix

### `Capture of 'self' with non-sendable type`

```swift
// Sai
class ViewModel {
    func load() {
        Task {
            let data = await fetch()
            self.update(data)  // ← error
        }
    }
}

// Đúng
@MainActor
class ViewModel {
    func load() {
        Task {
            let data = await fetch()
            self.update(data)  // ← OK vì @MainActor
        }
    }
}
```

### `Sending value of non-sendable type`

```swift
// Sai
let nonSendable = SomeClass()
Task.detached {
    use(nonSendable)  // ← error
}

// Đúng — wrap Sendable
struct SendableWrapper: Sendable {
    let value: SomeData
}
let wrapper = SendableWrapper(value: data)
Task.detached {
    use(wrapper.value)  // OK
}
```

### `Main actor-isolated property cannot be accessed from a non-isolated context`

```swift
// Sai
nonisolated func foo() {
    print(self.uiProperty)  // ← error
}

// Đúng
func foo() async {
    let value = await self.uiProperty
    print(value)
}
```

## 13. Cấm

- `@unchecked Sendable` — phải có comment giải thích lý do và lock mechanism
- `nonisolated(unsafe)` — chỉ cho immutable hoặc có lock manual
- `Task { @MainActor in ... }` để workaround — sửa root cause
- Tắt warning bằng `-disable-availability-checking`
- `unsafeBitCast` cross-isolation
