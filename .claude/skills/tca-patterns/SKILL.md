---
name: tca-patterns
description: Standard TCA (The Composable Architecture) patterns for Kaso. Trigger when the user mentions reducer, store, action, dependency, TCA navigation, or when writing/editing *Feature.swift files.
---

# TCA Patterns for Kaso

When working with TCA, follow these patterns.

## 1. Standard Reducer

```swift
import ComposableArchitecture
import Foundation

@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var transactions: IdentifiedArrayOf<Transaction> = []
        public var isLoading = false
        public var error: AppError?

        @Presents public var destination: Destination.State?

        public init() {}
    }

    public enum Action {
        case task
        case transactionsLoaded([Transaction])
        case loadFailed(AppError)
        case addButtonTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    public enum Destination {
        case addTransaction(AddTransactionFeature)
        case detail(TransactionDetailFeature)
    }

    @Dependency(\.transactionRepository) var repository
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let transactions = try await repository.fetchAll()
                        await send(.transactionsLoaded(transactions))
                    } catch {
                        await send(.loadFailed(.from(error)))
                    }
                }

            case let .transactionsLoaded(transactions):
                state.isLoading = false
                state.transactions = IdentifiedArray(uniqueElements: transactions)
                return .none

            case let .loadFailed(error):
                state.isLoading = false
                state.error = error
                return .none

            case .addButtonTapped:
                state.destination = .addTransaction(AddTransactionFeature.State())
                return .none

            case .destination(.presented(.addTransaction(.delegate(.saved(let transaction))))):
                state.transactions.append(transaction)
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

## 2. Non-Negotiable Rules

### State
- Always `Equatable` (TCA needs it for diffing)
- `@ObservableState` macro — automatically conforms to `Observable`
- Do not contain mutable reference types (classes) — use structs
- Do not contain closures — they cannot be Equatable
- `public` initializer so other features can compose it

### Action
- Use past tense for events ("tapped", "loaded", "failed")
- Use imperative for external commands ("start", "stop") — rarely used
- Nest by destination/child feature
- Do not put logic in actions — they are only "data" describing events
- Use the `delegate(.xxx)` pattern so parents handle events from children

### Reducer body
- Exhaustive `switch` over Action
- Every case returns an `Effect` (`.none`, `.run`, `.send`, ...)
- No side effects outside `.run`
- Capture dependencies through `@Dependency`; do not inject through initializer

### Effect
- Use `.run { send in ... }` for async work
- Use `withTaskCancellation(id:)` for cancellable work (search debounce, polling)
- Do not use `Combine` Effect for new code — use AsyncStream

## 3. View binding

```swift
import ComposableArchitecture
import SwiftUI

public struct TransactionView: View {
    @Bindable public var store: StoreOf<TransactionFeature>

    public init(store: StoreOf<TransactionFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(store.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .overlay {
            if store.isLoading { ProgressView() }
        }
        .toolbar {
            Button("Add") { store.send(.addButtonTapped) }
        }
        .task { await store.send(.task).finish() }
        .sheet(item: $store.scope(state: \.destination?.addTransaction, action: \.destination.addTransaction)) { addStore in
            AddTransactionView(store: addStore)
        }
    }
}
```

## 4. Dependencies

Every external dependency must go through `DependencyKey`:

```swift
import Dependencies

public struct TransactionRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Transaction]
    public var save: @Sendable (Transaction) async throws -> Void
    public var delete: @Sendable (Transaction.ID) async throws -> Void
}

extension TransactionRepository: DependencyKey {
    public static let liveValue = TransactionRepository(
        fetchAll: { /* SwiftData query */ },
        save: { _ in /* ... */ },
        delete: { _ in /* ... */ }
    )

    public static let testValue = TransactionRepository(
        fetchAll: unimplemented("fetchAll"),
        save: unimplemented("save"),
        delete: unimplemented("delete")
    )

    public static let previewValue = TransactionRepository(
        fetchAll: { Transaction.mockList },
        save: { _ in },
        delete: { _ in }
    )
}

extension DependencyValues {
    public var transactionRepository: TransactionRepository {
        get { self[TransactionRepository.self] }
        set { self[TransactionRepository.self] = newValue }
    }
}
```

## 5. Testing with TestStore

```swift
import ComposableArchitecture
import Testing
@testable import TransactionFeature

@MainActor
@Suite("TransactionFeature")
struct TransactionFeatureTests {
    @Test("loads transactions on task")
    func loadsOnTask() async {
        let mockTransactions = [Transaction.mock(amount: 100_000)]

        let store = TestStore(initialState: TransactionFeature.State()) {
            TransactionFeature()
        } withDependencies: {
            $0.transactionRepository.fetchAll = { mockTransactions }
        }

        await store.send(.task) {
            $0.isLoading = true
        }

        await store.receive(\.transactionsLoaded) {
            $0.isLoading = false
            $0.transactions = IdentifiedArray(uniqueElements: mockTransactions)
        }
    }
}
```

## 6. Anti-patterns (Forbidden)

- `@StateObject var viewModel = ViewModel()` — use Store
- Logic in `View.body` — move it into the reducer
- `Reducer` captures `self` in a closure — must capture a local variable instead
- `@Dependency` in `View` — only use it in Reducers
- Directly mutating `store.state` from a View — use `.send(action)`
- Singleton store outside the `App` root — composition must be explicit

## 7. Composition pattern

Parent feature scopes into child:

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State {
        var transaction = TransactionFeature.State()
        var dashboard = DashboardFeature.State()
    }

    enum Action {
        case transaction(TransactionFeature.Action)
        case dashboard(DashboardFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }
        Scope(state: \.dashboard, action: \.dashboard) {
            DashboardFeature()
        }
        Reduce { state, action in
            // cross-feature coordination
            switch action {
            case .transaction(.delegate(.transactionAdded)):
                return .send(.dashboard(.refresh))
            default:
                return .none
            }
        }
    }
}
```

## 8. When to Use `@Shared` (TCA 1.10+)

When state must be shared across multiple features without going through composition:
- User session
- Feature flags
- Network connectivity status

Do not use `@Shared` for:
- Normal domain models — composition is the default
- State used by only one feature

```swift
@Shared(.fileStorage(.documentsDirectory.appending(component: "session.json")))
var session: UserSession?
```
