import ComposableArchitecture
import Foundation
import PaywallDomain

@Reducer
public struct PaywallFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var isLoading: Bool
        public var isPurchasing: Bool
        public var isRestoring: Bool
        public var entitlement: SubscriptionEntitlement
        public var selectedTier: SubscriptionTier
        public var resolvedProducts: [String: ResolvedProduct]
        public var errorMessageKey: String?
        public var successMessageKey: String?

        public init(
            isLoading: Bool = false,
            isPurchasing: Bool = false,
            isRestoring: Bool = false,
            entitlement: SubscriptionEntitlement = .free,
            selectedTier: SubscriptionTier = .pro,
            resolvedProducts: [String: ResolvedProduct] = [:],
            errorMessageKey: String? = nil,
            successMessageKey: String? = nil
        ) {
            self.isLoading = isLoading
            self.isPurchasing = isPurchasing
            self.isRestoring = isRestoring
            self.entitlement = entitlement
            self.selectedTier = selectedTier
            self.resolvedProducts = resolvedProducts
            self.errorMessageKey = errorMessageKey
            self.successMessageKey = successMessageKey
        }

        public var plansForSelectedTier: [PricingPlan] {
            PricingPlan.bundledPlans(for: selectedTier)
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case productsLoaded([ResolvedProduct])
        case entitlementLoaded(SubscriptionEntitlement)
        case loadFailed(String)
        case selectTier(SubscriptionTier)
        case purchaseButtonTapped(String)
        case purchaseCompleted(PaywallPurchaseOutcome)
        case restoreButtonTapped
        case restoreCompleted(PaywallPurchaseOutcome)
        case dismissError
    }

    @Dependency(\.paywallStoreClient) private var storeClient
    @Dependency(\.subscriptionEntitlementRepository) private var entitlementRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                state.successMessageKey = nil
                let productIDs = PricingPlan.bundledCatalogue.map(\.productID)
                return .run { send in
                    do {
                        let entitlement = try await entitlementRepository.load()
                        await send(.entitlementLoaded(entitlement))
                        let products = try await storeClient.fetchProducts(productIDs)
                        await send(.productsLoaded(products))
                    } catch {
                        await send(.loadFailed("paywall.error.loadFailed"))
                    }
                }

            case let .entitlementLoaded(entitlement):
                state.entitlement = entitlement
                if entitlement.tier > .free {
                    state.selectedTier = entitlement.tier
                }
                return .none

            case let .productsLoaded(products):
                state.isLoading = false
                var map: [String: ResolvedProduct] = [:]
                for product in products {
                    map[product.productID] = product
                }
                state.resolvedProducts = map
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case let .selectTier(tier):
                state.selectedTier = tier
                state.errorMessageKey = nil
                return .none

            case let .purchaseButtonTapped(productID):
                guard state.isPurchasing == false else { return .none }
                state.isPurchasing = true
                state.errorMessageKey = nil
                state.successMessageKey = nil
                return .run { send in
                    let outcome = await storeClient.purchase(productID)
                    await send(.purchaseCompleted(outcome))
                }

            case let .purchaseCompleted(outcome):
                state.isPurchasing = false
                return handlePurchaseOutcome(&state, outcome: outcome)

            case .restoreButtonTapped:
                guard state.isRestoring == false else { return .none }
                state.isRestoring = true
                state.errorMessageKey = nil
                state.successMessageKey = nil
                return .run { send in
                    let outcome = await storeClient.restorePurchases()
                    await send(.restoreCompleted(outcome))
                }

            case let .restoreCompleted(outcome):
                state.isRestoring = false
                return handlePurchaseOutcome(&state, outcome: outcome)

            case .dismissError:
                state.errorMessageKey = nil
                return .none
            }
        }
    }

    private func handlePurchaseOutcome(_ state: inout State, outcome: PaywallPurchaseOutcome) -> Effect<Action> {
        switch outcome {
        case let .purchased(entitlement):
            state.entitlement = entitlement
            state.successMessageKey = entitlement.tier == .free
                ? "paywall.success.restored"
                : "paywall.success.purchased"
            return .run { _ in
                try? await entitlementRepository.save(entitlement)
            }

        case .userCancelled:
            return .none

        case .pending:
            state.successMessageKey = "paywall.success.pending"
            return .none

        case let .failed(messageKey):
            state.errorMessageKey = messageKey
            return .none
        }
    }
}
