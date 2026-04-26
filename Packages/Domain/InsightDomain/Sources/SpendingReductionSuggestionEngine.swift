import Foundation
import TransactionDomain

public enum SpendingReductionSuggestionEngine {
    public static func suggestions(
        transactions: [Transaction],
        referenceDate: Date = Date(),
        lookbackMonthCount: Int = 3,
        calendar: Calendar = .current
    ) -> [SpendingReductionSuggestion] {
        let currentTotals = monthlyTotals(
            transactions: transactions,
            containing: referenceDate,
            calendar: calendar
        )
        let currentTotal = currentTotals.values.reduce(Decimal(0), +)
        guard currentTotal > 0 else {
            return []
        }

        let historicalTotals = historicalMonthlyTotals(
            transactions: transactions,
            referenceDate: referenceDate,
            lookbackMonthCount: lookbackMonthCount,
            calendar: calendar
        )

        return currentTotals.compactMap { category, currentAmount in
            suggestion(
                category: category,
                currentAmount: currentAmount,
                currentTotal: currentTotal,
                historicalMonthlyAmounts: historicalTotals[category.id] ?? [],
                lookbackMonthCount: lookbackMonthCount
            )
        }
        .sorted { lhs, rhs in
            if lhs.suggestedMonthlySaving == rhs.suggestedMonthlySaving {
                return lhs.category.id < rhs.category.id
            }

            return lhs.suggestedMonthlySaving > rhs.suggestedMonthlySaving
        }
    }

    private static func suggestion(
        category: TransactionCategory,
        currentAmount: Decimal,
        currentTotal: Decimal,
        historicalMonthlyAmounts: [Decimal],
        lookbackMonthCount: Int
    ) -> SpendingReductionSuggestion? {
        let nonZeroHistoricalAmounts = historicalMonthlyAmounts.filter { $0 > 0 }
        if nonZeroHistoricalAmounts.isEmpty == false {
            let baselineAmount = nonZeroHistoricalAmounts.reduce(Decimal(0), +)
                / Decimal(nonZeroHistoricalAmounts.count)
            let excessAmount = currentAmount - baselineAmount
            guard baselineAmount > 0,
                  currentAmount >= baselineAmount * spikeRatio,
                  excessAmount >= minimumSuggestedSaving else {
                return nil
            }

            let suggestedSaving = roundedToThousands(excessAmount * spikeReductionShare)
            guard suggestedSaving >= minimumSuggestedSaving else {
                return nil
            }

            return SpendingReductionSuggestion(
                kind: .categorySpike,
                category: category,
                currentMonthlyAmount: currentAmount,
                baselineMonthlyAmount: baselineAmount,
                suggestedMonthlySaving: suggestedSaving,
                projectedMonthlyAmount: currentAmount - suggestedSaving
            )
        }

        let categoryShare = decimalDouble(currentAmount / currentTotal)
        guard categoryShare >= dominantCategoryShare,
              currentAmount >= minimumDominantCategoryAmount else {
            return nil
        }

        let suggestedSaving = roundedToThousands(currentAmount * dominantCategoryReductionShare)
        guard suggestedSaving >= minimumSuggestedSaving else {
            return nil
        }

        return SpendingReductionSuggestion(
            kind: .dominantCategory,
            category: category,
            currentMonthlyAmount: currentAmount,
            baselineMonthlyAmount: 0,
            suggestedMonthlySaving: suggestedSaving,
            projectedMonthlyAmount: currentAmount - suggestedSaving
        )
    }

    private static func monthlyTotals(
        transactions: [Transaction],
        containing date: Date,
        calendar: Calendar
    ) -> [TransactionCategory: Decimal] {
        transactions
            .filter { transaction in
                transaction.kind == .expense
                    && transaction.amount > 0
                    && calendar.isDate(transaction.occurredAt, equalTo: date, toGranularity: .month)
            }
            .reduce(into: [TransactionCategory: Decimal]()) { result, transaction in
                result[transaction.category, default: 0] += transaction.amount
            }
    }

    private static func historicalMonthlyTotals(
        transactions: [Transaction],
        referenceDate: Date,
        lookbackMonthCount: Int,
        calendar: Calendar
    ) -> [String: [Decimal]] {
        let historicalMonthStarts = (1 ... max(lookbackMonthCount, 1)).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: referenceDate).map {
                calendar.dateComponents([.year, .month], from: $0)
            }
        }

        var totals: [String: [Decimal]] = [:]
        for components in historicalMonthStarts {
            let monthTransactions = transactions.filter { transaction in
                transaction.kind == .expense
                    && transaction.amount > 0
                    && calendar.component(.year, from: transaction.occurredAt) == components.year
                    && calendar.component(.month, from: transaction.occurredAt) == components.month
            }
            let monthTotals = monthTransactions.reduce(into: [String: Decimal]()) { result, transaction in
                result[transaction.category.id, default: 0] += transaction.amount
            }

            for (categoryID, amount) in monthTotals {
                totals[categoryID, default: []].append(amount)
            }
        }

        return totals
    }

    private static func roundedToThousands(_ amount: Decimal) -> Decimal {
        let number = NSDecimalNumber(decimal: amount)
        let roundedValue = (number.doubleValue / 1_000).rounded() * 1_000
        return Decimal(Int(roundedValue))
    }

    private static func decimalDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private static let dominantCategoryReductionShare = Decimal(10) / Decimal(100)
    private static let dominantCategoryShare = 0.35
    private static let minimumDominantCategoryAmount = Decimal(1_000_000)
    private static let minimumSuggestedSaving = Decimal(100_000)
    private static let spikeRatio = Decimal(120) / Decimal(100)
    private static let spikeReductionShare = Decimal(50) / Decimal(100)
}
