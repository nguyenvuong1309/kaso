import Foundation
import TransactionDomain

public struct SpendingAnomalyDetectionConfiguration: Equatable, Sendable {
    public var historyMonthCount: Int
    public var minimumHistoricalTransactionCount: Int
    public var largeTransactionMultiplier: Decimal
    public var categorySpikeMultiplier: Decimal
    public var minimumAmountDelta: Decimal

    public init(
        historyMonthCount: Int = 3,
        minimumHistoricalTransactionCount: Int = 3,
        largeTransactionMultiplier: Decimal = 2,
        categorySpikeMultiplier: Decimal = Decimal(string: "1.4") ?? 1.4,
        minimumAmountDelta: Decimal = 100_000
    ) {
        self.historyMonthCount = historyMonthCount
        self.minimumHistoricalTransactionCount = minimumHistoricalTransactionCount
        self.largeTransactionMultiplier = largeTransactionMultiplier
        self.categorySpikeMultiplier = categorySpikeMultiplier
        self.minimumAmountDelta = minimumAmountDelta
    }
}

public enum SpendingAnomalyDetector {
    public static func detect(
        transactions: [Transaction],
        currentDate: Date,
        calendar: Calendar = .current,
        configuration: SpendingAnomalyDetectionConfiguration = .init()
    ) -> [SpendingAnomaly] {
        let expenseTransactions = transactions.filter { $0.kind == .expense }
        guard
            configuration.historyMonthCount > 0,
            let currentMonth = calendar.dateInterval(of: .month, for: currentDate)
        else {
            return []
        }

        let currentTransactions = expenseTransactions.filter {
            currentMonth.contains($0.occurredAt)
        }
        let historicalTransactions = expenseTransactions.filter {
            isHistorical(
                $0.occurredAt,
                before: currentMonth.start,
                calendar: calendar,
                monthCount: configuration.historyMonthCount
            )
        }

        return (
            largeTransactionAnomalies(
                currentTransactions: currentTransactions,
                historicalTransactions: historicalTransactions,
                configuration: configuration
            )
            + categorySpikeAnomalies(
                currentTransactions: currentTransactions,
                historicalTransactions: historicalTransactions,
                currentMonthStart: currentMonth.start,
                calendar: calendar,
                configuration: configuration
            )
        )
        .sorted {
            if $0.occurredAt == $1.occurredAt {
                return $0.amount > $1.amount
            }

            return $0.occurredAt > $1.occurredAt
        }
    }

    private static func largeTransactionAnomalies(
        currentTransactions: [Transaction],
        historicalTransactions: [Transaction],
        configuration: SpendingAnomalyDetectionConfiguration
    ) -> [SpendingAnomaly] {
        let historicalByCategory = Dictionary(grouping: historicalTransactions) {
            $0.category.id
        }

        return currentTransactions.compactMap { transaction in
            guard
                let historicalCategoryTransactions = historicalByCategory[transaction.category.id],
                historicalCategoryTransactions.count >= configuration.minimumHistoricalTransactionCount
            else {
                return nil
            }

            let baseline = averageAmount(historicalCategoryTransactions.map(\.amount))
            guard isAnomalous(
                amount: transaction.amount,
                baseline: baseline,
                multiplier: configuration.largeTransactionMultiplier,
                minimumAmountDelta: configuration.minimumAmountDelta
            ) else {
                return nil
            }

            return SpendingAnomaly(
                id: "large-\(transaction.id.uuidString)",
                kind: .largeTransaction,
                category: transaction.category,
                amount: transaction.amount,
                baselineAmount: baseline,
                occurredAt: transaction.occurredAt,
                transactionID: transaction.id
            )
        }
    }

    private static func categorySpikeAnomalies(
        currentTransactions: [Transaction],
        historicalTransactions: [Transaction],
        currentMonthStart: Date,
        calendar: Calendar,
        configuration: SpendingAnomalyDetectionConfiguration
    ) -> [SpendingAnomaly] {
        let currentTotals = categoryTotals(for: currentTransactions)
        let historicalMonthlyTotals = monthlyCategoryTotals(
            for: historicalTransactions,
            calendar: calendar
        )

        return currentTotals.compactMap { categoryID, currentTotal in
            let historicalTotals = historicalMonthlyTotals[categoryID] ?? []
            guard historicalTotals.count >= configuration.historyMonthCount else {
                return nil
            }

            let baseline = averageAmount(historicalTotals)
            guard isAnomalous(
                amount: currentTotal.total,
                baseline: baseline,
                multiplier: configuration.categorySpikeMultiplier,
                minimumAmountDelta: configuration.minimumAmountDelta
            ) else {
                return nil
            }

            return SpendingAnomaly(
                id: "category-\(categoryID)-\(currentMonthStart.timeIntervalSinceReferenceDate)",
                kind: .categorySpike,
                category: currentTotal.category,
                amount: currentTotal.total,
                baselineAmount: baseline,
                occurredAt: currentMonthStart
            )
        }
    }

    private static func categoryTotals(
        for transactions: [Transaction]
    ) -> [String: CategoryTotal] {
        transactions.reduce(into: [:]) { result, transaction in
            let categoryID = transaction.category.id
            if var total = result[categoryID] {
                total.total += transaction.amount
                result[categoryID] = total
            } else {
                result[categoryID] = CategoryTotal(
                    category: transaction.category,
                    total: transaction.amount
                )
            }
        }
    }

    private static func monthlyCategoryTotals(
        for transactions: [Transaction],
        calendar: Calendar
    ) -> [String: [Decimal]] {
        let monthlyTotals = transactions.reduce(into: [:]) { result, transaction in
            guard let month = calendar.dateInterval(of: .month, for: transaction.occurredAt) else {
                return
            }

            let key = MonthlyCategoryKey(
                monthStart: month.start,
                categoryID: transaction.category.id
            )
            result[key, default: 0] += transaction.amount
        } as [MonthlyCategoryKey: Decimal]

        return monthlyTotals.reduce(into: [:]) { result, entry in
            result[entry.key.categoryID, default: []].append(entry.value)
        }
    }

    private static func isHistorical(
        _ date: Date,
        before currentMonthStart: Date,
        calendar: Calendar,
        monthCount: Int
    ) -> Bool {
        guard let earliestMonthStart = calendar.date(
            byAdding: .month,
            value: -monthCount,
            to: currentMonthStart
        ) else {
            return false
        }

        return date >= earliestMonthStart && date < currentMonthStart
    }

    private static func averageAmount(_ amounts: [Decimal]) -> Decimal {
        guard amounts.isEmpty == false else {
            return 0
        }

        return amounts.reduce(0, +) / Decimal(amounts.count)
    }

    private static func isAnomalous(
        amount: Decimal,
        baseline: Decimal,
        multiplier: Decimal,
        minimumAmountDelta: Decimal
    ) -> Bool {
        guard baseline > 0 else {
            return false
        }

        return amount >= baseline * multiplier
            && amount - baseline >= minimumAmountDelta
    }
}

private struct CategoryTotal: Equatable {
    var category: TransactionCategory
    var total: Decimal
}

private struct MonthlyCategoryKey: Hashable {
    var monthStart: Date
    var categoryID: String
}
