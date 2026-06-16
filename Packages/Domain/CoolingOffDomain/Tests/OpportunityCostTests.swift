import Foundation
import Testing
@testable import CoolingOffDomain

@Test("opportunity cost preserves the amount")
func opportunityCostPreservesAmount() {
    let cost = OpportunityCostCalculator.calculate(amount: 3_000_000, inputs: .empty)
    #expect(cost.amount == 3_000_000)
}

@Test("opportunity cost yields nil hours when income is zero")
func opportunityCostNilHoursWhenNoIncome() {
    let inputs = OpportunityCostInputs(monthlyIncome: 0, monthlyExpenses: 5_000_000)
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.hoursOfWork == nil)
}

@Test("opportunity cost yields nil hours when averageHoursPerMonth is zero")
func opportunityCostNilHoursWhenNoHours() {
    let inputs = OpportunityCostInputs(monthlyIncome: 20_000_000)
    let cost = OpportunityCostCalculator.calculate(
        amount: 1_000_000,
        inputs: inputs,
        averageHoursPerMonth: 0
    )
    #expect(cost.hoursOfWork == nil)
}

@Test("opportunity cost honors custom averageHoursPerMonth")
func opportunityCostCustomHours() {
    let inputs = OpportunityCostInputs(monthlyIncome: 10_000_000)
    let cost = OpportunityCostCalculator.calculate(
        amount: 1_000_000,
        inputs: inputs,
        averageHoursPerMonth: 200
    )
    let hours = try? #require(cost.hoursOfWork)
    #expect(hours.map { abs($0 - 20.0) < 0.0001 } ?? false)
}

@Test("opportunity cost yields nil emergency coverage when expenses are zero")
func opportunityCostNilEmergencyWhenNoExpenses() {
    let inputs = OpportunityCostInputs(monthlyExpenses: 0)
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.emergencyMonthsCoverage == nil)
}

@Test("opportunity cost computes emergency months coverage")
func opportunityCostEmergencyCoverage() {
    let inputs = OpportunityCostInputs(monthlyExpenses: 4_000_000)
    let cost = OpportunityCostCalculator.calculate(amount: 8_000_000, inputs: inputs)
    let coverage = try? #require(cost.emergencyMonthsCoverage)
    #expect(coverage.map { abs($0 - 2.0) < 0.0001 } ?? false)
}

@Test("opportunity cost goal delay is nil when remaining is missing")
func opportunityCostGoalDelayNilNoRemaining() {
    let inputs = OpportunityCostInputs(savingGoalDailyContribution: 100_000)
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == nil)
}

@Test("opportunity cost goal delay is nil when daily contribution is missing")
func opportunityCostGoalDelayNilNoDaily() {
    let inputs = OpportunityCostInputs(savingGoalRemaining: 1_000_000)
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == nil)
}

@Test("opportunity cost goal delay is nil when remaining is zero")
func opportunityCostGoalDelayNilZeroRemaining() {
    let inputs = OpportunityCostInputs(
        savingGoalRemaining: 0,
        savingGoalDailyContribution: 100_000
    )
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == nil)
}

@Test("opportunity cost goal delay is nil when daily contribution is zero")
func opportunityCostGoalDelayNilZeroDaily() {
    let inputs = OpportunityCostInputs(
        savingGoalRemaining: 1_000_000,
        savingGoalDailyContribution: 0
    )
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == nil)
}

@Test("opportunity cost goal delay rounds up to whole days")
func opportunityCostGoalDelayRoundsUp() {
    let inputs = OpportunityCostInputs(
        savingGoalRemaining: 5_000_000,
        savingGoalDailyContribution: 100_000
    )
    // 1_050_000 / 100_000 = 10.5 -> rounds up to 11
    let cost = OpportunityCostCalculator.calculate(amount: 1_050_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == 11)
}

@Test("opportunity cost goal delay is exact when evenly divisible")
func opportunityCostGoalDelayExact() {
    let inputs = OpportunityCostInputs(
        savingGoalRemaining: 5_000_000,
        savingGoalDailyContribution: 250_000
    )
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: inputs)
    #expect(cost.savingGoalDelayDays == 4)
}

@Test("opportunity cost on empty inputs leaves all derived values nil")
func opportunityCostEmptyInputs() {
    let cost = OpportunityCostCalculator.calculate(amount: 1_000_000, inputs: .empty)
    #expect(cost.hoursOfWork == nil)
    #expect(cost.savingGoalDelayDays == nil)
    #expect(cost.emergencyMonthsCoverage == nil)
    #expect(cost.amount == 1_000_000)
}

@Test("opportunity cost on zero amount produces zero derived values")
func opportunityCostZeroAmount() {
    let inputs = OpportunityCostInputs(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 5_000_000
    )
    let cost = OpportunityCostCalculator.calculate(amount: 0, inputs: inputs)
    #expect(cost.hoursOfWork == 0)
    #expect(cost.emergencyMonthsCoverage == 0)
}

@Test("opportunity cost inputs empty has zero defaults")
func opportunityCostInputsEmpty() {
    let inputs = OpportunityCostInputs.empty
    #expect(inputs.monthlyIncome == 0)
    #expect(inputs.monthlyExpenses == 0)
    #expect(inputs.emergencyFundTarget == 0)
    #expect(inputs.savingGoalRemaining == nil)
    #expect(inputs.savingGoalDailyContribution == nil)
}

@Test("opportunity cost inputs round-trip through Codable")
func opportunityCostInputsCodableRoundTrip() throws {
    let inputs = OpportunityCostInputs(
        monthlyIncome: 20_000_000,
        monthlyExpenses: 12_000_000,
        emergencyFundTarget: 60_000_000,
        savingGoalRemaining: 5_000_000,
        savingGoalDailyContribution: 100_000
    )
    let data = try JSONEncoder().encode(inputs)
    let decoded = try JSONDecoder().decode(OpportunityCostInputs.self, from: data)
    #expect(decoded == inputs)
}

@Test("opportunity cost value type supports equality")
func opportunityCostEquality() {
    let a = OpportunityCost(amount: 100, hoursOfWork: 1, savingGoalDelayDays: 2, emergencyMonthsCoverage: 0.5)
    let b = OpportunityCost(amount: 100, hoursOfWork: 1, savingGoalDelayDays: 2, emergencyMonthsCoverage: 0.5)
    let c = OpportunityCost(amount: 100, hoursOfWork: 2, savingGoalDelayDays: 2, emergencyMonthsCoverage: 0.5)
    #expect(a == b)
    #expect(a != c)
}
