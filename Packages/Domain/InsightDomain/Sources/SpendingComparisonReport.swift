import Foundation

public enum SpendingComparisonTrend: String, Codable, Equatable, Sendable {
    case increased
    case decreased
    case flat
}

public struct SpendingPeriodComparison: Equatable, Sendable {
    public let currentExpense: Decimal
    public let previousExpense: Decimal
    public let delta: Decimal
    public let percentageChange: Double?
    public let trend: SpendingComparisonTrend

    public init(
        currentExpense: Decimal,
        previousExpense: Decimal,
        delta: Decimal,
        percentageChange: Double?,
        trend: SpendingComparisonTrend
    ) {
        self.currentExpense = currentExpense
        self.previousExpense = previousExpense
        self.delta = delta
        self.percentageChange = percentageChange
        self.trend = trend
    }
}

public struct SpendingComparisonReport: Equatable, Sendable {
    public let month: SpendingPeriodComparison
    public let yearToDate: SpendingPeriodComparison

    public init(
        month: SpendingPeriodComparison,
        yearToDate: SpendingPeriodComparison
    ) {
        self.month = month
        self.yearToDate = yearToDate
    }
}
