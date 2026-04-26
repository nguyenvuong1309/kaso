import AuthFeature
import ComposableArchitecture
import OnboardingFeature
import TransactionFeature

@Reducer
public struct KasoRootFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var auth: AuthFeature.State
        public var onboarding: OnboardingFeature.State
        public var transaction: TransactionFeature.State

        public init(
            auth: AuthFeature.State = AuthFeature.State(),
            onboarding: OnboardingFeature.State = OnboardingFeature.State(),
            transaction: TransactionFeature.State = TransactionFeature.State()
        ) {
            self.auth = auth
            self.onboarding = onboarding
            self.transaction = transaction
        }
    }

    public enum Action: Equatable, Sendable {
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case transaction(TransactionFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }
    }
}
