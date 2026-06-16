import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

// MARK: - GuiltFreeBudgetConfiguration

@Test("configuration default init zeroes amounts and empties fixed costs")
func configurationDefaults() throws {
    let updatedAt = try configDate(2026, 6, 16)
    let config = GuiltFreeBudgetConfiguration(updatedAt: updatedAt)

    #expect(config.monthlyIncome == 0)
    #expect(config.monthlySavingsTarget == 0)
    #expect(config.emergencyFundMonthlyContribution == 0)
    #expect(config.fixedCosts.isEmpty)
    #expect(config.updatedAt == updatedAt)
}

@Test("configuration init stores all provided fields")
func configurationStoresFields() throws {
    let updatedAt = try configDate(2026, 5, 1)
    let costs = [GuiltFreeFixedCost(name: "Nhà", amount: 7_000_000, kind: .housing)]
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 18_000_000,
        monthlySavingsTarget: 2_000_000,
        emergencyFundMonthlyContribution: 500_000,
        fixedCosts: costs,
        updatedAt: updatedAt
    )

    #expect(config.monthlyIncome == 18_000_000)
    #expect(config.monthlySavingsTarget == 2_000_000)
    #expect(config.emergencyFundMonthlyContribution == 500_000)
    #expect(config.fixedCosts == costs)
    #expect(config.updatedAt == updatedAt)
}

@Test("two configurations with identical fields are equal")
func configurationEquatable() throws {
    let updatedAt = try configDate(2026, 5, 1)
    let costs = [GuiltFreeFixedCost(
        id: try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555")),
        name: "Nhà",
        amount: 7_000_000,
        kind: .housing
    )]
    let lhs = GuiltFreeBudgetConfiguration(
        monthlyIncome: 18_000_000,
        fixedCosts: costs,
        updatedAt: updatedAt
    )
    let rhs = GuiltFreeBudgetConfiguration(
        monthlyIncome: 18_000_000,
        fixedCosts: costs,
        updatedAt: updatedAt
    )
    var different = rhs
    different.monthlyIncome = 19_000_000

    #expect(lhs == rhs)
    #expect(lhs != different)
}

@Test("configuration round-trips through Codable preserving fields")
func configurationCodableRoundTrip() throws {
    let updatedAt = try configDate(2026, 3, 10)
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 25_000_000,
        monthlySavingsTarget: 5_000_000,
        emergencyFundMonthlyContribution: 1_000_000,
        fixedCosts: [
            GuiltFreeFixedCost(
                id: try #require(UUID(uuidString: "66666666-6666-6666-6666-666666666666")),
                name: "Tiền nhà",
                amount: 8_000_000,
                kind: .housing
            ),
        ],
        updatedAt: updatedAt
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let data = try encoder.encode(config)
    let decoded = try decoder.decode(GuiltFreeBudgetConfiguration.self, from: data)

    #expect(decoded == config)
    #expect(decoded.fixedCosts.count == 1)
    #expect(decoded.monthlyIncome == 25_000_000)
}

// MARK: - Helpers

private func configCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func configDate(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: configCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
