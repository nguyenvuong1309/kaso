import Foundation

public struct WrappedContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [WrappedTransactionInput]

    public init(loadTransactions: @escaping @Sendable () async throws -> [WrappedTransactionInput]) {
        self.loadTransactions = loadTransactions
    }
}

public extension WrappedContextClient {
    static let empty = WrappedContextClient(loadTransactions: { [] })

    static let preview = WrappedContextClient(
        loadTransactions: {
            let calendar = Calendar.current
            let now = Date()
            return (0 ..< 40).compactMap { offset -> WrappedTransactionInput? in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else {
                    return nil
                }
                let isExpense = offset % 5 != 0
                let category = ["food", "transport", "shopping", "entertainment"][offset % 4]
                return WrappedTransactionInput(
                    amount: Decimal(50_000 + (offset % 6) * 30_000),
                    categoryID: isExpense ? category : "salary",
                    isExpense: isExpense,
                    occurredAt: date
                )
            }
        }
    )
}
