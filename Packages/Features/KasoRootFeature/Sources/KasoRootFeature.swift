import ComposableArchitecture
import AppearanceFeature
import AuthFeature
import BudgetDomain
import OnboardingDomain
import OnboardingFeature
import TransactionFeature

@Reducer
public struct KasoRootFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var appearance: AppearanceFeature.State
        public var auth: AuthFeature.State
        public var onboarding: OnboardingFeature.State
        public var transaction: TransactionFeature.State

        public init(
            appearance: AppearanceFeature.State = AppearanceFeature.State(),
            auth: AuthFeature.State = AuthFeature.State(),
            onboarding: OnboardingFeature.State = OnboardingFeature.State(),
            transaction: TransactionFeature.State = TransactionFeature.State()
        ) {
            self.appearance = appearance
            self.auth = auth
            self.onboarding = onboarding
            self.transaction = transaction
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case appearance(AppearanceFeature.Action)
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case transaction(TransactionFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.appearance, action: \.appearance) {
            AppearanceFeature()
        }

        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .send(.appearance(.task))

            case let .onboarding(.profileLoaded(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case let .onboarding(.profileSaved(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case .appearance, .auth, .onboarding, .transaction:
                return .none
            }
        }
    }

    private static func budgets(from profile: OnboardingProfile?) -> [Budget] {
        profile?.suggestedBudgets.map {
            Budget(
                category: $0.category,
                monthlyLimit: $0.monthlyLimit
            )
        } ?? []
    }
}
