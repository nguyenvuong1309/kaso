import ComposableArchitecture
import Foundation
import Testing
import WrappedDomain
@testable import WrappedFeature

@MainActor
struct WrappedFeatureTests {
    @Test("task loads report from context client")
    func taskLoadsReport() async {
        let store = TestStore(initialState: WrappedFeature.State()) {
            WrappedFeature()
        } withDependencies: {
            $0.wrappedContextClient = WrappedContextClient(loadTransactions: { [] })
            $0.date.now = Date()
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(\.reportLoaded) { state in
            state.isLoading = false
            state.report = WrappedBuilder.build(transactions: [], scope: .month)
        }
    }

    @Test("scopeChanged updates selected scope")
    func scopeChanged() async {
        let store = TestStore(initialState: WrappedFeature.State()) {
            WrappedFeature()
        } withDependencies: {
            $0.wrappedContextClient = WrappedContextClient(loadTransactions: { [] })
            $0.date.now = Date()
        }

        await store.send(.scopeChanged(.year)) {
            $0.selectedScope = .year
            $0.isLoading = true
        }
        await store.receive(\.reportLoaded) { state in
            state.isLoading = false
            state.report = WrappedBuilder.build(transactions: [], scope: .year)
        }
    }
}
