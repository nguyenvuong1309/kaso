import Foundation
import Testing
@testable import GiftTrackerDomain

// MARK: - GiftPersonSummary computed properties

@Test("netBalance is received minus given (positive)")
func netBalancePositive() throws {
    let calendar = Calendar(identifier: .gregorian)
    let summary = GiftPersonSummary(
        personName: "A",
        totalGiven: 300_000,
        totalReceived: 800_000,
        lastEventDate: try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar),
        lastEventKind: .tet,
        records: []
    )
    #expect(summary.netBalance == 500_000)
}

@Test("netBalance is zero when given equals received")
func netBalanceZero() throws {
    let calendar = Calendar(identifier: .gregorian)
    let summary = GiftPersonSummary(
        personName: "A",
        totalGiven: 400_000,
        totalReceived: 400_000,
        lastEventDate: try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar),
        lastEventKind: .wedding,
        records: []
    )
    #expect(summary.netBalance == 0)
}

@Test("id equals personName")
func summaryIdentifiable() throws {
    let calendar = Calendar(identifier: .gregorian)
    let summary = GiftPersonSummary(
        personName: "Nguyễn Văn Hùng",
        totalGiven: 0,
        totalReceived: 0,
        lastEventDate: try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar),
        lastEventKind: .other,
        records: []
    )
    #expect(summary.id == "Nguyễn Văn Hùng")
}

@Test("suggestedAmount is zero when there are no records")
func suggestedAmountEmpty() throws {
    let calendar = Calendar(identifier: .gregorian)
    let summary = GiftPersonSummary(
        personName: "A",
        totalGiven: 0,
        totalReceived: 0,
        lastEventDate: try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar),
        lastEventKind: .other,
        records: []
    )
    #expect(summary.suggestedAmount == 0)
}

@Test("suggestedAmount averages only given records when given history exists")
func suggestedAmountAveragesGiven() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeSummaryDate(year: 2026, month: 2, day: 2, calendar: calendar)
    let records = [
        GiftRecord(personName: "A", eventKind: .wedding, direction: .given, amount: 1_000_000, eventDate: date),
        GiftRecord(personName: "A", eventKind: .wedding, direction: .given, amount: 500_000, eventDate: date),
        GiftRecord(personName: "A", eventKind: .tet, direction: .received, amount: 999_999, eventDate: date),
    ]
    let summary = GiftPersonSummary(
        personName: "A",
        totalGiven: 1_500_000,
        totalReceived: 999_999,
        lastEventDate: date,
        lastEventKind: .wedding,
        records: records
    )
    // (1_000_000 + 500_000) / 2 = 750_000, received ignored
    #expect(summary.suggestedAmount == 750_000)
}

@Test("suggestedAmount falls back to averaging all records when no given history")
func suggestedAmountFallsBackToAll() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeSummaryDate(year: 2026, month: 3, day: 3, calendar: calendar)
    let records = [
        GiftRecord(personName: "A", eventKind: .tet, direction: .received, amount: 200_000, eventDate: date),
        GiftRecord(personName: "A", eventKind: .birthday, direction: .received, amount: 400_000, eventDate: date),
    ]
    let summary = GiftPersonSummary(
        personName: "A",
        totalGiven: 0,
        totalReceived: 600_000,
        lastEventDate: date,
        lastEventKind: .birthday,
        records: records
    )
    // (200_000 + 400_000) / 2 = 300_000
    #expect(summary.suggestedAmount == 300_000)
}

@Test("GiftPersonSummary is Equatable")
func summaryEquatable() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeSummaryDate(year: 2026, month: 4, day: 4, calendar: calendar)
    let lhs = GiftPersonSummary(
        personName: "A", totalGiven: 1, totalReceived: 2,
        lastEventDate: date, lastEventKind: .tet, records: []
    )
    let rhs = GiftPersonSummary(
        personName: "A", totalGiven: 1, totalReceived: 2,
        lastEventDate: date, lastEventKind: .tet, records: []
    )
    let different = GiftPersonSummary(
        personName: "A", totalGiven: 1, totalReceived: 3,
        lastEventDate: date, lastEventKind: .tet, records: []
    )
    #expect(lhs == rhs)
    #expect(lhs != different)
}

