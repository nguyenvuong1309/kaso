import Foundation

public struct SpendingDNAContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [SpendingDNATransactionInput]

    public init(loadTransactions: @escaping @Sendable () async throws -> [SpendingDNATransactionInput]) {
        self.loadTransactions = loadTransactions
    }
}

public extension SpendingDNAContextClient {
    static let empty = SpendingDNAContextClient(loadTransactions: { [] })

    static let preview = SpendingDNAContextClient(
        loadTransactions: {
            let calendar = Calendar.current
            let now = Date()
            return (0 ..< 60).compactMap { offset -> SpendingDNATransactionInput? in
                guard let date = calendar.date(byAdding: .day, value: -offset * 4, to: now) else {
                    return nil
                }
                let isExpense = offset % 6 != 0
                let category = ["food", "transport", "shopping", "entertainment"][offset % 4]
                return SpendingDNATransactionInput(
                    amount: Decimal(60_000 + (offset % 7) * 40_000),
                    categoryID: isExpense ? category : "salary",
                    isExpense: isExpense,
                    occurredAt: date
                )
            }
        }
    )
}
