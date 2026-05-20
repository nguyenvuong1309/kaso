import ComposableArchitecture
import Foundation
import SeasonalPlannerDomain

@Reducer
public struct SeasonalPlannerFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var plan: SeasonalPlan
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            plan: SeasonalPlan = .empty,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.plan = plan
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case planLoaded(SeasonalPlan)
        case loadFailed(String)
    }

    @Dependency(\.seasonalContextClient) private var contextClient
    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { [referenceDate = date.now] send in
                    do {
                        let transactions = try await contextClient.loadTransactions()
                        let plan = SeasonalPlanBuilder.build(
                            transactions: transactions,
                            referenceDate: referenceDate
                        )
                        await send(.planLoaded(plan))
                    } catch {
                        await send(.loadFailed("seasonalPlanner.error.loadFailed"))
                    }
                }

            case let .planLoaded(plan):
                state.isLoading = false
                state.plan = plan
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}
