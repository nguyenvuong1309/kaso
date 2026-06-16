import Foundation
import Testing
@testable import WhatIfDomain

// MARK: - WhatIfScenario

@Test("scenario default initializer applies documented defaults")
func scenarioDefaults() {
    let scenario = WhatIfScenario()

    #expect(scenario.monthlyIncome == 0)
    #expect(scenario.monthlyExpenses == 0)
    #expect(scenario.incomeDelta == 0)
    #expect(scenario.expenseDelta == 0)
    #expect(scenario.additionalSavings == 0)
    #expect(scenario.horizonMonths == 12)
    #expect(scenario.annualInvestmentReturnRate == 0.05)
    #expect(scenario.goalAmount == nil)
}

@Test("scenario custom initializer stores all provided values")
func scenarioCustomInit() {
    let scenario = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 6_000_000,
        incomeDelta: 1_000_000,
        expenseDelta: -500_000,
        additionalSavings: 250_000,
        horizonMonths: 36,
        annualInvestmentReturnRate: 0.08,
        goalAmount: 100_000_000
    )

    #expect(scenario.monthlyIncome == 10_000_000)
    #expect(scenario.monthlyExpenses == 6_000_000)
    #expect(scenario.incomeDelta == 1_000_000)
    #expect(scenario.expenseDelta == -500_000)
    #expect(scenario.additionalSavings == 250_000)
    #expect(scenario.horizonMonths == 36)
    #expect(scenario.annualInvestmentReturnRate == 0.08)
    #expect(scenario.goalAmount == 100_000_000)
}

@Test("scenario is Equatable across identical values")
func scenarioEquatable() {
    let a = WhatIfScenario(
        monthlyIncome: 5_000_000,
        monthlyExpenses: 3_000_000,
        goalAmount: 50_000_000
    )
    let b = WhatIfScenario(
        monthlyIncome: 5_000_000,
        monthlyExpenses: 3_000_000,
        goalAmount: 50_000_000
    )

    #expect(a == b)
}

@Test("scenario inequality when any field differs")
func scenarioInequality() {
    let base = WhatIfScenario(monthlyIncome: 5_000_000)
    var changed = base
    changed.incomeDelta = 1

    #expect(base != changed)
}

@Test("scenario mutation of value type does not affect copies")
func scenarioValueSemantics() {
    let original = WhatIfScenario(monthlyIncome: 1_000_000, horizonMonths: 12)
    var mutated = original
    mutated.monthlyIncome = 9_999_999
    mutated.horizonMonths = 99

    #expect(original.monthlyIncome == 1_000_000)
    #expect(original.horizonMonths == 12)
    #expect(mutated.monthlyIncome == 9_999_999)
    #expect(mutated.horizonMonths == 99)
}

// MARK: - WhatIfProjection

@Test("projection custom initializer stores all provided values")
func projectionCustomInit() {
    let projection = WhatIfProjection(
        effectiveMonthlyIncome: 10_000_000,
        effectiveMonthlyExpenses: 6_000_000,
        monthlyNetSavings: 4_000_000,
        savingsRate: 0.4,
        endingBalance: 48_000_000,
        totalSaved: 48_000_000,
        totalInterestEarned: 1_234,
        monthsToGoal: 7,
        monthlyBalances: [4_000_000, 8_000_000]
    )

    #expect(projection.effectiveMonthlyIncome == 10_000_000)
    #expect(projection.effectiveMonthlyExpenses == 6_000_000)
    #expect(projection.monthlyNetSavings == 4_000_000)
    #expect(projection.savingsRate == 0.4)
    #expect(projection.endingBalance == 48_000_000)
    #expect(projection.totalSaved == 48_000_000)
    #expect(projection.totalInterestEarned == 1_234)
    #expect(projection.monthsToGoal == 7)
    #expect(projection.monthlyBalances == [4_000_000, 8_000_000])
}

@Test("projection empty is fully zeroed with nil goal and no balances")
func projectionEmpty() {
    let empty = WhatIfProjection.empty

    #expect(empty.effectiveMonthlyIncome == 0)
    #expect(empty.effectiveMonthlyExpenses == 0)
    #expect(empty.monthlyNetSavings == 0)
    #expect(empty.savingsRate == 0)
    #expect(empty.endingBalance == 0)
    #expect(empty.totalSaved == 0)
    #expect(empty.totalInterestEarned == 0)
    #expect(empty.monthsToGoal == nil)
    #expect(empty.monthlyBalances.isEmpty)
}

@Test("projection is Equatable across identical values")
func projectionEquatable() {
    #expect(WhatIfProjection.empty == WhatIfProjection.empty)

    let a = WhatIfProjection(
        effectiveMonthlyIncome: 1,
        effectiveMonthlyExpenses: 2,
        monthlyNetSavings: 3,
        savingsRate: 0.5,
        endingBalance: 4,
        totalSaved: 5,
        totalInterestEarned: 6,
        monthsToGoal: 8,
        monthlyBalances: [1, 2, 3]
    )
    var b = a
    #expect(a == b)
    b.monthsToGoal = 9
    #expect(a != b)
}
