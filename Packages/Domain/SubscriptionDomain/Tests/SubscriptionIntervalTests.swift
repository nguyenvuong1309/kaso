import Foundation
import Testing
@testable import SubscriptionDomain

@Test("approximate days are defined per interval")
func approximateDaysPerInterval() {
    #expect(SubscriptionInterval.weekly.approximateDays == 7)
    #expect(SubscriptionInterval.monthly.approximateDays == 30)
    #expect(SubscriptionInterval.yearly.approximateDays == 365)
}

@Test("all cases are enumerated in declaration order")
func allCasesAreEnumerated() {
    #expect(SubscriptionInterval.allCases == [.weekly, .monthly, .yearly])
}

@Test("monthly equivalent prorates weekly amount across the year")
func monthlyEquivalentWeekly() {
    let amount = Decimal(12)
    // 12 * 52 / 12 = 52
    #expect(SubscriptionInterval.weekly.monthlyEquivalent(for: amount) == Decimal(52))
}

@Test("monthly equivalent passes monthly amount through unchanged")
func monthlyEquivalentMonthly() {
    #expect(SubscriptionInterval.monthly.monthlyEquivalent(for: Decimal(260_000)) == Decimal(260_000))
}

@Test("monthly equivalent divides yearly amount by twelve")
func monthlyEquivalentYearly() {
    #expect(SubscriptionInterval.yearly.monthlyEquivalent(for: Decimal(1_200_000)) == Decimal(100_000))
}

@Test("raw values round-trip through Codable")
func rawValueRoundTrip() throws {
    for interval in SubscriptionInterval.allCases {
        let encoded = try JSONEncoder().encode(interval)
        let decoded = try JSONDecoder().decode(SubscriptionInterval.self, from: encoded)
        #expect(decoded == interval)
    }
}

@Test("nextDate advances by one interval when already in the future")
func nextDateAdvancesByOneInterval() throws {
    let calendar = Calendar(identifier: .gregorian)
    let last = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let reference = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let next = SubscriptionInterval.monthly.nextDate(after: last, referenceDate: reference, calendar: calendar)
    let expected = try makeDate(year: 2026, month: 2, day: 1, calendar: calendar)
    #expect(next == expected)
}

@Test("nextDate skips past intervals already behind the reference date")
func nextDateSkipsPastIntervals() throws {
    let calendar = Calendar(identifier: .gregorian)
    let last = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let reference = try makeDate(year: 2026, month: 3, day: 15, calendar: calendar)
    let next = SubscriptionInterval.monthly.nextDate(after: last, referenceDate: reference, calendar: calendar)
    let expected = try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
    #expect(next == expected)
}

@Test("nextDate advances weekly intervals by a week")
func nextDateWeekly() throws {
    let calendar = Calendar(identifier: .gregorian)
    let last = try makeDate(year: 2026, month: 1, day: 3, calendar: calendar)
    let reference = try makeDate(year: 2026, month: 1, day: 3, calendar: calendar)
    let next = SubscriptionInterval.weekly.nextDate(after: last, referenceDate: reference, calendar: calendar)
    let expected = try makeDate(year: 2026, month: 1, day: 10, calendar: calendar)
    #expect(next == expected)
}

@Test("nextDate advances yearly intervals by a year")
func nextDateYearly() throws {
    let calendar = Calendar(identifier: .gregorian)
    let last = try makeDate(year: 2025, month: 4, day: 20, calendar: calendar)
    let reference = try makeDate(year: 2025, month: 4, day: 26, calendar: calendar)
    let next = SubscriptionInterval.yearly.nextDate(after: last, referenceDate: reference, calendar: calendar)
    let expected = try makeDate(year: 2026, month: 4, day: 20, calendar: calendar)
    #expect(next == expected)
}

@Test("matchesGap accepts weekly tolerance window and rejects outside it")
func matchesGapWeekly() throws {
    let calendar = Calendar(identifier: .gregorian)
    let start = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    // 5...9 day window is accepted.
    let lower = try makeDate(year: 2026, month: 1, day: 6, calendar: calendar)
    let upper = try makeDate(year: 2026, month: 1, day: 10, calendar: calendar)
    let belowWindow = try makeDate(year: 2026, month: 1, day: 5, calendar: calendar)
    let aboveWindow = try makeDate(year: 2026, month: 1, day: 11, calendar: calendar)

    #expect(SubscriptionInterval.weekly.matchesGap(from: start, to: lower, calendar: calendar))
    #expect(SubscriptionInterval.weekly.matchesGap(from: start, to: upper, calendar: calendar))
    #expect(!SubscriptionInterval.weekly.matchesGap(from: start, to: belowWindow, calendar: calendar))
    #expect(!SubscriptionInterval.weekly.matchesGap(from: start, to: aboveWindow, calendar: calendar))
}

@Test("matchesGap accepts monthly tolerance window boundaries")
func matchesGapMonthly() throws {
    let calendar = Calendar(identifier: .gregorian)
    let start = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    // 25...35 day window.
    let lower = try makeDate(year: 2026, month: 1, day: 26, calendar: calendar)
    let upper = try makeDate(year: 2026, month: 2, day: 5, calendar: calendar)
    let belowWindow = try makeDate(year: 2026, month: 1, day: 25, calendar: calendar)

    #expect(SubscriptionInterval.monthly.matchesGap(from: start, to: lower, calendar: calendar))
    #expect(SubscriptionInterval.monthly.matchesGap(from: start, to: upper, calendar: calendar))
    #expect(!SubscriptionInterval.monthly.matchesGap(from: start, to: belowWindow, calendar: calendar))
}

@Test("matchesGap accepts yearly tolerance window")
func matchesGapYearly() throws {
    let calendar = Calendar(identifier: .gregorian)
    let start = try makeDate(year: 2025, month: 1, day: 1, calendar: calendar)
    // 350...380 day window. 2025-01-01 -> 2026-01-01 is 365 days.
    let inWindow = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let tooShort = try makeDate(year: 2025, month: 6, day: 1, calendar: calendar)

    #expect(SubscriptionInterval.yearly.matchesGap(from: start, to: inWindow, calendar: calendar))
    #expect(!SubscriptionInterval.yearly.matchesGap(from: start, to: tooShort, calendar: calendar))
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
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
