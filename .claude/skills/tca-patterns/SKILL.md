---
name: tca-patterns
description: TCA (The Composable Architecture) patterns chuẩn cho Kaso. Trigger khi user nói về reducer, store, action, dependency, navigation TCA, hoặc khi viết/sửa file dạng *Feature.swift.
---

# TCA Patterns cho Kaso

Khi làm việc với TCA, tuân thủ các pattern sau.

## 1. Reducer chuẩn

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

## 2. Quy tắc bất di bất dịch

### State
- `Equatable` luôn (TCA cần để diff)
- `@ObservableState` macro — tự động conform `Observable`
- KHÔNG chứa reference type mutable (class) — dùng struct
- KHÔNG chứa closure — không Equatable được
- Init `public` để feature khác composition được

### Action
- Past tense cho event ("tapped", "loaded", "failed")
- Imperative cho command từ ngoài ("start", "stop") — hiếm dùng
- Nest theo destination/child feature
- KHÔNG đặt logic trong action — chỉ là "data" describing event
- `delegate(.xxx)` pattern để parent handle event từ child

### Reducer body
- `switch` exhaustive trên Action
- Mỗi case return `Effect` (`.none`, `.run`, `.send`, ...)
- KHÔNG side effect ngoài `.run`
- Capture dependency qua `@Dependency`, KHÔNG inject qua initializer

### Effect
- Dùng `.run { send in ... }` cho async work
- `withTaskCancellation(id:)` cho cancellable work (search debounce, polling)
- KHÔNG dùng `Combine` Effect cho code mới — dùng AsyncStream

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

Mọi external dependency phải qua `DependencyKey`:

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

## 5. Test với TestStore

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

## 6. Anti-patterns (cấm)

- `@StateObject var viewModel = ViewModel()` — dùng Store
- Logic trong `View.body` — đẩy vào reducer
- `Reducer` capture `self` trong closure — phải capture local var
- `@Dependency` trong `View` — chỉ dùng trong Reducer
- Trực tiếp mutate `store.state` từ View — dùng `.send(action)`
- Singleton store ngoài `App` root — composition phải explicit

## 7. Composition pattern

Parent feature scope vào child:

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

## 8. Khi nào dùng `@Shared` (TCA 1.10+)

Khi state cần share giữa nhiều feature không qua composition:
- User session
- Feature flags
- Network connectivity status

KHÔNG dùng `@Shared` cho:
- Domain model thông thường — composition là default
- State chỉ 1 feature dùng

```swift
@Shared(.fileStorage(.documentsDirectory.appending(component: "session.json")))
var session: UserSession?
```
