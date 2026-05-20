import ComposableArchitecture
import Foundation
import MoneyPersonalityDomain
import Testing
@testable import MoneyPersonalityFeature

@MainActor
struct MoneyPersonalityFeatureTests {
    @Test("task loads profile from context client")
    func taskLoadsProfile() async {
        let context = MoneyPersonalityContext(
            transactions: [],
            budgetUtilizationRatio: 0.5,
            savingsRate: 0.1
        )

        let store = TestStore(initialState: MoneyPersonalityFeature.State()) {
            MoneyPersonalityFeature()
        } withDependencies: {
            $0.moneyPersonalityContextClient = MoneyPersonalityContextClient(load: { context })
            $0.date.now = Date()
        }

        await store.send(.task) {
            $0.isAnalyzing = true
        }
        await store.receive(\.profileLoaded) {
            $0.isAnalyzing = false
            $0.profile = .insufficientPlaceholder
        }
    }

    @Test("shareButtonTapped opens share sheet")
    func shareSheet() async {
        let store = TestStore(initialState: MoneyPersonalityFeature.State()) {
            MoneyPersonalityFeature()
        } withDependencies: {
            $0.moneyPersonalityContextClient = .empty
            $0.date.now = Date()
        }

        await store.send(.shareButtonTapped) {
            $0.isShareSheetPresented = true
        }
        await store.send(.shareSheetDismissed) {
            $0.isShareSheetPresented = false
        }
    }
}
