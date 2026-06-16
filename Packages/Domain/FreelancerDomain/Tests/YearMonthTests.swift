import Foundation
import Testing
@testable import FreelancerDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
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

@Test("init clamps month into the 1...12 range")
func yearMonthClampsMonth() {
    #expect(YearMonth(year: 2026, month: 0).month == 1)
    #expect(YearMonth(year: 2026, month: -5).month == 1)
    #expect(YearMonth(year: 2026, month: 13).month == 12)
    #expect(YearMonth(year: 2026, month: 99).month == 12)
    #expect(YearMonth(year: 2026, month: 7).month == 7)
}

@Test("init keeps year unchanged")
func yearMonthKeepsYear() {
    #expect(YearMonth(year: 2026, month: 3).year == 2026)
    #expect(YearMonth(year: 1999, month: 3).year == 1999)
}

@Test("id pads month to two digits")
func yearMonthIdPadsMonth() {
    #expect(YearMonth(year: 2026, month: 1).id == "2026-01")
    #expect(YearMonth(year: 2026, month: 12).id == "2026-12")
    #expect(YearMonth(year: 2026, month: 9).id == "2026-09")
}

@Test("init from date extracts year and month")
func yearMonthFromDate() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2024, month: 8, day: 15, calendar: calendar)
    let yearMonth = YearMonth(date: date, calendar: calendar)
    #expect(yearMonth.year == 2024)
    #expect(yearMonth.month == 8)
}

@Test("date returns the first day of the month")
func yearMonthToDate() throws {
    let calendar = Calendar(identifier: .gregorian)
    let yearMonth = YearMonth(year: 2026, month: 5)
    let date = try #require(yearMonth.date(calendar: calendar))
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    #expect(components.year == 2026)
    #expect(components.month == 5)
    #expect(components.day == 1)
}

@Test("comparable orders by year then month")
func yearMonthComparable() {
    #expect(YearMonth(year: 2025, month: 12) < YearMonth(year: 2026, month: 1))
    #expect(YearMonth(year: 2026, month: 3) < YearMonth(year: 2026, month: 4))
    #expect(YearMonth(year: 2026, month: 4) > YearMonth(year: 2026, month: 3))
    #expect(!(YearMonth(year: 2026, month: 5) < YearMonth(year: 2026, month: 5)))
}

@Test("equatable matches on year and month")
func yearMonthEquatable() {
    #expect(YearMonth(year: 2026, month: 6) == YearMonth(year: 2026, month: 6))
    #expect(YearMonth(year: 2026, month: 6) != YearMonth(year: 2026, month: 7))
    #expect(YearMonth(year: 2025, month: 6) != YearMonth(year: 2026, month: 6))
}

@Test("hashable equal values share a hash")
func yearMonthHashable() {
    let set: Set<YearMonth> = [
        YearMonth(year: 2026, month: 6),
        YearMonth(year: 2026, month: 6),
        YearMonth(year: 2026, month: 7),
    ]
    #expect(set.count == 2)
}

@Test("codable round-trips through JSON")
func yearMonthCodableRoundTrip() throws {
    let original = YearMonth(year: 2026, month: 11)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(YearMonth.self, from: data)
    #expect(decoded == original)
}
