import Foundation

/// One purchasable offering inside the paywall — either a monthly or yearly
/// auto-renewing subscription tied to a `SubscriptionTier`.
public struct PricingPlan: Identifiable, Equatable, Sendable {
    public enum BillingCycle: String, Codable, Equatable, Sendable {
        case monthly
        case yearly
    }

    public let id: String
    public let productID: String
    public let tier: SubscriptionTier
    public let cycle: BillingCycle
    public let priceVND: Decimal
    public let isRecommended: Bool

    public init(
        productID: String,
        tier: SubscriptionTier,
        cycle: BillingCycle,
        priceVND: Decimal,
        isRecommended: Bool = false
    ) {
        id = productID
        self.productID = productID
        self.tier = tier
        self.cycle = cycle
        self.priceVND = priceVND
        self.isRecommended = isRecommended
    }
}

public extension PricingPlan {
    /// Bundled catalogue used by the paywall when StoreKit products are not
    /// yet loaded (offline, sandbox unavailable, preview). Numbers match
    /// `plan.md` § 19 — Pricing.
    static let bundledCatalogue: [PricingPlan] = [
        PricingPlan(
            productID: "com.vuongnguyen.kaso.pro.monthly",
            tier: .pro,
            cycle: .monthly,
            priceVND: 49_000
        ),
        PricingPlan(
            productID: "com.vuongnguyen.kaso.pro.yearly",
            tier: .pro,
            cycle: .yearly,
            priceVND: 399_000,
            isRecommended: true
        ),
        PricingPlan(
            productID: "com.vuongnguyen.kaso.family.monthly",
            tier: .family,
            cycle: .monthly,
            priceVND: 79_000
        ),
        PricingPlan(
            productID: "com.vuongnguyen.kaso.family.yearly",
            tier: .family,
            cycle: .yearly,
            priceVND: 599_000
        ),
    ]

    static func bundledPlans(for tier: SubscriptionTier) -> [PricingPlan] {
        bundledCatalogue.filter { $0.tier == tier }
    }
}
