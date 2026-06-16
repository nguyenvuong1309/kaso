import Foundation
import Testing
@testable import SpendingMapDomain

struct SpendingMapPeriodTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = TimeZone(identifier: "UTC")
        return try #require(calendar.date(from: components))
    }

    @Test("allCases exposes every period in declaration order")
    func allCasesOrder() {
        #expect(SpendingMapPeriod.allCases == [.last30Days, .last90Days, .allTime])
    }

    @Test("id matches the raw value for each period")
    func idMatchesRawValue() {
        for period in SpendingMapPeriod.allCases {
            #expect(period.id == period.rawValue)
        }
        #expect(SpendingMapPeriod.last30Days.id == "last30Days")
        #expect(SpendingMapPeriod.last90Days.id == "last90Days")
        #expect(SpendingMapPeriod.allTime.id == "allTime")
    }

    @Test("titleKey returns the namespaced localization key per case")
    func titleKeyPerCase() {
        #expect(SpendingMapPeriod.last30Days.titleKey == "spendingMap.period.last30Days")
        #expect(SpendingMapPeriod.last90Days.titleKey == "spendingMap.period.last90Days")
        #expect(SpendingMapPeriod.allTime.titleKey == "spendingMap.period.allTime")
    }

    @Test("last30Days startDate is exactly 30 days before reference")
    func startDateLast30() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        let expected = try makeDate(year: 2024, month: 10, day: 1, calendar: calendar)
        let start = try #require(
            SpendingMapPeriod.last30Days.startDate(referenceDate: reference, calendar: calendar)
        )
        #expect(start == expected)
    }

    @Test("last90Days startDate is exactly 90 days before reference")
    func startDateLast90() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        let expected = try makeDate(year: 2024, month: 8, day: 2, calendar: calendar)
        let start = try #require(
            SpendingMapPeriod.last90Days.startDate(referenceDate: reference, calendar: calendar)
        )
        #expect(start == expected)
    }

    @Test("allTime startDate is nil so nothing is filtered")
    func startDateAllTime() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        #expect(SpendingMapPeriod.allTime.startDate(referenceDate: reference, calendar: calendar) == nil)
    }

    @Test("period round-trips through Codable")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for period in SpendingMapPeriod.allCases {
            let data = try encoder.encode(period)
            let decoded = try decoder.decode(SpendingMapPeriod.self, from: data)
            #expect(decoded == period)
        }
    }

    @Test("period decodes from its raw string value")
    func decodesFromRawString() throws {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SpendingMapPeriod.self, from: Data("\"last90Days\"".utf8))
        #expect(decoded == .last90Days)
    }
}
