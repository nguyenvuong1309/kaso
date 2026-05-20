import ComposableArchitecture
import Foundation
import FutureSelfDomain
import Testing
@testable import FutureSelfFeature

@MainActor
struct FutureSelfFeatureTests {
    @Test("task builds letter from context client")
    func taskBuildsLetter() async {
        let now = Date()
        var txns = (0 ..< 6).map {
            FutureSelfTransactionInput(
                amount: 5_000_000,
                isExpense: false,
                occurredAt: now.addingTimeInterval(-Double($0) * 86_400)
            )
        }
        txns += (0 ..< 10).map {
            FutureSelfTransactionInput(
                amount: 200_000,
                isExpense: true,
                occurredAt: now.addingTimeInterval(-Double($0) * 86_400)
            )
        }
        let context = FutureSelfContext(transactions: txns, currentAge: 30)
        let expected = FutureSelfLetterBuilder.build(context: context)

        let store = TestStore(initialState: FutureSelfFeature.State()) {
            FutureSelfFeature()
        } withDependencies: {
            $0.futureSelfContextClient = FutureSelfContextClient(loadContext: { context })
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(.letterLoaded(expected)) {
            $0.isLoading = false
            $0.letter = expected
        }
    }

    @Test("loadFailed surfaces error key")
    func loadFailed() async {
        let store = TestStore(initialState: FutureSelfFeature.State(isLoading: true)) {
            FutureSelfFeature()
        } withDependencies: {
            $0.futureSelfContextClient = .empty
        }

        await store.send(.loadFailed("futureSelf.error.loadFailed")) {
            $0.isLoading = false
            $0.errorMessageKey = "futureSelf.error.loadFailed"
        }
    }
}
