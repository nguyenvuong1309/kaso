import Foundation
import Testing
@testable import GoalDomain

@Test("returns nil for non-positive monthly expense")
func emergencyNilForNonPositiveExpense() {
    #expect(EmergencyFundPlanner.recommendation(monthlyExpense: 0) == nil)
    #expect(EmergencyFundPlanner.recommendation(monthlyExpense: -100) == nil)
}

@Test("returns nil for non-positive target month count")
func emergencyNilForNonPositiveTargetMonths() {
    #expect(
        EmergencyFundPlanner.recommendation(monthlyExpense: 10_000_000, targetMonthCount: 0) == nil
    )
}

@Test("returns nil for non-positive build month count")
func emergencyNilForNonPositiveBuildMonths() {
    #expect(
        EmergencyFundPlanner.recommendation(monthlyExpense: 10_000_000, buildMonthCount: 0) == nil
    )
}

@Test("uses defaults of six target months and twelve build months")
func emergencyUsesDefaults() throws {
    let recommendation = try #require(
        EmergencyFundPlanner.recommendation(monthlyExpense: 10_000_000)
    )

    #expect(recommendation.targetMonthCount == 6)
    #expect(recommendation.recommendedAmount == 60_000_000)
    #expect(recommendation.currentAmount == 0)
    #expect(recommendation.remainingAmount == 60_000_000)
    #expect(recommendation.coverageMonthCount == 0)
    #expect(recommendation.monthlyTopUpAmount == 5_000_000)
}

@Test("clamps negative current amount to zero")
func emergencyClampsNegativeCurrent() throws {
    let recommendation = try #require(
        EmergencyFundPlanner.recommendation(
            monthlyExpense: 10_000_000,
            currentAmount: -5_000_000
        )
    )

    #expect(recommendation.currentAmount == 0)
    #expect(recommendation.remainingAmount == 60_000_000)
    #expect(recommendation.coverageMonthCount == 0)
}

@Test("caps coverage month count at target month count when overfunded")
func emergencyCapsCoverage() throws {
    let recommendation = try #require(
        EmergencyFundPlanner.recommendation(
            monthlyExpense: 10_000_000,
            currentAmount: 100_000_000,
            targetMonthCount: 6
        )
    )

    #expect(recommendation.coverageMonthCount == 6)
    #expect(recommendation.remainingAmount == 0)
    #expect(recommendation.monthlyTopUpAmount == 0)
}

@Test("computes coverage and remaining for partially funded reserve")
func emergencyPartiallyFunded() throws {
    let recommendation = try #require(
        EmergencyFundPlanner.recommendation(
            monthlyExpense: 8_000_000,
            currentAmount: 16_000_000,
            targetMonthCount: 6,
            buildMonthCount: 8
        )
    )

    #expect(recommendation.recommendedAmount == 48_000_000)
    #expect(recommendation.currentAmount == 16_000_000)
    #expect(recommendation.remainingAmount == 32_000_000)
    #expect(recommendation.coverageMonthCount == 2)
    #expect(recommendation.monthlyTopUpAmount == 4_000_000)
}

@Test("recommendation value type is Equatable")
func emergencyRecommendationEquatable() throws {
    let first = try #require(EmergencyFundPlanner.recommendation(monthlyExpense: 5_000_000))
    let second = try #require(EmergencyFundPlanner.recommendation(monthlyExpense: 5_000_000))

    #expect(first == second)
}
