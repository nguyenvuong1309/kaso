import Foundation

public struct SeasonalTransactionInput: Equatable, Sendable {
    public let amount: Decimal
    public let isExpense: Bool
    public let occurredAt: Date

    public init(amount: Decimal, isExpense: Bool, occurredAt: Date) {
        self.amount = amount
        self.isExpense = isExpense
        self.occurredAt = occurredAt
    }
}

public enum SeasonalPlanBuilder {
    /// A month counts as a spike when its historical average is at least this
    /// multiple of the overall monthly baseline.
    public static let spikeThreshold = 1.3
    public static let lookaheadWeeks = 8

    public static func build(
        transactions: [SeasonalTransactionInput],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> SeasonalPlan {
        let expenses = transactions.filter(\.isExpense)
        let distinctYears = Set(expenses.map { calendar.component(.year, from: $0.occurredAt) })

        // Need at least one full prior year of history to detect seasonality.
        guard distinctYears.count >= 2 else {
            return SeasonalPlan(spikes: [], generatedAt: referenceDate, isSufficient: false)
        }

        // Sum per (year, month), then average per month across the years it appears.
        var perYearMonth: [String: Decimal] = [:]
        for txn in expenses {
            let year = calendar.component(.year, from: txn.occurredAt)
            let month = calendar.component(.month, from: txn.occurredAt)
            perYearMonth["\(year)-\(month)", default: 0] += txn.amount
        }

        var monthTotals: [Int: (sum: Decimal, count: Int)] = [:]
        for (key, value) in perYearMonth {
            guard let month = Int(key.split(separator: "-")[1]) else { continue }
            let existing = monthTotals[month] ?? (sum: 0, count: 0)
            monthTotals[month] = (sum: existing.sum + value, count: existing.count + 1)
        }

        let monthAverages = monthTotals.mapValues { $0.sum / Decimal($0.count) }
        guard monthAverages.isEmpty == false else {
            return SeasonalPlan(spikes: [], generatedAt: referenceDate, isSufficient: false)
        }

        let baseline = monthAverages.values.reduce(Decimal(0), +) / Decimal(monthAverages.count)
        let baselineDouble = NSDecimalNumber(decimal: baseline).doubleValue

        let currentMonth = calendar.component(.month, from: referenceDate)
        var spikes: [SeasonalSpike] = []

        for offset in 0 ... 3 {
            let month = (currentMonth - 1 + offset) % 12 + 1
            guard
                let average = monthAverages[month],
                let observed = monthTotals[month]?.count
            else { continue }
            let averageDouble = NSDecimalNumber(decimal: average).doubleValue
            guard baselineDouble > 0, averageDouble >= baselineDouble * spikeThreshold else {
                continue
            }

            let weeksUntil = weeksUntilMonth(month, from: referenceDate, calendar: calendar)
            guard weeksUntil <= lookaheadWeeks else { continue }

            let extra = max(0, average - baseline)
            let weeklySaving = weeksUntil > 0 ? extra / Decimal(weeksUntil) : extra
            spikes.append(
                SeasonalSpike(
                    monthIndex: month,
                    nameKey: SeasonalMonthName.key(forMonth: month),
                    historicalAverage: average,
                    baselineAverage: baseline,
                    yearsObserved: observed,
                    weeksUntil: weeksUntil,
                    suggestedWeeklySaving: weeklySaving
                )
            )
        }

        spikes.sort { $0.weeksUntil < $1.weeksUntil }
        return SeasonalPlan(spikes: spikes, generatedAt: referenceDate, isSufficient: true)
    }

    private static func weeksUntilMonth(
        _ month: Int,
        from date: Date,
        calendar: Calendar
    ) -> Int {
        let currentMonth = calendar.component(.month, from: date)
        let currentYear = calendar.component(.year, from: date)
        let targetYear = month >= currentMonth ? currentYear : currentYear + 1
        var components = DateComponents()
        components.year = targetYear
        components.month = month
        components.day = 1
        guard let targetDate = calendar.date(from: components) else { return 0 }
        let days = calendar.dateComponents([.day], from: date, to: targetDate).day ?? 0
        return max(0, days / 7)
    }
}