// MARK: - GiftPersonSummaryBuilder

@Test("GiftPersonSummaryBuilder returns empty for empty input")
func builderEmptyInput() {
    let summaries = GiftPersonSummaryBuilder.build(from: [])
    #expect(summaries.isEmpty)
}

@Test("GiftPersonSummaryBuilder groups by person and sums per direction")
func builderGroupsAndSums() throws {
    let calendar = Calendar(identifier: .gregorian)
    let early = try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let late = try makeSummaryDate(year: 2026, month: 6, day: 1, calendar: calendar)

    let records = [
        GiftRecord(personName: "Hùng", eventKind: .wedding, direction: .given, amount: 1_000_000, eventDate: late),
        GiftRecord(personName: "Hùng", eventKind: .tet, direction: .received, amount: 500_000, eventDate: early),
        GiftRecord(personName: "Mai", eventKind: .babyShower, direction: .given, amount: 300_000, eventDate: early),
    ]

    let summaries = GiftPersonSummaryBuilder.build(from: records)
    #expect(summaries.count == 2)

    let hung = try #require(summaries.first { $0.personName == "Hùng" })
    #expect(hung.totalGiven == 1_000_000)
    #expect(hung.totalReceived == 500_000)
    #expect(hung.records.count == 2)
}

@Test("GiftPersonSummaryBuilder uses latest event for lastEventDate and lastEventKind")
func builderUsesLatestEvent() throws {
    let calendar = Calendar(identifier: .gregorian)
    let early = try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let late = try makeSummaryDate(year: 2026, month: 6, day: 1, calendar: calendar)

    let records = [
        GiftRecord(personName: "Hùng", eventKind: .tet, direction: .received, amount: 500_000, eventDate: early),
        GiftRecord(personName: "Hùng", eventKind: .wedding, direction: .given, amount: 1_000_000, eventDate: late),
    ]

    let summaries = GiftPersonSummaryBuilder.build(from: records)
    let hung = try #require(summaries.first)
    #expect(hung.lastEventDate == late)
    #expect(hung.lastEventKind == .wedding)
}

@Test("GiftPersonSummaryBuilder sorts each person's records newest first")
func builderSortsRecordsDescending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let early = try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let mid = try makeSummaryDate(year: 2026, month: 3, day: 1, calendar: calendar)
    let late = try makeSummaryDate(year: 2026, month: 6, day: 1, calendar: calendar)

    let records = [
        GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 1, eventDate: early),
        GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 2, eventDate: late),
        GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 3, eventDate: mid),
    ]

    let summaries = GiftPersonSummaryBuilder.build(from: records)
    let a = try #require(summaries.first)
    #expect(a.records.map(\.eventDate) == [late, mid, early])
}

@Test("GiftPersonSummaryBuilder sorts summaries by lastEventDate descending")
func builderSortsSummariesDescending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let early = try makeSummaryDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let late = try makeSummaryDate(year: 2026, month: 6, day: 1, calendar: calendar)

    let records = [
        GiftRecord(personName: "Early", eventKind: .tet, direction: .given, amount: 1, eventDate: early),
        GiftRecord(personName: "Late", eventKind: .tet, direction: .given, amount: 1, eventDate: late),
    ]

    let summaries = GiftPersonSummaryBuilder.build(from: records)
    #expect(summaries.map(\.personName) == ["Late", "Early"])
}

