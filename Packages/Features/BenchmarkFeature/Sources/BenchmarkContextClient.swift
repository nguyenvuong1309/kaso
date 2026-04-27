import Foundation
import ComposableArchitecture
import TransactionDomain

public struct BenchmarkContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [Transaction]
    public var defaultMonthlyIncome: @Sendable () async throws -> Decimal?

    public init(
        loadTransactions: @escaping @Sendable () async throws -> [Transaction],
        defaultMonthlyIncome: @escaping @Sendable () async throws -> Decimal?
    ) {
        self.loadTransactions = loadTransactions
        self.defaultMonthlyIncome = defaultMonthlyIncome
    }
}

public extension BenchmarkContextClient {
    static let empty = BenchmarkContextClient(
        loadTransactions: { [] },
        defaultMonthlyIncome: { nil }
    )

    static let preview = BenchmarkContextClient(
        loadTransactions: {
            [
                Transaction(
                    amount: 3_600_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 1_200_000,
                    kind: .expense,
                    category: .transport,
                    occurredAt: Date().addingTimeInterval(-86_400)
                ),
                Transaction(
                    amount: 5_500_000,
                    kind: .expense,
                    category: .housing,
                    occurredAt: Date().addingTimeInterval(-86_400 * 2)
                ),
            ]
        },
        defaultMonthlyIncome: { 22_000_000 }
    )
}

private enum BenchmarkContextClientKey: DependencyKey {
    static let liveValue = BenchmarkContextClient.empty
    static let previewValue = BenchmarkContextClient.preview
    static let testValue = BenchmarkContextClient.empty
}

public extension DependencyValues {
    var benchmarkContextClient: BenchmarkContextClient {
        get { self[BenchmarkContextClientKey.self] }
        set { self[BenchmarkContextClientKey.self] = newValue }
    }
}
