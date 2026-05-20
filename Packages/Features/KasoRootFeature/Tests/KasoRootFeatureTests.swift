import Foundation
import Testing
import ComposableArchitecture
import BudgetDomain
import OnboardingDomain
import PaywallDomain
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

@MainActor
@Test("proGateRequested for free tier opens paywall with feature context")
func proGateRequestedForFreeTierOpensPaywall() async {
    let store = TestStore(initialState: KasoRootFeature.State()) {
        KasoRootFeature()
    } withDependencies: {
        $0.date.now = Date()
    }

    // currentEntitlement defaults to .free → aiInsights is gated.
    await store.send(.proGateRequested(.aiInsights)) {
        $0.paywallGateRequestedFeature = .aiInsights
        $0.isPaywallPresented = true
    }
}

@MainActor
@Test("proGateRequested for unlocked feature does nothing")
func proGateRequestedForUnlockedFeatureNoop() async {
    let proEntitlement = SubscriptionEntitlement(tier: .pro)
    let store = TestStore(
        initialState: KasoRootFeature.State(currentEntitlement: proEntitlement)
    ) {
        KasoRootFeature()
    } withDependencies: {
        $0.date.now = Date()
    }

    await store.send(.proGateRequested(.aiInsights))
    // Pro tier unlocks aiInsights → no state change, no paywall.
    #expect(store.state.isPaywallPresented == false)
    #expect(store.state.paywallGateRequestedFeature == nil)
}

@MainActor
@Test("paywallDismissed clears gate context")
func paywallDismissedClearsGateContext() async {
    var initialState = KasoRootFeature.State()
    initialState.paywallGateRequestedFeature = .aiInsights
    initialState.isPaywallPresented = true
    let store = TestStore(initialState: initialState) {
        KasoRootFeature()
    } withDependencies: {
        $0.date.now = Date()
    }

    await store.send(.paywallDismissed) {
        $0.isPaywallPresented = false
        $0.paywallGateRequestedFeature = nil
    }
}

@MainActor
@Test("gateDecision evaluates against current entitlement")
func gateDecisionEvaluatesAgainstCurrentEntitlement() {
    var state = KasoRootFeature.State()
    #expect(state.gateDecision(for: .aiInsights) == .gated(requiresTier: .pro))
    #expect(state.gateDecision(for: .csvExport) == .allowed)

    state.currentEntitlement = SubscriptionEntitlement(tier: .pro)
    #expect(state.gateDecision(for: .aiInsights) == .allowed)
    #expect(state.gateDecision(for: .familySharing) == .gated(requiresTier: .family))
}