@Test("GiftPersonSummaryBuilder handles a person with a single record")
func builderSingleRecord() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeSummaryDate(year: 2026, month: 2, day: 14, calendar: calendar)
    let records = [
        GiftRecord(personName: "Solo", eventKind: .birthday, direction: .received, amount: 250_000, eventDate: date),
    ]

    let summaries = GiftPersonSummaryBuilder.build(from: records)
    #expect(summaries.count == 1)
    let solo = try #require(summaries.first)
    #expect(solo.totalGiven == 0)
    #expect(solo.totalReceived == 250_000)
    #expect(solo.records.count == 1)
    #expect(solo.lastEventKind == .birthday)
}

// MARK: - GiftYearlySummary

@Test("GiftYearlySummary stores initializer values and computes netBalance")
func yearlySummaryInit() {
    let summary = GiftYearlySummary(
        year: 2026,
        totalGiven: 1_000_000,
        totalReceived: 1_300_000,
        recordCount: 5
    )
    #expect(summary.year == 2026)
    #expect(summary.totalGiven == 1_000_000)
    #expect(summary.totalReceived == 1_300_000)
    #expect(summary.recordCount == 5)
    #expect(summary.netBalance == 300_000)
}

@Test("GiftYearlySummary is Equatable")
func yearlySummaryEquatable() {
    let lhs = GiftYearlySummary(year: 2026, totalGiven: 1, totalReceived: 2, recordCount: 3)
    let rhs = GiftYearlySummary(year: 2026, totalGiven: 1, totalReceived: 2, recordCount: 3)
    let different = GiftYearlySummary(year: 2025, totalGiven: 1, totalReceived: 2, recordCount: 3)
    #expect(lhs == rhs)
    #expect(lhs != different)
}

// MARK: - GiftYearlySummaryBuilder

@Test("GiftYearlySummaryBuilder returns zeros for empty input")
func yearlyBuilderEmpty() {
    let calendar = Calendar(identifier: .gregorian)
    let summary = GiftYearlySummaryBuilder.build(from: [], calendar: calendar)
    #expect(summary.totalGiven == 0)
    #expect(summary.totalReceived == 0)
    #expect(summary.recordCount == 0)
    #expect(summary.year == calendar.component(.year, from: Date()))
}

@Test("GiftYearlySummaryBuilder filters records to the current year")
func yearlyBuilderFiltersCurrentYear() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentYear = calendar.component(.year, from: Date())

    let inYearGiven = try makeSummaryDate(year: currentYear, month: 2, day: 1, calendar: calendar)
    let inYearReceived = try makeSummaryDate(year: currentYear, month: 7, day: 1, calendar: calendar)
    let priorYear = try makeSummaryDate(year: currentYear - 1, month: 12, day: 31, calendar: calendar)

    let records = [
        GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 500_000, eventDate: inYearGiven),
        GiftRecord(personName: "B", eventKind: .tet, direction: .received, amount: 200_000, eventDate: inYearReceived),
        GiftRecord(personName: "C", eventKind: .tet, direction: .given, amount: 1_000_000, eventDate: priorYear),
    ]

    let summary = GiftYearlySummaryBuilder.build(from: records, calendar: calendar)
    #expect(summary.year == currentYear)
    #expect(summary.totalGiven == 500_000)
    #expect(summary.totalReceived == 200_000)
    #expect(summary.recordCount == 2)
}

@Test("GiftYearlySummaryBuilder yields zeros when no records fall in the current year")
func yearlyBuilderNoCurrentYearRecords() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentYear = calendar.component(.year, from: Date())
    let priorYear = try makeSummaryDate(year: currentYear - 2, month: 5, day: 5, calendar: calendar)

    let records = [
        GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 999_999, eventDate: priorYear),
    ]

    let summary = GiftYearlySummaryBuilder.build(from: records, calendar: calendar)
    #expect(summary.recordCount == 0)
    #expect(summary.totalGiven == 0)
    #expect(summary.totalReceived == 0)
}

// MARK: - Helpers

private func makeSummaryDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
