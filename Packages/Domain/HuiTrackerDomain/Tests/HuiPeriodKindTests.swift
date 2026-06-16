import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiPeriodKindTests {
    @Test("all cases are exhaustive")
    func allCases() {
        #expect(HuiPeriodKind.allCases == [.weekly, .biweekly, .monthly])
    }

    @Test("id matches raw value for every case")
    func idMatchesRawValue() {
        for kind in HuiPeriodKind.allCases {
            #expect(kind.id == kind.rawValue)
        }
    }

    @Test("raw values are stable string keys")
    func rawValues() {
        #expect(HuiPeriodKind.weekly.rawValue == "weekly")
        #expect(HuiPeriodKind.biweekly.rawValue == "biweekly")
        #expect(HuiPeriodKind.monthly.rawValue == "monthly")
    }

    @Test("name key is namespaced under hui.period")
    func nameKey() {
        #expect(HuiPeriodKind.weekly.nameKey == "hui.period.weekly")
        #expect(HuiPeriodKind.biweekly.nameKey == "hui.period.biweekly")
        #expect(HuiPeriodKind.monthly.nameKey == "hui.period.monthly")
    }

    @Test("approximate days per period")
    func approximateDays() {
        #expect(HuiPeriodKind.weekly.approximateDays == 7)
        #expect(HuiPeriodKind.biweekly.approximateDays == 14)
        #expect(HuiPeriodKind.monthly.approximateDays == 30)
    }

    @Test("calendar component is day for weekly and biweekly, month for monthly")
    func calendarComponent() {
        #expect(HuiPeriodKind.weekly.calendarComponent == .day)
        #expect(HuiPeriodKind.biweekly.calendarComponent == .day)
        #expect(HuiPeriodKind.monthly.calendarComponent == .month)
    }

    @Test("calendar value per period")
    func calendarValue() {
        #expect(HuiPeriodKind.weekly.calendarValue == 7)
        #expect(HuiPeriodKind.biweekly.calendarValue == 14)
        #expect(HuiPeriodKind.monthly.calendarValue == 1)
    }

    @Test("decodes from raw string value")
    func decodesFromRawValue() throws {
        let json = Data("\"biweekly\"".utf8)
        let decoded = try JSONDecoder().decode(HuiPeriodKind.self, from: json)
        #expect(decoded == .biweekly)
    }

    @Test("encodes to raw string value")
    func encodesToRawValue() throws {
        let encoded = try JSONEncoder().encode(HuiPeriodKind.monthly)
        let string = String(decoding: encoded, as: UTF8.self)
        #expect(string == "\"monthly\"")
    }
}
