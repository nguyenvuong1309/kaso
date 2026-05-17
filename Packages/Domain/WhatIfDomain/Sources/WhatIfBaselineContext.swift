import Foundation

public struct WhatIfBaseline: Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var monthlyExpenses: Decimal

    public init(monthlyIncome: Decimal, monthlyExpenses: Decimal) {
        self.monthlyIncome = monthlyIncome
        self.monthlyExpenses = monthlyExpenses
    }

    public static let empty = WhatIfBaseline(monthlyIncome: 0, monthlyExpenses: 0)
}

public struct WhatIfBaselineClient: Sendable {
    public var load: @Sendable () async throws -> WhatIfBaseline

    public init(load: @escaping @Sendable () async throws -> WhatIfBaseline) {
        self.load = load
    }
}

public extension WhatIfBaselineClient {
    static let empty = WhatIfBaselineClient(load: { .empty })
}
