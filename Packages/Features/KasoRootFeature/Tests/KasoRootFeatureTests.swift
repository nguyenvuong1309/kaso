import Foundation
import Testing
import ComposableArchitecture
import BudgetDomain
import OnboardingDomain
import TransactionDomain
@testable import KasoRootFeature

@MainActor
@Test("passes onboarding budget suggestions to transaction feature")
func passesOnboardingBudgetSuggestionsToTransactionFeature() async throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let profile = OnboardingProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport],
        financialGoal: .buildEmergencyFund,
        monthlySavingsTarget: 6_000_000,
        suggestedBudgets: [
            BudgetSuggestion(category: .food, monthlyLimit: 4_000_000),
            BudgetSuggestion(category: .transport, monthlyLimit: 2_000_000),
        ],
        completedAt: date
    )
    let store = TestStore(initialState: KasoRootFeature.State()) {
        KasoRootFeature()
    } withDependencies: {
        $0.date.now = date
    }

    await store.send(.onboarding(.profileLoaded(profile))) {
        $0.onboarding.profile = profile
    }
    await store.receive(
        .transaction(
            .budgetsUpdated([
                Budget(category: .food, monthlyLimit: 4_000_000),
                Budget(category: .transport, monthlyLimit: 2_000_000),
            ])
        )
    ) {
        $0.transaction.budgets = [
            Budget(category: .food, monthlyLimit: 4_000_000),
            Budget(category: .transport, monthlyLimit: 2_000_000),
        ]
    }
}
