import Foundation

/// The user's active paid entitlement, derived from StoreKit transactions.
///
/// `tier` always reflects the highest currently-active product. `expiresAt`
/// is informational — the source of truth is StoreKit verification at
/// runtime.
public struct SubscriptionEntitlement: Codable, Equatable, Sendable {
    public var tier: SubscriptionTier
    public var activePlanID: String?
    public var purchasedAt: Date?
    public var expiresAt: Date?
    public var isInTrial: Bool

    public init(
        tier: SubscriptionTier = .free,
        activePlanID: String? = nil,
        purchasedAt: Date? = nil,
        expiresAt: Date? = nil,
        isInTrial: Bool = false
    ) {
        self.tier = tier
        self.activePlanID = activePlanID
        self.purchasedAt = purchasedAt
        self.expiresAt = expiresAt
        self.isInTrial = isInTrial
    }

    public static let free = SubscriptionEntitlement()
}

public struct SubscriptionEntitlementRepository: Sendable {
    public var load: @Sendable () async throws -> SubscriptionEntitlement
    public var save: @Sendable (SubscriptionEntitlement) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> SubscriptionEntitlement,
        save: @escaping @Sendable (SubscriptionEntitlement) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension SubscriptionEntitlementRepository {
    static let empty = SubscriptionEntitlementRepository(
        load: { .free },
        save: { _ in }
    )

    static let preview = SubscriptionEntitlementRepository(
        load: {
            SubscriptionEntitlement(
                tier: .pro,
                activePlanID: "com.vuongnguyen.kaso.pro.yearly",
                purchasedAt: Date().addingTimeInterval(-60 * 60 * 24 * 30),
                expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 335),
                isInTrial: false
            )
        },
        save: { _ in }
    )
}
