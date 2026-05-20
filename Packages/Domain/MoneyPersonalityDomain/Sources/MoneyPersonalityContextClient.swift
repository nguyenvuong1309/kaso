import Foundation

public struct MoneyPersonalityContext: Equatable, Sendable {
    public let transactions: [PersonalityTransactionInput]
    public let budgetUtilizationRatio: Double
    public let savingsRate: Double

    public init(
        transactions: [PersonalityTransactionInput],
        budgetUtilizationRatio: Double,
        savingsRate: Double
    ) {
        self.transactions = transactions
        self.budgetUtilizationRatio = budgetUtilizationRatio
        self.savingsRate = savingsRate
    }
}

public struct MoneyPersonalityContextClient: Sendable {
    public var load: @Sendable () async throws -> MoneyPersonalityContext

    public init(load: @escaping @Sendable () async throws -> MoneyPersonalityContext) {
        self.load = load
    }
}

public extension MoneyPersonalityContextClient {
    static let empty = MoneyPersonalityContextClient(
        load: {
            MoneyPersonalityContext(
                transactions: [],
                budgetUtilizationRatio: 0,
                savingsRate: 0
            )
        }
    )

    static let preview = MoneyPersonalityContextClient(
        load: {
            let now = Date()
            let calendar = Calendar.current
            let transactions: [PersonalityTransactionInput] = (0 ..< 60).map { index in
                let category = ["food", "food", "food", "transport", "shopping", "entertainment"][index % 6]
                let date = calendar.date(byAdding: .day, value: -index, to: now) ?? now
                return PersonalityTransactionInput(
                    amount: Decimal(50_000 + (index % 5) * 30_000),
                    categoryID: category,
                    isExpense: true,
                    occurredAt: date
                )
            }
            return MoneyPersonalityContext(
                transactions: transactions,
                budgetUtilizationRatio: 0.85,
                savingsRate: 0.15
            )
        }
    )
}
