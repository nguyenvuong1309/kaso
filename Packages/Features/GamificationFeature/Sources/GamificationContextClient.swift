import BudgetDomain
import ComposableArchitecture
import Foundation
import TransactionDomain

public struct GamificationContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [Transaction]
    public var loadBudgets: @Sendable () async throws -> [Budget]

    public init(
        loadTransactions: @escaping @Sendable () async throws -> [Transaction],
        loadBudgets: @escaping @Sendable () async throws -> [Budget]
    ) {
        self.loadTransactions = loadTransactions
        self.loadBudgets = loadBudgets
    }
}

public extension GamificationContextClient {
    static let empty = GamificationContextClient(
        loadTransactions: { [] },
        loadBudgets: { [] }
    )

    static let preview = GamificationContextClient(
        loadTransactions: {
            [
                Transaction(
                    amount: 65_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 18_000_000,
                    kind: .income,
                    category: .salary,
                    occurredAt: Date().addingTimeInterval(-3_600 * 24)
                ),
                Transaction(
                    amount: 120_000,
                    kind: .expense,
                    category: .transport,
                    occurredAt: Date().addingTimeInterval(-3_600 * 24 * 2)
                ),
            ]
        },
        loadBudgets: {
            [
                Budget(category: .food, monthlyLimit: 3_000_000, spent: 1_200_000),
                Budget(category: .transport, monthlyLimit: 1_500_000, spent: 600_000),
            ]
        }
    )
}

private enum GamificationContextClientKey: DependencyKey {
    static let liveValue = GamificationContextClient.empty
    static let previewValue = GamificationContextClient.preview
    static let testValue = GamificationContextClient.empty
}

public extension DependencyValues {
    var gamificationContextClient: GamificationContextClient {
        get { self[GamificationContextClientKey.self] }
        set { self[GamificationContextClientKey.self] = newValue }
    }
}
