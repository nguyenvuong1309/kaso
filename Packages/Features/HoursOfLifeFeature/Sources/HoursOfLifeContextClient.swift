import ComposableArchitecture
import Foundation
import TransactionDomain

public struct HoursOfLifeContextClient: Sendable {
    public var recentTransactions: @Sendable () async throws -> [Transaction]
    public var defaultMonthlyIncome: @Sendable () async throws -> Decimal?

    public init(
        recentTransactions: @escaping @Sendable () async throws -> [Transaction],
        defaultMonthlyIncome: @escaping @Sendable () async throws -> Decimal?
    ) {
        self.recentTransactions = recentTransactions
        self.defaultMonthlyIncome = defaultMonthlyIncome
    }
}

public extension HoursOfLifeContextClient {
    static let empty = HoursOfLifeContextClient(
        recentTransactions: { [] },
        defaultMonthlyIncome: { nil }
    )

    static let preview = HoursOfLifeContextClient(
        recentTransactions: {
            [
                Transaction(
                    amount: 65_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 320_000,
                    kind: .expense,
                    category: .transport,
                    occurredAt: Date().addingTimeInterval(-3600 * 5)
                ),
                Transaction(
                    amount: 1_200_000,
                    kind: .expense,
                    category: .shopping,
                    occurredAt: Date().addingTimeInterval(-3600 * 24)
                ),
                Transaction(
                    amount: 18_000_000,
                    kind: .income,
                    category: .salary,
                    occurredAt: Date().addingTimeInterval(-3600 * 48)
                ),
            ]
        },
        defaultMonthlyIncome: { 18_000_000 }
    )
}

private enum HoursOfLifeContextClientKey: DependencyKey {
    static let liveValue = HoursOfLifeContextClient.empty
    static let previewValue = HoursOfLifeContextClient.preview
    static let testValue = HoursOfLifeContextClient.empty
}

public extension DependencyValues {
    var hoursOfLifeContextClient: HoursOfLifeContextClient {
        get { self[HoursOfLifeContextClientKey.self] }
        set { self[HoursOfLifeContextClientKey.self] = newValue }
    }
}
