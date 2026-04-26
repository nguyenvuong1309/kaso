import Foundation
import Testing
import TransactionDomain
@testable import OnboardingDomain

@Test("creates onboarding profile with weighted budget suggestions")
func createsOnboardingProfileWithWeightedBudgetSuggestions() throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport],
        financialGoal: .buildEmergencyFund,
        completedAt: date
    )

    #expect(profile.monthlyIncome == 20_000_000)
    #expect(profile.primaryCategories == [.food, .transport])
    #expect(profile.financialGoal == .buildEmergencyFund)
    #expect(profile.monthlySavingsTarget == 6_000_000)
    #expect(
        profile.suggestedBudgets == [
            BudgetSuggestion(category: .food, monthlyLimit: 8_750_000),
            BudgetSuggestion(category: .transport, monthlyLimit: 5_250_000),
        ]
    )
}

@Test("rejects non-positive monthly income")
func rejectsNonPositiveMonthlyIncome() {
    #expect(throws: OnboardingValidationError.monthlyIncomeMustBePositive) {
        try OnboardingPlanner.makeProfile(
            monthlyIncome: 0,
            primaryCategories: [.food],
            financialGoal: .trackCashflow,
            completedAt: Date(timeIntervalSinceReferenceDate: 0)
        )
    }
}

@Test("requires at least one primary category")
func requiresAtLeastOnePrimaryCategory() {
    #expect(throws: OnboardingValidationError.primaryCategoriesRequired) {
        try OnboardingPlanner.makeProfile(
            monthlyIncome: 20_000_000,
            primaryCategories: [],
            financialGoal: .trackCashflow,
            completedAt: Date(timeIntervalSinceReferenceDate: 0)
        )
    }
}
