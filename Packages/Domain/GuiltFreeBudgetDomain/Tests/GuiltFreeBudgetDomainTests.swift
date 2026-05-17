import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

@Test("calculates free money after fixed costs and savings")
func calculatesFreeMoney() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 25_000_000,
        monthlySavingsTarget: 5_000_000,
        emergencyFundMonthlyContribution: 1_000_000,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Tiền nhà", amount: 8_000_000, kind: .housing),
            GuiltFreeFixedCost(name: "Điện nước", amount: 1_200_000, kind: .utilities),
        ]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.monthlyIncome == 25_000_000)
    #expect(budget.totalFixedCosts == 9_200_000)
    #expect(budget.totalSavings == 5_000_000)
    #expect(budget.totalEmergency == 1_000_000)
    #expect(budget.freeMoney == 9_800_000)
    #expect(budget.health == .healthy)
}

@Test("flags overspending when allocations exceed income")
func flagsOverspending() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: 2_000_000,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Tiền nhà", amount: 9_000_000, kind: .housing),
        ]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.freeMoney == -1_000_000)
    #expect(budget.health == .overspending)
}

@Test("marks income missing when not configured")
func marksIncomeMissing() {
    let budget = GuiltFreeBudgetCalculator.calculate(GuiltFreeBudgetConfiguration())

    #expect(budget.health == .incomeMissing)
    #expect(budget.freeMoneyRatio == 0)
}

@Test("marks tight when free money under 10 percent of income")
func marksTight() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: 0,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Cố định", amount: 9_500_000, kind: .other),
        ]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.health == .tight)
}

@Test("daily allowance divides free money by remaining days")
func dailyAllowanceDivides() throws {
    let budget = GuiltFreeBudgetCalculator.calculate(
        GuiltFreeBudgetConfiguration(
            monthlyIncome: 10_000_000,
            fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 5_000_000, kind: .other)]
        )
    )
    let reference = try date(2026, 4, 20)

    let perDay = GuiltFreeBudgetCalculator.dailyAllowance(
        from: budget,
        referenceDate: reference,
        calendar: fixedCalendar()
    )

    // April has 30 days, 20–30 inclusive = 11 days
    #expect(perDay == Decimal(5_000_000) / Decimal(11))
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
