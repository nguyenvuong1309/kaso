import Foundation

public struct FutureSelfContextClient: Sendable {
    public var loadContext: @Sendable () async throws -> FutureSelfContext

    public init(loadContext: @escaping @Sendable () async throws -> FutureSelfContext) {
        self.loadContext = loadContext
    }
}

public extension FutureSelfContextClient {
    static let empty = FutureSelfContextClient(
        loadContext: { FutureSelfContext(transactions: [], currentAge: nil) }
    )

    static let preview = FutureSelfContextClient(
        loadContext: {
            let calendar = Calendar.current
            let now = Date()
            let transactions = (0 ..< 30).compactMap { offset -> FutureSelfTransactionInput? in
                guard let date = calendar.date(byAdding: .day, value: -offset * 2, to: now) else {
                    return nil
                }
                let isExpense = offset % 4 != 0
                return FutureSelfTransactionInput(
                    amount: Decimal(isExpense ? 120_000 : 4_000_000),
                    isExpense: isExpense,
                    occurredAt: date
                )
            }
            return FutureSelfContext(transactions: transactions, currentAge: 28)
        }
    )
}
