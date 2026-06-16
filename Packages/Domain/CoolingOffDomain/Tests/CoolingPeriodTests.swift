import Foundation
import Testing
@testable import CoolingOffDomain

@Test("cooling period seconds match expected day counts")
func coolingPeriodSeconds() {
    #expect(CoolingPeriod.oneDay.seconds == 86_400)
    #expect(CoolingPeriod.threeDays.seconds == 3 * 86_400)
    #expect(CoolingPeriod.oneWeek.seconds == 7 * 86_400)
    #expect(CoolingPeriod.twoWeeks.seconds == 14 * 86_400)
}

@Test("cooling period id equals raw value")
func coolingPeriodIdentifiable() {
    for period in CoolingPeriod.allCases {
        #expect(period.id == period.rawValue)
    }
}

@Test("cooling period name key follows localization convention")
func coolingPeriodNameKey() {
    #expect(CoolingPeriod.oneDay.nameKey == "coolingOff.period.oneDay")
    #expect(CoolingPeriod.threeDays.nameKey == "coolingOff.period.threeDays")
    #expect(CoolingPeriod.oneWeek.nameKey == "coolingOff.period.oneWeek")
    #expect(CoolingPeriod.twoWeeks.nameKey == "coolingOff.period.twoWeeks")
}

@Test("cooling period exposes all four cases")
func coolingPeriodAllCases() {
    #expect(CoolingPeriod.allCases.count == 4)
    #expect(CoolingPeriod.allCases == [.oneDay, .threeDays, .oneWeek, .twoWeeks])
}

@Test("cooling period round-trips through Codable")
func coolingPeriodCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for period in CoolingPeriod.allCases {
        let data = try encoder.encode(period)
        let decoded = try decoder.decode(CoolingPeriod.self, from: data)
        #expect(decoded == period)
    }
}

@Test("cooling period raw values are stable identifiers")
func coolingPeriodRawValues() {
    #expect(CoolingPeriod.oneDay.rawValue == "oneDay")
    #expect(CoolingPeriod.threeDays.rawValue == "threeDays")
    #expect(CoolingPeriod.oneWeek.rawValue == "oneWeek")
    #expect(CoolingPeriod.twoWeeks.rawValue == "twoWeeks")
}
