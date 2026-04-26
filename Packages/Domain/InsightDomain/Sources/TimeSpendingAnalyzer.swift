import Foundation
import TransactionDomain

public enum TimeSpendingAnalyzer {
    public static func analyze(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar = .current,
        configuration: TimeSpendingAnalysisConfiguration = .init()
    ) -> TimeSpendingAnalysis {
        guard
            configuration.lookbackMonthCount > 0,
            configuration.minimumTransactionCount > 0,
            configuration.topWeekdayCount > 0,
            configuration.topHourCount > 0,
            let interval = analysisInterval(
                containing: referenceDate,
                calendar: calendar,
                monthCount: configuration.lookbackMonthCount
            )
        else {
            return emptyAnalysis
        }

        let expenses = transactions.filter {
            $0.kind == .expense
                && $0.occurredAt >= interval.start
                && $0.occurredAt <= referenceDate
        }
        let totalExpense = expenses.reduce(Decimal.zero) { $0 + $1.amount }

        guard expenses.count >= configuration.minimumTransactionCount, totalExpense > 0 else {
            return TimeSpendingAnalysis(
                totalExpense: totalExpense,
                transactionCount: expenses.count,
                peakWeekdays: [],
                peakHours: [],
                eveningSpike: nil
            )
        }

        let peakWeekdays = peakWeekdayPatterns(
            expenses: expenses,
            totalExpense: totalExpense,
            calendar: calendar,
            limit: configuration.topWeekdayCount
        )
        let peakHours = peakHourPatterns(
            expenses: expenses,
            totalExpense: totalExpense,
            calendar: calendar,
            limit: configuration.topHourCount
        )
        let eveningSpike = eveningPattern(
            expenses: expenses,
            totalExpense: totalExpense,
            calendar: calendar,
            configuration: configuration
        )

        return TimeSpendingAnalysis(
            totalExpense: totalExpense,
            transactionCount: expenses.count,
            peakWeekdays: peakWeekdays,
            peakHours: peakHours,
            eveningSpike: eveningSpike
        )
    }

    private static var emptyAnalysis: TimeSpendingAnalysis {
        TimeSpendingAnalysis(
            totalExpense: 0,
            transactionCount: 0,
            peakWeekdays: [],
            peakHours: [],
            eveningSpike: nil
        )
    }

    private static func analysisInterval(
        containing referenceDate: Date,
        calendar: Calendar,
        monthCount: Int
    ) -> DateInterval? {
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: referenceDate),
            let start = calendar.date(
                byAdding: .month,
                value: -(monthCount - 1),
                to: currentMonth.start
            )
        else {
            return nil
        }

        return DateInterval(start: start, end: referenceDate)
    }

    private static func peakWeekdayPatterns(
        expenses: [Transaction],
        totalExpense: Decimal,
        calendar: Calendar,
        limit: Int
    ) -> [WeekdaySpendingPattern] {
        let totals = expenses.reduce(into: [:]) { result, transaction in
            let weekday = calendar.component(.weekday, from: transaction.occurredAt)
            result[weekday, default: SpendingBucket()].add(transaction.amount)
        } as [Int: SpendingBucket]

        return totals
            .map { weekday, bucket in
                WeekdaySpendingPattern(
                    weekday: weekday,
                    amount: bucket.amount,
                    transactionCount: bucket.transactionCount,
                    shareOfTotal: share(bucket.amount, of: totalExpense)
                )
            }
            .sorted(by: spendingPatternSort)
            .prefix(limit)
            .map { $0 }
    }

    private static func peakHourPatterns(
        expenses: [Transaction],
        totalExpense: Decimal,
        calendar: Calendar,
        limit: Int
    ) -> [HourlySpendingPattern] {
        let totals = expenses.reduce(into: [:]) { result, transaction in
            let hour = calendar.component(.hour, from: transaction.occurredAt)
            result[hour, default: SpendingBucket()].add(transaction.amount)
        } as [Int: SpendingBucket]

        return totals
            .map { hour, bucket in
                HourlySpendingPattern(
                    hour: hour,
                    amount: bucket.amount,
                    transactionCount: bucket.transactionCount,
                    shareOfTotal: share(bucket.amount, of: totalExpense)
                )
            }
            .sorted(by: spendingPatternSort)
            .prefix(limit)
            .map { $0 }
    }

    private static func eveningPattern(
        expenses: [Transaction],
        totalExpense: Decimal,
        calendar: Calendar,
        configuration: TimeSpendingAnalysisConfiguration
    ) -> EveningSpendingPattern? {
        let eveningBucket = expenses.reduce(into: SpendingBucket()) { bucket, transaction in
            let hour = calendar.component(.hour, from: transaction.occurredAt)
            guard hour >= configuration.eveningStartHour else {
                return
            }

            bucket.add(transaction.amount)
        }
        let eveningShare = share(eveningBucket.amount, of: totalExpense)

        guard
            eveningBucket.amount >= configuration.minimumEveningAmount,
            eveningShare >= configuration.eveningShareThreshold
        else {
            return nil
        }

        return EveningSpendingPattern(
            startHour: configuration.eveningStartHour,
            amount: eveningBucket.amount,
            transactionCount: eveningBucket.transactionCount,
            shareOfTotal: eveningShare
        )
    }

    private static func share(_ amount: Decimal, of total: Decimal) -> Decimal {
        guard total > 0 else {
            return 0
        }

        return amount / total
    }

    private static func spendingPatternSort(
        lhs: WeekdaySpendingPattern,
        rhs: WeekdaySpendingPattern
    ) -> Bool {
        if lhs.amount == rhs.amount {
            return lhs.transactionCount > rhs.transactionCount
        }

        return lhs.amount > rhs.amount
    }

    private static func spendingPatternSort(
        lhs: HourlySpendingPattern,
        rhs: HourlySpendingPattern
    ) -> Bool {
        if lhs.amount == rhs.amount {
            return lhs.transactionCount > rhs.transactionCount
        }

        return lhs.amount > rhs.amount
    }
}

private struct SpendingBucket {
    var amount: Decimal = 0
    var transactionCount = 0

    mutating func add(_ transactionAmount: Decimal) {
        amount += transactionAmount
        transactionCount += 1
    }
}
