import Foundation
import TransactionDomain

public enum AnonymousBenchmarkReporter {
    public static func report(
        transactions: [Transaction],
        profile: AnonymousBenchmarkProfile,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> AnonymousBenchmarkReport {
        let currentMonthTotals = categoryTotals(
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let comparisons = TransactionCategory.defaultExpenseCategories.map { category in
            comparison(
                category: category,
                userAmount: currentMonthTotals[category.id] ?? 0,
                benchmarkAmount: AnonymousBenchmarkDataset.benchmarkAmount(
                    category: category,
                    profile: profile
                )
            )
        }
        let totalUserExpense = comparisons.reduce(Decimal.zero) { $0 + $1.userAmount }
        let totalBenchmarkExpense = comparisons.reduce(Decimal.zero) { $0 + $1.benchmarkAmount }

        return AnonymousBenchmarkReport(
            profile: profile,
            totalUserExpense: totalUserExpense,
            totalBenchmarkExpense: totalBenchmarkExpense,
            overallStatus: status(userAmount: totalUserExpense, benchmarkAmount: totalBenchmarkExpense),
            overallPeerPercentile: percentile(userAmount: totalUserExpense, benchmarkAmount: totalBenchmarkExpense),
            comparisons: comparisons
        )
    }

    private static func categoryTotals(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> [String: Decimal] {
        transactions.reduce(into: [:]) { result, transaction in
            guard
                transaction.kind == .expense,
                transaction.amount > 0,
                transaction.occurredAt <= referenceDate,
                calendar.isDate(transaction.occurredAt, equalTo: referenceDate, toGranularity: .month)
            else {
                return
            }

            result[transaction.category.id, default: 0] += transaction.amount
        }
    }

    private static func comparison(
        category: TransactionCategory,
        userAmount: Decimal,
        benchmarkAmount: Decimal
    ) -> AnonymousBenchmarkCategoryComparison {
        let differenceAmount = userAmount - benchmarkAmount
        let differenceRatio = ratio(differenceAmount, benchmarkAmount)

        return AnonymousBenchmarkCategoryComparison(
            category: category,
            userAmount: userAmount,
            benchmarkAmount: benchmarkAmount,
            differenceAmount: differenceAmount,
            differenceRatio: differenceRatio,
            status: status(userAmount: userAmount, benchmarkAmount: benchmarkAmount),
            peerPercentile: percentile(userAmount: userAmount, benchmarkAmount: benchmarkAmount)
        )
    }

    private static func status(
        userAmount: Decimal,
        benchmarkAmount: Decimal
    ) -> AnonymousBenchmarkStatus {
        guard benchmarkAmount > 0 else {
            return .nearMedian
        }

        if userAmount <= benchmarkAmount * belowMedianThreshold {
            return .belowMedian
        }

        if userAmount >= benchmarkAmount * aboveMedianThreshold {
            return .aboveMedian
        }

        return .nearMedian
    }

    private static func percentile(
        userAmount: Decimal,
        benchmarkAmount: Decimal
    ) -> Int {
        guard benchmarkAmount > 0 else {
            return 50
        }

        let ratio = NSDecimalNumber(decimal: userAmount / benchmarkAmount).doubleValue
        let estimated = 50 + ((ratio - 1) * 35)
        return min(95, max(5, Int(estimated.rounded())))
    }

    private static func ratio(
        _ numerator: Decimal,
        _ denominator: Decimal
    ) -> Decimal {
        guard denominator > 0 else {
            return 0
        }

        return numerator / denominator
    }

    private static let belowMedianThreshold = Decimal(string: "0.85") ?? 0.85
    private static let aboveMedianThreshold = Decimal(string: "1.15") ?? 1.15
}
