import Foundation

public struct MonthlyTransactionSummary: Equatable, Sendable {
    public var income: Decimal
    public var expense: Decimal
    public var balance: Decimal

    public init(
        income: Decimal,
        expense: Decimal,
        balance: Decimal
    ) {
        self.income = income
        self.expense = expense
        self.balance = balance
    }
}

public extension MonthlyTransactionSummary {
    static let empty = MonthlyTransactionSummary(
        income: Decimal(0),
        expense: Decimal(0),
        balance: Decimal(0)
    )
}

public extension Sequence where Element == Transaction {
    func monthlySummary(
        containing date: Date,
        calendar: Calendar = .current
    ) -> MonthlyTransactionSummary {
        let transactions = filter {
            calendar.isDate($0.occurredAt, equalTo: date, toGranularity: .month)
        }
        let income = transactions
            .filter { $0.kind == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let expense = transactions
            .filter { $0.kind == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }

        return MonthlyTransactionSummary(
            income: income,
            expense: expense,
            balance: income - expense
        )
    }
}
