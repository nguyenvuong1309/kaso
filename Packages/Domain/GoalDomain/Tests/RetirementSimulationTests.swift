import Foundation
import Testing
@testable import GoalDomain

@Test("returns nil for non-positive monthly expense")
func retirementNilForNonPositiveExpense() {
    #expect(
        RetirementSimulator.simulate(monthlyIncome: 30_000_000, monthlyExpense: 0) == nil
    )
}

@Test("returns nil for non-positive target multiplier")
func retirementNilForNonPositiveMultiplier() {
    #expect(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 10_000_000,
            targetAnnualExpenseMultiplier: 0
        ) == nil
    )
}

@Test("reports ready with zero months when already at target")
func retirementReadyWhenFunded() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 3_000_000_000,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.status == .ready)
    #expect(simulation.projectedMonthCount == 0)
    #expect(simulation.targetAmount == 3_000_000_000)
}

@Test("computes monthly contribution as income minus expense")
func retirementContribution() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 25_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 0,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.monthlyContribution == 15_000_000)
}

@Test("clamps negative contribution to zero")
func retirementClampsNegativeContribution() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 5_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 0,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.monthlyContribution == 0)
}

@Test("clamps negative current savings to zero")
func retirementClampsNegativeSavings() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: -50_000_000,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.currentSavings == 0)
}

@Test("reports unreachable when no contribution and no return")
func retirementUnreachable() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 10_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 0,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.status == .unreachable)
    #expect(simulation.projectedMonthCount == nil)
    #expect(simulation.monthlyContribution == 0)
}

@Test("reports unreachable when target not met within projection horizon")
func retirementUnreachableBeyondHorizon() throws {
    // Tiny contribution against a huge target within a 1-year horizon.
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 10_000_001,
            monthlyExpense: 10_000_000,
            currentSavings: 0,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25,
            maximumProjectionYearCount: 1
        )
    )

    #expect(simulation.status == .unreachable)
    #expect(simulation.projectedMonthCount == nil)
}

@Test("reaches target through growth even without contribution")
func retirementReachableThroughGrowthOnly() throws {
    // No contribution but positive return rate lets savings compound toward target.
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 10_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 2_900_000_000,
            annualReturnRate: Decimal(string: "0.12") ?? 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.monthlyContribution == 0)
    #expect(simulation.status == .reachable)
    let months = try #require(simulation.projectedMonthCount)
    #expect(months >= 1)
}

@Test("matches deterministic month count for flat savings rate")
func retirementDeterministicMonthCount() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 100_000_000,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    // (3,000,000,000 - 100,000,000) / 20,000,000 = 145 months.
    #expect(simulation.projectedMonthCount == 145)
    #expect(simulation.status == .reachable)
}

@Test("preserves the supplied annual return rate and multiplier")
func retirementPreservesInputs() throws {
    let rate = Decimal(string: "0.05") ?? 0
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 12_000_000,
            currentSavings: 0,
            annualReturnRate: rate,
            targetAnnualExpenseMultiplier: 20
        )
    )

    #expect(simulation.annualReturnRate == rate)
    #expect(simulation.targetAnnualExpenseMultiplier == 20)
    #expect(simulation.targetAmount == 12_000_000 * 12 * 20)
}

@Test("simulation status encodes to its raw string value")
func retirementStatusRawValues() {
    #expect(RetirementSimulationStatus.ready.rawValue == "ready")
    #expect(RetirementSimulationStatus.reachable.rawValue == "reachable")
    #expect(RetirementSimulationStatus.unreachable.rawValue == "unreachable")
}
