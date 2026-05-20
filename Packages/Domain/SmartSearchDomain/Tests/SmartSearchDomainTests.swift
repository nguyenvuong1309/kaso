import Foundation
import Testing
@testable import SmartSearchDomain

struct SmartSearchDomainTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let reference: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 5
        comps.day = 19
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
    }()

    @Test("parses Vietnamese 'cà phê tuần trước'")
    func parsesVietnameseLastWeek() {
        let query = SmartSearchParser.parse(
            "cà phê tuần trước",
            referenceDate: reference,
            calendar: calendar
        )
        #expect(query.keyword == "cà phê")
        #expect(query.dateRange != nil)
    }

    @Test("parses English 'Grab last month'")
    func parsesEnglishLastMonth() {
        let query = SmartSearchParser.parse(
            "Grab last month",
            referenceDate: reference,
            calendar: calendar
        )
        #expect(query.keyword == "grab")
        let expectedStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? Date()
        #expect(query.dateRange?.start == expectedStart)
    }

    @Test("parses 'tháng 3'")
    func parsesMonthNumber() {
        let query = SmartSearchParser.parse(
            "ăn sáng tháng 3",
            referenceDate: reference,
            calendar: calendar
        )
        #expect(query.keyword.contains("ăn sáng"))
        let expectedStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? Date()
        #expect(query.dateRange?.start == expectedStart)
    }

    @Test("returns nil interval when no phrase matches")
    func noDateRange() {
        let query = SmartSearchParser.parse(
            "phở tái",
            referenceDate: reference,
            calendar: calendar
        )
        #expect(query.keyword == "phở tái")
        #expect(query.dateRange == nil)
    }
}
