import Foundation

public struct FutureSelfTransactionInput: Equatable, Sendable {
    public let amount: Decimal
    public let isExpense: Bool
    public let occurredAt: Date

    public init(amount: Decimal, isExpense: Bool, occurredAt: Date) {
        self.amount = amount
        self.isExpense = isExpense
        self.occurredAt = occurredAt
    }
}

public struct FutureSelfContext: Equatable, Sendable {
    public let transactions: [FutureSelfTransactionInput]
    public let currentAge: Int?

    public init(transactions: [FutureSelfTransactionInput], currentAge: Int?) {
        self.transactions = transactions
        self.currentAge = currentAge
    }
}

public enum FutureSelfLetterBuilder {
    public static let minimumTransactionCount = 10
    private static let defaultCurrentAge = 30
    private static let projectionYears = 30

    public static func build(
        context: FutureSelfContext,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> FutureSelfLetter {
        let cutoff = calendar.date(byAdding: .month, value: -3, to: referenceDate) ?? referenceDate
        let recent = context.transactions.filter { $0.occurredAt >= cutoff }

        guard recent.count >= minimumTransactionCount else {
            return FutureSelfLetter(
                quarterLabel: quarterLabel(for: referenceDate, calendar: calendar),
                tone: .steady,
                projectedAge: (context.currentAge ?? defaultCurrentAge) + projectionYears,
                projectedAnnualSavings: 0,
                paragraphKeys: [],
                savingsRate: 0,
                generatedAt: referenceDate,
                isSufficient: false
            )
        }

        let income = recent.filter { !$0.isExpense }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = recent.filter(\.isExpense).reduce(Decimal(0)) { $0 + $1.amount }
        let incomeDouble = NSDecimalNumber(decimal: income).doubleValue
        let expenseDouble = NSDecimalNumber(decimal: expense).doubleValue
        let savingsRate = incomeDouble > 0 ? (incomeDouble - expenseDouble) / incomeDouble : -1
        let monthlyNet = (income - expense) / 3
        let projectedAnnualSavings = max(0, monthlyNet * 12)

        let tone: FutureSelfTone
        if savingsRate >= 0.2 {
            tone = .optimistic
        } else if savingsRate >= 0 {
            tone = .steady
        } else {
            tone = .cautionary
        }

        let paragraphKeys = [
            "futureSelf.body.\(tone.rawValue).1",
            "futureSelf.body.\(tone.rawValue).2",
            "futureSelf.body.\(tone.rawValue).3",
        ]

        return FutureSelfLetter(
            quarterLabel: quarterLabel(for: referenceDate, calendar: calendar),
            tone: tone,
            projectedAge: (context.currentAge ?? defaultCurrentAge) + projectionYears,
            projectedAnnualSavings: projectedAnnualSavings,
            paragraphKeys: paragraphKeys,
            savingsRate: savingsRate,
            generatedAt: referenceDate,
            isSufficient: true
        )
    }

    private static func quarterLabel(for date: Date, calendar: Calendar) -> String {
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let quarter = (month - 1) / 3 + 1
        return "Q\(quarter) \(year)"
    }
}
