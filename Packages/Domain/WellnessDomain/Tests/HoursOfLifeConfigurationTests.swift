import Foundation
import Testing
@testable import WellnessDomain

@Test("configuration is valid only when both fields are positive")
func configurationIsValidOnlyWhenBothFieldsPositive() {
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: 1, averageMonthlyWorkHours: 1).isValid
    )
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: 0, averageMonthlyWorkHours: 160).isValid == false
    )
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 0).isValid == false
    )
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: -1, averageMonthlyWorkHours: -1).isValid == false
    )
}

@Test("net income per work hour divides income by hours")
func netIncomePerWorkHourDividesIncomeByHours() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 16_000_000,
        averageMonthlyWorkHours: 160
    )

    let rate = try #require(configuration.netIncomePerWorkHour)
    #expect(rate == 100_000)
}

@Test("net income per work hour is nil for invalid configuration")
func netIncomePerWorkHourIsNilForInvalidConfiguration() {
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: 0, averageMonthlyWorkHours: 160)
            .netIncomePerWorkHour == nil
    )
    #expect(
        HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 0)
            .netIncomePerWorkHour == nil
    )
}

@Test("configuration equality compares both fields")
func configurationEqualityComparesBothFields() {
    let base = HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 160)

    #expect(base == HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 160))
    #expect(base != HoursOfLifeConfiguration(monthlyNetIncome: 19_000_000, averageMonthlyWorkHours: 160))
    #expect(base != HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 168))
}

@Test("configuration round-trips through codable")
func configurationRoundTripsThroughCodable() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 18_500_000,
        averageMonthlyWorkHours: 168
    )

    let data = try JSONEncoder().encode(configuration)
    let decoded = try JSONDecoder().decode(HoursOfLifeConfiguration.self, from: data)

    #expect(decoded == configuration)
}
