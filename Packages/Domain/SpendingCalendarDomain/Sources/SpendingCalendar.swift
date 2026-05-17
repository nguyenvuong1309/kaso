import Foundation

public struct SpendingCalendarMonth: Equatable, Sendable {
    public var month: Date
    public var days: [DailySpending]
    public var actualTotal: Decimal
    public var forecastTotal: Decimal
    public var averageDailySpending: Decimal
    public var topDay: DailySpending?

    public init(
        month: Date,
        days: [DailySpending],
        actualTotal: Decimal,
        forecastTotal: Decimal,
        averageDailySpending: Decimal,
        topDay: DailySpending?
    ) {
        self.month = month
        self.days = days
        self.actualTotal = actualTotal
        self.forecastTotal = forecastTotal
        self.averageDailySpending = averageDailySpending
        self.topDay = topDay
    }

    public static let empty = SpendingCalendarMonth(
        month: Date(timeIntervalSinceReferenceDate: 0),
        days: [],
        actualTotal: 0,
        forecastTotal: 0,
        averageDailySpending: 0,
        topDay: nil
    )
}
