import Foundation

public struct SeasonalSpike: Identifiable, Equatable, Sendable {
    public let id: Int // month index 1-12
    public let monthIndex: Int
    public let nameKey: String
    public let historicalAverage: Decimal
    public let baselineAverage: Decimal
    public let yearsObserved: Int
    public let weeksUntil: Int
    public let suggestedWeeklySaving: Decimal

    public var extraVsBaseline: Decimal { max(0, historicalAverage - baselineAverage) }

    public init(
        monthIndex: Int,
        nameKey: String,
        historicalAverage: Decimal,
        baselineAverage: Decimal,
        yearsObserved: Int,
        weeksUntil: Int,
        suggestedWeeklySaving: Decimal
    ) {
        id = monthIndex
        self.monthIndex = monthIndex
        self.nameKey = nameKey
        self.historicalAverage = historicalAverage
        self.baselineAverage = baselineAverage
        self.yearsObserved = yearsObserved
        self.weeksUntil = weeksUntil
        self.suggestedWeeklySaving = suggestedWeeklySaving
    }
}

public struct SeasonalPlan: Equatable, Sendable {
    public let spikes: [SeasonalSpike]
    public let generatedAt: Date
    public let isSufficient: Bool

    public init(spikes: [SeasonalSpike], generatedAt: Date, isSufficient: Bool) {
        self.spikes = spikes
        self.generatedAt = generatedAt
        self.isSufficient = isSufficient
    }

    public static let empty = SeasonalPlan(
        spikes: [],
        generatedAt: Date(timeIntervalSinceReferenceDate: 0),
        isSufficient: false
    )
}

public enum SeasonalMonthName {
    /// Hyperlocal Vietnamese seasons mapped by month.
    public static func key(forMonth month: Int) -> String {
        switch month {
        case 1, 2: "seasonal.name.tet"
        case 8, 9: "seasonal.name.backToSchool"
        case 11: "seasonal.name.shopping"
        case 12: "seasonal.name.yearEnd"
        default: "seasonal.name.general"
        }
    }
}
