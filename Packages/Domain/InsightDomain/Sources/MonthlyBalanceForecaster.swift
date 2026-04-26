import Foundation
import TransactionDomain

public enum MonthlyBalanceForecaster {
    public static func forecast(
        transactions: [Transaction],
        referenceDate: Date = Date(),
        lookbackMonthCount: Int = 3,
        calendar: Calendar = .current
    ) -> MonthlyBalanceForecast {
        let incomeToDate = currentMonthTotal(
            transactions: transactions,
            kind: .income,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let expenseToDate = currentMonthTotal(
            transactions: transactions,
            kind: .expense,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let monthDayCount = dayCountInMonth(containing: referenceDate, calendar: calendar)
        let elapsedDayDifference = calendar.dateComponents(
            [.day],
            from: monthStart(containing: referenceDate, calendar: calendar),
            to: referenceDate
        ).day ?? 0
        let elapsedDayCount = max(
            1,
            elapsedDayDifference + 1
        )
        let currentDailyRate = expenseToDate / Decimal(elapsedDayCount)
        let historicalDailyRate = historicalDailyExpenseRate(
            transactions: transactions,
            referenceDate: referenceDate,
            lookbackMonthCount: lookbackMonthCount,
            calendar: calendar
        )
        let dailyExpenseRate = max(currentDailyRate, historicalDailyRate)
        let projectedExpense = max(
            expenseToDate,
            roundedToThousands(dailyExpenseRate * Decimal(monthDayCount))
        )
        let projectedBalance = incomeToDate - projectedExpense

        return MonthlyBalanceForecast(
            incomeToDate: incomeToDate,
            expenseToDate: expenseToDate,
            projectedExpense: projectedExpense,
            projectedBalance: projectedBalance,
            dailyExpenseRate: roundedToThousands(dailyExpenseRate),
            remainingDayCount: max(0, monthDayCount - elapsedDayCount),
            status: status(projectedBalance: projectedBalance, incomeToDate: incomeToDate)
        )
    }

    private static func currentMonthTotal(
        transactions: [Transaction],
        kind: TransactionKind,
        referenceDate: Date,
        calendar: Calendar
    ) -> Decimal {
        transactions
            .filter { transaction in
                transaction.kind == kind
                    && transaction.amount > 0
                    && transaction.occurredAt <= referenceDate
                    && calendar.isDate(transaction.occurredAt, equalTo: referenceDate, toGranularity: .month)
            }
            .reduce(Decimal(0)) { total, transaction in
                total + transaction.amount
            }
    }

    private static func historicalDailyExpenseRate(
        transactions: [Transaction],
        referenceDate: Date,
        lookbackMonthCount: Int,
        calendar: Calendar
    ) -> Decimal {
        let monthDates = (1 ... max(lookbackMonthCount, 1)).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: referenceDate)
        }

        let monthlySamples = monthDates.compactMap { date -> HistoricalMonthlySample? in
            let total = historicalExpenseTotal(
                transactions: transactions,
                containing: date,
                calendar: calendar
            )
            guard total > 0 else {
                return nil
            }

            return HistoricalMonthlySample(
                expense: total,
                dayCount: dayCountInMonth(containing: date, calendar: calendar)
            )
        }
        let totalExpense = monthlySamples.reduce(Decimal(0)) { total, sample in
            total + sample.expense
        }
        let totalDays = monthlySamples.reduce(0) { total, sample in
            total + sample.dayCount
        }

        guard totalExpense > 0, totalDays > 0 else {
            return 0
        }

        return totalExpense / Decimal(totalDays)
    }

    private static func historicalExpenseTotal(
        transactions: [Transaction],
        containing date: Date,
        calendar: Calendar
    ) -> Decimal {
        transactions
            .filter { transaction in
                transaction.kind == .expense
                    && transaction.amount > 0
                    && calendar.isDate(transaction.occurredAt, equalTo: date, toGranularity: .month)
            }
            .reduce(Decimal(0)) { total, transaction in
                total + transaction.amount
            }
    }

    private static func monthStart(
        containing date: Date,
        calendar: Calendar
    ) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    private static func dayCountInMonth(
        containing date: Date,
        calendar: Calendar
    ) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private static func status(
        projectedBalance: Decimal,
        incomeToDate: Decimal
    ) -> MonthlyBalanceForecastStatus {
        if projectedBalance < 0 {
            return .negative
        }

        if incomeToDate > 0, projectedBalance <= incomeToDate * tightBalanceRatio {
            return .tight
        }

        return .safe
    }

    private static func roundedToThousands(_ amount: Decimal) -> Decimal {
        let number = NSDecimalNumber(decimal: amount)
        let roundedValue = (number.doubleValue / 1_000).rounded() * 1_000
        return Decimal(Int(roundedValue))
    }

    private static let tightBalanceRatio = Decimal(10) / Decimal(100)
}

private struct HistoricalMonthlySample: Equatable, Sendable {
    let expense: Decimal
    let dayCount: Int
}
