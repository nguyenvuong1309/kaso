import Foundation
import Testing
@testable import RoundUpDomain

@Test("empty summary has zeroed totals and no entries")
func emptySummaryDefaults() {
    let summary = RoundUpJarSummary.empty
    #expect(summary.entries.isEmpty)
    #expect(summary.totalContribution == 0)
    #expect(summary.monthlyContribution == 0)
    #expect(summary.monthlyEntryCount == 0)
    #expect(summary.lifetimeEntryCount == 0)
}

@Test("summary init stores all fields")
func summaryInitStoresFields() throws {
    let entry = RoundUpEntry(
        originalAmount: 1,
        roundedAmount: 1_000,
        contribution: 999,
        step: .oneThousand,
        createdAt: try makeDate(year: 2026, month: 6, day: 1)
    )
    let summary = RoundUpJarSummary(
        entries: [entry],
        totalContribution: 999,
        monthlyContribution: 999,
        monthlyEntryCount: 1,
        lifetimeEntryCount: 1
    )

    #expect(summary.entries == [entry])
    #expect(summary.totalContribution == 999)
    #expect(summary.monthlyContribution == 999)
    #expect(summary.monthlyEntryCount == 1)
    #expect(summary.lifetimeEntryCount == 1)
}

@Test("builder on empty input returns zeroed summary")
func builderEmptyInput() throws {
    let summary = RoundUpJarSummaryBuilder.summary(
        entries: [],
        referenceDate: try makeDate(year: 2026, month: 6, day: 1),
        calendar: fixedCalendar()
    )
    #expect(summary.entries.isEmpty)
    #expect(summary.totalContribution == 0)
    #expect(summary.monthlyContribution == 0)
    #expect(summary.monthlyEntryCount == 0)
    #expect(summary.lifetimeEntryCount == 0)
}

@Test("builder sorts entries by createdAt descending")
func builderSortsDescending() throws {
    let oldest = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 999,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 1, day: 1)
    )
    let middle = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 999,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 3, day: 1)
    )
    let newest = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 999,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 6, day: 1)
    )

    let summary = RoundUpJarSummaryBuilder.summary(
        entries: [oldest, newest, middle],
        referenceDate: try makeDate(year: 2026, month: 6, day: 15),
        calendar: fixedCalendar()
    )

    #expect(summary.entries.map(\.createdAt) == [newest.createdAt, middle.createdAt, oldest.createdAt])
}

@Test("builder counts only entries within reference month for monthly stats")
func builderMonthlyFiltering() throws {
    let inMonthEarly = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 1_000,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 6, day: 1)
    )
    let inMonthLate = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 2_000,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 6, day: 30)
    )
    let differentMonthSameYear = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 4_000,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 5, day: 30)
    )
    let sameMonthDifferentYear = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 8_000,
        step: .oneThousand, createdAt: try makeDate(year: 2025, month: 6, day: 15)
    )

    let summary = RoundUpJarSummaryBuilder.summary(
        entries: [inMonthEarly, inMonthLate, differentMonthSameYear, sameMonthDifferentYear],
        referenceDate: try makeDate(year: 2026, month: 6, day: 16),
        calendar: fixedCalendar()
    )

    #expect(summary.lifetimeEntryCount == 4)
    #expect(summary.totalContribution == 15_000)
    #expect(summary.monthlyEntryCount == 2)
    #expect(summary.monthlyContribution == 3_000)
}

@Test("builder defaults monthly stats to zero when no entries match the month")
func builderNoMonthlyMatch() throws {
    let entry = RoundUpEntry(
        originalAmount: 1, roundedAmount: 1_000, contribution: 5_000,
        step: .oneThousand, createdAt: try makeDate(year: 2026, month: 1, day: 1)
    )

    let summary = RoundUpJarSummaryBuilder.summary(
        entries: [entry],
        referenceDate: try makeDate(year: 2026, month: 6, day: 16),
        calendar: fixedCalendar()
    )

    #expect(summary.lifetimeEntryCount == 1)
    #expect(summary.totalContribution == 5_000)
    #expect(summary.monthlyEntryCount == 0)
    #expect(summary.monthlyContribution == 0)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var calendar = calendar
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return try #require(
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
