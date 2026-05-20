import Foundation

public struct WrappedTransactionInput: Equatable, Sendable {
    public let amount: Decimal
    public let categoryID: String
    public let isExpense: Bool
    public let occurredAt: Date

    public init(amount: Decimal, categoryID: String, isExpense: Bool, occurredAt: Date) {
        self.amount = amount
        self.categoryID = categoryID
        self.isExpense = isExpense
        self.occurredAt = occurredAt
    }
}

public enum WrappedBuilder {
    public static let minimumTransactionCount = 5

    public static func build(
        transactions: [WrappedTransactionInput],
        scope: WrappedScope,
        referenceDate: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> WrappedReport {
        let interval: DateInterval? = {
            switch scope {
            case .month: calendar.dateInterval(of: .month, for: referenceDate)
            case .year: calendar.dateInterval(of: .year, for: referenceDate)
            }
        }()
        guard let interval else {
            return WrappedReport.empty
        }

        let scoped = transactions.filter { interval.contains($0.occurredAt) }
        guard scoped.count >= minimumTransactionCount else {
            return WrappedReport(
                scope: scope,
                periodLabel: formatPeriod(scope: scope, date: referenceDate, calendar: calendar, locale: locale),
                totalIncome: 0,
                totalExpense: 0,
                netBalance: 0,
                transactionCount: scoped.count,
                topCategories: [],
                largestTransaction: 0,
                noSpendDays: 0,
                bestStreak: 0,
                generatedAt: referenceDate,
                isSufficient: false
            )
        }

        let income = scoped.filter { !$0.isExpense }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = scoped.filter(\.isExpense).reduce(Decimal(0)) { $0 + $1.amount }
        let net = income - expense

        let categoryTotals = scoped
            .filter(\.isExpense)
            .reduce(into: [String: (amount: Decimal, count: Int)]()) { acc, item in
                let existing = acc[item.categoryID] ?? (amount: 0, count: 0)
                acc[item.categoryID] = (amount: existing.amount + item.amount, count: existing.count + 1)
            }

        let totalExpenseDouble = NSDecimalNumber(decimal: expense).doubleValue
        let topCategories = categoryTotals
            .map { categoryID, value -> WrappedTopCategory in
                let percentage: Double = totalExpenseDouble > 0
                    ? NSDecimalNumber(decimal: value.amount).doubleValue / totalExpenseDouble
                    : 0
                return WrappedTopCategory(
                    categoryID: categoryID,
                    totalAmount: value.amount,
                    percentage: percentage,
                    transactionCount: value.count
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount }
            .prefix(3)

        let largest = scoped.filter(\.isExpense).map(\.amount).max() ?? 0
        let noSpendDays = computeNoSpendDays(transactions: scoped, interval: interval, calendar: calendar)
        let bestStreak = computeBestNoSpendStreak(transactions: scoped, interval: interval, calendar: calendar)

        return WrappedReport(
            scope: scope,
            periodLabel: formatPeriod(scope: scope, date: referenceDate, calendar: calendar, locale: locale),
            totalIncome: income,
            totalExpense: expense,
            netBalance: net,
            transactionCount: scoped.count,
            topCategories: Array(topCategories),
            largestTransaction: largest,
            noSpendDays: noSpendDays,
            bestStreak: bestStreak,
            generatedAt: referenceDate,
            isSufficient: true
        )
    }

    private static func formatPeriod(
        scope: WrappedScope,
        date: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        switch scope {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: date)
    }

    private static func computeNoSpendDays(
        transactions: [WrappedTransactionInput],
        interval: DateInterval,
        calendar: Calendar
    ) -> Int {
        let expenseDays = Set(
            transactions
                .filter(\.isExpense)
                .map { calendar.startOfDay(for: $0.occurredAt) }
        )

        guard
            let totalDays = calendar.dateComponents(
                [.day],
                from: interval.start,
                to: min(interval.end, Date())
            ).day
        else {
            return 0
        }

        return max(0, totalDays - expenseDays.count)
    }

    private static func computeBestNoSpendStreak(
        transactions: [WrappedTransactionInput],
        interval: DateInterval,
        calendar: Calendar
    ) -> Int {
        let expenseDays = Set(
            transactions
                .filter(\.isExpense)
                .map { calendar.startOfDay(for: $0.occurredAt) }
        )

        var bestStreak = 0
        var currentStreak = 0
        var cursor = interval.start
        let endDate = min(interval.end, Date())

        while cursor < endDate {
            let day = calendar.startOfDay(for: cursor)
            if expenseDays.contains(day) {
                currentStreak = 0
            } else {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? endDate
        }

        return bestStreak
    }
}
