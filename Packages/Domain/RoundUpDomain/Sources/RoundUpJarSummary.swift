import Foundation

public struct RoundUpJarSummary: Equatable, Sendable {
    public var entries: [RoundUpEntry]
    public var totalContribution: Decimal
    public var monthlyContribution: Decimal
    public var monthlyEntryCount: Int
    public var lifetimeEntryCount: Int

    public init(
        entries: [RoundUpEntry],
        totalContribution: Decimal,
        monthlyContribution: Decimal,
        monthlyEntryCount: Int,
        lifetimeEntryCount: Int
    ) {
        self.entries = entries
        self.totalContribution = totalContribution
        self.monthlyContribution = monthlyContribution
        self.monthlyEntryCount = monthlyEntryCount
        self.lifetimeEntryCount = lifetimeEntryCount
    }

    public static let empty = RoundUpJarSummary(
        entries: [],
        totalContribution: 0,
        monthlyContribution: 0,
        monthlyEntryCount: 0,
        lifetimeEntryCount: 0
    )
}

public enum RoundUpJarSummaryBuilder {
    public static func summary(
        entries: [RoundUpEntry],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> RoundUpJarSummary {
        let sorted = entries.sorted { $0.createdAt > $1.createdAt }
        let total = sorted.reduce(Decimal(0)) { $0 + $1.contribution }
        let monthly = sorted.filter {
            calendar.isDate($0.createdAt, equalTo: referenceDate, toGranularity: .month)
        }
        let monthlyTotal = monthly.reduce(Decimal(0)) { $0 + $1.contribution }

        return RoundUpJarSummary(
            entries: sorted,
            totalContribution: total,
            monthlyContribution: monthlyTotal,
            monthlyEntryCount: monthly.count,
            lifetimeEntryCount: sorted.count
        )
    }
}
