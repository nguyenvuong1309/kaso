import Foundation
import Testing
@testable import SmartSearchDomain

struct SmartSearchParserTests {
    private let calendar = Calendar(identifier: .gregorian)

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

    // Reference: Tuesday, 2026-05-19, 10:00.
    private func reference() throws -> Date {
        try makeDate(year: 2026, month: 5, day: 19, hour: 10, calendar: calendar)
    }

    // MARK: - "today" / "hôm nay"

    @Test("parses 'today' to the current day interval")
    func parsesTodayEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("coffee today", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "coffee")
        let expected = try #require(calendar.dateInterval(of: .day, for: ref))
        #expect(query.dateRange == expected)
        #expect(query.rawText == "coffee today")
    }

    @Test("parses Vietnamese 'hôm nay'")
    func parsesTodayVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("cà phê hôm nay", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "cà phê")
        let expected = try #require(calendar.dateInterval(of: .day, for: ref))
        #expect(query.dateRange == expected)
    }

    // MARK: - "yesterday" / "hôm qua"

    @Test("parses 'yesterday' to the prior day interval")
    func parsesYesterdayEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("tea yesterday", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "tea")
        let prior = try #require(calendar.date(byAdding: .day, value: -1, to: ref))
        let expected = try #require(calendar.dateInterval(of: .day, for: prior))
        #expect(query.dateRange == expected)
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 5, day: 18, calendar: calendar)))
    }

    @Test("parses Vietnamese 'hôm qua'")
    func parsesYesterdayVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("trà hôm qua", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "trà")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 5, day: 18, calendar: calendar)))
    }

    // MARK: - "this week" / "tuần này"

    @Test("parses 'this week'")
    func parsesThisWeekEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("lunch this week", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "lunch")
        let expected = try #require(calendar.dateInterval(of: .weekOfYear, for: ref))
        #expect(query.dateRange == expected)
    }

    @Test("parses Vietnamese 'tuần này'")
    func parsesThisWeekVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("ăn trưa tuần này", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "ăn trưa")
        let expected = try #require(calendar.dateInterval(of: .weekOfYear, for: ref))
        #expect(query.dateRange == expected)
    }

    // MARK: - "last week" / "tuần trước" / "tuần rồi"

    @Test("parses 'last week'")
    func parsesLastWeekEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("Grab last week", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "grab")
        let prior = try #require(calendar.date(byAdding: .weekOfYear, value: -1, to: ref))
        let expected = try #require(calendar.dateInterval(of: .weekOfYear, for: prior))
        #expect(query.dateRange == expected)
    }

    @Test("parses Vietnamese alternate 'tuần rồi'")
    func parsesLastWeekAlternate() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("xăng tuần rồi", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "xăng")
        let prior = try #require(calendar.date(byAdding: .weekOfYear, value: -1, to: ref))
        let expected = try #require(calendar.dateInterval(of: .weekOfYear, for: prior))
        #expect(query.dateRange == expected)
    }

    // MARK: - "this month" / "tháng này"

    @Test("parses 'this month'")
    func parsesThisMonthEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("rent this month", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "rent")
        let expected = try #require(calendar.dateInterval(of: .month, for: ref))
        #expect(query.dateRange == expected)
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)))
    }

    @Test("parses Vietnamese 'tháng này'")
    func parsesThisMonthVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("tiền nhà tháng này", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "tiền nhà")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)))
    }

    // MARK: - "last month" / "tháng trước"

    @Test("parses Vietnamese 'tháng trước'")
    func parsesLastMonthVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("hoá đơn tháng trước", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "hoá đơn")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)))
    }

    // MARK: - "this year" / "năm nay"

    @Test("parses 'this year'")
    func parsesThisYearEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("salary this year", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "salary")
        let expected = try #require(calendar.dateInterval(of: .year, for: ref))
        #expect(query.dateRange == expected)
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)))
    }

    @Test("parses Vietnamese 'năm nay'")
    func parsesThisYearVietnamese() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("lương năm nay", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "lương")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)))
    }

    // MARK: - "last year" / "năm trước" / "năm ngoái"

    @Test("parses 'last year'")
    func parsesLastYearEnglish() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("bonus last year", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "bonus")
        #expect(query.dateRange?.start == (try makeDate(year: 2025, month: 1, day: 1, calendar: calendar)))
    }

    @Test("parses Vietnamese alternate 'năm ngoái'")
    func parsesLastYearAlternate() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("thưởng năm ngoái", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "thưởng")
        #expect(query.dateRange?.start == (try makeDate(year: 2025, month: 1, day: 1, calendar: calendar)))
    }

    // MARK: - month number via "month <n>" / "tháng <n>"

    @Test("parses English 'month 7'")
    func parsesEnglishMonthNumber() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("travel month 7", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "travel")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)))
    }

    @Test("parses two-digit 'tháng 12'")
    func parsesTwoDigitMonth() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("quà tháng 12", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "quà")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 12, day: 1, calendar: calendar)))
    }

    @Test("month number out of range (13) is ignored")
    func monthNumberOutOfRange() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("ăn tháng 13", referenceDate: ref, calendar: calendar)
        #expect(query.dateRange == nil)
        // Only the leading "1" of "13" is consumed by month extraction? No —
        // 13 is parsed as a number but rejected, so the phrase remains.
        #expect(query.keyword.contains("ăn"))
    }

    @Test("month prefix without digits keeps text and yields no interval")
    func monthPrefixWithoutDigits() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("tháng đẹp", referenceDate: ref, calendar: calendar)
        #expect(query.dateRange == nil)
        #expect(query.keyword.contains("tháng đẹp"))
    }

    @Test("month zero is rejected")
    func monthZeroRejected() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("x tháng 0", referenceDate: ref, calendar: calendar)
        #expect(query.dateRange == nil)
    }

    // MARK: - keyword stripping / whitespace

    @Test("named phrase wins over month-number extraction")
    func namedPhrasePriority() throws {
        let ref = try reference()
        // "tháng này" is a named phrase; "tháng 5" extraction must not run.
        let query = SmartSearchParser.parse("cà phê tháng này", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "cà phê")
        #expect(query.dateRange?.start == (try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)))
    }

    @Test("uppercase input is lowercased in keyword")
    func uppercaseLowercased() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("COFFEE", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "coffee")
        #expect(query.rawText == "COFFEE")
    }

    @Test("empty input yields empty keyword and no date range")
    func emptyInput() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("", referenceDate: ref, calendar: calendar)
        #expect(query.keyword.isEmpty)
        #expect(query.dateRange == nil)
        #expect(query.rawText.isEmpty)
    }

    @Test("phrase-only input yields empty keyword")
    func phraseOnly() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("today", referenceDate: ref, calendar: calendar)
        #expect(query.keyword.isEmpty)
        #expect(query.dateRange != nil)
    }

    @Test("surrounding whitespace is trimmed from keyword")
    func trimsWhitespace() throws {
        let ref = try reference()
        let query = SmartSearchParser.parse("  phở  ", referenceDate: ref, calendar: calendar)
        #expect(query.keyword == "phở")
    }

    @Test("only the first matching named phrase is applied")
    func firstPhraseOnly() throws {
        let ref = try reference()
        // Both "today" and "this week" present; "today" is checked first.
        let query = SmartSearchParser.parse("today this week", referenceDate: ref, calendar: calendar)
        let expected = try #require(calendar.dateInterval(of: .day, for: ref))
        #expect(query.dateRange == expected)
        // "this week" remains in the keyword since only one phrase is stripped.
        #expect(query.keyword.contains("this week"))
    }

    @Test("default calendar parameter path executes")
    func defaultCalendarParameter() throws {
        let ref = try reference()
        // Exercises the default calendar argument; only assert structural shape.
        let query = SmartSearchParser.parse("groceries", referenceDate: ref)
        #expect(query.keyword == "groceries")
        #expect(query.dateRange == nil)
    }
}
