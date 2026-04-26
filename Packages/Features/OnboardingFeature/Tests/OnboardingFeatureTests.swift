import ComposableArchitecture
import Foundation
import OnboardingDomain
import Testing
import TransactionDomain
@testable import OnboardingFeature

@MainActor
@Test("loads saved onboarding profile on task")
func loadsSavedOnboardingProfileOnTask() async throws {
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
        financialGoal: .trackCashflow,
        completedAt: date
    )
    let store = TestStore(initialState: OnboardingFeature.State()) {
        OnboardingFeature()
    } withDependencies: {
        $0.onboardingProfileRepository.load = { profile }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.profileLoaded(profile)) {
        $0.isLoading = false
        $0.profile = profile
    }
}

@MainActor
@Test("validates monthly income before moving forward")
func validatesMonthlyIncomeBeforeMovingForward() async {
    let store = TestStore(initialState: OnboardingFeature.State()) {
        OnboardingFeature()
    }

    await store.send(.nextButtonTapped) {
        $0.formErrorMessageKey = "onboarding.error.invalidIncome"
    }
    await store.send(.monthlyIncomeTextChanged("20000000")) {
        $0.monthlyIncomeText = "20.000.000"
        $0.formErrorMessageKey = nil
    }
    await store.send(.nextButtonTapped) {
        $0.step = .categories
    }
}

@MainActor
@Test("requires a primary category")
func requiresAPrimaryCategory() async {
    let store = TestStore(
        initialState: OnboardingFeature.State(
            step: .categories,
            monthlyIncomeText: "20.000.000",
            selectedCategoryIDs: []
        )
    ) {
        OnboardingFeature()
    }

    await store.send(.nextButtonTapped) {
        $0.formErrorMessageKey = "onboarding.error.categoriesRequired"
    }
}

@MainActor
@Test("saves completed onboarding profile")
func savesCompletedOnboardingProfile() async throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let expectedProfile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport],
        financialGoal: .buildEmergencyFund,
        completedAt: date
    )
    let store = TestStore(
        initialState: OnboardingFeature.State(
            step: .review,
            monthlyIncomeText: "20.000.000",
            selectedCategoryIDs: ["food", "transport"],
            selectedGoal: .buildEmergencyFund,
            suggestedBudgets: IdentifiedArray(
                uniqueElements: expectedProfile.suggestedBudgets
            )
        )
    ) {
        OnboardingFeature()
    } withDependencies: {
        $0.date.now = date
        $0.onboardingProfileRepository.save = { _ in }
    }

    await store.send(.completeButtonTapped) {
        $0.monthlySavingsTarget = 6_000_000
        $0.isSaving = true
    }
    await store.receive(.profileSaved(expectedProfile)) {
        $0.isSaving = false
        $0.profile = expectedProfile
    }
}
