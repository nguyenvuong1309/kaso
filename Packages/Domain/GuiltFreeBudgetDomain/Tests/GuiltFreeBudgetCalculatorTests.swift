import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

// MARK: - calculate: negative input clamping

@Test("clamps negative income to zero and reports income missing")
func calculatorClampsNegativeIncome() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: -5_000_000,
        monthlySavingsTarget: 1_000_000,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: []
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.monthlyIncome == 0)
    #expect(budget.health == .incomeMissing)
    #expect(budget.freeMoneyRatio == 0)
    #expect(budget.fixedCostsRatio == 0)
    #expect(budget.savingsRatio == 0)
}

@Test("clamps negative fixed cost amounts to zero in total")
func calculatorClampsNegativeFixedCost() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: 0,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Hợp lệ", amount: 2_000_000, kind: .housing),
            GuiltFreeFixedCost(name: "Âm", amount: -3_000_000, kind: .other),
        ]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.totalFixedCosts == 2_000_000)
    #expect(budget.freeMoney == 8_000_000)
}

@Test("clamps negative savings target and emergency contribution to zero")
func calculatorClampsNegativeSavingsAndEmergency() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: -2_000_000,
        emergencyFundMonthlyContribution: -1_000_000,
        fixedCosts: []
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.totalSavings == 0)
    #expect(budget.totalEmergency == 0)
    #expect(budget.freeMoney == 10_000_000)
}

// MARK: - calculate: ratios

@Test("computes free, fixed, and savings ratios relative to income")
func calculatorComputesRatios() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 20_000_000,
        monthlySavingsTarget: 3_000_000,
        emergencyFundMonthlyContribution: 1_000_000,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Nhà", amount: 6_000_000, kind: .housing),
        ]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    // free = 20M - (6M fixed + 3M savings + 1M emergency) = 10M
    #expect(budget.freeMoney == 10_000_000)
    #expect(abs(budget.freeMoneyRatio - 0.5) < 0.0001)
    #expect(abs(budget.fixedCostsRatio - 0.3) < 0.0001)
    // savingsRatio includes savings + emergency = 4M / 20M
    #expect(abs(budget.savingsRatio - 0.2) < 0.0001)
}

@Test("ratios are zero when income is zero")
func calculatorRatiosZeroWhenNoIncome() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 0,
        monthlySavingsTarget: 1_000_000,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [GuiltFreeFixedCost(name: "x", amount: 500_000, kind: .other)]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.freeMoneyRatio == 0)
    #expect(budget.fixedCostsRatio == 0)
    #expect(budget.savingsRatio == 0)
    #expect(budget.health == .incomeMissing)
}

// MARK: - calculate: health boundaries

@Test("free money exactly at 10 percent of income is healthy")
func calculatorTenPercentIsHealthy() {
    // free money == 10% of income should be healthy (boundary is < 0.1 => tight)
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: 0,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 9_000_000, kind: .other)]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.freeMoney == 1_000_000)
    #expect(budget.health == .healthy)
}

@Test("free money of exactly zero with positive income is tight")
func calculatorZeroFreeMoneyIsTight() {
    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        monthlySavingsTarget: 0,
        emergencyFundMonthlyContribution: 0,
        fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 10_000_000, kind: .other)]
    )

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.freeMoney == 0)
    #expect(budget.freeMoneyRatio == 0)
    #expect(budget.health == .tight)
}

@Test("calculate with no allocations leaves all income free")
func calculatorNoAllocations() {
    let config = GuiltFreeBudgetConfiguration(monthlyIncome: 15_000_000)

    let budget = GuiltFreeBudgetCalculator.calculate(config)

    #expect(budget.totalFixedCosts == 0)
    #expect(budget.totalSavings == 0)
    #expect(budget.totalEmergency == 0)
    #expect(budget.freeMoney == 15_000_000)
    #expect(abs(budget.freeMoneyRatio - 1.0) < 0.0001)
    #expect(budget.health == .healthy)
}

// MARK: - dailyAllowance

@Test("daily allowance is zero when free money is zero or negative")
func dailyAllowanceZeroWhenNoFreeMoney() throws {
    let budget = GuiltFreeBudgetCalculator.calculate(
        GuiltFreeBudgetConfiguration(
            monthlyIncome: 10_000_000,
            fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 12_000_000, kind: .other)]
        )
    )
    let reference = try calcDate(2026, 4, 10)

    let perDay = GuiltFreeBudgetCalculator.dailyAllowance(
        from: budget,
        referenceDate: reference,
        calendar: calcCalendar()
    )

    #expect(budget.freeMoney < 0)
    #expect(perDay == 0)
}

@Test("daily allowance on last day of month returns full free money")
func dailyAllowanceLastDay() throws {
    let budget = GuiltFreeBudgetCalculator.calculate(
        GuiltFreeBudgetConfiguration(
            monthlyIncome: 10_000_000,
            fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 4_000_000, kind: .other)]
        )
    )
    // April has 30 days; day 30 => remaining = 30 - 30 + 1 = 1
    let reference = try calcDate(2026, 4, 30)

    let perDay = GuiltFreeBudgetCalculator.dailyAllowance(
        from: budget,
        referenceDate: reference,
        calendar: calcCalendar()
    )

    #expect(perDay == 6_000_000)
}

@Test("daily allowance on first day divides by full month length")
func dailyAllowanceFirstDay() throws {
    let budget = GuiltFreeBudgetCalculator.calculate(
        GuiltFreeBudgetConfiguration(
            monthlyIncome: 10_000_000,
            fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 4_700_000, kind: .other)]
        )
    )
    // January has 31 days; day 1 => remaining = 31
    let reference = try calcDate(2026, 1, 1)

    let perDay = GuiltFreeBudgetCalculator.dailyAllowance(
        from: budget,
        referenceDate: reference,
        calendar: calcCalendar()
    )

    #expect(perDay == Decimal(5_300_000) / Decimal(31))
}

@Test("daily allowance accounts for leap February length")
func dailyAllowanceLeapFebruary() throws {
    let budget = GuiltFreeBudgetCalculator.calculate(
        GuiltFreeBudgetConfiguration(
            monthlyIncome: 10_000_000,
            fixedCosts: [GuiltFreeFixedCost(name: "Cố định", amount: 1_000_000, kind: .other)]
        )
    )
    // 2024 is a leap year => February has 29 days; day 1 => remaining = 29
    let reference = try calcDate(2024, 2, 1)

    let perDay = GuiltFreeBudgetCalculator.dailyAllowance(
        from: budget,
        referenceDate: reference,
        calendar: calcCalendar()
    )

    #expect(perDay == Decimal(9_000_000) / Decimal(29))
}

// MARK: - Helpers

private func calcCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func calcDate(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: calcCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
