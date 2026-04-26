import Foundation

public struct MonthlyCategorySpending: Identifiable, Equatable, Sendable {
    public var category: TransactionCategory
    public var amount: Decimal
    public var fraction: Double

    public var id: String {
        category.id
    }

    public init(
        category: TransactionCategory,
        amount: Decimal,
        fraction: Double
    ) {
        self.category = category
        self.amount = amount
        self.fraction = fraction
    }
}

public extension Sequence where Element == Transaction {
    func monthlyCategorySpendings(
        containing date: Date,
        calendar: Calendar = .current
    ) -> [MonthlyCategorySpending] {
        let currentMonthExpenses = filter {
            $0.kind == .expense
                && calendar.isDate($0.occurredAt, equalTo: date, toGranularity: .month)
        }
        let totalExpense = currentMonthExpenses.reduce(Decimal(0)) {
            $0 + $1.amount
        }

        guard totalExpense > Decimal(0) else {
            return []
        }

        var categoryAmounts: [TransactionCategory: Decimal] = [:]
        currentMonthExpenses.forEach { transaction in
            categoryAmounts[transaction.category, default: Decimal(0)] += transaction.amount
        }

        let totalExpenseValue = NSDecimalNumber(decimal: totalExpense).doubleValue
        return categoryAmounts
            .map { category, amount in
                MonthlyCategorySpending(
                    category: category,
                    amount: amount,
                    fraction: NSDecimalNumber(decimal: amount).doubleValue / totalExpenseValue
                )
            }
            .sorted {
                if $0.amount == $1.amount {
                    $0.category.id < $1.category.id
                } else {
                    $0.amount > $1.amount
                }
            }
    }
}
