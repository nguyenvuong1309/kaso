import Foundation
import Testing
@testable import SmartSearchDomain

struct SmartSearchQueryTests {
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

    @Test("stores all initializer values")
    func storesValues() throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let end = try makeDate(year: 2026, month: 2, day: 1, calendar: calendar)
        let interval = DateInterval(start: start, end: end)
        let query = SmartSearchQuery(
            rawText: "Cà phê tháng 1",
            keyword: "cà phê",
            dateRange: interval
        )
        #expect(query.rawText == "Cà phê tháng 1")
        #expect(query.keyword == "cà phê")
        #expect(query.dateRange == interval)
    }

    @Test("hasDateRange is true when a date range is present")
    func hasDateRangeTrue() throws {
        let start = try makeDate(year: 2026, month: 3, day: 1)
        let end = try makeDate(year: 2026, month: 4, day: 1)
        let query = SmartSearchQuery(
            rawText: "x",
            keyword: "x",
            dateRange: DateInterval(start: start, end: end)
        )
        #expect(query.hasDateRange)
    }

    @Test("hasDateRange is false when date range is nil")
    func hasDateRangeFalse() {
        let query = SmartSearchQuery(rawText: "x", keyword: "x", dateRange: nil)
        #expect(query.hasDateRange == false)
    }

    @Test("equatable: identical queries are equal")
    func equatableEqual() throws {
        let start = try makeDate(year: 2026, month: 5, day: 1)
        let end = try makeDate(year: 2026, month: 6, day: 1)
        let interval = DateInterval(start: start, end: end)
        let lhs = SmartSearchQuery(rawText: "raw", keyword: "kw", dateRange: interval)
        let rhs = SmartSearchQuery(rawText: "raw", keyword: "kw", dateRange: interval)
        #expect(lhs == rhs)
    }

    @Test("equatable: differing keyword makes queries unequal")
    func equatableUnequalKeyword() {
        let lhs = SmartSearchQuery(rawText: "raw", keyword: "a", dateRange: nil)
        let rhs = SmartSearchQuery(rawText: "raw", keyword: "b", dateRange: nil)
        #expect(lhs != rhs)
    }

    @Test("equatable: differing date range makes queries unequal")
    func equatableUnequalDateRange() throws {
        let start = try makeDate(year: 2026, month: 5, day: 1)
        let end = try makeDate(year: 2026, month: 6, day: 1)
        let lhs = SmartSearchQuery(
            rawText: "raw",
            keyword: "kw",
            dateRange: DateInterval(start: start, end: end)
        )
        let rhs = SmartSearchQuery(rawText: "raw", keyword: "kw", dateRange: nil)
        #expect(lhs != rhs)
    }
}
