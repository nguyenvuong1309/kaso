import Foundation

/// Resolved product info coming back from StoreKit (or a mocked source for
/// tests). Decoupled from `StoreKit.Product` so the domain layer never
/// imports `StoreKit` directly.
public struct ResolvedProduct: Equatable, Sendable {
    public let productID: String
    public let displayName: String
    public let displayPrice: String
    public let priceVND: Decimal?

    public init(productID: String, displayName: String, displayPrice: String, priceVND: Decimal?) {
        self.productID = productID
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.priceVND = priceVND
    }
}

public enum PaywallPurchaseOutcome: Equatable, Sendable {
    case purchased(SubscriptionEntitlement)
    case userCancelled
    case pending
    case failed(String)
}

/// Adapter the paywall feature uses to talk to StoreKit. The live
/// implementation lives in the App target where StoreKit is wired up; the
/// domain only sees the pure data shapes.
public struct PaywallStoreClient: Sendable {
    public var fetchProducts: @Sendable ([String]) async throws -> [ResolvedProduct]
    public var purchase: @Sendable (String) async -> PaywallPurchaseOutcome
    public var restorePurchases: @Sendable () async -> PaywallPurchaseOutcome
    public var currentEntitlement: @Sendable () async -> SubscriptionEntitlement

    public init(
        fetchProducts: @escaping @Sendable ([String]) async throws -> [ResolvedProduct],
        purchase: @escaping @Sendable (String) async -> PaywallPurchaseOutcome,
        restorePurchases: @escaping @Sendable () async -> PaywallPurchaseOutcome,
        currentEntitlement: @escaping @Sendable () async -> SubscriptionEntitlement
    ) {
        self.fetchProducts = fetchProducts
        self.purchase = purchase
        self.restorePurchases = restorePurchases
        self.currentEntitlement = currentEntitlement
    }
}

public extension PaywallStoreClient {
    static let empty = PaywallStoreClient(
        fetchProducts: { _ in [] },
        purchase: { _ in .failed("paywall.error.storeUnavailable") },
        restorePurchases: { .failed("paywall.error.storeUnavailable") },
        currentEntitlement: { .free }
    )

    /// Offline preview returns the bundled prices so SwiftUI previews work
    /// without StoreKit configuration.
    static let preview = PaywallStoreClient(
        fetchProducts: { ids in
            PricingPlan.bundledCatalogue
                .filter { ids.contains($0.productID) }
                .map { plan in
                    ResolvedProduct(
                        productID: plan.productID,
                        displayName: plan.tier.rawValue.capitalized,
                        displayPrice: plan.priceVND.formatted(.currency(code: "VND")),
                        priceVND: plan.priceVND
                    )
                }
        },
        purchase: { productID in
            guard let plan = PricingPlan.bundledCatalogue.first(where: { $0.productID == productID }) else {
                return .failed("paywall.error.productNotFound")
            }
            return .purchased(
                SubscriptionEntitlement(
                    tier: plan.tier,
                    activePlanID: productID,
                    purchasedAt: Date(),
                    expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 30),
                    isInTrial: false
                )
            )
        },
        restorePurchases: { .purchased(.free) },
        currentEntitlement: { .free }
    )
}
