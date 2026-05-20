import ComposableArchitecture
import Foundation
import MoneyPersonalityDomain

@Reducer
public struct MoneyPersonalityFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var profile: MoneyPersonalityProfile
        public var isAnalyzing: Bool
        public var isShareSheetPresented: Bool
        public var errorMessageKey: String?

        public init(
            profile: MoneyPersonalityProfile = .insufficientPlaceholder,
            isAnalyzing: Bool = false,
            isShareSheetPresented: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.profile = profile
            self.isAnalyzing = isAnalyzing
            self.isShareSheetPresented = isShareSheetPresented
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case analyze
        case profileLoaded(MoneyPersonalityProfile)
        case analysisFailed(String)
        case shareButtonTapped
        case shareSheetDismissed
    }

    @Dependency(\.moneyPersonalityContextClient) private var contextClient
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task, .analyze:
                state.isAnalyzing = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let context = try await contextClient.load()
                        let profile = MoneyPersonalityAnalyzer.analyze(
                            transactions: context.transactions,
                            budgetUtilizationRatio: context.budgetUtilizationRatio,
                            savingsRate: context.savingsRate
                        )
                        await send(.profileLoaded(profile))
                    } catch {
                        await send(.analysisFailed("personality.error.analysisFailed"))
                    }
                }

            case let .profileLoaded(profile):
                state.isAnalyzing = false
                state.profile = profile
                return .none

            case let .analysisFailed(key):
                state.isAnalyzing = false
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
