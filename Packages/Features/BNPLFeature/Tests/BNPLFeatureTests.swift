import BNPLDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import BNPLFeature

@MainActor
struct BNPLFeatureTests {
    @Test("task loads obligations and computes summary")
    func taskLoadsObligations() async {
        let obligation = BNPLObligation(
            provider: .atome,
            purchaseName: "iPhone",
            totalAmount: 3_000_000,
            purchaseDate: Date(),
            installmentCount: 3,
            installments: BNPLInstallmentBuilder.generateMonthly(
                totalAmount: 3_000_000,
                installmentCount: 3,
                startDate: Date()
            )
        )

        let store = TestStore(initialState: BNPLFeature.State()) {
            BNPLFeature()
        } withDependencies: {
            $0.bnplRepository = BNPLRepository(
                fetchAll: { [obligation] },
                save: { _ in },
                delete: { _ in }
            )
            $0.bnplContextClient = BNPLContextClient(monthlyIncome: { 20_000_000 })
            $0.date.now = Date()
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(\.dataLoaded) {
            $0.isLoading = false
            $0.obligations = IdentifiedArray(uniqueElements: [obligation])
            $0.monthlyIncome = 20_000_000
            $0.summary = BNPLSummaryBuilder.build(
                obligations: [obligation],
                monthlyIncome: 20_000_000,
                referenceDate: $0.summary.nextInstallmentDate ?? Date()
            )
        }
    }

    @Test("editorDismissed closes editor")
    func editorDismissedClosesEditor() async {
        let store = TestStore(initialState: BNPLFeature.State(isEditorPresented: true)) {
            BNPLFeature()
        } withDependencies: {
            $0.bnplRepository = .empty
            $0.bnplContextClient = .empty
            $0.date.now = Date()
        }

        await store.send(.editorDismissed) {
            $0.isEditorPresented = false
        }
    }
}
