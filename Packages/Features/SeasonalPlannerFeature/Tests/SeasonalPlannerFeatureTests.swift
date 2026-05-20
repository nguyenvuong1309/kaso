import ComposableArchitecture
import Foundation
import SeasonalPlannerDomain
import Testing
@testable import SeasonalPlannerFeature

@MainActor
struct SeasonalPlannerFeatureTests {
    @Test("task loads plan from context client")
    func taskLoadsPlan() async {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()

        let inputs: [SeasonalTransactionInput] = (2024 ... 2025).flatMap { year in
            (1 ... 12).compactMap { month -> SeasonalTransactionInput? in
                var comps = DateComponents()
                comps.year = year
                comps.month = month
                comps.day = 10
                guard let date = calendar.date(from: comps) else { return nil }
                let isTet = month == 2
                return SeasonalTransactionInput(
                    amount: Decimal(isTet ? 9_000_000 : 2_000_000),
                    isExpense: true,
                    occurredAt: date
                )
            }
        }

        let store = TestStore(initialState: SeasonalPlannerFeature.State()) {
            SeasonalPlannerFeature()
        } withDependencies: {
            $0.seasonalContextClient = SeasonalContextClient(loadTransactions: { inputs })
            $0.date = .constant(referenceDate)
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }

        let expected = SeasonalPlanBuilder.build(
            transactions: inputs,
            referenceDate: referenceDate
        )

        await store.receive(\.planLoaded) {
            $0.isLoading = false
            $0.plan = expected
        }
    }

    @Test("task surfaces error on failure")
    func taskFailure() async {
        struct LoadError: Error {}
        let store = TestStore(initialState: SeasonalPlannerFeature.State()) {
            SeasonalPlannerFeature()
        } withDependencies: {
            $0.seasonalContextClient = SeasonalContextClient(loadTransactions: {
                throw LoadError()
            })
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }

        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessageKey = "seasonalPlanner.error.loadFailed"
        }
    }
}
