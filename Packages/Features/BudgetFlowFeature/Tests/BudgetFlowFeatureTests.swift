import BudgetFlowDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import BudgetFlowFeature

@MainActor
struct BudgetFlowFeatureTests {
    @Test("task loads flow from provider")
    func taskLoadsFlow() async {
        let expected = BudgetFlowSampleData.householdMonth
        let store = TestStore(initialState: BudgetFlowFeature.State()) {
            BudgetFlowFeature()
        } withDependencies: {
            $0.budgetFlowProvider = BudgetFlowProvider { expected }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }

        await store.receive(\.flowLoaded) {
            $0.isLoading = false
            $0.flow = expected
        }
    }

    @Test("task surfaces error on failure")
    func taskFailure() async {
        struct LoadError: Error {}
        let store = TestStore(initialState: BudgetFlowFeature.State()) {
            BudgetFlowFeature()
        } withDependencies: {
            $0.budgetFlowProvider = BudgetFlowProvider { throw LoadError() }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }

        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessageKey = "budgetFlow.error.loadFailed"
        }
    }

    @Test("display mode toggles between amount and percent")
    func displayModeToggle() async {
        let store = TestStore(initialState: BudgetFlowFeature.State()) {
            BudgetFlowFeature()
        }

        await store.send(.displayModeToggled) {
            $0.displayMode = .percent
        }
        await store.send(.displayModeToggled) {
            $0.displayMode = .amount
        }
    }

    @Test("display mode selection sets exact mode")
    func displayModeSelected() async {
        let store = TestStore(initialState: BudgetFlowFeature.State()) {
            BudgetFlowFeature()
        }

        await store.send(.displayModeSelected(.percent)) {
            $0.displayMode = .percent
        }
    }

    @Test("tapping a node selects it; tapping again clears")
    func nodeSelectionToggles() async {
        let store = TestStore(
            initialState: BudgetFlowFeature.State(flow: BudgetFlowSampleData.householdMonth)
        ) {
            BudgetFlowFeature()
        }

        await store.send(.nodeTapped("housing")) {
            $0.selectedNodeID = "housing"
        }
        await store.send(.nodeTapped("housing")) {
            $0.selectedNodeID = nil
        }
    }

    @Test("tapping a different node replaces the selection")
    func nodeSelectionReplaces() async {
        let store = TestStore(
            initialState: BudgetFlowFeature.State(
                flow: BudgetFlowSampleData.householdMonth,
                selectedNodeID: "housing"
            )
        ) {
            BudgetFlowFeature()
        }

        await store.send(.nodeTapped("savings")) {
            $0.selectedNodeID = "savings"
        }
    }

    @Test("selectionCleared resets selectedNodeID")
    func selectionCleared() async {
        let store = TestStore(
            initialState: BudgetFlowFeature.State(selectedNodeID: "housing")
        ) {
            BudgetFlowFeature()
        }

        await store.send(.selectionCleared) {
            $0.selectedNodeID = nil
        }
    }

    @Test("flowLoaded drops a now-missing selection")
    func flowLoadedDropsMissingSelection() async {
        let initial = BudgetFlowFeature.State(
            flow: BudgetFlowSampleData.householdMonth,
            selectedNodeID: "housing"
        )
        let replacement = BudgetFlowCalculator.makeFlow(
            total: 100,
            items: [(id: "savings", labelKey: "x", amount: 100, colorName: "mint", symbolName: "leaf")]
        )

        let store = TestStore(initialState: initial) {
            BudgetFlowFeature()
        }

        await store.send(.flowLoaded(replacement)) {
            $0.flow = replacement
            $0.selectedNodeID = nil
        }
    }
}
