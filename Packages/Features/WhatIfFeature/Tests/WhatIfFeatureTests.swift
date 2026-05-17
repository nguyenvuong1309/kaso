import ComposableArchitecture
import Foundation
import Testing
import WhatIfDomain
@testable import WhatIfFeature

@MainActor
@Test("loads baseline on task and primes scenario")
func loadsBaselineOnTask() async {
    let baseline = WhatIfBaseline(monthlyIncome: 20_000_000, monthlyExpenses: 13_000_000)
    let store = TestStore(initialState: WhatIfFeature.State()) {
        WhatIfFeature()
    } withDependencies: {
        $0.whatIfBaselineClient.load = { baseline }
    }

    await store.send(.task) {
        $0.isLoadingBaseline = true
    }
    await store.receive(.baselineLoaded(baseline)) {
        $0.isLoadingBaseline = false
        $0.hasLoadedBaseline = true
        $0.baseline = baseline
        $0.scenario.monthlyIncome = baseline.monthlyIncome
        $0.scenario.monthlyExpenses = baseline.monthlyExpenses
    }
}

@MainActor
@Test("income delta recomputes projection through state")
func incomeDeltaRecomputes() async {
    let store = TestStore(
        initialState: WhatIfFeature.State(
            scenario: WhatIfScenario(monthlyIncome: 10_000_000, monthlyExpenses: 6_000_000, horizonMonths: 12)
        )
    ) {
        WhatIfFeature()
    }

    await store.send(.incomeDeltaChanged(5_000_000)) {
        $0.scenario.incomeDelta = 5_000_000
    }
    #expect(store.state.projection.monthlyNetSavings == 9_000_000)
}

@MainActor
@Test("goal text parses into scenario goal amount")
func goalTextParses() async {
    let store = TestStore(
        initialState: WhatIfFeature.State(
            scenario: WhatIfScenario(monthlyIncome: 10_000_000, monthlyExpenses: 6_000_000, horizonMonths: 12)
        )
    ) {
        WhatIfFeature()
    }

    await store.send(.goalTextChanged("20.000.000")) {
        $0.goalText = "20.000.000"
        $0.scenario.goalAmount = 20_000_000
    }
    #expect(store.state.projection.monthsToGoal == 5)
}

@MainActor
@Test("reset restores scenario to baseline keeping horizon and rate")
func resetRestoresBaseline() async {
    let store = TestStore(
        initialState: WhatIfFeature.State(
            baseline: WhatIfBaseline(monthlyIncome: 20_000_000, monthlyExpenses: 13_000_000),
            scenario: WhatIfScenario(
                monthlyIncome: 5_000_000,
                monthlyExpenses: 2_000_000,
                incomeDelta: 1_000_000,
                expenseDelta: -500_000,
                additionalSavings: 1_000_000,
                horizonMonths: 24,
                annualInvestmentReturnRate: 0.08,
                goalAmount: 50_000_000
            )
        )
    ) {
        WhatIfFeature()
    }

    await store.send(.resetTapped) {
        $0.scenario = WhatIfScenario(
            monthlyIncome: 20_000_000,
            monthlyExpenses: 13_000_000,
            horizonMonths: 24,
            annualInvestmentReturnRate: 0.08,
            goalAmount: 50_000_000
        )
    }
}
