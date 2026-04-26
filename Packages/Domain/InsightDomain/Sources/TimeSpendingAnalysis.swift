import Foundation

public struct TimeSpendingAnalysisConfiguration: Equatable, Sendable {
    public var lookbackMonthCount: Int
    public var minimumTransactionCount: Int
    public var topWeekdayCount: Int
    public var topHourCount: Int
    public var eveningStartHour: Int
    public var eveningShareThreshold: Decimal
    public var minimumEveningAmount: Decimal

    public init(
        lookbackMonthCount: Int = 3,
        minimumTransactionCount: Int = 5,
        topWeekdayCount: Int = 2,
        topHourCount: Int = 1,
        eveningStartHour: Int = 20,
        eveningShareThreshold: Decimal = Decimal(string: "0.3") ?? 0.3,
        minimumEveningAmount: Decimal = 100_000
    ) {
        self.lookbackMonthCount = lookbackMonthCount
        self.minimumTransactionCount = minimumTransactionCount
        self.topWeekdayCount = topWeekdayCount
        self.topHourCount = topHourCount
        self.eveningStartHour = eveningStartHour
        self.eveningShareThreshold = eveningShareThreshold
        self.minimumEveningAmount = minimumEveningAmount
    }
}

public struct TimeSpendingAnalysis: Equatable, Sendable {
    public let totalExpense: Decimal
    public let transactionCount: Int
    public let peakWeekdays: [WeekdaySpendingPattern]
    public let peakHours: [HourlySpendingPattern]
    public let eveningSpike: EveningSpendingPattern?

    public init(
        totalExpense: Decimal,
        transactionCount: Int,
        peakWeekdays: [WeekdaySpendingPattern],
        peakHours: [HourlySpendingPattern],
        eveningSpike: EveningSpendingPattern?
    ) {
        self.totalExpense = totalExpense
        self.transactionCount = transactionCount
        self.peakWeekdays = peakWeekdays
        self.peakHours = peakHours
        self.eveningSpike = eveningSpike
    }

    public var isEmpty: Bool {
        peakWeekdays.isEmpty && peakHours.isEmpty && eveningSpike == nil
    }
}

public struct WeekdaySpendingPattern: Identifiable, Equatable, Sendable {
    public let weekday: Int
    public let amount: Decimal
    public let transactionCount: Int
    public let shareOfTotal: Decimal

    public init(
        weekday: Int,
        amount: Decimal,
        transactionCount: Int,
        shareOfTotal: Decimal
    ) {
        self.weekday = weekday
        self.amount = amount
        self.transactionCount = transactionCount
        self.shareOfTotal = shareOfTotal
    }

    public var id: String {
        "weekday-\(weekday)"
    }
}

public struct HourlySpendingPattern: Identifiable, Equatable, Sendable {
    public let hour: Int
    public let amount: Decimal
    public let transactionCount: Int
    public let shareOfTotal: Decimal

    public init(
        hour: Int,
        amount: Decimal,
        transactionCount: Int,
        shareOfTotal: Decimal
    ) {
        self.hour = hour
        self.amount = amount
        self.transactionCount = transactionCount
        self.shareOfTotal = shareOfTotal
    }

    public var id: String {
        "hour-\(hour)"
    }
}

public struct EveningSpendingPattern: Identifiable, Equatable, Sendable {
    public let startHour: Int
    public let amount: Decimal
    public let transactionCount: Int
    public let shareOfTotal: Decimal

    public init(
        startHour: Int,
        amount: Decimal,
        transactionCount: Int,
        shareOfTotal: Decimal
    ) {
        self.startHour = startHour
        self.amount = amount
        self.transactionCount = transactionCount
        self.shareOfTotal = shareOfTotal
    }

    public var id: String {
        "evening-\(startHour)"
    }
}
