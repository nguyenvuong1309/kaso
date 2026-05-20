import Foundation

public struct SeasonalContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [SeasonalTransactionInput]

    public init(loadTransactions: @escaping @Sendable () async throws -> [SeasonalTransactionInput]) {
        self.loadTransactions = loadTransactions
    }
}

public extension SeasonalContextClient {
    static let empty = SeasonalContextClient(loadTransactions: { [] })

    static let preview = SeasonalContextClient(
        loadTransactions: {
            let calendar = Calendar.current
            let now = Date()
            var result: [SeasonalTransactionInput] = []
            for yearOffset in 1 ... 2 {
                for month in 1 ... 12 {
                    var comps = DateComponents()
                    comps.year = calendar.component(.year, from: now) - yearOffset
                    comps.month = month
                    comps.day = 10
                    guard let date = calendar.date(from: comps) else { continue }
                    let isTet = month == 1 || month == 2
                    result.append(
                        SeasonalTransactionInput(
                            amount: Decimal(isTet ? 9_000_000 : 3_000_000),
                            isExpense: true,
                            occurredAt: date
                        )
                    )
                }
            }
            return result
        }
    )
}
