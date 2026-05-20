import ComposableArchitecture
import Foundation
import WrappedDomain

@Reducer
public struct WrappedFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var report: WrappedReport
        public var selectedScope: WrappedScope
        public var isLoading: Bool
        public var isShareSheetPresented: Bool
        public var errorMessageKey: String?

        public init(
            report: WrappedReport = .empty,
            selectedScope: WrappedScope = .month,
            isLoading: Bool = false,
            isShareSheetPresented: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.report = report
            self.selectedScope = selectedScope
            self.isLoading = isLoading
            self.isShareSheetPresented = isShareSheetPresented
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case scopeChanged(WrappedScope)
        case reportLoaded(WrappedReport)
        case loadFailed(String)
        case shareButtonTapped
        case shareSheetDismissed
    }

    @Dependency(\.wrappedContextClient) private var contextClient
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                let scope = state.selectedScope
                return .run { send in
                    do {
                        let transactions = try await contextClient.loadTransactions()
                        let report = WrappedBuilder.build(
                            transactions: transactions,
                            scope: scope
                        )
                        await send(.reportLoaded(report))
                    } catch {
                        await send(.loadFailed("wrapped.error.loadFailed"))
                    }
                }

            case let .scopeChanged(scope):
                state.selectedScope = scope
                state.isLoading = true
                return .run { send in
                    let transactions = (try? await contextClient.loadTransactions()) ?? []
                    let report = WrappedBuilder.build(transactions: transactions, scope: scope)
                    await send(.reportLoaded(report))
                }

            case let .reportLoaded(report):
                state.isLoading = false
                state.report = report
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case .shareButtonTapped:
                state.isShareSheetPresented = true
                return .none

            case .shareSheetDismissed:
                state.isShareSheetPresented = false
                return .none
            }
        }
    }
}
