import Foundation

public struct PhantomExpenseCategorySummary: Identifiable, Equatable, Sendable {
    public var category: PhantomExpenseCategory
    public var amount: Decimal
    public var count: Int
    public var fraction: Double

    public init(
        category: PhantomExpenseCategory,
        amount: Decimal,
        count: Int,
        fraction: Double
    ) {
        self.category = category
        self.amount = amount
        self.count = count
        self.fraction = fraction
    }

    public var id: PhantomExpenseCategory {
        category
    }
}

public struct PhantomExpenseMonthlySummary: Equatable, Sendable {
    public var expenses: [PhantomExpense]
    public var totalAvoided: Decimal
    public var categorySummaries: [PhantomExpenseCategorySummary]

    public init(
        expenses: [PhantomExpense],
        totalAvoided: Decimal,
        categorySummaries: [PhantomExpenseCategorySummary]
    ) {
        self.expenses = expenses
        self.totalAvoided = totalAvoided
        self.categorySummaries = categorySummaries
    }

    public static let empty = PhantomExpenseMonthlySummary(
        expenses: [],
        totalAvoided: 0,
        categorySummaries: []
    )

    public var count: Int {
        expenses.count
    }

    public var averageAvoided: Decimal {
        guard count > 0 else {
            return 0
        }
        return totalAvoided / Decimal(count)
    }
}

public enum PhantomExpenseSummaryBuilder {
    public static func monthly(
        expenses: [PhantomExpense],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> PhantomExpenseMonthlySummary {
        let monthlyExpenses = expenses
            .filter { calendar.isDate($0.avoidedAt, equalTo: referenceDate, toGranularity: .month) }
            .sorted { $0.avoidedAt > $1.avoidedAt }
        let total = monthlyExpenses.reduce(Decimal(0)) { $0 + $1.amount }

        let categoryTotals = monthlyExpenses.reduce(into: [PhantomExpenseCategory: (Decimal, Int)]()) { partial, expense in
            let current = partial[expense.category] ?? (0, 0)
            partial[expense.category] = (current.0 + expense.amount, current.1 + 1)
        }
        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        let categorySummaries = categoryTotals
            .map { category, value -> PhantomExpenseCategorySummary in
                let fraction = totalDouble > 0
                    ? NSDecimalNumber(decimal: value.0).doubleValue / totalDouble
                    : 0
                return PhantomExpenseCategorySummary(
                    category: category,
                    amount: value.0,
                    count: value.1,
                    fraction: fraction
                )
            }
            .sorted { $0.amount > $1.amount }

        return PhantomExpenseMonthlySummary(
            expenses: monthlyExpenses,
            totalAvoided: total,
            categorySummaries: categorySummaries
        )
    }
}
