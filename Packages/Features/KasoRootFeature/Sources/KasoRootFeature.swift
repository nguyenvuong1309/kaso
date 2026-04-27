import ComposableArchitecture
import AppearanceFeature
import AuthFeature
import BudgetDomain
import DebtFeature
import InvestmentFeature
import OnboardingDomain
import OnboardingFeature
import TransactionFeature
import WealthFeature
import WellnessFeature

@Reducer
public struct KasoRootFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var appearance: AppearanceFeature.State
        public var auth: AuthFeature.State
        public var onboarding: OnboardingFeature.State
        public var transaction: TransactionFeature.State
        public var wealth: WealthFeature.State
        public var investment: InvestmentFeature.State
        public var wellness: WellnessFeature.State
        public var debt: DebtFeature.State

        public init(
            appearance: AppearanceFeature.State = AppearanceFeature.State(),
            auth: AuthFeature.State = AuthFeature.State(),
            onboarding: OnboardingFeature.State = OnboardingFeature.State(),
            transaction: TransactionFeature.State = TransactionFeature.State(),
            wealth: WealthFeature.State = WealthFeature.State(),
            investment: InvestmentFeature.State = InvestmentFeature.State(),
            wellness: WellnessFeature.State = WellnessFeature.State(),
            debt: DebtFeature.State = DebtFeature.State()
        ) {
            self.appearance = appearance
            self.auth = auth
            self.onboarding = onboarding
            self.transaction = transaction
            self.wealth = wealth
            self.investment = investment
            self.wellness = wellness
            self.debt = debt
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case appearance(AppearanceFeature.Action)
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case transaction(TransactionFeature.Action)
        case wealth(WealthFeature.Action)
        case investment(InvestmentFeature.Action)
        case wellness(WellnessFeature.Action)
        case debt(DebtFeature.Action)
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

        Scope(state: \.wealth, action: \.wealth) {
            WealthFeature()
        }

        Scope(state: \.investment, action: \.investment) {
            InvestmentFeature()
        }

        Scope(state: \.wellness, action: \.wellness) {
            WellnessFeature()
        }

        Scope(state: \.debt, action: \.debt) {
            DebtFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .send(.appearance(.task))

            case let .onboarding(.profileLoaded(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case let .onboarding(.profileSaved(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case .appearance, .auth, .onboarding, .transaction, .wealth, .investment, .wellness, .debt:
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
