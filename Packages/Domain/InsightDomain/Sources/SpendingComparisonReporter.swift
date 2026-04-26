import Foundation
import TransactionDomain

public enum SpendingComparisonReporter {
    public static func report(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> SpendingComparisonReport {
        SpendingComparisonReport(
            month: monthComparison(
                transactions: transactions,
                referenceDate: referenceDate,
                calendar: calendar
            ),
            yearToDate: yearToDateComparison(
                transactions: transactions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        )
    }

    private static func monthComparison(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> SpendingPeriodComparison {
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: referenceDate),
            let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonth.start),
            let previousMonth = calendar.dateInterval(of: .month, for: previousMonthDate)
        else {
            return emptyComparison
        }

        return comparison(
            currentExpense: expenseTotal(
                transactions: transactions,
                interval: DateInterval(start: currentMonth.start, end: referenceDate)
            ),
            previousExpense: expenseTotal(transactions: transactions, interval: previousMonth)
        )
    }

    private static func yearToDateComparison(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> SpendingPeriodComparison {
        guard
            let currentYear = calendar.dateInterval(of: .year, for: referenceDate),
            let previousYearStart = calendar.date(byAdding: .year, value: -1, to: currentYear.start),
            let previousReferenceDate = calendar.date(byAdding: .year, value: -1, to: referenceDate)
        else {
            return emptyComparison
        }

        return comparison(
            currentExpense: expenseTotal(
                transactions: transactions,
                interval: DateInterval(start: currentYear.start, end: referenceDate)
            ),
            previousExpense: expenseTotal(
                transactions: transactions,
                interval: DateInterval(start: previousYearStart, end: previousReferenceDate)
            )
        )
    }

    private static var emptyComparison: SpendingPeriodComparison {
        SpendingPeriodComparison(
            currentExpense: 0,
            previousExpense: 0,
            delta: 0,
            percentageChange: nil,
            trend: .flat
        )
    }

    private static func expenseTotal(
        transactions: [Transaction],
        interval: DateInterval
    ) -> Decimal {
        transactions
            .filter {
                $0.kind == .expense
                    && $0.occurredAt >= interval.start
                    && $0.occurredAt <= interval.end
            }
            .reduce(0) { $0 + $1.amount }
    }

    private static func comparison(
        currentExpense: Decimal,
        previousExpense: Decimal
    ) -> SpendingPeriodComparison {
        let delta = currentExpense - previousExpense
        let percentageChange: Double?
        if previousExpense > 0 {
            percentageChange = NSDecimalNumber(decimal: delta / previousExpense).doubleValue
        } else {
            percentageChange = nil
        }

        return SpendingPeriodComparison(
            currentExpense: currentExpense,
            previousExpense: previousExpense,
            delta: delta,
            percentageChange: percentageChange,
            trend: trend(for: delta)
        )
    }

    private static func trend(for delta: Decimal) -> SpendingComparisonTrend {
        if delta > 0 {
            return .increased
        }

        if delta < 0 {
            return .decreased
        }

        return .flat
    }
}
