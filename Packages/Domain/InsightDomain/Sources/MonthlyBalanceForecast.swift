import Foundation

public enum MonthlyBalanceForecastStatus: String, Codable, Equatable, Sendable {
    case safe
    case tight
    case negative

    public var titleKey: String {
        "insight.forecast.\(rawValue).title"
    }

    public var descriptionKey: String {
        "insight.forecast.\(rawValue).description"
    }
}

public struct MonthlyBalanceForecast: Equatable, Sendable {
    public let incomeToDate: Decimal
    public let expenseToDate: Decimal
    public let projectedExpense: Decimal
    public let projectedBalance: Decimal
    public let dailyExpenseRate: Decimal
    public let remainingDayCount: Int
    public let status: MonthlyBalanceForecastStatus

    public init(
        incomeToDate: Decimal,
        expenseToDate: Decimal,
        projectedExpense: Decimal,
        projectedBalance: Decimal,
        dailyExpenseRate: Decimal,
        remainingDayCount: Int,
        status: MonthlyBalanceForecastStatus
    ) {
        self.incomeToDate = incomeToDate
        self.expenseToDate = expenseToDate
        self.projectedExpense = projectedExpense
        self.projectedBalance = projectedBalance
        self.dailyExpenseRate = dailyExpenseRate
        self.remainingDayCount = remainingDayCount
        self.status = status
    }
}
