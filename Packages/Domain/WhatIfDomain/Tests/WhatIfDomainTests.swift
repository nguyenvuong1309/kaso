import Foundation
import Testing
@testable import WhatIfDomain

@Test("zero return rate computes simple sum of monthly savings")
func zeroReturnSimpleSum() {
    let scenario = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 6_000_000,
        horizonMonths: 12,
        annualInvestmentReturnRate: 0
    )

    let projection = WhatIfCalculator.project(scenario)

    #expect(projection.monthlyNetSavings == 4_000_000)
    #expect(projection.endingBalance == 48_000_000)
    #expect(projection.totalSaved == 48_000_000)
    #expect(projection.totalInterestEarned == 0)
}

@Test("income delta increases monthly net savings")
func incomeDeltaIncreasesSavings() {
    let baseline = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 6_000_000,
        horizonMonths: 6,
        annualInvestmentReturnRate: 0
    )
    var boosted = baseline
    boosted.incomeDelta = 5_000_000

    let baselineProjection = WhatIfCalculator.project(baseline)
    let boostedProjection = WhatIfCalculator.project(boosted)

    #expect(boostedProjection.monthlyNetSavings == baselineProjection.monthlyNetSavings + 5_000_000)
}

@Test("monthly balances grow with compounding when return rate positive")
func monthlyBalancesGrowWithCompounding() throws {
    let scenario = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 6_000_000,
        horizonMonths: 24,
        annualInvestmentReturnRate: 0.12
    )

    let projection = WhatIfCalculator.project(scenario)

    #expect(projection.monthlyBalances.count == 24)
    let zeroReturnEnd = projection.totalSaved
    #expect(projection.endingBalance > zeroReturnEnd)
}

@Test("monthsToGoal reports when goal reached within horizon")
func monthsToGoalWithinHorizon() throws {
    let scenario = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 6_000_000,
        horizonMonths: 24,
        annualInvestmentReturnRate: 0,
        goalAmount: 20_000_000
    )

    let projection = WhatIfCalculator.project(scenario)

    #expect(projection.monthsToGoal == 5)
}

@Test("breakdownToHitGoal extends beyond horizon when needed")
func breakdownToHitGoalExtends() throws {
    let scenario = WhatIfScenario(
        monthlyIncome: 10_000_000,
        monthlyExpenses: 8_000_000,
        horizonMonths: 12,
        annualInvestmentReturnRate: 0,
        goalAmount: 50_000_000
    )

    let months = WhatIfCalculator.breakdownToHitGoal(scenario)
    #expect(months == 25)
}

@Test("savings cap at zero when expenses exceed income")
func savingsCapAtZero() {
    let scenario = WhatIfScenario(
        monthlyIncome: 5_000_000,
        monthlyExpenses: 8_000_000,
        horizonMonths: 6
    )

    let projection = WhatIfCalculator.project(scenario)

    #expect(projection.monthlyNetSavings == 0)
    #expect(projection.endingBalance == 0)
}
