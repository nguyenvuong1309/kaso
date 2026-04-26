---
name: swift6-concurrency
description: Swift 6 strict concurrency patterns — Sendable, actor, MainActor, isolation. Trigger when the user encounters concurrency warnings/errors, or when writing async code, actors, or Sendable conformance.
---

# Swift 6 Strict Concurrency for Kaso

Kaso has strict concurrency enabled from day 1. Every `.swift` file must compile cleanly in this mode.

## 1. Mental model

| Concept | Meaning |
|-----------|-------|
| **Isolation** | "Which context this code runs in" — main actor, custom actor, or nonisolated |
| **Sendable** | "This type can safely move across isolation domains" |
| **Actor** | "A type that protects state — only 1 task accesses it at a time" |

Compiler checks happen at compile time — there is no runtime cost for these checks.

## 2. `@MainActor` — UI code

All code that touches UI (SwiftUI View, UIKit, Core Animation) must be MainActor-isolated:

```swift
@MainActor
public final class KasoRenderer: NSObject, MTKViewDelegate {
    func draw(in view: MTKView) {
        // automatically MainActor
    }
}

@Reducer
public struct TransactionFeature {
    // Does not need MainActor — TCA Reducer is `Sendable`, runs on TCA's queue
}

public struct TransactionView: View {
    // SwiftUI View is automatically `@MainActor`
}
```

## 3. `Sendable` — values crossing isolation

```swift
// Value-type struct containing only Sendable values: automatically Sendable
public struct Transaction: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let amount: Decimal      // Sendable
    public let date: Date           // Sendable
    public let note: String         // Sendable
}

// Class — must be explicit
public final class TransactionStore: Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var _items: [Transaction] = []
    // ... protected by lock
}

// Better: use an actor
public actor TransactionStore {
    private var items: [Transaction] = []
    public func add(_ transaction: Transaction) { items.append(transaction) }
}
```

## 4. Actor for mutable shared state

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

// Usage:
let limiter = RateLimiter(minInterval: 1.0)
if await limiter.shouldAllow() {
    // ...
}
```

## 5. `@Dependency` closure — must be `@Sendable`

```swift
public struct TransactionRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Transaction]
    public var save: @Sendable (Transaction) async throws -> Void
}
```

`@Sendable` closure: do not capture mutable non-Sendable state.

## 6. Bridging older Apple APIs

Many Apple APIs are not fully annotated with `Sendable`. Handling patterns:

```swift
// MTKView delegate — MainActor by design
@MainActor
final class Renderer: NSObject, MTKViewDelegate {
    func draw(in view: MTKView) { /* main actor */ }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { /* main actor */ }
}

// CoreLocation, CloudKit — wrap as an actor or use AsyncStream
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

## 7. `nonisolated` when needed

```swift
@MainActor
public final class ViewModel {
    public let id: UUID = UUID()  // immutable, does not need MainActor

    nonisolated public func description() -> String {
        "VM-\(id)"  // does not touch isolated state
    }
}
```

## 8. Correct async/await

```swift
// Correct
public func loadDashboard() async throws -> Dashboard {
    async let transactions = repository.fetchTransactions()
    async let budgets = repository.fetchBudgets()
    return try await Dashboard(
        transactions: transactions,
        budgets: budgets
    )
}

// Incorrect — sequential when it could be parallel
public func loadBad() async throws -> Dashboard {
    let transactions = try await repository.fetchTransactions()
    let budgets = try await repository.fetchBudgets()  // waits for transactions before starting
    return Dashboard(transactions: transactions, budgets: budgets)
}
```

## 9. `TaskGroup` for dynamic parallelism

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

## 11. AsyncStream instead of Combine

```swift
// Old — Combine
let cancellable = NotificationCenter.default
    .publisher(for: UIApplication.didEnterBackgroundNotification)
    .sink { _ in /* ... */ }

// New — AsyncStream
for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
    // ...
}
```

## 12. Common errors & fixes

### `Capture of 'self' with non-sendable type`

```swift
// Incorrect
class ViewModel {
    func load() {
        Task {
            let data = await fetch()
            self.update(data)  // ← error
        }
    }
}

// Correct
@MainActor
class ViewModel {
    func load() {
        Task {
            let data = await fetch()
            self.update(data)  // ← OK because @MainActor
        }
    }
}
```

### `Sending value of non-sendable type`

```swift
// Incorrect
let nonSendable = SomeClass()
Task.detached {
    use(nonSendable)  // ← error
}

// Correct — wrap in Sendable
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
// Incorrect
nonisolated func foo() {
    print(self.uiProperty)  // ← error
}

// Correct
func foo() async {
    let value = await self.uiProperty
    print(value)
}
```

## 13. Forbidden

- `@unchecked Sendable` — must have a comment explaining the reason and lock mechanism
- `nonisolated(unsafe)` — only for immutable data or manually locked data
- `Task { @MainActor in ... }` as a workaround — fix the root cause
- Disabling warnings with `-disable-availability-checking`
- `unsafeBitCast` cross-isolation
