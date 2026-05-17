import Foundation

public struct MoodSpendingBreakdown: Identifiable, Equatable, Sendable {
    public var mood: Mood
    public var entryCount: Int
    public var averageSpending: Decimal
    public var totalSpending: Decimal

    public init(mood: Mood, entryCount: Int, averageSpending: Decimal, totalSpending: Decimal) {
        self.mood = mood
        self.entryCount = entryCount
        self.averageSpending = averageSpending
        self.totalSpending = totalSpending
    }

    public var id: Mood {
        mood
    }
}

public struct MoodInsight: Equatable, Sendable {
    public var breakdowns: [MoodSpendingBreakdown]
    public var overallAverageSpending: Decimal
    public var negativeMoodAverage: Decimal
    public var positiveMoodAverage: Decimal
    public var deltaPercent: Double?
    public var entryCount: Int
    public var hasEnoughData: Bool

    public init(
        breakdowns: [MoodSpendingBreakdown],
        overallAverageSpending: Decimal,
        negativeMoodAverage: Decimal,
        positiveMoodAverage: Decimal,
        deltaPercent: Double?,
        entryCount: Int,
        hasEnoughData: Bool
    ) {
        self.breakdowns = breakdowns
        self.overallAverageSpending = overallAverageSpending
        self.negativeMoodAverage = negativeMoodAverage
        self.positiveMoodAverage = positiveMoodAverage
        self.deltaPercent = deltaPercent
        self.entryCount = entryCount
        self.hasEnoughData = hasEnoughData
    }

    public static let empty = MoodInsight(
        breakdowns: [],
        overallAverageSpending: 0,
        negativeMoodAverage: 0,
        positiveMoodAverage: 0,
        deltaPercent: nil,
        entryCount: 0,
        hasEnoughData: false
    )
}

public enum MoodInsightCalculator {
    public static let minimumEntriesForInsight = 6

    public static func insight(from entries: [MoodEntry]) -> MoodInsight {
        guard entries.isEmpty == false else {
            return .empty
        }

        let totals = Dictionary(grouping: entries, by: \.mood)
        let breakdowns = totals
            .map { mood, items -> MoodSpendingBreakdown in
                let total = items.reduce(Decimal(0)) { $0 + $1.spendingTotalSnapshot }
                let average = total / Decimal(items.count)
                return MoodSpendingBreakdown(
                    mood: mood,
                    entryCount: items.count,
                    averageSpending: average,
                    totalSpending: total
                )
            }
            .sorted { $0.averageSpending > $1.averageSpending }

        let overallTotal = entries.reduce(Decimal(0)) { $0 + $1.spendingTotalSnapshot }
        let overallAverage = overallTotal / Decimal(entries.count)

        let negativeEntries = entries.filter { $0.mood.isNegative }
        let positiveEntries = entries.filter { $0.mood.positivityScore > 0 }

        let negativeAverage = negativeEntries.isEmpty
            ? 0
            : negativeEntries.reduce(Decimal(0)) { $0 + $1.spendingTotalSnapshot } / Decimal(negativeEntries.count)
        let positiveAverage = positiveEntries.isEmpty
            ? 0
            : positiveEntries.reduce(Decimal(0)) { $0 + $1.spendingTotalSnapshot } / Decimal(positiveEntries.count)

        let delta: Double? = {
            guard
                negativeEntries.isEmpty == false,
                positiveEntries.isEmpty == false,
                positiveAverage > 0
            else {
                return nil
            }
            let negativeDouble = NSDecimalNumber(decimal: negativeAverage).doubleValue
            let positiveDouble = NSDecimalNumber(decimal: positiveAverage).doubleValue
            return ((negativeDouble - positiveDouble) / positiveDouble) * 100
        }()

        return MoodInsight(
            breakdowns: breakdowns,
            overallAverageSpending: overallAverage,
            negativeMoodAverage: negativeAverage,
            positiveMoodAverage: positiveAverage,
            deltaPercent: delta,
            entryCount: entries.count,
            hasEnoughData: entries.count >= minimumEntriesForInsight
        )
    }
}
