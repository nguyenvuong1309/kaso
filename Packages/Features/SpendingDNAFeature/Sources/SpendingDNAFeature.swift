import ComposableArchitecture
import Foundation
import SpendingDNADomain

@Reducer
public struct SpendingDNAFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var report: SpendingDNAReport
        public var isLoading: Bool
        public var isShareSheetPresented: Bool
        public var errorMessageKey: String?

        public init(
            report: SpendingDNAReport = .empty,
            isLoading: Bool = false,
            isShareSheetPresented: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.report = report
            self.isLoading = isLoading
            self.isShareSheetPresented = isShareSheetPresented
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case reportLoaded(SpendingDNAReport)
        case loadFailed(String)
        case shareButtonTapped
        case shareSheetDismissed
    }

    @Dependency(\.spendingDNAContextClient) private var contextClient

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let transactions = try await contextClient.loadTransactions()
                        let report = SpendingDNABuilder.build(transactions: transactions)
                        await send(.reportLoaded(report))
                    } catch {
                        await send(.loadFailed("dna.error.loadFailed"))
                    }
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
