import ComposableArchitecture
import AppearanceFeature
import AuthFeature
import BenchmarkFeature
import BudgetDomain
import CoolingOffFeature
import DebtFeature
import FinancialAssistantFeature
import GuiltFreeBudgetFeature
import InvestmentFeature
import MoodJournalFeature
import OnboardingDomain
import OnboardingFeature
import PaywallDomain
import PaywallFeature
import RegretScoreFeature
import RoundUpFeature
import SpendingCalendarFeature
import TransactionFeature
import WealthFeature
import WellnessFeature
import WhatIfFeature

@Reducer
public struct KasoRootFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var appearance: AppearanceFeature.State
        public var auth: AuthFeature.State
        public var benchmark: BenchmarkFeature.State
        public var onboarding: OnboardingFeature.State
        public var transaction: TransactionFeature.State
        public var assistant: FinancialAssistantFeature.State
        public var wealth: WealthFeature.State
        public var investment: InvestmentFeature.State
        public var wellness: WellnessFeature.State
        public var debt: DebtFeature.State
        public var paywall: PaywallFeature.State
        public var isPaywallPresented: Bool
        public var currentEntitlement: SubscriptionEntitlement
        public var paywallGateRequestedFeature: SubscriptionFeatureFlag?

        public init(
            appearance: AppearanceFeature.State = AppearanceFeature.State(),
            auth: AuthFeature.State = AuthFeature.State(),
            benchmark: BenchmarkFeature.State = BenchmarkFeature.State(),
            onboarding: OnboardingFeature.State = OnboardingFeature.State(),
            transaction: TransactionFeature.State = TransactionFeature.State(),
            assistant: FinancialAssistantFeature.State = FinancialAssistantFeature.State(),
            wealth: WealthFeature.State = WealthFeature.State(),
            investment: InvestmentFeature.State = InvestmentFeature.State(),
            wellness: WellnessFeature.State = WellnessFeature.State(),
            debt: DebtFeature.State = DebtFeature.State(),
            paywall: PaywallFeature.State = PaywallFeature.State(),
            isPaywallPresented: Bool = false,
            currentEntitlement: SubscriptionEntitlement = .free,
            paywallGateRequestedFeature: SubscriptionFeatureFlag? = nil
        ) {
            self.appearance = appearance
            self.auth = auth
            self.benchmark = benchmark
            self.onboarding = onboarding
            self.transaction = transaction
            self.assistant = assistant
            self.wealth = wealth
            self.investment = investment
            self.wellness = wellness
            self.debt = debt
            self.paywall = paywall
            self.isPaywallPresented = isPaywallPresented
            self.currentEntitlement = currentEntitlement
            self.paywallGateRequestedFeature = paywallGateRequestedFeature
        }

        public func gateDecision(for feature: SubscriptionFeatureFlag) -> PaywallGateDecision {
            PaywallGate.evaluate(feature: feature, entitlement: currentEntitlement)
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case appearance(AppearanceFeature.Action)
        case auth(AuthFeature.Action)
        case benchmark(BenchmarkFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case transaction(TransactionFeature.Action)
        case assistant(FinancialAssistantFeature.Action)
        case wealth(WealthFeature.Action)
        case investment(InvestmentFeature.Action)
        case wellness(WellnessFeature.Action)
        case debt(DebtFeature.Action)
        case paywall(PaywallFeature.Action)
        case paywallButtonTapped
        case paywallDismissed
        case paywallPromptEvaluated(Bool)
        case entitlementLoaded(SubscriptionEntitlement)
        case proGateRequested(SubscriptionFeatureFlag)
    }

    @Dependency(\.subscriptionEntitlementRepository) private var entitlementRepository
    @Dependency(\.paywallPromptScheduleRepository) private var paywallPromptScheduleRepository
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.appearance, action: \.appearance) {
            AppearanceFeature()
        }

        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        Scope(state: \.benchmark, action: \.benchmark) {
            BenchmarkFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }

        Scope(state: \.assistant, action: \.assistant) {
            FinancialAssistantFeature()
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

        Scope(state: \.paywall, action: \.paywall) {
            PaywallFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .send(.appearance(.task)),
                    evaluatePaywallPrompt()
                )

            case .paywallPromptEvaluated(let shouldPrompt):
                guard shouldPrompt else { return .none }
                state.isPaywallPresented = true
                return .run { [reference = now] _ in
                    var schedule = (try? await paywallPromptScheduleRepository.load()) ?? .initial
                    PaywallPromptScheduler.recordPromptShown(in: &schedule, now: reference)
                    try? await paywallPromptScheduleRepository.save(schedule)
                }

            case let .onboarding(.profileLoaded(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case let .onboarding(.profileSaved(profile)):
                return .send(.transaction(.budgetsUpdated(Self.budgets(from: profile))))

            case .paywallButtonTapped:
                state.paywallGateRequestedFeature = nil
                state.isPaywallPresented = true
                return .send(.paywall(.setTriggeringFeature(nil)))

            case .paywallDismissed:
                state.isPaywallPresented = false
                state.paywallGateRequestedFeature = nil
                return .send(.paywall(.setTriggeringFeature(nil)))

            case let .entitlementLoaded(entitlement):
                state.currentEntitlement = entitlement
                return .send(.transaction(.entitlementUpdated(entitlement)))

            case let .transaction(.delegate(.paywallGateRequested(feature))):
                return .send(.proGateRequested(feature))

            case let .proGateRequested(feature):
                let decision = PaywallGate.evaluate(
                    feature: feature,
                    entitlement: state.currentEntitlement
                )
                guard decision.isGated else { return .none }
                state.paywallGateRequestedFeature = feature
                state.isPaywallPresented = true
                return .send(.paywall(.setTriggeringFeature(feature)))

            case .appearance, .auth, .benchmark, .onboarding, .transaction, .assistant,
                 .wealth, .investment, .wellness, .debt, .paywall:
                return .none
            }
        }
    }

    private func evaluatePaywallPrompt() -> Effect<Action> {
        .run { [reference = now] send in
            var schedule = (try? await paywallPromptScheduleRepository.load()) ?? .initial
            PaywallPromptScheduler.recordFirstLaunchIfNeeded(in: &schedule, now: reference)
            try? await paywallPromptScheduleRepository.save(schedule)
            let entitlement = (try? await entitlementRepository.load()) ?? .free
            await send(.entitlementLoaded(entitlement))
            let shouldPrompt = PaywallPromptScheduler.shouldPrompt(
                tier: entitlement.tier,
                schedule: schedule,
                now: reference
            )
            await send(.paywallPromptEvaluated(shouldPrompt))
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
