import ComposableArchitecture
import Foundation
import PaywallDomain
import Testing
@testable import PaywallFeature

@MainActor
struct PaywallFeatureTests {
    @Test("task loads entitlement and resolved products")
    func taskLoadsEntitlementAndProducts() async {
        let product = ResolvedProduct(
            productID: "com.vuongnguyen.kaso.pro.yearly",
            displayName: "Pro Yearly",
            displayPrice: "399.000 ₫",
            priceVND: 399_000
        )
        let store = TestStore(initialState: PaywallFeature.State()) {
            PaywallFeature()
        } withDependencies: {
            $0.paywallStoreClient = PaywallStoreClient(
                fetchProducts: { _ in [product] },
                purchase: { _ in .userCancelled },
                restorePurchases: { .userCancelled },
                currentEntitlement: { .free }
            )
            $0.subscriptionEntitlementRepository = SubscriptionEntitlementRepository(
                load: { .free },
                save: { _ in }
            )
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
            $0.successMessageKey = nil
        }
        await store.receive(.entitlementLoaded(.free))
        await store.receive(.productsLoaded([product])) {
            $0.isLoading = false
            $0.resolvedProducts = [product.productID: product]
        }
    }

    @Test("selectTier switches the focused tier")
    func selectTier() async {
        let store = TestStore(initialState: PaywallFeature.State()) {
            PaywallFeature()
        } withDependencies: {
            $0.paywallStoreClient = .preview
            $0.subscriptionEntitlementRepository = .empty
        }

        await store.send(.selectTier(.family)) {
            $0.selectedTier = .family
        }
    }

    @Test("purchaseCompleted with purchased outcome updates entitlement and sets success")
    func purchasedUpdatesEntitlement() async {
        let entitlement = SubscriptionEntitlement(
            tier: .pro,
            activePlanID: "com.vuongnguyen.kaso.pro.yearly",
            purchasedAt: Date(timeIntervalSince1970: 1_700_000_000),
            expiresAt: Date(timeIntervalSince1970: 1_710_000_000),
            isInTrial: false
        )
        let store = TestStore(initialState: PaywallFeature.State(isPurchasing: true)) {
            PaywallFeature()
        } withDependencies: {
            $0.paywallStoreClient = .empty
            $0.subscriptionEntitlementRepository = SubscriptionEntitlementRepository(
                load: { .free },
                save: { _ in }
            )
        }

        await store.send(.purchaseCompleted(.purchased(entitlement))) {
            $0.isPurchasing = false
            $0.entitlement = entitlement
            $0.successMessageKey = "paywall.success.purchased"
        }
    }

    @Test("purchaseCompleted with failure sets error message")
    func failedPurchaseSetsError() async {
        let store = TestStore(initialState: PaywallFeature.State(isPurchasing: true)) {
            PaywallFeature()
        } withDependencies: {
            $0.paywallStoreClient = .empty
            $0.subscriptionEntitlementRepository = .empty
        }

        await store.send(.purchaseCompleted(.failed("paywall.error.storeUnavailable"))) {
            $0.isPurchasing = false
            $0.errorMessageKey = "paywall.error.storeUnavailable"
        }
    }

    @Test("restoreCompleted with cancelled outcome leaves state untouched")
    func restoreCancelled() async {
        let store = TestStore(initialState: PaywallFeature.State(isRestoring: true)) {
            PaywallFeature()
        } withDependencies: {
            $0.paywallStoreClient = .empty
            $0.subscriptionEntitlementRepository = .empty
        }

        await store.send(.restoreCompleted(.userCancelled)) {
            $0.isRestoring = false
        }
    }
}
