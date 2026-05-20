import ComposableArchitecture
import Foundation
import SpendingDNADomain
import Testing
@testable import SpendingDNAFeature

@MainActor
struct SpendingDNAFeatureTests {
    @Test("task loads report from context client")
    func taskLoadsReport() async {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? Date()
        let inputs = (0 ..< 15).map { _ in
            SpendingDNATransactionInput(
                amount: 100_000,
                categoryID: "food",
                isExpense: true,
                occurredAt: date
            )
        }
        let expected = SpendingDNABuilder.build(transactions: inputs)

        let store = TestStore(initialState: SpendingDNAFeature.State()) {
            SpendingDNAFeature()
        } withDependencies: {
            $0.spendingDNAContextClient = SpendingDNAContextClient(loadTransactions: { inputs })
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(.reportLoaded(expected)) {
            $0.isLoading = false
            $0.report = expected
        }
    }

    @Test("shareButtonTapped presents share sheet")
    func sharePresented() async {
        let store = TestStore(initialState: SpendingDNAFeature.State()) {
            SpendingDNAFeature()
        } withDependencies: {
            $0.spendingDNAContextClient = .empty
        }

        await store.send(.shareButtonTapped) {
            $0.isShareSheetPresented = true
        }
        await store.send(.shareSheetDismissed) {
            $0.isShareSheetPresented = false
        }
    }

    @Test("loadFailed surfaces error key")
    func loadFailed() async {
        let store = TestStore(initialState: SpendingDNAFeature.State(isLoading: true)) {
            SpendingDNAFeature()
        } withDependencies: {
            $0.spendingDNAContextClient = .empty
        }

        await store.send(.loadFailed("dna.error.loadFailed")) {
            $0.isLoading = false
            $0.errorMessageKey = "dna.error.loadFailed"
        }
    }
}
