import Foundation
import TransactionDomain

public enum SleepSpendingDataBuilder {
    public static func makeDataPoints(
        sleepSamples: [SleepSample],
        transactions: [Transaction],
        calendar: Calendar = .current
    ) -> [SleepSpendingDataPoint] {
        let expenseTransactions = transactions.filter { $0.kind == .expense && $0.amount > 0 }
        let transactionsByDay = Dictionary(grouping: expenseTransactions) {
            calendar.startOfDay(for: $0.occurredAt)
        }

        return sleepSamples
            .filter { $0.hours > 0 }
            .map { sample in
                let day = calendar.startOfDay(for: sample.date)
                let dayTransactions = transactionsByDay[day] ?? []
                return SleepSpendingDataPoint(
                    date: day,
                    sleepHours: sample.hours,
                    totalSpending: dayTransactions.reduce(Decimal(0)) { $0 + $1.amount },
                    transactionCount: dayTransactions.count,
                    categories: categorySpending(from: dayTransactions)
                )
            }
            .sorted { $0.date < $1.date }
    }

    public static func filter(
        dataPoints: [SleepSpendingDataPoint],
        period: SleepCorrelationPeriod,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> [SleepSpendingDataPoint] {
        guard let start = startDate(for: period, referenceDate: referenceDate, calendar: calendar) else {
            return dataPoints
        }
        return dataPoints.filter { $0.date >= start && $0.date <= referenceDate }
    }
}

private extension SleepSpendingDataBuilder {
    static func categorySpending(from transactions: [Transaction]) -> [CategorySpending] {
        let grouped = Dictionary(grouping: transactions, by: \.category)
        return grouped.map { category, transactions in
            CategorySpending(
                category: category,
                amount: transactions.reduce(Decimal(0)) { $0 + $1.amount }
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    static func startDate(
        for period: SleepCorrelationPeriod,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        switch period {
        case .all:
            return nil
        case .lastThirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: referenceDate)
        case .lastNinetyDays:
            return calendar.date(byAdding: .day, value: -90, to: referenceDate)
        }
    }
}
